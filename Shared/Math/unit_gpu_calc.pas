(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2026 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit unit_gpu_calc;

(* Each fit owns one evaluator and uses it only from its fitting thread:
   a D3D11 immediate context is not thread-safe.

   Cancellation-sensitive shader expressions need targeted `precise`
   qualifiers to prevent compiler/driver reassociation. Global IEEE
   strictness reaches the same accuracy but costs more per evaluation.

   Self-check validates shader bytes, not device state, so a successful
   check is shared process-wide. It guards against gross driver/compiler
   errors, not every loss caused by removing `precise`. *)

interface

uses
  System.SysUtils, System.SyncObjs, System.Math,
  Winapi.Windows, Winapi.DXGI, Winapi.D3DCommon, Winapi.D3D11, Winapi.D3DCompiler,
  unit_Types, unit_calc, unit_parratt_ref;

type
  EGpuError = class(Exception);

  /// <summary>The likelihood kernel's per-point inputs (spec section 2), on the
  /// angles TGpuEvaluator.Setup was given.</summary>
  TGpuLikInputs = record
    LnData: TArray<Single>;  // ln D_i (true natural log); never read where InvN < 0
    InvN: TArray<Single>;    // 1/N_i; 0 when the curve has no counts; -1 leaves the point out
    FMin2: Single;           // f_min squared: V_min = 1/N_i + FMin2
  end;

  TGpuEvaluator = class
  private type
    TParamsCB = packed record
      NLay, NAng, NPart, Pol: UINT;
      c1, c2, Limit, KScale: Single;
      ConvN, WinSize, ChiFirst, ChiLast: UINT;
      RF, PartOffset: UINT;
      ChiNorm, Pad: Single;
      SolveScale: UINT;
      ScaleWindow, FMin2, Pad3: Single;
    end;
  private class var
    FLock: TCriticalSection;
    FReflectCode, FChiCode: TBytes;
    FLogLikCode: TBytes;
    FProbed, FProbeOK: Boolean;
    FProbeName, FProbeError: string;
    FProbeTick: UInt64;
    FFailAfter: Integer;
    FStrict: Boolean;
    FShaderMode: string;
    FSelfChecked: Boolean;
    FSelfCheckError: Double;
    FSelfCheckErrorWorst: Double;
    FSelfCheckBound: Double;
    FSelfCheckWorstBound: Double;
    FFailSelfChecks: Integer;
    FSelfCheckFailMsg: string;
    FSelfCheckFailTick: UInt64;
  private
    FDev: ID3D11Device;
    FCtx: ID3D11DeviceContext;
    FReflect, FChi: ID3D11ComputeShader;
    FCB: ID3D11Buffer;
    FLayers, FSinG, FWeights, FLogData, FPointWeight, FCurve, FChiBuf: ID3D11Buffer;
    FChiStage, FRowStage: ID3D11Buffer;
    FSRV: array [0..7] of ID3D11ShaderResourceView;
    FUAV: array [0..1] of ID3D11UnorderedAccessView;
    FParams: TParamsCB;
    FNLay, FNAng, FNPart, FChunk: Integer;
    FStepsPerDispatch: Int64;
    FAdapterName: string;
    FLogLik: ID3D11ComputeShader;
    FNuis, FLnData, FInvN: ID3D11Buffer;
    FLikReady: Boolean;
    FInSelfCheck: Boolean;
    class procedure Check(HR: HRESULT; const What: string); static;
    class procedure CompileShaders; static;
    class function CompileEntry(const Entry: AnsiString; Strict: Boolean): TBytes; static;
    class procedure CompileLogLik; static;
    function Structured(ElemSize, Count: UINT; Bind: UINT; Init: Pointer): ID3D11Buffer;
    function Staging(Size: UINT): ID3D11Buffer;
    procedure SetOffset(Offset, Count: Integer);
    procedure RunKernels(const Layers: TArray<Single>; Second: ID3D11ComputeShader;
      var Output: TArray<Single>);
    /// <summary>Does not consume FailAfter. Leaves buffers sized for one
    /// particle; the caller must replace them with its own Setup.</summary>
    function SelfCheck: Double;
  public
    class constructor Create;
    class destructor Destroy;
    class function Available(out Name, Error: string): Boolean; static;

    constructor Create;
    /// <summary>NLay includes ambient and substrate.</summary>
    procedure Setup(const Inputs: TGpuEvalInputs; NLay, NPart: Integer;
      Pol: TPolarisation; RF: TRoughnessFunction; Lambda, KScale, Limit: Single);
    /// <summary>Layers holds NPart * NLay records of four Singles, particle
    /// after particle, each model surface first: delta (1 - Re epsilon),
    /// e.im, thickness, sigma. Chi receives one chi-squared per particle.</summary>
    procedure Evaluate(const Layers: TArray<Single>; var Chi: TArray<Single>);
    /// <summary>Adds the likelihood kernel to a Setup evaluator: Lik is on the
    /// angles of Setup's Inputs, and the kernel sums ChiFirst..ChiLast as
    /// ChiSquare does. Call it again after every Setup, which drops it.</summary>
    procedure SetupLikelihood(const Lik: TGpuLikInputs);
    /// <summary>Layers as for Evaluate. Nuisance holds NPart records of four
    /// Singles: scale (10^LogScale, not the log), background, f squared,
    /// unused. Cost receives, per particle, CurveLikelihood's Cost over
    /// ChiFirst..ChiLast, to single precision. Raises EGpuError before
    /// SetupLikelihood.</summary>
    procedure EvaluateLikelihood(const Layers, Nuisance: TArray<Single>;
      var Cost: TArray<Single>);
    /// <summary>The raw (unconvolved, Limit-clamped) curve of one particle of
    /// the last Evaluate, for TCalc.FinishRawCurve.</summary>
    function RawCurve(Particle: Integer): TArray<Single>;
    property AdapterName: string read FAdapterName;
    property LayerCount: Integer read FNLay;
    property ParticleCount: Integer read FNPart;
    /// <summary>Angle x layer steps per dispatch. Set before Setup.</summary>
    property StepsPerDispatch: Int64 read FStepsPerDispatch write FStepsPerDispatch;
    property ParticlesPerDispatch: Integer read FChunk;
    /// <summary>Process-wide one-shot failure on the N-th Evaluate or
    /// EvaluateLikelihood. Self-check evaluations must not consume the
    /// caller's count.</summary>
    class property FailAfter: Integer read FFailAfter write FFailAfter;
    /// <summary>'precise' or 'ieee_strict'; empty until a check succeeds.</summary>
    class property ShaderMode: string read FShaderMode;
    /// <summary>Mean |log10 R/R_ref|; the strict attempt's value if both fail.</summary>
    class property SelfCheckError: Double read FSelfCheckError;
    /// <summary>Worst |log10 R/R_ref| over the reference angles.</summary>
    class property SelfCheckErrorWorst: Double read FSelfCheckErrorWorst;
    /// <summary>Failure bound for mean |log10 R/R_ref|.</summary>
    class property SelfCheckBound: Double read FSelfCheckBound write FSelfCheckBound;
    class property SelfCheckWorstBound: Double read FSelfCheckWorstBound write FSelfCheckWorstBound;
    class property FailSelfChecks: Integer read FFailSelfChecks write FFailSelfChecks;
    class procedure ResetShaders; static;
  end;

/// Distinct particles may be packed concurrently; each occupies a separate
/// block of 4 * Length(L) Singles.
procedure PackModelLayers(const L: TCalcLayers; var Layers: TArray<Single>; Particle: Integer);

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
        uint  NPart;
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
        uint  SolveScale;
        float ScaleWindow;// |log10 scale| bound; 0 pins it
        float FMin2;       // f_min^2 (LogLik)
        float Pad3;
    };

    StructuredBuffer<float4> Layers      : register(t0);  // delta, e.im, L, sigma
    StructuredBuffer<float>  SinG        : register(t1);  // grazing sine, Double on the host (Setup)
    StructuredBuffer<float>  Weights     : register(t2);
    StructuredBuffer<float>  LogData     : register(t3);
    StructuredBuffer<float>  PointWeight : register(t4);
    StructuredBuffer<float4> Nuis        : register(t5);  // per particle: scale, background, f^2, unused
    StructuredBuffer<float>  LnData      : register(t6);  // ln D (LogLik)
    StructuredBuffer<float>  InvN        : register(t7);  // 1/N; 0 without counts; < 0 leaves the point out
    RWStructuredBuffer<float> Curve      : register(u0);  // raw R, particle-major
    RWStructuredBuffer<float> Chi        : register(u1);

    float2 cmul(float2 a, float2 b) { return float2(a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x); }
    float2 cdiv(float2 a, float2 b)
    {
        float d = 1.0 / (b.x*b.x + b.y*b.y);
        return float2((a.x*b.x + a.y*b.y) * d, (a.y*b.x - a.x*b.y) * d);
    }
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
    float Roughness(float sigma, float s)
    {
        if (RF == 0) return exp(-(sigma * sigma * 0.5) * s * s);
        if (RF == 1) return 1.0 / (1.0 + (s * s * sigma * sigma) * 0.5);
        if (RF == 2)
        {
            float x = 1.73205080757 * sigma * s;
            return abs(x) < 1e-4 ? 1.0 : sin(x) / x;
        }
        if (RF == 3) return cos(sigma * s);
        if (RF == 4)
        {
            // u = a - pi/2 is 0/0 at a = pi/2; guarded like RF == 2 above.
            // v = a + pi/2 guarded the same way.
            float a = 2.29760311750 * sigma * s;
            float u = a - 1.57079632679, v = a + 1.57079632679;
            float t1 = abs(u) < 1e-4 ? 1.0 : sin(u) / u;
            float t2 = abs(v) < 1e-4 ? 1.0 : sin(v) / v;
            return 0.785398163397 * (t1 + t2);
        }
        return 1.0;
    }

    [numthreads(64, 1, 1)]
    void Reflect(uint3 gid : SV_DispatchThreadID)
    {
        uint a = gid.x;
        if (a >= NAng) return;
        uint p = gid.y + PartOffset;

        // sin_g = the grazing sine, uploaded by Setup in double precision from
        // the host. The Fresnel term is sin^2(t) - delta, delta = 1 - Re
        // epsilon carried directly from the materials (Layers.x): no near-1
        // subtraction of epsilon remains.
        float sin_g = SinG[a];
        float sin_g2 = sin_g * sin_g;

        uint base = p * NLay;
        float4 lb = Layers[base + NLay - 1];
        float dB = lb.x, bB = lb.y;
        float2 eB = float2(1 - dB, bB);
        // precise: without it, the compiler/driver may reassociate
        // sin_g2 - dB against surrounding sums, undoing the cancellation-free
        // form.
        precise float reB = sin_g2 - dB;
        float2 KB = c2 * csqrt(float2(reB, bB));
        float2 R  = float2(0, 0);
        float2 Rp = float2(0, 0);
        bool first = true;

        for (int i = (int)NLay - 2; i >= 0; --i)
        {
            float4 li = Layers[base + i];
            float di = li.x, bi = li.y;
            float2 ei = float2(1 - di, bi);
            precise float rei = sin_g2 - di;
            float2 Ki = c2 * csqrt(float2(rei, bi));

            // 1 - |ei/eB| computed directly from delta and beta
            // (unit_calc.EpsRatio's Double form, here in Single): no near-1
            // subtraction of ei/eB remains.
            float ai = length(ei), aB = length(eB);
            precise float num = (di - dB) * (2 - di - dB) + (bB * bB - bi * bi);
            precise float oneMinusRatio = num / (aB * (aB + ai));
            float eRatio = ai / aB;
            // precise: without it, the compiler/driver may reassociate
            // oneMinusRatio + eRatio * sin_g2, undoing the cancellation-free form.
            precise float s1Signed = oneMinusRatio + eRatio * sin_g2;
            float s1 = abs(s1Signed);
            float rf = Roughness(lb.w, c1 * sqrt(sin_g * sqrt(s1)));

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

            lb = li; eB = ei; KB = Ki; dB = di; bB = bi;
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
        // With the scale solved the sum is taken again, at a, as w (d + a)^2:
        // never negative. S2 + 2 a S1 + a^2 S0 is the same number on paper, but
        // one point with R within 1e-5 of 1 has w = 1e10, every term is then
        // near 1e9 and their sum, near 1e2, is rounding noise of either sign in
        // single precision - and a negative chi2 wins every comparison of a fit.
        float t0 = P0[0], t1 = P1[0], t2 = P2[0];
        GroupMemoryBarrierWithGroupSync();      // all have read before P0 is reused
        float c = 0;
        if (SolveScale != 0)
        {
            float a = 0;
            if (t0 > 0)
                a = clamp(-t1 / t0, -ScaleWindow, ScaleWindow);
            for (uint i2 = ChiFirst + gtid.x; i2 <= ChiLast; i2 += CHI_THREADS)
            {
                float r = 0;
                for (uint k = 0; k < WinSize; ++k)
                    r += Curve[base + i2 - ConvN + k] * Weights[k];
                if (r != 0)
                {
                    float lr = 0.434294481903 * log(r);
                    float e = (LogData[i2] - lr + a) / lr;
                    c += PointWeight[i2] * e * e;
                }
            }
        }
        else if (gtid.x == 0)
            c = t2;
        P0[gtid.x] = c;
        GroupMemoryBarrierWithGroupSync();
        for (uint s3 = CHI_THREADS / 2; s3 > 0; s3 >>= 1)
        {
            if (gtid.x < s3)
                P0[gtid.x] += P0[gtid.x + s3];
            GroupMemoryBarrierWithGroupSync();
        }
        if (gtid.x == 0)
            Chi[p] = P0[0] * ChiNorm;
    }

    // unit_Likelihood.CurveLikelihood's Cost, one particle per group: over the
    // points kept, r^2 / V + ln(V / Vmin) with r = ln D - ln(s R + b),
    // V = 1/N + f^2 and Vmin = 1/N + fmin^2 (1/N = 0 without counts). R is the
    // convolved curve, as in ChiSquare.
    [numthreads(CHI_THREADS, 1, 1)]
    void LogLik(uint3 gtid : SV_GroupThreadID, uint3 grp : SV_GroupID)
    {
        uint p = grp.x + PartOffset;
        uint base = p * NAng;
        float4 nu = Nuis[p];
        float c = 0;
        for (uint i = ChiFirst + gtid.x; i <= ChiLast; i += CHI_THREADS)
        {
            float n1 = InvN[i];
            if (n1 < 0) continue;
            float r = 0;
            for (uint k = 0; k < WinSize; ++k)
                r += Curve[base + i - ConvN + k] * Weights[k];
            float res = LnData[i] - log(nu.x * r + nu.y);
            float v = n1 + nu.z;
            c += res * res / v + log(v / (n1 + FMin2));
        }
        P0[gtid.x] = c;
        GroupMemoryBarrierWithGroupSync();
        for (uint h = CHI_THREADS / 2; h > 0; h >>= 1)
        {
            if (gtid.x < h) P0[gtid.x] += P0[gtid.x + h];
            GroupMemoryBarrierWithGroupSync();
        }
        if (gtid.x == 0) Chi[p] = P0[0];
    }
    ''';


class constructor TGpuEvaluator.Create;
begin
  FLock := TCriticalSection.Create;
  FSelfCheckBound := 3E-4;
  { ~40x the worst |log10 R/R_ref| measured on the reference GPU (RTX 5080)
    with `precise` (7.89E-5), rounded up to one significant digit - the same
    ratio as SelfCheckBound to that GPU's measured mean (3E-4 to ~7.3E-6). }
  FSelfCheckWorstBound := 4E-3;
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

class function TGpuEvaluator.CompileEntry(const Entry: AnsiString; Strict: Boolean): TBytes;
var
  Src: AnsiString;
  Code, Errors: ID3DBlob;
  HR: HRESULT;
  Flags1: UINT;
begin
  Src := AnsiString(HLSL);
  Flags1 := D3DCOMPILE_OPTIMIZATION_LEVEL3;
  if Strict then
    // Disables the compiler/driver's freedom to reassociate or fuse
    // floating-point sums globally - the self-check's fallback when the
    // targeted `precise` qualifiers above did not hold on this GPU/driver.
    Flags1 := Flags1 or D3DCOMPILE_IEEE_STRICTNESS;
  HR := D3DCompile(PAnsiChar(Src), Length(Src), 'unit_gpu_calc.hlsl', nil, nil,
    PAnsiChar(Entry), 'cs_5_0', Flags1, 0, Code, Errors);
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

class procedure TGpuEvaluator.CompileShaders;
var
  Reflect, Chi: TBytes;
begin
  FLock.Enter;
  try
    if (Length(FReflectCode) = 0) or (Length(FChiCode) = 0) then
    begin
      Reflect := CompileEntry('Reflect', FStrict);
      Chi := CompileEntry('ChiSquare', FStrict);
      FReflectCode := Reflect;
      FChiCode := Chi;
    end;
  finally
    FLock.Leave;
  end;
end;

class procedure TGpuEvaluator.CompileLogLik;
begin
  FLock.Enter;
  try
    if Length(FLogLikCode) = 0 then
      FLogLikCode := CompileEntry('LogLik', FStrict);
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
  Err, Worst, FirstErr, FirstWorst: Double;
  Bad: Boolean;
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

  { Lock the whole compile/create/check sequence: fallback rewrites global
    code blobs and FStrict after instance shaders have been created.
    Other constructors must see only the settled state. Available can
    already hold FLock here; Windows critical sections are re-entrant. }
  FLock.Enter;
  try
    { Direct Create bypasses Available's failure cache. Cache a double
      self-check failure too, or every particle fit attempt recompiles and
      checks both shader variants during the retry window. }
    if (FSelfCheckFailMsg <> '') and (GetTickCount64 - FSelfCheckFailTick <= 60000) then
      raise EGpuError.Create(FSelfCheckFailMsg);

    CompileShaders;
    Check(FDev.CreateComputeShader(@FReflectCode[0], Length(FReflectCode), nil, FReflect),
      'CreateComputeShader(Reflect)');
    Check(FDev.CreateComputeShader(@FChiCode[0], Length(FChiCode), nil, FChi),
      'CreateComputeShader(ChiSquare)');

    if not FSelfChecked then
    begin
      Err := SelfCheck;
      Worst := FSelfCheckErrorWorst;
      FirstErr := Err;
      FirstWorst := Worst;
      // NaN-robust: a NaN comparison is false either way, so a NaN measurement
      // must fail explicitly rather than slip through `Err > Bound` (false).
      Bad := not ((Err <= FSelfCheckBound) and (Worst <= FSelfCheckWorstBound));
      if FFailSelfChecks > 0 then
      begin
        Dec(FFailSelfChecks);
        Bad := True;
      end;
      if Bad and not FStrict then
      begin
        FStrict := True;
        FReflectCode := nil;
        FChiCode := nil;
        FLogLikCode := nil;     // recompiled lazily again if a likelihood fit needs it
        CompileShaders;
        Check(FDev.CreateComputeShader(@FReflectCode[0], Length(FReflectCode), nil, FReflect),
          'CreateComputeShader(Reflect, IEEE strict)');
        Check(FDev.CreateComputeShader(@FChiCode[0], Length(FChiCode), nil, FChi),
          'CreateComputeShader(ChiSquare, IEEE strict)');
        try
          Err := SelfCheck;
        except
          { A transient device error must not leave future attempts stuck
            in strict mode; restart from targeted precise compilation. }
          FStrict := False;
          FReflectCode := nil;
          FChiCode := nil;
          FLogLikCode := nil;
          raise;
        end;
        Worst := FSelfCheckErrorWorst;
        Bad := not ((Err <= FSelfCheckBound) and (Worst <= FSelfCheckWorstBound));
        if FFailSelfChecks > 0 then
        begin
          Dec(FFailSelfChecks);
          Bad := True;
        end;
      end;
      if Bad then
      begin
        { Reset shader state so the next retry starts from precise, but cache
          the failure message to prevent repeated checks for 60 seconds. }
        FShaderMode := '';
        FStrict := False;
        FReflectCode := nil;
        FChiCode := nil;
        FLogLikCode := nil;
        FSelfCheckFailMsg := Format('GPU self-check failed: mean/worst |log10 R/R_ref| ' +
          '%.2e/%.2e with precise and %.2e/%.2e with IEEE strictness',
          [FirstErr, FirstWorst, Err, Worst]);
        FSelfCheckFailTick := GetTickCount64;
      end
      else
      begin
        FSelfChecked := True;
        if FStrict then
          FShaderMode := 'ieee_strict'
        else
          FShaderMode := 'precise';
      end;
    end;
    if FShaderMode = '' then
      raise EGpuError.Create(FSelfCheckFailMsg);
  finally
    FLock.Leave;
  end;
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
  SinG: TArray<Single>;
  ThetaK: Single;
  i: Integer;
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
  FLikReady := False;           // SetupLikelihood sizes its buffers for this Setup
  FSRV[5] := nil;
  FSRV[6] := nil;
  FSRV[7] := nil;
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

  Steps := Int64(FNAng) * FNLay;
  FChunk := FStepsPerDispatch div Steps;
  if FChunk < 1 then FChunk := 1;
  if FChunk > MAX_GROUPS then FChunk := MAX_GROUPS;

  { Match CPU rounding: ThetaK is Single, then Sin runs in Double.
    KScale remains in the cbuffer despite being unused by Reflect;
    Delphi and HLSL must keep the same 80-byte layout. }
  SetLength(SinG, FNAng);
  for i := 0 to FNAng - 1 do
  begin
    ThetaK := Inputs.Theta[i] / KScale;
    SinG[i] := Sin(Pi * Double(ThetaK) / 180);
  end;

  FillChar(Desc, SizeOf(Desc), 0);
  Desc.ByteWidth := SizeOf(TParamsCB);
  Desc.Usage := D3D11_USAGE_DEFAULT;
  Desc.BindFlags := D3D11_BIND_CONSTANT_BUFFER;
  Check(FDev.CreateBuffer(Desc, nil, FCB), 'CreateBuffer(constants)');

  FLayers      := Structured(16, FNPart * FNLay, D3D11_BIND_SHADER_RESOURCE, nil);
  FSinG        := Structured(4, FNAng, D3D11_BIND_SHADER_RESOURCE, @SinG[0]);
  FWeights     := Structured(4, Length(Inputs.ConvWeights), D3D11_BIND_SHADER_RESOURCE,
                    @Inputs.ConvWeights[0]);
  FLogData     := Structured(4, FNAng, D3D11_BIND_SHADER_RESOURCE, @Inputs.LogData[0]);
  FPointWeight := Structured(4, FNAng, D3D11_BIND_SHADER_RESOURCE, @Inputs.PointWeight[0]);
  FCurve       := Structured(4, FNPart * FNAng, D3D11_BIND_UNORDERED_ACCESS, nil);
  FChiBuf      := Structured(4, FNPart, D3D11_BIND_UNORDERED_ACCESS, nil);
  FChiStage    := Staging(4 * FNPart);
  FRowStage    := Staging(4 * FNAng);

  Check(FDev.CreateShaderResourceView(FLayers, nil, FSRV[0]), 'SRV(layers)');
  Check(FDev.CreateShaderResourceView(FSinG, nil, FSRV[1]), 'SRV(sin g)');
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

procedure TGpuEvaluator.RunKernels(const Layers: TArray<Single>; Second: ID3D11ComputeShader;
  var Output: TArray<Single>);
var
  NoCI: ID3D11ClassInstance;
  Mapped: D3D11_MAPPED_SUBRESOURCE;
  Offset, Count: Integer;
begin
  if Length(Layers) <> 4 * FNPart * FNLay then
    raise EGpuError.CreateFmt('Evaluate: %d values for %d particles of %d layers',
      [Length(Layers), FNPart, FNLay]);
  if (FFailAfter > 0) and not FInSelfCheck then
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
    FCtx.CSSetShader(Second, NoCI, 0);
    FCtx.Dispatch(Count, 1, 1);
    Inc(Offset, Count);
  end;

  FCtx.CopyResource(FChiStage, FChiBuf);
  Check(FCtx.Map(FChiStage, 0, D3D11_MAP_READ, 0, Mapped), 'Map(chi)');
  try
    SetLength(Output, FNPart);
    Move(Mapped.pData^, Output[0], 4 * FNPart);
  finally
    FCtx.Unmap(FChiStage, 0);
  end;
end;

{ Fixed optical constants, without Henke tables or TLayeredModel, make the
  self-check independent of machine-local data. }
function TGpuEvaluator.SelfCheck: Double;
const
  LAMBDA = 1.5406;
  LIMIT: Single = 1E-12;
  N_ANG = 200;
  THETA_MIN = 0.1;
  THETA_MAX = 4.0;
  N_PERIODS = 20;
  SUBSTRATE_L = 1E8;   // TLayeredModel.AddSubstrate's sentinel (unit_materials.pas)
var
  L: TCalcLayers;
  Inputs: TGpuEvalInputs;
  Layers, Chi, Raw: TArray<Single>;
  ThetaDeg: TArray<Single>;
  i, Idx: Integer;
  Ref, d, Sum, Worst: Double;
begin
  FInSelfCheck := True;
  try
    SetLength(L, 2 + 2 * N_PERIODS);
    L[0].e.re := 1; L[0].e.im := 0; L[0].delta := 0; L[0].L := 0; L[0].s := 0;
    Idx := 1;
    for i := 1 to N_PERIODS do
    begin
      L[Idx].delta := 9.6E-5;
      L[Idx].e.re := 1 - L[Idx].delta;
      L[Idx].e.im := 7.8E-6;
      L[Idx].L := 12;
      L[Idx].s := 3;
      Inc(Idx);
      L[Idx].delta := 1.66E-5;
      L[Idx].e.re := 1 - L[Idx].delta;
      L[Idx].e.im := 1.6E-8;
      L[Idx].L := 22;
      L[Idx].s := 3;
      Inc(Idx);
    end;
    L[Idx].delta := 1.52E-5;
    L[Idx].e.re := 1 - L[Idx].delta;
    L[Idx].e.im := 3.5E-7;
    L[Idx].L := SUBSTRATE_L;
    L[Idx].s := 3;

    SetLength(ThetaDeg, N_ANG);
    for i := 0 to N_ANG - 1 do
      ThetaDeg[i] := THETA_MIN + i * (THETA_MAX - THETA_MIN) / (N_ANG - 1);

    Inputs := Default(TGpuEvalInputs);
    Inputs.Theta := Copy(ThetaDeg);
    SetLength(Inputs.LogData, N_ANG);          // zeros: unused, Evaluate/Chi are not read
    SetLength(Inputs.PointWeight, N_ANG);
    for i := 0 to N_ANG - 1 do
      Inputs.PointWeight[i] := 1;
    Inputs.ConvWeights := [1];
    Inputs.ConvN := 0;
    Inputs.ChiFirst := 0;
    Inputs.ChiLast := N_ANG - 1;
    Inputs.ChiNorm := 1;

    Setup(Inputs, Length(L), 1, cmS, rfError, LAMBDA, 1, LIMIT);
    SetLength(Layers, 4 * Length(L));
    PackModelLayers(L, Layers, 0);
    Evaluate(Layers, Chi);
    Raw := RawCurve(0);

    Sum := 0;
    Worst := 0;
    for i := 0 to N_ANG - 1 do
    begin
      Ref := Max(ParrattRef(L, ThetaDeg[i], LAMBDA, False, rfError), Double(LIMIT));
      d := Abs(System.Math.Log10(Raw[i] / Ref));
      Sum := Sum + d;
      if d > Worst then Worst := d;
    end;
    Result := Sum / N_ANG;
    FSelfCheckError := Result;
    FSelfCheckErrorWorst := Worst;
  finally
    FInSelfCheck := False;
  end;
end;

procedure TGpuEvaluator.Evaluate(const Layers: TArray<Single>; var Chi: TArray<Single>);
begin
  RunKernels(Layers, FChi, Chi);
end;

procedure TGpuEvaluator.SetupLikelihood(const Lik: TGpuLikInputs);
begin
  FLikReady := False;           // any failure below must leave EvaluateLikelihood refusing
  if FNPart = 0 then
    raise EGpuError.Create('SetupLikelihood before Setup');
  if (Length(Lik.LnData) <> FNAng) or (Length(Lik.InvN) <> FNAng) then
    raise EGpuError.CreateFmt('SetupLikelihood: %d ln D and %d 1/N values for %d angles',
      [Length(Lik.LnData), Length(Lik.InvN), FNAng]);
  CompileLogLik;
  if FLogLik = nil then
    Check(FDev.CreateComputeShader(@FLogLikCode[0], Length(FLogLikCode), nil, FLogLik),
      'CreateComputeShader(LogLik)');
  FParams.FMin2 := Lik.FMin2;
  FNuis   := Structured(16, FNPart, D3D11_BIND_SHADER_RESOURCE, nil);
  FLnData := Structured(4, FNAng, D3D11_BIND_SHADER_RESOURCE, @Lik.LnData[0]);
  FInvN   := Structured(4, FNAng, D3D11_BIND_SHADER_RESOURCE, @Lik.InvN[0]);
  Check(FDev.CreateShaderResourceView(FNuis, nil, FSRV[5]), 'SRV(nuisance)');
  Check(FDev.CreateShaderResourceView(FLnData, nil, FSRV[6]), 'SRV(ln data)');
  Check(FDev.CreateShaderResourceView(FInvN, nil, FSRV[7]), 'SRV(1/N)');
  FLikReady := True;
end;

procedure TGpuEvaluator.EvaluateLikelihood(const Layers, Nuisance: TArray<Single>;
  var Cost: TArray<Single>);
begin
  if not FLikReady then
    raise EGpuError.Create('EvaluateLikelihood before SetupLikelihood');
  if Length(Nuisance) <> 4 * FNPart then
    raise EGpuError.CreateFmt('EvaluateLikelihood: %d nuisance values for %d particles',
      [Length(Nuisance), FNPart]);
  FCtx.UpdateSubresource(FNuis, 0, nil, @Nuisance[0], 0, 0);
  RunKernels(Layers, FLogLik, Cost);
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

procedure PackModelLayers(const L: TCalcLayers; var Layers: TArray<Single>; Particle: Integer);
var
  k, Base: Integer;
begin
  Base := 4 * Length(L) * Particle;
  for k := 0 to High(L) do
  begin
    Layers[Base + 4 * k]     := L[k].delta;
    Layers[Base + 4 * k + 1] := L[k].e.Im;
    Layers[Base + 4 * k + 2] := L[k].L;
    Layers[Base + 4 * k + 3] := L[k].s;
  end;
end;

class procedure TGpuEvaluator.ResetShaders;
begin
  FLock.Enter;
  try
    FReflectCode := nil;
    FChiCode := nil;
    FLogLikCode := nil;
    FStrict := False;
    FSelfChecked := False;
    FShaderMode := '';
    FSelfCheckError := 0;
    FSelfCheckErrorWorst := 0;
    FSelfCheckFailMsg := '';
    FSelfCheckFailTick := 0;
    FProbed := False;
  finally
    FLock.Leave;
  end;
end;

end.
