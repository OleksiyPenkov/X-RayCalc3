unit unit_XRCLayerControl;

interface

uses
  SysUtils, Classes, Controls, ExtCtrls, RzEdit, RzSpnEdt,
  RzPanel, RzButton, RzLabel, RzRadChk, RzCommon, Vcl.Graphics, unit_types,
  Messages, Winapi.Windows, unit_consts;

type
  TXRCLayerControl = class (TRzPanel)
    private
      Name: TRzLabel;
      Thickness: TRzSpinEdit;
      Sigma: TRzSpinEdit;
      Rho: TRzSpinEdit;
      FLinkCheckBox: TRzCheckBox;

      FData : TLayerData;
      FOnSet:  boolean;
      FHandler: HWND;

      FLinked : TXRCLayerControl;
      FSubstrate: boolean;
      FSelected: boolean;

      procedure ValueChange(Sender: TObject);
      procedure SetIncrement(const Value: Double);
      procedure SetEnabled(const Value: Boolean);
      function GetEnabled: Boolean;
      function GetLinked: TXRCLayerControl;
      procedure SetLinked(const Value: TXRCLayerControl);
      function GetCheckBox: TRzCheckBox;
      procedure SetCheckBox(const Value: TRzCheckBox);
      function GetLinkChecked: Boolean;
      procedure SetSubstrate(const Value: boolean);
      procedure InternalOnDblClick(Sender: TObject);
      procedure InternalOnClick(Sender: TObject);
      function AddSpinEdit(const index, Left, Max: integer): TRzSpinEdit;
      procedure SetLayerData(const Value: TLayerData);
      procedure SetSlected(const Value: boolean);
    public
      constructor Create(AOwner: TComponent; const Handler: HWND; const Data: TLayerData);
      destructor  Destroy; override;

      property Substrate: boolean read FSubstrate write SetSubstrate;

      procedure Edit;
    published
      property Increment: Double write SetIncrement;
      property Enabled: Boolean read GetEnabled write SetEnabled;
      property Linked:TXRCLayerControl read GetLinked write SetLinked;
      property Onset: Boolean read FOnSet write FOnSet;
      property CheckBox:TRzCheckBox read GetCheckBox write SetCheckBox;
      property Checked: Boolean read GetLinkChecked;
      property Selected: boolean read FSelected write SetSlected;

      property Data: TLayerData read FData write SetLayerData;

      procedure IncreaseThickness;
      procedure DecreaseThickness;
      procedure UpdateID(const StackID, LayerID: integer);
  end;

implementation

uses
  editor_Substrate, unit_SMessages;

{ TXRCLayerControl }

function TXRCLayerControl.AddSpinEdit(const index, Left, Max: integer):TRzSpinEdit;
begin
  Result := TRzSpinEdit.Create(Self);

  Result.Parent := Self;
  Result.Left := Left;
  Result.Top := 11;
  Result.Width := 65;
  Result.Height := 21;
  Result.Decimals := 2;
  Result.Increment := 0.1;
  Result.Max := Max;
  Result.Min := 0;
  Result.AllowKeyEdit := True;
  Result.IntegersOnly := False;
  Result.CheckRange := True;
  Result.Tag := Index;

  Result.OnChange := ValueChange
end;

constructor TXRCLayerControl.Create(AOwner: TComponent; const Handler: HWND; const Data: TLayerData);
begin
  inherited Create(AOwner);
  Parent := AOwner as TWinControl;
  FHandler := Handler;

  FOnset := True;
  FData  := Data;


  AlignWithMargins := True;
  Align := alTop;
  BevelWidth := 5;
  BorderOuter := fsFlatRounded;

  //Name
  Name := TRzLabel.Create(Self);

  //Thickness
  Thickness := AddSpinEdit(1, 110, 99999);

  //Sigma
  Sigma := AddSpinEdit(2, 180, 50);

  //Rho
  Rho := AddSpinEdit(3, 250, 30);

  //RzCheckBox1
  FLinkCheckBox := TRzCheckBox.Create(Self);


  //Name
  Name.Name := 'Name';
  Name.Parent := Self;
  Name.Left := 33;
  Name.Top := 14;
  Name.Width := 129;
  Name.Height := 13;
  Name.AutoSize := False;
  Name.Caption := 'Name';
  Name.Font.Height := -11;
  Name.Font.Name := 'Tahoma';
  Name.Font.Style := [fsBold];
  Name.ParentFont := False;

  //Link
  FLinkCheckBox.Name := '';
  FLinkCheckBox.Parent := Self;
  FLinkCheckBox.Left := 8;
  FLinkCheckBox.Top := 13;
  FLinkCheckBox.Width := 19;
  FLinkCheckBox.Height := 15;
  FLinkCheckBox.TabOrder := 3;


  Name.Caption    := FData.Material;
  Thickness.Text  := FloatToStrF(FData.H.V, ffFixed, 4, 2);
  Sigma.Text      := FloatToStrF(FData.s.V, ffFixed, 4, 2);
  Rho.Text        := FloatToStrF(FData.r.V, ffFixed, 4, 2);

  FLinked := nil;

  Self.OnDblClick := InternalOnDblClick;
  Name.OnDblClick := InternalOnDblClick;
  Self.OnClick := InternalOnClick;
  Name.OnClick := InternalOnClick;

  FSubstrate := False;
  FOnset := False;
end;

procedure TXRCLayerControl.DecreaseThickness;
begin
  Thickness.Value := Thickness.Value - Thickness.Increment;
end;

destructor TXRCLayerControl.Destroy;
begin
  FLinked := nil;
  inherited Destroy;
end;

procedure TXRCLayerControl.Edit;
var
  S1, S2: string;
begin
  if FSubstrate then
  begin
    S1 := Sigma.Text;
    S2 := Rho.Text;

    edtrSubstrate.Edit(FData.Material, S1, S2);

    Sigma.Text := S1;
    Rho.Text   := S2;
  end;
end;

procedure TXRCLayerControl.SetCheckBox(const Value: TRzCheckBox);
begin
  FLinkCheckBox := Value;
end;

procedure TXRCLayerControl.SetEnabled(const Value: Boolean);
begin
  Enabled := Value;
end;

function TXRCLayerControl.GetCheckBox: TRzCheckBox;
begin
  Result := FLinkCheckBox;
end;

function TXRCLayerControl.GetEnabled: Boolean;
begin
  Result := Enabled;
end;

function TXRCLayerControl.GetLinkChecked: Boolean;
begin
  Result := FLinkCheckBox.Checked;
end;

function TXRCLayerControl.GetLinked: TXRCLayerControl;
begin
  Result := nil;
  Result := FLinked;
end;

procedure TXRCLayerControl.IncreaseThickness;
begin
  Thickness.Value := Thickness.Value + Thickness.Increment;
end;

procedure TXRCLayerControl.InternalOnClick(Sender: TObject);
begin
  if not FSubstrate then
      LayerClick(FData.StackID, FData.ID);
end;

procedure TXRCLayerControl.InternalOnDblClick(Sender: TObject);
begin
  Edit;
end;

procedure TXRCLayerControl.SetIncrement(const Value: Double);
begin
  Thickness.Increment := Value;
  Sigma.Increment     := Value;
  Rho.Increment       := Value;
end;

procedure TXRCLayerControl.SetLayerData(const Value: TLayerData);
begin
  FData := Value;

  Thickness.Value := FData.H.V;
  Sigma.Value     := FData.s.V;
  Rho.Value       := FData.r.V;
end;

procedure TXRCLayerControl.SetLinked(const Value: TXRCLayerControl);
begin
  FLinked := Value;
end;

procedure TXRCLayerControl.SetSlected(const Value: boolean);
begin
  FSelected := Value;
  if FSelected then
    Name.Font.Color := clRed
  else
    Name.Font.Color := clBlack;
end;

procedure TXRCLayerControl.SetSubstrate(const Value: boolean);
begin
  FSubstrate := Value;
  Thickness.Visible := not FSubstrate;
  FLinkCheckBox.Visible := not FSubstrate;
  Color := clLtGray;
end;

procedure TXRCLayerControl.UpdateID(const StackID, LayerID: integer);
begin
  FData.StackID := StackID;
  if LayerID <> -1 then
       FData.ID := LayerID;
end;

procedure TXRCLayerControl.ValueChange;
var
  FOnSetOld: Boolean;
begin
  FOnSetOld := FOnSet;
  Onset := True;

  if (FLinked <> nil) and (not FLinked.OnSet) then
  begin
    FLinked.OnSet := True;
//    if FData.H > Thickness.Text then FLinked.IncreaseThickness else FLinked.DecreaseThickness;

    FLinked.OnSet := False;
  end;

   case (Sender as TRzSpinEdit).Tag of
     1: FData.H.V := (Sender as TRzSpinEdit).Value;
     2: FData.s.V := (Sender as TRzSpinEdit).Value;
     3: FData.r.V := (Sender as TRzSpinEdit).Value;
   end;

  FOnSet := FOnSetOld;
  if not FOnSet then
     SendRecalcMessage;
end;

end.
