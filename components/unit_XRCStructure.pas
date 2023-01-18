unit unit_XRCStructure;

interface

uses
  SysUtils, Classes, VCL.Controls, VCL.ExtCtrls, RzEdit, RzSpnEdt, VCL.StdCtrls,
  VCL.Forms, unit_XRCLayerControl, unit_XRCStackControl,
  RzPanel, RzButton, RzLabel, RzRadChk, RzCommon, Vcl.Graphics, JvDesignSurface;

type

  TXRCStructure = class (TRzPanel)
    private
      Header: TRzPanel;
      Label1: TRzLabel;
      Label2: TRzLabel;
      Label3: TRzLabel;
      Label4: TRzLabel;
      Box: TJvDesignScrollBox;

      Stacks: array of TXRCStack;



    public
      constructor Create(AOwner: TComponent);
      destructor  Destroy; override;

      procedure AddLayer(const StackID: Integer; const Data: TLayerData);
      procedure AddStack(const N: Integer; const Title: string);
    published

  end;

var
  Structure: TXRCStructure;

implementation

{ TXRCStructure }

procedure TXRCStructure.AddLayer(const StackID: Integer;
  const Data: TLayerData);
begin
  Stacks[StackID].AddLayer(Data);
end;

procedure TXRCStructure.AddStack(const N: Integer; const Title: string);
var
  Count: Integer;
begin
  Count := Length(Stacks);
  SetLength(Stacks, Count + 1);

  Stacks[Count] := TXRCStack.Create(Box, Title, N);

end;

constructor TXRCStructure.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Align := alClient;
  BorderInner := fsNone;
  BorderOuter := fsNone;

  //RzPanel1
  Header := TRzPanel.Create(Self);

  //Label1
  Label1 := TRzLabel.Create(Self);

  //Label2
  Label2 := TRzLabel.Create(Self);

  //Label3
  Label3 := TRzLabel.Create(Self);

  //Label4
  Label4 := TRzLabel.Create(Self);

  //Box
  Box := TJvDesignScrollBox.Create(Self);

  //Header
  Header.Name := 'rzpnlHeader';
  Header.Parent := Self;
  Header.Height := 30;
  Header.AlignWithMargins := True;
  Header.Align := alTop;
  Header.BorderOuter := fsFlatRounded;
  Header.Color := clSkyBlue;
  Header.TabOrder := 0;

  //Label1
  Label1.Name := 'Label1';
  Label1.Parent := Header;
  Label1.Left := 5;
  Label1.Top := 6;
  Label1.Width := 37;
  Label1.Height := 16;
  Label1.Caption := 'Stack / Layer';
  Label1.Font.Color := clWindowText;
  Label1.Font.Height := -13;
  Label1.Font.Name := 'Tahoma';
  Label1.Font.Style := [fsBold];
  Label1.ParentFont := False;

  //Label2
  Label2.Name := 'Label2';
  Label2.Parent := Header;
  Label2.Left := 120;
  Label2.Top := 6;
  Label2.Width := 35;
  Label2.Height := 16;
  Label2.Caption := 'H ('#197')';
  Label2.Font.Color := clWindowText;
  Label2.Font.Height := -13;
  Label2.Font.Name := 'Tahoma';
  Label2.Font.Style := [fsBold];
  Label2.ParentFont := False;

  //Label3
  Label3.Name := 'Label3';
  Label3.Parent := Header;
  Label3.Left := 191;
  Label3.Top := 6;
  Label3.Width := 35;
  Label3.Height := 16;
  Label3.Caption := #963' ('#197')';
  Label3.Font.Color := clWindowText;
  Label3.Font.Height := -13;
  Label3.Font.Name := 'Tahoma';
  Label3.Font.Style := [fsBold];
  Label3.ParentFont := False;

  //Label4
  Label4.Name := 'Label4';
  Label4.Parent := Header;
  Label4.Left := 268;
  Label4.Top := 6;
  Label4.Width := 65;
  Label4.Height := 16;
  Label4.Caption := #961' (g/cm'#179')';
  Label4.Font.Color := clWindowText;
  Label4.Font.Height := -13;
  Label4.Font.Name := 'Tahoma';
  Label4.Font.Style := [fsBold];
  Label4.ParentFont := False;

  //Box
  Box.Name := 'Box';
  Box.Parent := Self;
  Box.AlignWithMargins := True;
  Box.HorzScrollBar.Visible := False;
  Box.VertScrollBar.Style := ssFlat;
  Box.VertScrollBar.Tracking := True;
  Box.Align := alClient;
  Box.BevelInner := bvNone;
  Box.BevelOuter := bvNone;
  Box.BorderStyle := bsNone;
  Box.TabOrder := 1;
end;

destructor TXRCStructure.Destroy;
begin
  inherited Destroy;
end;

end.
