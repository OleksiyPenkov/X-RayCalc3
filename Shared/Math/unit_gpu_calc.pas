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

   The recursion mirrors TCalc.RefCalc layer for layer, including its
   cancellation-free form of eps - sin^2(t): sin^2(theta) - delta, delta = 1 -
   Re epsilon carried directly from the materials (TCalcLayer.delta,
   unit_materials.PrepareLayers) into the layer buffer's first float, rather
   than recovered from a Single epsilon near 1 (both engines since
   2026-09-28). The grazing sine itself comes from the host, in Double,
   exactly as TCalc.CalcTet's angle reaches TCalc.RefCalc: Setup computes
   Single ThetaK := Theta[i] / KScale, then System.Sin(Pi * Double(ThetaK) /
   180) in Double, stored as Single, and uploads it per angle in the SinG
   buffer the Reflect kernel reads directly - the same Single value
   TCalc.RefCalc itself uses. KScale stays in TParamsCB/cbuffer Params even
   though Reflect no longer reads it, so the 80-byte constant-buffer layout is
   unchanged.

   Carrying delta end to end (task 2, 2026-09-28) still leaves cancellation-
   sensitive sums in the kernel: sin_g^2 - delta feeding the Fresnel argument,
   and the delta/beta form of 1 - |ei/eB| (EpsRatio's Double math, done here in
   Single) feeding s1. The compiler/driver, compiled with
   D3DCOMPILE_OPTIMIZATION_LEVEL3 and without D3DCOMPILE_IEEE_STRICTNESS, may
   still reassociate those sums with their neighbours. Marking them, and the
   intermediates that feed them, `precise` - source-order, unfused IEEE
   evaluation for just those expressions (see the comments at KB/Ki and at s1
   in Reflect below) - keeps the GPU close to TCalc's own accuracy; see
   TestGpuCalc's GpuRawCurve_CloseToDoublePrecision for the measured mean and
   worst |log10 R/R_ref| against a double-precision Parratt, before and after
   this task, and CpuRawCurve_CloseToDoublePrecision for TCalc's own.
   D3DCOMPILE_IEEE_STRICTNESS globally reaches the same accuracy but costs
   ~13% more time per Evaluate; the targeted `precise` qualifiers cost nothing
   measurable, which is why they were chosen over the global flag.

   Each fit owns one TGpuEvaluator and uses it from the fitting thread only:
   a D3D11 immediate context is not thread-safe.

   The first Create in the process also self-checks (SelfCheck) the compiled
   shaders against the double-precision reference ParrattRef
   (unit_parratt_ref) on a fixed W/B4C multilayer, 200 angles from 0.1 deg to
   4 deg: the mean and the worst |log10 R/R_ref| must stay under
   SelfCheckBound (3E-4) and SelfCheckWorstBound. This is a general guard
   against a grossly wrong GPU result - a bad driver/compiler, a
   transcendental (sqrt/sin/cos/log/exp) that is far less accurate than this
   one's, a broken division - measured against the same reference the CPU is
   measured against, not a targeted test of `precise` alone: on this GPU
   (RTX 5080), removing every `precise` qualifier does not move the
   self-check's own numbers outside its bounds (mean 7.61E-6 without
   `precise` vs 7.27E-6 with it, worst 7.89E-5 with it - see TestGpuCalc's
   SelfCheck_PassesWithPrecise/SelfCheck_FallsBackToIeeeStrict for the full
   measurement), because carrying delta end to end (task 2, 2026-09-28) already
   turned sin_g^2 - delta into a well-conditioned subtraction (delta is
   small, not recovered from a near-1 epsilon) regardless of reassociation.
   `precise` stays in place as defence in depth - `num` below (the epsilon
   ratio's numerator) is the one expression where an increasingly aggressive
   compiler could still reintroduce a cancellation the self-check would then
   catch - and GpuRawCurve_CloseToDoublePrecision keeps measuring the
   `precise` build's own accuracy directly. If the self-check fails, the
   shaders are recompiled once with D3DCOMPILE_IEEE_STRICTNESS (globally
   disabling reassociation) and checked again; if that also fails, Create
   raises and the caller falls back to the CPU, same as any other EGpuError,
   and the whole sequence retries from a clean state on the next Create
   (Available's own 60-second retry, or the caller's next attempt). ShaderMode
   ('precise' or 'ieee_strict'), SelfCheckError and SelfCheckErrorWorst are
   reported by XRC_MCP's describe_server as the server section's gpu_shader,
   gpu_self_check and gpu_self_check_worst, so an agent can see which path a
   remote machine took. A successful Create's self-check runs once per
   process: later Creates skip it, since it validates the shader bytes, not
   the device state. *)

interface

uses
  System.SysUtils, System.SyncObjs, System.Math,
  Winapi.Windows, Winapi.DXGI, Winapi.D3DCommon, Winapi.D3D11, Winapi.D3DCompiler,
  unit_Types, unit_calc, unit_parratt_ref;

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
    FStrict: Boolean;            // shaders compiled with D3DCOMPILE_IEEE_STRICTNESS
    FShaderMode: string;         // '' | 'precise' | 'ieee_strict', after the self-check
    FSelfChecked: Boolean;       // the self-check has settled on a usable compilation
    FSelfCheckError: Double;
    FSelfCheckErrorWorst: Double;
    FSelfCheckBound: Double;
    FSelfCheckWorstBound: Double;
    FFailSelfChecks: Integer;
    FSelfCheckFailMsg: string;   // cached message of a double self-check failure; '' = none cached
    FSelfCheckFailTick: UInt64;  // GetTickCount64 when FSelfCheckFailMsg was set
  private
    FDev: ID3D11Device;
    FCtx: ID3D11DeviceContext;
    FReflect, FChi: ID3D11ComputeShader;
    FCB: ID3D11Buffer;
    FLayers, FSinG, FWeights, FLogData, FPointWeight, FCurve, FChiBuf: ID3D11Buffer;
    FChiStage, FRowStage: ID3D11Buffer;
    FSRV: array [0..4] of ID3D11ShaderResourceView;
    FUAV: array [0..1] of ID3D11UnorderedAccessView;
    FParams: TParamsCB;
    FNLay, FNAng, FNPart, FChunk: Integer;
    FStepsPerDispatch: Int64;
    FAdapterName: string;
    FInSelfCheck: Boolean;   // true while SelfCheck's own Evaluate/RunKernels run
    class procedure Check(HR: HRESULT; const What: string); static;
    class procedure CompileShaders; static;
    class function CompileEntry(const Entry: AnsiString; Strict: Boolean): TBytes; static;
    function Structured(ElemSize, Count: UINT; Bind: UINT; Init: Pointer): ID3D11Buffer;
    function Staging(Size: UINT): ID3D11Buffer;
    procedure SetOffset(Offset, Count: Integer);
    procedure RunKernels(const Layers: TArray<Single>; Second: ID3D11ComputeShader;
      var Output: TArray<Single>);
    /// <summary>Evaluates a fixed W/B4C multilayer (200 angles, 0.1..4 deg)
    /// against the double-precision ParrattRef and returns the mean
    /// |log10 R/R_ref|, also left in FSelfCheckError; the worst of the 200
    /// is left in FSelfCheckErrorWorst. Does not consume or trigger
    /// FailAfter (FInSelfCheck). Uses Self's own Setup/Evaluate/RawCurve, so
    /// it leaves its buffers sized for one particle of this layer count -
    /// the caller's own Setup below replaces them.</summary>
    function SelfCheck: Double;
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
    /// after particle, each model surface first: delta (1 - Re epsilon),
    /// e.im, thickness, sigma. Chi receives one chi-squared per particle.</summary>
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
    /// <summary>Test hook: when positive, the N-th Evaluate of any
    /// evaluator in the process raises EGpuError instead of running, once, and the
    /// hook resets itself. It exercises the engines' fallback to the CPU.
    /// Does not count the self-check's own internal Evaluate (SelfCheck runs
    /// before Create hands the evaluator to anyone, and must not consume a
    /// count meant for the caller's own evaluations).</summary>
    class property FailAfter: Integer read FFailAfter write FFailAfter;
    /// <summary>'precise' or 'ieee_strict': how the shaders were compiled,
    /// after the self-check; '' before the first evaluator is created, or
    /// again whenever the self-check has just failed under both
    /// compilations (the next Create retries the whole sequence).</summary>
    class property ShaderMode: string read FShaderMode;
    /// <summary>The self-check's mean |log10 R/R_ref| on its reference
    /// multilayer, at whichever compilation it finally settled on (or the
    /// IEEE-strict attempt's value, if both failed).</summary>
    class property SelfCheckError: Double read FSelfCheckError;
    /// <summary>The self-check's worst |log10 R/R_ref| over its 200 angles,
    /// at whichever compilation it finally settled on.</summary>
    class property SelfCheckErrorWorst: Double read FSelfCheckErrorWorst;
    /// <summary>Mean |log10 R/R_ref| above which the self-check fails.
    /// 3E-4.</summary>
    class property SelfCheckBound: Double read FSelfCheckBound write FSelfCheckBound;
    /// <summary>Worst-point |log10 R/R_ref| above which the self-check
    /// fails, alongside SelfCheckBound on the mean. Default is about 40x
    /// the worst measured on the reference GPU with `precise` (the same
    /// ratio as SelfCheckBound to that GPU's measured mean), rounded up to
    /// one significant digit.</summary>
    class property SelfCheckWorstBound: Double read FSelfCheckWorstBound write FSelfCheckWorstBound;
    /// <summary>Test hook: the next N self-checks fail whatever they
    /// measure; resets itself.</summary>
    class property FailSelfChecks: Integer read FFailSelfChecks write FFailSelfChecks;
    /// <summary>Test hook: forget the compiled shaders, the self-check and
    /// the probe, so the next Create compiles and checks again.</summary>
    class procedure ResetShaders; static;
  end;

/// <summary>Writes one particle's expanded layers into Layers the way
/// TGpuEvaluator.Evaluate reads them: four Singles
/// per layer (delta = 1 - Re epsilon, e.im, thickness, sigma), the particle's
/// block starting at 4 * Length(L) * Particle. Distinct particles may be
/// packed from several threads at once.</summary>
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

    StructuredBuffer<float4> Layers      : register(t0);  // delta, e.im, L, sigma
    StructuredBuffer<float>  SinG        : register(t1);  // grazing sine, Double on the host (Setup)
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
    // TCalc.RefCalc's Roughness (the 3.9.3 forms: rfLinear damps at every
    // sigma, not only below 0.5 A; rfSinus is the Stearns form, not 0)
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
        float4 lb = Layers[base + NLay - 1];            // the layer below, i + 1
        float dB = lb.x, bB = lb.y;
        float2 eB = float2(1 - dB, bB);            // for the P ratio and |eB|
        // precise: without it, the compiler/driver may reassociate
        // sin_g2 - dB against surrounding sums, undoing the cancellation-free
        // form.
        precise float reB = sin_g2 - dB;
        float2 KB = c2 * csqrt(float2(reB, bB));
        float2 R  = float2(0, 0);
        float2 Rp = float2(0, 0);
        bool first = true;   // R = 0 below the first interface: no phase term

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

  { Locked for the whole compile-and-self-check sequence, not just the
    self-check: CompileShaders, FStrict, FSelfChecked and FReflectCode/
    FChiCode are process-global, and the fallback below rewrites them after
    this instance's own compute shaders were already created from the
    pre-fallback bytes. Holding FLock across all of it means a second thread
    creating an evaluator at the same time either finishes its own compile-
    create-check sequence entirely before this one starts (so it never
    observes a half-updated FReflectCode/FChiCode/FStrict), or blocks here
    until this one is done and then compiles/creates from the settled
    result. Available already holds FLock for its whole body, including the
    throwaway Create its probe calls; TCriticalSection is re-entrant for the
    same thread (it wraps a Windows critical section), so that nested Enter
    succeeds immediately instead of deadlocking. }
  FLock.Enter;
  try
    { A double self-check failure (below) is cached for 60 seconds, the same
      window Available retries on: only Available's own probe caches a
      failure otherwise, so a direct Create (unit_LFPSO_Base's classic-fit
      evaluator, unit_PosteriorBatch's) would otherwise recompile both
      compilations and re-run the self-check every single time within that
      window, since FSelfChecked stays False forever after a double failure.
      ResetShaders clears this cache too. }
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
        { The self-check did not hold on this GPU/driver with `precise`:
          fall back to compiling every kernel with D3DCOMPILE_IEEE_STRICTNESS
          and check again before this evaluator is handed to a caller. }
        FStrict := True;
        FReflectCode := nil;
        FChiCode := nil;
        CompileShaders;
        Check(FDev.CreateComputeShader(@FReflectCode[0], Length(FReflectCode), nil, FReflect),
          'CreateComputeShader(Reflect, IEEE strict)');
        Check(FDev.CreateComputeShader(@FChiCode[0], Length(FChiCode), nil, FChi),
          'CreateComputeShader(ChiSquare, IEEE strict)');
        try
          Err := SelfCheck;
        except
          { A failure inside the IEEE-strict self-check itself (for example
            the device was removed mid-dispatch) still leaves this Create
            failing, but must not leave the process stuck compiling strict
            forever: reset FStrict and the code blobs so a later retry
            (Available's 60-second retry, or the caller's next Create) tries
            `precise` again from scratch instead of skipping straight to
            IEEE strictness because of an unrelated transient error. }
          FStrict := False;
          FReflectCode := nil;
          FChiCode := nil;
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
        { Both compilations failed (or only `precise` was tried and it was
          already strict): leave FSelfChecked False and reset FStrict and
          every code blob, so a later Create - Available's 60-second retry
          after a transient driver problem, or the caller's own next
          attempt - runs the whole compile-and-check sequence again from
          `precise`, instead of failing instantly forever. The failure
          message itself IS cached for that same 60 seconds (FSelfCheckFailMsg/
          FSelfCheckFailTick, checked at the top of this method), so a direct
          Create within the window raises at once instead of recompiling and
          re-checking both compilations again first. }
        FShaderMode := '';
        FStrict := False;
        FReflectCode := nil;
        FChiCode := nil;
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

  { The grazing sine, computed once per angle on the host in Double, exactly
    as TCalc.CalcTet's angle reaches TCalc.RefCalc: ThetaK is Single, as
    CalcTet's (t / K), and Sin runs in Double before narrowing back to Single.
    KScale stays in FParams/cbuffer Params below even though Reflect no
    longer reads it, so the 80-byte layout is unchanged. }
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

{ A fixed W/B4C multilayer on Si, built by hand (no Henke tables, no
  TLayeredModel) so the self-check runs on every machine the same way: 20
  periods of W (delta 9.6E-5, beta 7.8E-6, 12 A) and B4C (delta 1.66E-5, beta
  1.6E-8, 22 A), sigma 3 A throughout, on a Si substrate (delta 1.52E-5, beta
  3.5E-7). 200 angles, 0.1..4 deg, Cu-Kalpha, rfError, S polarisation. The
  substrate's L uses the same 1E8 A sentinel TLayeredModel.AddSubstrate does
  (unit_materials.pas): Reflect's comment at "first" explains why the
  sentinel's exact value never reaches the result. }
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
    L[0].e.re := 1; L[0].e.im := 0; L[0].delta := 0; L[0].L := 0; L[0].s := 0;   // ambient
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
    L[Idx].delta := 1.52E-5;                  // substrate, Si
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

    { Setup/Evaluate/RawCurve on Self: sizes this evaluator's buffers for one
      particle of Length(L) layers. The caller's own Setup, right after Create
      returns, replaces every one of them before any real evaluation runs. }
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
