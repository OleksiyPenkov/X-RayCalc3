unit TestXRFLines;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestXRFLines = class
  public
    [Test] procedure Test_GetLambda_KnownElements;
    [Test] procedure Test_GetLambda_CaseInsensitive;
    [Test] procedure Test_GetLambda_UnknownRaises;
    [Test] procedure Test_ExpandRange_Normal;
    [Test] procedure Test_ExpandRange_SingleElement;
    [Test] procedure Test_ExpandRange_Reversed;
    [Test] procedure Test_ExpandRange_InvalidEndpoint;
    [Test] procedure Test_ExpandRange_CrossKaLa;
    [Test] procedure Test_GetAllElements_Count;
    [Test] procedure Test_GetAllElements_Order;
  end;

implementation

uses
  System.SysUtils, unit_xrf_lines;

procedure TTestXRFLines.Test_GetLambda_KnownElements;
begin
  Assert.AreEqual(67.6,   GetXRFLambda('B'),  0.01, 'B Ka');
  Assert.AreEqual(44.7,   GetXRFLambda('C'),  0.01, 'C Ka');
  Assert.AreEqual(7.126,  GetXRFLambda('Si'), 0.01, 'Si Ka');
  Assert.AreEqual(0.9131, GetXRFLambda('U'),  0.01, 'U La');
end;

procedure TTestXRFLines.Test_GetLambda_CaseInsensitive;
begin
  Assert.AreEqual(GetXRFLambda('Si'), GetXRFLambda('si'), 0.001);
  Assert.AreEqual(GetXRFLambda('Si'), GetXRFLambda('SI'), 0.001);
end;

procedure TTestXRFLines.Test_GetLambda_UnknownRaises;
begin
  Assert.WillRaise(
    procedure begin GetXRFLambda('Xx'); end,
    EArgumentException
  );
end;

procedure TTestXRFLines.Test_ExpandRange_Normal;
var
  R: TArray<string>;
begin
  R := ExpandElementRange('B-N');
  Assert.AreEqual(3, Length(R));
  Assert.AreEqual('B', R[0]);
  Assert.AreEqual('C', R[1]);
  Assert.AreEqual('N', R[2]);
end;

procedure TTestXRFLines.Test_ExpandRange_SingleElement;
var
  R: TArray<string>;
begin
  R := ExpandElementRange('C-C');
  Assert.AreEqual(1, Length(R));
  Assert.AreEqual('C', R[0]);
end;

procedure TTestXRFLines.Test_ExpandRange_Reversed;
var
  R: TArray<string>;
begin
  R := ExpandElementRange('Si-B');
  Assert.AreEqual(10, Length(R));
  Assert.AreEqual('B', R[0]);
  Assert.AreEqual('Si', R[9]);
end;

procedure TTestXRFLines.Test_ExpandRange_InvalidEndpoint;
begin
  Assert.WillRaise(
    procedure begin ExpandElementRange('Xx-Si'); end,
    EArgumentException
  );
end;

procedure TTestXRFLines.Test_ExpandRange_CrossKaLa;
var
  R: TArray<string>;
begin
  R := ExpandElementRange('Cs-Ba');
  Assert.AreEqual(2, Length(R));
  Assert.AreEqual('Cs', R[0]);
  Assert.AreEqual('Ba', R[1]);
end;

procedure TTestXRFLines.Test_GetAllElements_Count;
begin
  Assert.AreEqual(90, Length(GetAllElements));
end;

procedure TTestXRFLines.Test_GetAllElements_Order;
var
  All: TArray<string>;
begin
  All := GetAllElements;
  Assert.AreEqual('Li', All[0]);
  Assert.AreEqual('U', All[89]);
end;

end.
