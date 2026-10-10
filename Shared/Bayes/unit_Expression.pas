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

unit unit_Expression;

(* Derived-quantity expressions ("s0.l1.thickness - s0.l3.thickness"), compiled
   once to RPN and evaluated many times against a chain sample's reported
   values. TExpression.Create is a small recursive-descent parser over the
   grammar in the phase B1 brief:

     expr    := term (('+'|'-') term)*
     term    := unary (('*'|'/') unary)*
     unary   := ('-'|'+') unary | power
     power   := primary ('^' unary)?          // right-associative; -2^2 = -4
     primary := number | name | func '(' expr ')' | '(' expr ')'
     func    := sqrt | abs | ln | exp         // case-insensitive
     name    := letter (letter | digit | '_' | '.')*
     number  := digits ['.' digits] [exp] | '.' digits [exp]
     exp     := ('e'|'E') ['+'|'-'] digits

   A bad expression raises EExpression with the 1-based column of the
   problem, so sample_posterior can refuse a request at submission time.
   Evaluate never raises: it masks the FPU's arithmetic exceptions for the
   run of the stack machine, so 1/0 is +/-Infinity and ln(-1) is NaN, and
   restores the mask afterwards regardless of what ran. *)

interface

uses
  System.SysUtils;

type
  EExpression = class(Exception)
  public
    /// The 1-based column of the token that caused the error.
    Position: Integer;
  end;

  TOpKind = (okNum, okVar, okNeg, okAdd, okSub, okMul, okDiv, okPow,
    okSqrt, okAbs, okLn, okExp);

  /// One RPN instruction. Num* fields are unused except for the kind they
  /// belong to: Value for okNum, Index (into the Values passed to Evaluate)
  /// for okVar.
  TOp = record
    Kind: TOpKind;
    Value: Double;
    Index: Integer;
  end;

  TExpressionTokenKind = (tkNumber, tkIdent, tkPlus, tkMinus, tkStar, tkSlash,
    tkCaret, tkLParen, tkRParen, tkEnd);

  /// One lexed token, with the 1-based column of its first character.
  TExpressionToken = record
    Kind: TExpressionTokenKind;
    Pos: Integer;
    Text: string;
    Num: Double;
  end;

  TExpression = class
  private
    FText: string;
    FNames: TArray<string>;
    FProgram: TArray<TOp>;
    FTokens: TArray<TExpressionToken>;
    FPos: Integer;
    function Cur: TExpressionToken;
    procedure Advance;
    procedure Emit(K: TOpKind);
    procedure EmitNum(V: Double);
    procedure EmitVar(Idx: Integer);
    procedure RaiseAt(APos: Integer; const Msg: string);
    procedure RaiseUnexpected(const Tok: TExpressionToken);
    function IndexOfName(const Name: string): Integer;
    function FuncKindOf(const Name: string; out K: TOpKind): Boolean;
    procedure Tokenize;
    procedure ParseExpr;
    procedure ParseTerm;
    procedure ParseUnary;
    procedure ParsePower;
    procedure ParsePrimary;
  public
    constructor Create(const AText: string; const Names: array of string);
    /// Values[i] belongs to the i'th name passed to Create. NaN/Inf
    /// propagate through the stack machine; this never raises.
    function Evaluate(const Values: array of Double): Double;
    property Text: string read FText;
  end;

implementation

uses
  System.Math, System.Generics.Collections;

function MakeOp(K: TOpKind): TOp;
begin
  Result.Kind := K;
  Result.Value := 0;
  Result.Index := 0;
end;

function MakeNum(V: Double): TOp;
begin
  Result.Kind := okNum;
  Result.Value := V;
  Result.Index := 0;
end;

function MakeVar(Idx: Integer): TOp;
begin
  Result.Kind := okVar;
  Result.Value := 0;
  Result.Index := Idx;
end;

function IsDigitCh(C: Char): Boolean; inline;
begin
  Result := (C >= '0') and (C <= '9');
end;

function IsLetterCh(C: Char): Boolean; inline;
begin
  Result := ((C >= 'A') and (C <= 'Z')) or ((C >= 'a') and (C <= 'z'));
end;

function IsNameCh(C: Char): Boolean; inline;
begin
  Result := IsLetterCh(C) or IsDigitCh(C) or (C = '_') or (C = '.');
end;

function SingleCharKind(C: Char; out K: TExpressionTokenKind): Boolean;
begin
  Result := True;
  case C of
    '+': K := tkPlus;
    '-': K := tkMinus;
    '*': K := tkStar;
    '/': K := tkSlash;
    '^': K := tkCaret;
    '(': K := tkLParen;
    ')': K := tkRParen;
  else
    Result := False;
  end;
end;

{ TExpression }

constructor TExpression.Create(const AText: string; const Names: array of string);
var
  i: Integer;
begin
  inherited Create;
  FText := AText;
  SetLength(FNames, Length(Names));
  for i := 0 to High(Names) do
    FNames[i] := Names[i];
  Tokenize;
  FPos := 0;
  FProgram := nil;
  ParseExpr;
  if Cur.Kind <> tkEnd then
    RaiseUnexpected(Cur);
end;

procedure TExpression.Tokenize;
var
  S: string;
  Len, i, Start, ExpAt: Integer;
  Ch: Char;
  Toks: TList<TExpressionToken>;
  Tok: TExpressionToken;
  RawNum: string;
  FS: TFormatSettings;
  TK: TExpressionTokenKind;
begin
  S := FText;
  Len := Length(S);
  FS := TFormatSettings.Invariant;
  Toks := TList<TExpressionToken>.Create;
  try
    i := 1;
    while i <= Len do
    begin
      Ch := S[i];
      if (Ch = ' ') or (Ch = #9) or (Ch = #13) or (Ch = #10) then
      begin
        Inc(i);
        Continue;
      end;

      if IsDigitCh(Ch) or ((Ch = '.') and (i < Len) and IsDigitCh(S[i + 1])) then
      begin
        Start := i;
        if Ch = '.' then
        begin
          Inc(i); // past the leading dot
          while (i <= Len) and IsDigitCh(S[i]) do
            Inc(i);
        end
        else
        begin
          while (i <= Len) and IsDigitCh(S[i]) do
            Inc(i);
          if (i <= Len) and (S[i] = '.') and (i < Len) and IsDigitCh(S[i + 1]) then
          begin
            Inc(i); // past the dot
            while (i <= Len) and IsDigitCh(S[i]) do
              Inc(i);
          end;
        end;
        if (i <= Len) and ((S[i] = 'e') or (S[i] = 'E')) then
        begin
          ExpAt := i + 1;
          if (ExpAt <= Len) and ((S[ExpAt] = '+') or (S[ExpAt] = '-')) then
            Inc(ExpAt);
          if (ExpAt <= Len) and IsDigitCh(S[ExpAt]) then
          begin
            i := ExpAt;
            while (i <= Len) and IsDigitCh(S[i]) do
              Inc(i);
          end;
        end;
        RawNum := Copy(S, Start, i - Start);
        Tok.Kind := tkNumber;
        Tok.Pos := Start;
        Tok.Text := RawNum;
        if RawNum[1] = '.' then
          Tok.Num := StrToFloat('0' + RawNum, FS)
        else
          Tok.Num := StrToFloat(RawNum, FS);
        Toks.Add(Tok);
        Continue;
      end;

      if IsLetterCh(Ch) then
      begin
        Start := i;
        Inc(i);
        while (i <= Len) and IsNameCh(S[i]) do
          Inc(i);
        Tok.Kind := tkIdent;
        Tok.Pos := Start;
        Tok.Text := Copy(S, Start, i - Start);
        Tok.Num := 0;
        Toks.Add(Tok);
        Continue;
      end;

      if SingleCharKind(Ch, TK) then
      begin
        Tok.Kind := TK;
        Tok.Pos := i;
        Tok.Text := Ch;
        Tok.Num := 0;
        Toks.Add(Tok);
        Inc(i);
        Continue;
      end;

      RaiseAt(i, Format('unexpected "%s"', [Ch]));
    end;

    Tok.Kind := tkEnd;
    Tok.Pos := Len + 1;
    Tok.Text := '';
    Tok.Num := 0;
    Toks.Add(Tok);

    FTokens := Toks.ToArray;
  finally
    Toks.Free;
  end;
end;

function TExpression.Cur: TExpressionToken;
begin
  Result := FTokens[FPos];
end;

procedure TExpression.Advance;
begin
  if FTokens[FPos].Kind <> tkEnd then
    Inc(FPos);
end;

procedure TExpression.Emit(K: TOpKind);
begin
  SetLength(FProgram, Length(FProgram) + 1);
  FProgram[High(FProgram)] := MakeOp(K);
end;

procedure TExpression.EmitNum(V: Double);
begin
  SetLength(FProgram, Length(FProgram) + 1);
  FProgram[High(FProgram)] := MakeNum(V);
end;

procedure TExpression.EmitVar(Idx: Integer);
begin
  SetLength(FProgram, Length(FProgram) + 1);
  FProgram[High(FProgram)] := MakeVar(Idx);
end;

procedure TExpression.RaiseAt(APos: Integer; const Msg: string);
var
  Ex: EExpression;
begin
  Ex := EExpression.CreateFmt('%s at column %d', [Msg, APos]);
  Ex.Position := APos;
  raise Ex;
end;

procedure TExpression.RaiseUnexpected(const Tok: TExpressionToken);
begin
  if Tok.Kind = tkEnd then
    RaiseAt(Tok.Pos, 'unexpected end')
  else
    RaiseAt(Tok.Pos, Format('unexpected "%s"', [Tok.Text]));
end;

function TExpression.IndexOfName(const Name: string): Integer;
var
  i: Integer;
begin
  for i := 0 to High(FNames) do
    if FNames[i] = Name then
      Exit(i);
  Result := -1;
end;

function TExpression.FuncKindOf(const Name: string; out K: TOpKind): Boolean;
begin
  Result := True;
  if SameText(Name, 'sqrt') then
    K := okSqrt
  else if SameText(Name, 'abs') then
    K := okAbs
  else if SameText(Name, 'ln') then
    K := okLn
  else if SameText(Name, 'exp') then
    K := okExp
  else
    Result := False;
end;

procedure TExpression.ParseExpr;
var
  K: TExpressionTokenKind;
begin
  ParseTerm;
  while Cur.Kind in [tkPlus, tkMinus] do
  begin
    K := Cur.Kind;
    Advance;
    ParseTerm;
    if K = tkPlus then
      Emit(okAdd)
    else
      Emit(okSub);
  end;
end;

procedure TExpression.ParseTerm;
var
  K: TExpressionTokenKind;
begin
  ParseUnary;
  while Cur.Kind in [tkStar, tkSlash] do
  begin
    K := Cur.Kind;
    Advance;
    ParseUnary;
    if K = tkStar then
      Emit(okMul)
    else
      Emit(okDiv);
  end;
end;

procedure TExpression.ParseUnary;
begin
  if Cur.Kind = tkMinus then
  begin
    Advance;
    ParseUnary;
    Emit(okNeg);
  end
  else if Cur.Kind = tkPlus then
  begin
    Advance;
    ParseUnary;
  end
  else
    ParsePower;
end;

procedure TExpression.ParsePower;
begin
  ParsePrimary;
  if Cur.Kind = tkCaret then
  begin
    Advance;
    ParseUnary; // right-associative: the exponent is itself a unary/power chain
    Emit(okPow);
  end;
end;

procedure TExpression.ParsePrimary;
var
  Tok: TExpressionToken;
  FK: TOpKind;
  Idx: Integer;
begin
  Tok := Cur;
  case Tok.Kind of
    tkNumber:
      begin
        Advance;
        EmitNum(Tok.Num);
      end;
    tkIdent:
      begin
        Advance;
        if Cur.Kind = tkLParen then
        begin
          // Followed by '(': this identifier must name one of the four
          // recognised functions, case-insensitively.
          if not FuncKindOf(Tok.Text, FK) then
            RaiseAt(Tok.Pos, Format('unknown function "%s"', [Tok.Text]));
          Advance; // consume '('
          ParseExpr;
          if Cur.Kind <> tkRParen then
            RaiseAt(Cur.Pos, 'expected ")"');
          Advance; // consume ')'
          Emit(FK);
        end
        else
        begin
          // Not followed by '(': a plain variable reference, matched
          // case-sensitively against the names given to Create.
          Idx := IndexOfName(Tok.Text);
          if Idx < 0 then
            RaiseAt(Tok.Pos, Format('unknown name "%s"', [Tok.Text]));
          EmitVar(Idx);
        end;
      end;
    tkLParen:
      begin
        Advance;
        ParseExpr;
        if Cur.Kind <> tkRParen then
          RaiseAt(Cur.Pos, 'expected ")"');
        Advance;
      end;
  else
    RaiseUnexpected(Tok);
  end;
end;

function TExpression.Evaluate(const Values: array of Double): Double;
var
  Stack: TArray<Double>;
  SP, i, Idx: Integer;
  OldMask: TArithmeticExceptionMask;
begin
  OldMask := GetExceptionMask;
  try
    SetExceptionMask(exAllArithmeticExceptions);
    SetLength(Stack, Length(FProgram) + 1);
    SP := 0;
    for i := 0 to High(FProgram) do
    begin
      case FProgram[i].Kind of
        okNum:
          begin
            Stack[SP] := FProgram[i].Value;
            Inc(SP);
          end;
        okVar:
          begin
            Idx := FProgram[i].Index;
            if (Idx >= 0) and (Idx <= High(Values)) then
              Stack[SP] := Values[Idx]
            else
              Stack[SP] := NaN; // defensive: caller's Values shorter than Names
            Inc(SP);
          end;
        okNeg:
          Stack[SP - 1] := -Stack[SP - 1];
        okAdd:
          begin
            Dec(SP);
            Stack[SP - 1] := Stack[SP - 1] + Stack[SP];
          end;
        okSub:
          begin
            Dec(SP);
            Stack[SP - 1] := Stack[SP - 1] - Stack[SP];
          end;
        okMul:
          begin
            Dec(SP);
            Stack[SP - 1] := Stack[SP - 1] * Stack[SP];
          end;
        okDiv:
          begin
            Dec(SP);
            Stack[SP - 1] := Stack[SP - 1] / Stack[SP];
          end;
        okPow:
          begin
            Dec(SP);
            Stack[SP - 1] := Power(Stack[SP - 1], Stack[SP]);
          end;
        okSqrt:
          Stack[SP - 1] := Sqrt(Stack[SP - 1]);
        okAbs:
          Stack[SP - 1] := Abs(Stack[SP - 1]);
        okLn:
          Stack[SP - 1] := Ln(Stack[SP - 1]);
        okExp:
          Stack[SP - 1] := Exp(Stack[SP - 1]);
      end;
    end;
    if SP > 0 then
      Result := Stack[SP - 1]
    else
      Result := NaN;
  finally
    SetExceptionMask(OldMask);
  end;
end;

end.
