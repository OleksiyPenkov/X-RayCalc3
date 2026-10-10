(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2026 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  *   This file is part of X-Ray Calc 3, released under the MIT License:
  *   see LICENSE in the repository root.
  *
  ****************************************************************************** *)

unit unit_JointPosterior;

(* Several curves' posteriors as one (spec section 6). Each member is a
   TLogPosterior with its own map, data and nuisance slots. A link makes one
   parameter of several members a single shared slot.

   The joint vector is the members' slots in member order, a linked slot at
   the place of its first member's. A slot that is not linked is named
   "m<k>." + its member's own name; a linked one takes the link's name.

     Cost      = sum_m w_m * likelihood cost_m + sum_m prior term_m
     Minus2LnL = sum_m w_m * Minus2LnL_m

   A shared slot's priors are each member's prior on it: every member adds
   its own term, so the Gaussians multiply. Its bounds are the intersection
   of the members' bounds, and each member's own Apply still checks its own.

   CreateSingle wraps one TLogPosterior with no prefix and weight 1: its
   slots, names, reported values, costs and curves are the member's own, bit
   for bit, so the single-curve fit and sampler run through this class
   unchanged.

   Every member keeps its own TCalc and TLayeredModel (TJointWorkspace).
   TLayeredModel's arrays only grow - Reset keeps them - and TCalc reads their
   whole length, so a model shared by members of different layer counts would
   hand the smaller member the larger one's stale layers. *)

interface

uses
  System.SysUtils, unit_Types, unit_materials, unit_calc, unit_ParamMap, unit_LogPosterior;

type
  EJointPosterior = class(Exception);

  /// <summary>One link: every listed member's own slot LocalName becomes the
  /// one shared slot Name. The member's value is A * slot + B; only A = 1,
  /// B = 0 (a plain shared value) is supported - the fields are there so that
  /// affine ties can come later (spec section 6).</summary>
  TJointLink = record
    Name, LocalName: string;
    Members: TArray<Integer>;
    A, B: Double;
  end;

  /// <summary>One worker's scratch: a TCalc and a TLayeredModel per member,
  /// never shared between members (see the unit header).</summary>
  TJointWorkspace = record
    Calcs: TArray<TCalc>;
    Models: TArray<TLayeredModel>;
  end;

  TJointTerms = record
    /// Every member's TParamMap.Apply accepted its part of the vector.
    Feasible: Boolean;
    Cost: Double;          // INFEASIBLE_COST when not Feasible
    Minus2LnL: Double;     // sum of w_m * Minus2LnL_m
    PriorTerm: Double;     // sum of the members' prior terms
    /// One entry per member; after an infeasible member the rest are Default.
    Members: TArray<TPosteriorTerms>;
  end;

  TJointPosterior = class
  private
    FMembers: TArray<TLogPosterior>;
    FWeights: TArray<Double>;
    FPrefixes: TArray<string>;
    FSlots: TArray<TParamSlot>;
    FSources: TArray<TArray<Integer>>;   // [member][member slot] -> joint slot
    FOwns: Boolean;
    function GetSlot(i: Integer): TParamSlot;
    function GetMember(m: Integer): TLogPosterior;
    function GetWeight(m: Integer): Double;
    function GetPrefix(m: Integer): string;
    function SharedSlot(const Link: TJointLink): TParamSlot;
  public
    /// <summary>APosterior alone, no prefix, weight 1. With AOwns the
    /// posterior and its map are freed with this object.</summary>
    constructor CreateSingle(APosterior: TLogPosterior; AOwns: Boolean = False);
    /// <summary>Members "m0.", "m1.", ... joined by ALinks. With AOwns the
    /// members and their maps belong to this object from the call on - even
    /// when Create raises, since the destructor then runs and frees them.
    /// Raises EJointPosterior for a bad weight, link or name.</summary>
    constructor Create(const AMembers: TArray<TLogPosterior>; const AWeights: TArray<Double>;
      const ALinks: TArray<TJointLink>; AOwns: Boolean);
    destructor Destroy; override;
    function Count: Integer;
    function MemberCount: Integer;
    function IndexOf(const Name: string): Integer;
    function StartVector: TArray<Double>;
    /// <summary>Member m's own vector, in its map's slot order.</summary>
    function MemberTheta(m: Integer; const Theta: array of Double): TArray<Double>;
    /// <summary>Every member's Apply, in member order; Member is the first
    /// member that refuses its part, -1 when none does.</summary>
    function Feasible(const Theta: array of Double; out Member: Integer): Boolean;
    function NewWorkspace: TJointWorkspace;
    /// <summary>Frees W's calcs and models from member FromMember on; the
    /// ones before it are left alone (TLFPSO_Posterior lends member 0's).</summary>
    class procedure FreeWorkspace(var W: TJointWorkspace; FromMember: Integer = 0); static;
    /// <summary>The joint terms on W. Curves[m] is member m's unscaled model
    /// curve, nil for a member that was not evaluated. Thread-safe with one W
    /// per thread; it never calls Random.</summary>
    function Evaluate(const W: TJointWorkspace; const Theta: array of Double;
      out Curves: TArray<TDataArray>): TJointTerms;
    function EvaluateOnce(const Theta: array of Double; out Curves: TArray<TDataArray>): TJointTerms;
    /// <summary>The joint slots, then per member its map's aliases and
    /// derived layers (ReportedNames past its slots), prefixed.</summary>
    function ReportedNames: TArray<string>;
    function ReportedValues(const Theta: array of Double; out Values: TArray<Double>): Boolean;
    /// <summary>A weight other than 1 (spec section 6: the intervals then lose
    /// their plain meaning).</summary>
    function Tempered: Boolean;
    property Slots[i: Integer]: TParamSlot read GetSlot;
    property Members[m: Integer]: TLogPosterior read GetMember;
    property Weights[m: Integer]: Double read GetWeight;
    property Prefixes[m: Integer]: string read GetPrefix;
  end;

/// <summary>A plain shared link (A = 1, B = 0).</summary>
function JointLink(const Name, LocalName: string; const Members: array of Integer): TJointLink;

implementation

uses
  System.Math, unit_Likelihood;

function JointLink(const Name, LocalName: string; const Members: array of Integer): TJointLink;
var
  i: Integer;
begin
  Result := Default(TJointLink);
  Result.Name := Name;
  Result.LocalName := LocalName;
  SetLength(Result.Members, Length(Members));
  for i := 0 to High(Members) do
    Result.Members[i] := Members[i];
  Result.A := 1;
  Result.B := 0;
end;

constructor TJointPosterior.CreateSingle(APosterior: TLogPosterior; AOwns: Boolean);
var
  i: Integer;
begin
  inherited Create;
  FOwns := AOwns;
  FMembers := [APosterior];
  FWeights := [1.0];
  FPrefixes := [''];
  SetLength(FSlots, APosterior.Map.Count);
  SetLength(FSources, 1);
  SetLength(FSources[0], APosterior.Map.Count);
  for i := 0 to High(FSlots) do
  begin
    FSlots[i] := APosterior.Map.Slots[i];
    FSources[0][i] := i;
  end;
end;

constructor TJointPosterior.Create(const AMembers: TArray<TLogPosterior>;
  const AWeights: TArray<Double>; const ALinks: TArray<TJointLink>; AOwns: Boolean);
var
  m, i, j, k, Local: Integer;
  LinkOf: TArray<TArray<Integer>>;   // [member][member slot] -> link, -1
  LinkSlot: TArray<Integer>;         // [link] -> joint slot, -1 until placed
  Map: TParamMap;
  Slot: TParamSlot;
begin
  inherited Create;
  FOwns := AOwns;                    // first: Destroy frees what was handed over
  FMembers := Copy(AMembers);
  if Length(AMembers) = 0 then
    raise EJointPosterior.Create('A joint posterior needs at least one member');
  if Length(AWeights) <> Length(AMembers) then
    raise EJointPosterior.CreateFmt('%d weights for %d members',
      [Length(AWeights), Length(AMembers)]);
  FWeights := Copy(AWeights);
  for m := 0 to High(FWeights) do
    if not (FWeights[m] > 0) then
      raise EJointPosterior.CreateFmt('Member %d: the weight must be greater than 0', [m]);
  SetLength(FPrefixes, Length(AMembers));
  for m := 0 to High(AMembers) do
    FPrefixes[m] := Format('m%d.', [m]);

  SetLength(LinkOf, Length(AMembers));
  for m := 0 to High(AMembers) do
  begin
    SetLength(LinkOf[m], AMembers[m].Map.Count);
    for i := 0 to High(LinkOf[m]) do
      LinkOf[m][i] := -1;
  end;

  for k := 0 to High(ALinks) do
  begin
    if (ALinks[k].A <> 1) or (ALinks[k].B <> 0) then
      raise EJointPosterior.CreateFmt('Link "%s": only a shared value is supported ' +
        '(A = 1, B = 0), not an affine tie', [ALinks[k].Name]);
    for j := 0 to k - 1 do
      if SameText(ALinks[j].Name, ALinks[k].Name) then
        raise EJointPosterior.CreateFmt('Two links are named "%s"', [ALinks[k].Name]);
    if Length(ALinks[k].Members) < 2 then
      raise EJointPosterior.CreateFmt('Link "%s" must list at least two members',
        [ALinks[k].Name]);
    for j := 0 to High(ALinks[k].Members) do
    begin
      m := ALinks[k].Members[j];
      if (m < 0) or (m > High(AMembers)) then
        raise EJointPosterior.CreateFmt('Link "%s": there is no member %d', [ALinks[k].Name, m]);
      for i := 0 to j - 1 do
        if ALinks[k].Members[i] = m then
          raise EJointPosterior.CreateFmt('Link "%s" lists member %d twice', [ALinks[k].Name, m]);
      Map := AMembers[m].Map;
      Local := Map.IndexOf(ALinks[k].LocalName);
      if (Local < 0) or (Map.Slots[Local].Kind <> skParam) then
      begin
        for i := 0 to High(Map.Derived) do
          if SameText(Map.Derived[i].Name, ALinks[k].LocalName) then
            raise EJointPosterior.CreateFmt('Link "%s": %s is member %d''s derived layer, ' +
              'which cannot be linked', [ALinks[k].Name, ALinks[k].LocalName, m]);
        raise EJointPosterior.CreateFmt('Link "%s": member %d has no free layer parameter %s',
          [ALinks[k].Name, m, ALinks[k].LocalName]);
      end;
      if LinkOf[m][Local] >= 0 then
        raise EJointPosterior.CreateFmt('Links "%s" and "%s" both take member %d''s %s',
          [ALinks[LinkOf[m][Local]].Name, ALinks[k].Name, m, ALinks[k].LocalName]);
      LinkOf[m][Local] := k;
    end;
  end;

  SetLength(LinkSlot, Length(ALinks));
  for k := 0 to High(LinkSlot) do
    LinkSlot[k] := -1;
  SetLength(FSources, Length(AMembers));
  for m := 0 to High(AMembers) do
  begin
    Map := AMembers[m].Map;
    SetLength(FSources[m], Map.Count);
    for i := 0 to Map.Count - 1 do
    begin
      k := LinkOf[m][i];
      if k < 0 then
      begin
        Slot := Map.Slots[i];
        Slot.Name := FPrefixes[m] + Slot.Name;
        FSources[m][i] := Length(FSlots);
        FSlots := FSlots + [Slot];
      end
      else
      begin
        if LinkSlot[k] < 0 then
        begin
          LinkSlot[k] := Length(FSlots);
          FSlots := FSlots + [SharedSlot(ALinks[k])];
        end;
        FSources[m][i] := LinkSlot[k];
      end;
    end;
  end;

  for i := 0 to High(FSlots) do
    for j := 0 to i - 1 do
      if SameText(FSlots[i].Name, FSlots[j].Name) then
        raise EJointPosterior.CreateFmt('Two parameters of the joint fit are both named "%s"',
          [FSlots[i].Name]);
end;

{ The members' slots intersected: the first listed member's slot, with the
  largest lower and the smallest upper bound, its start clamped into them, and
  the product of every member's Gaussian prior (precision-weighted mean,
  sd = 1/sqrt(sum of precisions)) - the prior DrawStart draws from. The
  posterior itself never reads this prior: each member adds its own term. }
function TJointPosterior.SharedSlot(const Link: TJointLink): TParamSlot;
var
  j: Integer;
  Map: TParamMap;
  S: TParamSlot;
  Precision, Weighted: Double;
begin
  Map := FMembers[Link.Members[0]].Map;
  Result := Map.Slots[Map.IndexOf(Link.LocalName)];
  Result.Name := Link.Name;
  Result.HasPrior := False;
  Precision := 0;
  Weighted := 0;
  for j := 0 to High(Link.Members) do
  begin
    Map := FMembers[Link.Members[j]].Map;
    S := Map.Slots[Map.IndexOf(Link.LocalName)];
    Result.Lower := Max(Result.Lower, S.Lower);
    Result.Upper := Min(Result.Upper, S.Upper);
    if S.HasPrior then
    begin
      Precision := Precision + 1 / Sqr(S.PriorSD);
      Weighted := Weighted + S.PriorMean / Sqr(S.PriorSD);
    end;
  end;
  if Result.Lower > Result.Upper then
    raise EJointPosterior.CreateFmt('Link "%s": the members'' bounds on %s do not overlap',
      [Link.Name, Link.LocalName]);
  Result.Start := EnsureRange(Result.Start, Result.Lower, Result.Upper);
  if Precision > 0 then
  begin
    Result.HasPrior := True;
    Result.PriorMean := Weighted / Precision;
    Result.PriorSD := 1 / Sqrt(Precision);
  end;
end;

destructor TJointPosterior.Destroy;
var
  m: Integer;
  Map: TParamMap;
begin
  if FOwns then
    for m := 0 to High(FMembers) do
      if FMembers[m] <> nil then
      begin
        Map := FMembers[m].Map;
        FMembers[m].Free;            // before its map: the posterior points at it
        Map.Free;
      end;
  inherited;
end;

function TJointPosterior.GetSlot(i: Integer): TParamSlot;
begin
  Result := FSlots[i];
end;

function TJointPosterior.GetMember(m: Integer): TLogPosterior;
begin
  Result := FMembers[m];
end;

function TJointPosterior.GetWeight(m: Integer): Double;
begin
  Result := FWeights[m];
end;

function TJointPosterior.GetPrefix(m: Integer): string;
begin
  Result := FPrefixes[m];
end;

function TJointPosterior.Count: Integer;
begin
  Result := Length(FSlots);
end;

function TJointPosterior.MemberCount: Integer;
begin
  Result := Length(FMembers);
end;

function TJointPosterior.IndexOf(const Name: string): Integer;
var
  i: Integer;
begin
  for i := 0 to High(FSlots) do
    if SameText(FSlots[i].Name, Name) then
      Exit(i);
  Result := -1;
end;

function TJointPosterior.StartVector: TArray<Double>;
var
  i: Integer;
begin
  SetLength(Result, Length(FSlots));
  for i := 0 to High(FSlots) do
    Result[i] := FSlots[i].Start;
end;

function TJointPosterior.MemberTheta(m: Integer; const Theta: array of Double): TArray<Double>;
var
  i: Integer;
begin
  SetLength(Result, Length(FSources[m]));
  for i := 0 to High(Result) do
    Result[i] := Theta[FSources[m][i]];
end;

function TJointPosterior.Feasible(const Theta: array of Double; out Member: Integer): Boolean;
var
  m: Integer;
  S: TFitStructure;
  Nuis: TNuisance;
begin
  for m := 0 to High(FMembers) do
  begin
    FMembers[m].Map.Template.CopyContent(S);
    if not FMembers[m].Map.Apply(MemberTheta(m, Theta), S, Nuis) then
    begin
      Member := m;
      Exit(False);
    end;
  end;
  Member := -1;
  Result := True;
end;

function TJointPosterior.NewWorkspace: TJointWorkspace;
var
  m: Integer;
begin
  SetLength(Result.Calcs, Length(FMembers));
  SetLength(Result.Models, Length(FMembers));
  try
    for m := 0 to High(FMembers) do
    begin
      Result.Models[m] := TLayeredModel.Create;
      Result.Models[m].Init;
      Result.Calcs[m] := FMembers[m].NewCalc;
    end;
  except
    FreeWorkspace(Result);
    raise;
  end;
end;

class procedure TJointPosterior.FreeWorkspace(var W: TJointWorkspace; FromMember: Integer);
var
  m: Integer;
begin
  for m := FromMember to High(W.Calcs) do
    if W.Calcs[m] <> nil then
    begin
      W.Calcs[m].Model := nil;     // TCalc.Destroy frees its model; the models are ours
      FreeAndNil(W.Calcs[m]);
    end;
  for m := FromMember to High(W.Models) do
    FreeAndNil(W.Models[m]);
end;

{ The sums start at 0 and add in member order, so for one member of weight 1
  they are exactly that member's numbers: 0 + 1 * x = x, and Cost = its
  likelihood cost + its prior term, the sum TLogPosterior.Evaluate forms. }
function TJointPosterior.Evaluate(const W: TJointWorkspace; const Theta: array of Double;
  out Curves: TArray<TDataArray>): TJointTerms;
var
  m: Integer;
  T: TPosteriorTerms;
  LikCost, Prior, M2: Double;
begin
  Result := Default(TJointTerms);
  SetLength(Curves, Length(FMembers));
  SetLength(Result.Members, Length(FMembers));
  LikCost := 0;
  Prior := 0;
  M2 := 0;
  for m := 0 to High(FMembers) do
  begin
    T := FMembers[m].Evaluate(W.Calcs[m], W.Models[m], MemberTheta(m, Theta), Curves[m]);
    Result.Members[m] := T;
    if not T.Feasible then
    begin
      Result.Cost := INFEASIBLE_COST;
      Exit;
    end;
    LikCost := LikCost + FWeights[m] * T.Likelihood.Cost;
    Prior := Prior + T.PriorTerm;
    M2 := M2 + FWeights[m] * T.Likelihood.Minus2LnL;
  end;
  Result.Feasible := True;
  Result.PriorTerm := Prior;
  Result.Minus2LnL := M2;
  Result.Cost := LikCost + Prior;
end;

function TJointPosterior.EvaluateOnce(const Theta: array of Double;
  out Curves: TArray<TDataArray>): TJointTerms;
var
  W: TJointWorkspace;
begin
  W := NewWorkspace;
  try
    Result := Evaluate(W, Theta, Curves);
  finally
    FreeWorkspace(W);
  end;
end;

function TJointPosterior.ReportedNames: TArray<string>;
var
  m, i: Integer;
  Own: TArray<string>;
begin
  SetLength(Result, Length(FSlots));
  for i := 0 to High(FSlots) do
    Result[i] := FSlots[i].Name;
  for m := 0 to High(FMembers) do
  begin
    Own := FMembers[m].Map.ReportedNames;
    for i := FMembers[m].Map.Count to High(Own) do
      Result := Result + [FPrefixes[m] + Own[i]];
  end;
end;

function TJointPosterior.ReportedValues(const Theta: array of Double;
  out Values: TArray<Double>): Boolean;
var
  m, i: Integer;
  Own: TArray<Double>;
begin
  SetLength(Values, Length(FSlots));
  for i := 0 to High(FSlots) do
    Values[i] := Theta[i];
  for m := 0 to High(FMembers) do
  begin
    if not FMembers[m].Map.ReportedValues(MemberTheta(m, Theta), Own) then
    begin
      Values := nil;
      Exit(False);
    end;
    for i := FMembers[m].Map.Count to High(Own) do
      Values := Values + [Own[i]];
  end;
  Result := True;
end;

function TJointPosterior.Tempered: Boolean;
var
  m: Integer;
begin
  for m := 0 to High(FWeights) do
    if FWeights[m] <> 1 then
      Exit(True);
  Result := False;
end;

end.
