(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2026 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit unit_gpu_calc;

(* Evaluates a whole LFPSO population on the GPU: for every particle the
   Parratt reflectivity on the measured angles, the resolution convolution and
   the chi-squared TCalc.CalcChiSquare computes, in two compute dispatches.

   Direct3D 11 compute shaders, so there is no runtime to install: d3d11.dll,
   dxgi.dll and d3dcompiler_47.dll ship with Windows 10 and later, and the same
   code runs in the Win32 and the Win64 builds. The shader is compiled from the
   HLSL below once per process.

   The recursion mirrors TCalc.RefCalc layer for layer, with one change of
   form: eps - sin^2(t) at t near 90 degrees is computed as
   (eps.re - 1) + sin^2(theta) from the grazing angle. The naive form cancels
   (eps ~ 1 - 1e-5) and doubled the error against a double-precision reference;
   in this form the GPU is at least as accurate as the CPU engine (mean
   |log10 R| error 1.0e-3 against 1.5e-3, 2026-09-21).

   Each fit owns one TGpuEvaluator and uses it from the fitting thread only:
   a D3D11 immediate context is not thread-safe. *)

interface

uses
  System.SysUtils, System.SyncObjs,
  Winapi.Windows, Winapi.DXGI, Winapi.D3DCommon, Winapi.D3D11, Winapi.D3DCompiler,
  unit_Types, unit_calc;

type
  EGpuError = class(Exception);

  TGpuEvaluator = class
  private type
    TParamsCB = packed record
      NLay, NAng, NPart, Pol: UINT;
      c1, c2, Limit, KScale: Single;
      ConvN, WinSize, ChiFirst, ChiLast: UINT;
      RF, PartOffset: UINT;
      ChiNorm, Pad: Single;
      SolveScale: UINT;
      ScaleWindow, Pad2, Pad3: Single;
    end;
  private class var
    FLock: TCriticalSection;
    FReflectCode, FChiCode: TBytes;
    FProbed, FProbeOK: Boolean;
    FProbeName, FProbeError: string;
    FProbeTick: UInt64;
    FFailAfter: Integer;
  private
    FDev: ID3D11Device;
    FCtx: ID3D11DeviceContext;
    FReflect, FChi: ID3D11ComputeShader;
    FCB: ID3D11Buffer;
    FLayers, FTheta, FWeights, FLogData, FPointWeight, FCurve, FChiBuf: ID3D11Buffer;
    FChiStage, FRowStage: ID3D11Buffer;
    FSRV: array [0..4] of ID3D11ShaderResourceView;
    FUAV: array [0..1] of ID3D11UnorderedAccessView;
    FParams: TParamsCB;
    FNLay, FNAng, FNPart, FChunk: Integer;
    FStepsPerDispatch: Int64;
    FAdapterName: string;
    class procedure Check(HR: HRESULT; const What: string); static;
    class procedure CompileShaders; static;
    function Structured(ElemSize, Count: UINT; Bind: UINT; Init: Pointer): ID3D11Buffer;
    function Staging(Size: UINT): ID3D11Buffer;
    procedure SetOffset(Offset, Count: Integer);
  public
    class constructor Create;
    class destructor Destroy;
    /// <summary>Whether a GPU evaluator can be created on this machine: a
    /// hardware adapter, feature level 11_0 and the shader compiler. A success
    /// holds for the process, a failure is tried again after a minute; Name is
    /// the adapter, Error why it cannot.</summary>
    class function Available(out Name, Error: string): Boolean; static;

    /// <summary>Opens the hardware adapter with the most dedicated memory.
    /// Raises EGpuError when there is none that can run the shaders.</summary>
    constructor Create;
    /// <summary>Sizes every buffer for NPart particles of NLay layers
    /// (ambient and substrate included) on the angles of Inputs.</summary>
    procedure Setup(const Inputs: TGpuEvalInputs; NLay, NPart: Integer;
      Pol: TPolarisation; RF: TRoughnessFunction; Lambda, KScale, Limit: Single);
    /// <summary>Layers holds NPart * NLay records of four Singles, particle
    /// after particle, each model surface first: e.re, e.im, thickness, sigma.
    /// Chi receives one chi-squared per particle.</summary>
    procedure Evaluate(const Layers: TArray<Single>; var Chi: TArray<Single>);
    /// <summary>The raw (unconvolved, Limit-clamped) curve of one particle of
    /// the last Evaluate, for TCalc.FinishRawCurve.</summary>
    function RawCurve(Particle: Integer): TArray<Single>;
    property AdapterName: string read FAdapterName;
    property LayerCount: Integer read FNLay;
    property ParticleCount: Integer read FNPart;
    /// <summary>Angle x layer steps one Reflect dispatch may take; more
    /// particles than that are split over several dispatches. Set before
    /// Setup. Tests lower it to exercise the split.</summary>
    property StepsPerDispatch: Int64 read FStepsPerDispatch write FStepsPerDispatch;
    /// <summary>Particles per dispatch after Setup.</summary>
    property ParticlesPerDispatch: Integer read FChunk;
    /// <summary>Test hook: when positive, the N-th Evaluate of any evaluator
    /// in the process raises EGpuError instead of running, once, and the
    /// hook resets itself. It exercises the engines' fallback to the CPU.
    /// </summary>
    class property FailAfter: Integer read FFailAfter write FFailAfter;
  end;

implementation

const
  { Upper bound on angle x layer steps per Reflect dispatch. At ~8 ps a step on
    an RTX 5080 this is ~2 ms; a GPU fifty times slower still stays far from
    the two-second Windows timeout (TDR). }
  MAX_STEPS_PER_DISPATCH = 250000000;
  MAX_GROUPS = 65535;
  { Largest buffer asked for. D3D11 guarantees 128 MB and allows up to a
    quarter of video memory; beyond this the CPU is the safer engine. }
  MAX_BUFFER_BYTES = Int64(1) shl 30;
  THREADS_X = 64;

  HLSL = '''
    cbuffer Params : register(b0)
    {
        uint  NLay;       // layers incl. ambient (0) and substrate (NLay-1)
        uint  NAng;
        uint  NPart;      // particles in this dispatch
        uint  Pol;        // 0 = S, 1 = S+P averaged
        float c1;         // 4 pi / lambda
        float c2;         // c1 / 2
        float Limit;
        float KScale;     // TCalcThreadParams.K
        uint  ConvN;      // half window, 0 = no convolution
        uint  WinSize;
        uint  ChiFirst;
        uint  ChiLast;    // inclusive
        uint  RF;         // TRoughnessFunction
        uint  PartOffset; // first particle of this dispatch
        float ChiNorm;    // 1000 / High(data)
        float Pad;
        uint  SolveScale; // 1: score at the scale that minimises chi2 (TCalc.SolveScale)
        float ScaleWindow;// |log10 scale| bound; 0 pins it
        float Pad2;
        float Pad3;
    };

    StructuredBuffer<float4> Layers      : register(t0);  // e.re, e.im, L, sigma
    StructuredBuffer<float>  Theta       : register(t1);
    StructuredBuffer<float>  Weights     : register(t2);
    StructuredBuffer<float>  LogData     : register(t3);
    StructuredBuffer<float>  PointWeight : register(t4);
    RWStructuredBuffer<float> Curve      : register(u0);  // raw R, particle-major
    RWStructuredBuffer<float> Chi        : register(u1);

    float2 cmul(float2 a, float2 b) { return float2(a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x); }
    float2 cdiv(float2 a, float2 b)
    {
        float d = 1.0 / (b.x*b.x + b.y*b.y);
        return float2((a.x*b.x + a.y*b.y) * d, (a.y*b.x - a.x*b.y) * d);
    }
    // the branch of math_complex.SqrtZ
    float2 csqrt(float2 z)
    {
        if (z.x == 0 && z.y == 0) return float2(0, 0);
        float m = length(z);
        if (z.x > 0)
        {
            m += z.x;
            return float2(sqrt(m * 0.5), z.y * rsqrt(m * 2));
        }
        m -= z.x;
        float im = sqrt(m * 0.5);
        return float2(abs(z.y) * rsqrt(m * 2), z.y < 0 ? -im : im);
    }
    // TCalc.RefCalc's Roughness
    float Roughness(float sigma, float s)
    {
        if (RF == 0) return exp(-(sigma * sigma * 0.5) * s * s);
        if (RF == 1) return 1.0 / (1.0 + (s * s * sigma * sigma) * 0.5);
        if (RF == 2)
        {
            if (sigma >= 0.5) return 1.0;
            float x = 1.73205080757 * sigma * s;
            return x == 0 ? 1.0 : sin(x) / x;
        }
        if (RF == 3) return cos(sigma * s);
        return 0.0;
    }

    [numthreads(64, 1, 1)]
    void Reflect(uint3 gid : SV_DispatchThreadID)
    {
        uint a = gid.x;
        if (a >= NAng) return;
        uint p = gid.y + PartOffset;

        // cos_t = sin(grazing angle): keep eps - sin^2(t) as (eps - 1) + cos_t^2
        float cos_t = sin(0.0174532925199 * (Theta[a] / KScale));
        float cos2 = cos_t * cos_t;

        uint base = p * NLay;
        float4 lb = Layers[base + NLay - 1];            // the layer below, i + 1
        float2 eB = lb.xy;
        float2 KB = c2 * csqrt(float2((eB.x - 1) + cos2, eB.y));
        float2 R  = float2(0, 0);
        float2 Rp = float2(0, 0);
        bool first = true;   // R = 0 below the first interface: no phase term

        for (int i = (int)NLay - 2; i >= 0; --i)
        {
            float4 li = Layers[base + i];
            float2 ei = li.xy;
            float2 Ki = c2 * csqrt(float2((ei.x - 1) + cos2, ei.y));

            float eRatio = length(cdiv(ei, eB));
            float s1 = abs((1 - eRatio) + eRatio * cos2);
            float rf = Roughness(lb.w, c1 * sqrt(cos_t * sqrt(s1)));

            float2 RFs = rf * cdiv(Ki - KB, Ki + KB);
            float2 RFp = float2(0, 0);
            if (Pol == 1)
            {
                float2 k1 = cdiv(Ki, ei);
                float2 k2 = cdiv(KB, eB);
                RFp = rf * cdiv(k1 - k2, k1 + k2);
            }

            if (first)
            {
                // The substrate's "thickness" is a 1e8 A sentinel: its phase
                // would be sincos of ~1e8, which D3D leaves unspecified, and
                // it multiplies R = 0 anyway.
                R = RFs;
                Rp = RFp;
                first = false;
            }
            else
            {
                float L2 = lb.z * 2;
                float ex = exp(-L2 * KB.y);
                float sp, cp;
                sincos(L2 * KB.x, sp, cp);
                float2 ph = float2(ex * cp, ex * sp);

                float2 a1 = cmul(R, ph);
                R = cdiv(RFs + a1, float2(1, 0) + cmul(RFs, a1));
                if (Pol == 1)
                {
                    float2 b1 = cmul(Rp, ph);
                    Rp = cdiv(RFp + b1, float2(1, 0) + cmul(RFp, b1));
                }
            }

            lb = li; eB = ei; KB = Ki;
        }

        float r = dot(R, R);
        if (Pol == 1) r = (r + dot(Rp, Rp)) * 0.5;
        Curve[p * NAng + a] = max(r, Limit);
    }

    #define CHI_THREADS 256
    groupshared float P0[CHI_THREADS];
    groupshared float P1[CHI_THREADS];
    groupshared float P2[CHI_THREADS];

    // The same sum TCalc.CalcChiSquare builds, as three partial sums so that
    // the scale can be solved in closed form: with W = PointWeight / (log10 R)^2
    // and d = log10 D - log10 R, chi2(a) = S2 + 2 a S1 + a^2 S0 for a scale
    // 10^a on the data, and a* = -S1/S0. SolveScale = 0 leaves a = 0.
    [numthreads(CHI_THREADS, 1, 1)]
    void ChiSquare(uint3 gtid : SV_GroupThreadID, uint3 grp : SV_GroupID)
    {
        uint p = grp.x + PartOffset;
        uint base = p * NAng;
        float s0 = 0, s1 = 0, s2 = 0;
        for (uint i = ChiFirst + gtid.x; i <= ChiLast; i += CHI_THREADS)
        {
            float r = 0;
            for (uint k = 0; k < WinSize; ++k)
                r += Curve[base + i - ConvN + k] * Weights[k];
            if (r != 0)
            {
                float lr = 0.434294481903 * log(r);
                float w = PointWeight[i] / (lr * lr);
                float d = LogData[i] - lr;
                s2 += w * d * d;
                s1 += w * d;
                s0 += w;
            }
        }
        P0[gtid.x] = s0; P1[gtid.x] = s1; P2[gtid.x] = s2;
        GroupMemoryBarrierWithGroupSync();
        for (uint s = CHI_THREADS / 2; s > 0; s >>= 1)
        {
            if (gtid.x < s)
            {
                P0[gtid.x] += P0[gtid.x + s];
                P1[gtid.x] += P1[gtid.x + s];
                P2[gtid.x] += P2[gtid.x + s];
            }
            GroupMemoryBarrierWithGroupSync();
        }
        if (gtid.x == 0)
        {
            float a = 0;
            if (SolveScale != 0 && P0[0] > 0)
                a = clamp(-P1[0] / P0[0], -ScaleWindow, ScaleWindow);
            Chi[p] = (P2[0] + 2 * a * P1[0] + a * a * P0[0]) * ChiNorm;
        }
    }
    ''';

{ TGpuEvaluator }

class constructor TGpuEvaluator.Create;
begin
  FLock := TCriticalSection.Create;
end;

class destructor TGpuEvaluator.Destroy;
begin
  FLock.Free;
end;

class procedure TGpuEvaluator.Check(HR: HRESULT; const What: string);
begin
  if Failed(HR) then
    raise EGpuError.CreateFmt('%s failed (HRESULT 0x%.8x)', [What, Cardinal(HR)]);
end;

class procedure TGpuEvaluator.CompileShaders;

  function Compile(const Entry: AnsiString): TBytes;
  var
    Src: AnsiString;
    Code, Errors: ID3DBlob;
    HR: HRESULT;
  begin
    Src := AnsiString(HLSL);
    HR := D3DCompile(PAnsiChar(Src), Length(Src), 'unit_gpu_calc.hlsl', nil, nil,
      PAnsiChar(Entry), 'cs_5_0', D3DCOMPILE_OPTIMIZATION_LEVEL3, 0, Code, Errors);
    if Failed(HR) then
    begin
      if Errors <> nil then
        raise EGpuError.Create('Shader compilation failed: ' +
          string(PAnsiChar(Errors.GetBufferPointer)));
      Check(HR, 'D3DCompile');
    end;
    SetLength(Result, Code.GetBufferSize);
    Move(Code.GetBufferPointer^, Result[0], Length(Result));
  end;

var
  Reflect, Chi: TBytes;
begin
  FLock.Enter;
  try
    if (Length(FReflectCode) = 0) or (Length(FChiCode) = 0) then
    begin
      Reflect := Compile('Reflect');
      Chi := Compile('ChiSquare');
      FReflectCode := Reflect;       // both or neither
      FChiCode := Chi;
    end;
  finally
    FLock.Leave;
  end;
end;

class function TGpuEvaluator.Available(out Name, Error: string): Boolean;
var
  G: TGpuEvaluator;
begin
  FLock.Enter;
  try
    { A success holds for the process; a failure is tried again after a
      minute, so that a long-running server recovers from a driver reset or
      a remote session that had no GPU. }
    if (not FProbed) or ((not FProbeOK) and (GetTickCount64 - FProbeTick > 60000)) then
    begin
      FProbed := True;
      FProbeTick := GetTickCount64;
      FProbeError := '';
      try
        G := TGpuEvaluator.Create;
        try
          FProbeName := G.AdapterName;
          FProbeOK := True;
        finally
          G.Free;
        end;
      except
        on E: Exception do
        begin
          FProbeOK := False;
          FProbeError := E.Message;
        end;
      end;
    end;
    Name := FProbeName;
    Error := FProbeError;
    Result := FProbeOK;
  finally
    FLock.Leave;
  end;
end;

constructor TGpuEvaluator.Create;
const
  SOFTWARE_ADAPTER = 2;   // DXGI_ADAPTER_FLAG_SOFTWARE
var
  Factory: IDXGIFactory1;
  Adapter, Best: IDXGIAdapter1;
  Desc: TDXGIAdapterDesc1;
  BestMem: NativeUInt;
  i: UINT;
  FL, OutFL: D3D_FEATURE_LEVEL;
begin
  inherited Create;
  FStepsPerDispatch := MAX_STEPS_PER_DISPATCH;
  try
    Check(CreateDXGIFactory1(IDXGIFactory1, Factory), 'CreateDXGIFactory1');
  except
    on E: Exception do
      raise EGpuError.Create('DirectX is not available: ' + E.Message);
  end;

  BestMem := 0;
  i := 0;
  while Factory.EnumAdapters1(i, Adapter) = S_OK do
  begin
    if Succeeded(Adapter.GetDesc1(Desc)) and (Desc.Flags and SOFTWARE_ADAPTER = 0) and
       ((Best = nil) or (Desc.DedicatedVideoMemory > BestMem)) then
    begin
      BestMem := Desc.DedicatedVideoMemory;
      Best := Adapter;
      FAdapterName := Trim(string(Desc.Description));
    end;
    Inc(i);
  end;
  if Best = nil then
    raise EGpuError.Create('No hardware graphics adapter');

  FL := D3D_FEATURE_LEVEL_11_0;
  Check(D3D11CreateDevice(Best, D3D_DRIVER_TYPE_UNKNOWN, 0,
    D3D11_CREATE_DEVICE_SINGLETHREADED, @FL, 1, D3D11_SDK_VERSION, FDev, OutFL, FCtx),
    'D3D11CreateDevice on ' + FAdapterName);

  CompileShaders;
  Check(FDev.CreateComputeShader(@FReflectCode[0], Length(FReflectCode), nil, FReflect),
    'CreateComputeShader(Reflect)');
  Check(FDev.CreateComputeShader(@FChiCode[0], Length(FChiCode), nil, FChi),
    'CreateComputeShader(ChiSquare)');
end;

function TGpuEvaluator.Structured(ElemSize, Count: UINT; Bind: UINT;
  Init: Pointer): ID3D11Buffer;
var
  Desc: TD3D11_BUFFER_DESC;
  Data: D3D11_SUBRESOURCE_DATA;
  PData: PD3D11_SUBRESOURCE_DATA;
begin
  FillChar(Desc, SizeOf(Desc), 0);
  Desc.ByteWidth := ElemSize * Count;
  Desc.Usage := D3D11_USAGE_DEFAULT;
  Desc.BindFlags := Bind;
  Desc.MiscFlags := UINT(D3D11_RESOURCE_MISC_BUFFER_STRUCTURED);
  Desc.StructureByteStride := ElemSize;
  PData := nil;
  if Init <> nil then
  begin
    FillChar(Data, SizeOf(Data), 0);
    Data.pSysMem := Init;
    PData := @Data;
  end;
  Check(FDev.CreateBuffer(Desc, PData, Result), 'CreateBuffer');
end;

function TGpuEvaluator.Staging(Size: UINT): ID3D11Buffer;
var
  Desc: TD3D11_BUFFER_DESC;
begin
  FillChar(Desc, SizeOf(Desc), 0);
  Desc.ByteWidth := Size;
  Desc.Usage := D3D11_USAGE_STAGING;
  Desc.CPUAccessFlags := D3D11_CPU_ACCESS_READ;
  Desc.MiscFlags := UINT(D3D11_RESOURCE_MISC_BUFFER_STRUCTURED);
  Desc.StructureByteStride := 4;
  Check(FDev.CreateBuffer(Desc, nil, Result), 'CreateBuffer(staging)');
end;

procedure TGpuEvaluator.Setup(const Inputs: TGpuEvalInputs; NLay, NPart: Integer;
  Pol: TPolarisation; RF: TRoughnessFunction; Lambda, KScale, Limit: Single);
var
  Desc: TD3D11_BUFFER_DESC;
  Steps: Int64;
begin
  if (NLay < 2) or (NPart < 1) or (Length(Inputs.Theta) < 2) then
    raise EGpuError.CreateFmt('Nothing to evaluate: %d layers, %d particles, %d angles',
      [NLay, NPart, Length(Inputs.Theta)]);
  { Buffer sizes are UINTs, and a release build does not check overflow: a
    wrapped size would make a buffer too small for what is written into it.
    Refuse early instead; the caller falls back to the CPU. }
  if (Int64(NPart) * NLay * 16 > MAX_BUFFER_BYTES) or
     (Int64(NPart) * Length(Inputs.Theta) * 4 > MAX_BUFFER_BYTES) then
    raise EGpuError.CreateFmt('%d particles x %d layers x %d angles do not fit ' +
      'in GPU buffers', [NPart, NLay, Length(Inputs.Theta)]);
  FNLay := NLay;
  FNAng := Length(Inputs.Theta);
  FNPart := NPart;

  FParams := Default(TParamsCB);
  FParams.NLay := FNLay;
  FParams.NAng := FNAng;
  FParams.Pol := Ord(Pol = cmSP);
  FParams.c1 := 4 * Pi / Lambda;
  FParams.c2 := FParams.c1 * 0.5;
  FParams.Limit := Limit;
  FParams.KScale := KScale;
  FParams.ConvN := Inputs.ConvN;
  FParams.WinSize := Length(Inputs.ConvWeights);
  FParams.ChiFirst := Inputs.ChiFirst;
  FParams.ChiLast := Inputs.ChiLast;
  FParams.RF := Ord(RF);
  FParams.ChiNorm := Inputs.ChiNorm;
  FParams.SolveScale := Ord(Inputs.SolveScale);
  FParams.ScaleWindow := Inputs.ScaleWindow;

  // particles per dispatch: bounded by the step budget and the group limit
  Steps := Int64(FNAng) * FNLay;
  FChunk := FStepsPerDispatch div Steps;
  if FChunk < 1 then FChunk := 1;
  if FChunk > MAX_GROUPS then FChunk := MAX_GROUPS;

  FillChar(Desc, SizeOf(Desc), 0);
  Desc.ByteWidth := SizeOf(TParamsCB);
  Desc.Usage := D3D11_USAGE_DEFAULT;
  Desc.BindFlags := D3D11_BIND_CONSTANT_BUFFER;
  Check(FDev.CreateBuffer(Desc, nil, FCB), 'CreateBuffer(constants)');

  FLayers      := Structured(16, FNPart * FNLay, D3D11_BIND_SHADER_RESOURCE, nil);
  FTheta       := Structured(4, FNAng, D3D11_BIND_SHADER_RESOURCE, @Inputs.Theta[0]);
  FWeights     := Structured(4, Length(Inputs.ConvWeights), D3D11_BIND_SHADER_RESOURCE,
                    @Inputs.ConvWeights[0]);
  FLogData     := Structured(4, FNAng, D3D11_BIND_SHADER_RESOURCE, @Inputs.LogData[0]);
  FPointWeight := Structured(4, FNAng, D3D11_BIND_SHADER_RESOURCE, @Inputs.PointWeight[0]);
  FCurve       := Structured(4, FNPart * FNAng, D3D11_BIND_UNORDERED_ACCESS, nil);
  FChiBuf      := Structured(4, FNPart, D3D11_BIND_UNORDERED_ACCESS, nil);
  FChiStage    := Staging(4 * FNPart);
  FRowStage    := Staging(4 * FNAng);

  Check(FDev.CreateShaderResourceView(FLayers, nil, FSRV[0]), 'SRV(layers)');
  Check(FDev.CreateShaderResourceView(FTheta, nil, FSRV[1]), 'SRV(theta)');
  Check(FDev.CreateShaderResourceView(FWeights, nil, FSRV[2]), 'SRV(weights)');
  Check(FDev.CreateShaderResourceView(FLogData, nil, FSRV[3]), 'SRV(log data)');
  Check(FDev.CreateShaderResourceView(FPointWeight, nil, FSRV[4]), 'SRV(point weights)');
  Check(FDev.CreateUnorderedAccessView(FCurve, nil, FUAV[0]), 'UAV(curve)');
  Check(FDev.CreateUnorderedAccessView(FChiBuf, nil, FUAV[1]), 'UAV(chi)');
end;

procedure TGpuEvaluator.SetOffset(Offset, Count: Integer);
begin
  FParams.PartOffset := Offset;
  FParams.NPart := Count;
  FCtx.UpdateSubresource(FCB, 0, nil, @FParams, 0, 0);
end;

procedure TGpuEvaluator.Evaluate(const Layers: TArray<Single>; var Chi: TArray<Single>);
var
  NoCI: ID3D11ClassInstance;
  Mapped: D3D11_MAPPED_SUBRESOURCE;
  Offset, Count: Integer;
begin
  if Length(Layers) <> 4 * FNPart * FNLay then
    raise EGpuError.CreateFmt('Evaluate: %d values for %d particles of %d layers',
      [Length(Layers), FNPart, FNLay]);
  if FFailAfter > 0 then
  begin
    Dec(FFailAfter);
    if FFailAfter = 0 then
      raise EGpuError.Create('injected GPU failure (TGpuEvaluator.FailAfter)');
  end;
  NoCI := nil;
  FCtx.UpdateSubresource(FLayers, 0, nil, @Layers[0], 0, 0);

  FCtx.CSSetConstantBuffers(0, 1, FCB);
  FCtx.CSSetShaderResources(0, Length(FSRV), FSRV[0]);
  FCtx.CSSetUnorderedAccessViews(0, Length(FUAV), FUAV[0], nil);

  Offset := 0;
  while Offset < FNPart do
  begin
    Count := FNPart - Offset;
    if Count > FChunk then Count := FChunk;
    SetOffset(Offset, Count);
    FCtx.CSSetShader(FReflect, NoCI, 0);
    FCtx.Dispatch((FNAng + THREADS_X - 1) div THREADS_X, Count, 1);
    FCtx.CSSetShader(FChi, NoCI, 0);
    FCtx.Dispatch(Count, 1, 1);
    Inc(Offset, Count);
  end;

  FCtx.CopyResource(FChiStage, FChiBuf);
  Check(FCtx.Map(FChiStage, 0, D3D11_MAP_READ, 0, Mapped), 'Map(chi)');
  try
    SetLength(Chi, FNPart);
    Move(Mapped.pData^, Chi[0], 4 * FNPart);
  finally
    FCtx.Unmap(FChiStage, 0);
  end;
end;

function TGpuEvaluator.RawCurve(Particle: Integer): TArray<Single>;
var
  Box: D3D11_BOX;
  Mapped: D3D11_MAPPED_SUBRESOURCE;
begin
  if (Particle < 0) or (Particle >= FNPart) then
    raise EGpuError.CreateFmt('RawCurve: no particle %d', [Particle]);
  FillChar(Box, SizeOf(Box), 0);
  Box.left := UINT(4 * Particle * FNAng);
  Box.right := Box.left + UINT(4 * FNAng);
  Box.bottom := 1;
  Box.back := 1;
  FCtx.CopySubresourceRegion(FRowStage, 0, 0, 0, 0, FCurve, 0, @Box);
  Check(FCtx.Map(FRowStage, 0, D3D11_MAP_READ, 0, Mapped), 'Map(curve)');
  try
    SetLength(Result, FNAng);
    Move(Mapped.pData^, Result[0], 4 * FNAng);
  finally
    FCtx.Unmap(FRowStage, 0);
  end;
end;

end.
