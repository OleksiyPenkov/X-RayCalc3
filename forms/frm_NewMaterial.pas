(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2023 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit frm_NewMaterial;

interface

uses
  Windows,
  Messages,
  SysUtils,
  Variants,
  Classes,
  Graphics,
  Controls,
  Forms,
  Dialogs,
  StdCtrls,
  Spin,
  Grids,
  ExtCtrls,
  RzPanel,
  Menus, Vcl.Buttons;

type
  TfrmNewMaterial = class(TForm)
    RzGroupBox1: TRzGroupBox;
    StringGrid1: TStringGrid;
    bntSave: TButton;
    SpinEdit1: TSpinEdit;
    Label3: TLabel;
    Edit1: TEdit;
    Edit2: TEdit;
    Label2: TLabel;
    Label1: TLabel;
    PopupMenu1: TPopupMenu;
    Inserttothetable1: TMenuItem;
    N1: TMenuItem;
    Deletefile1: TMenuItem;
    btnClear: TButton;
    btnClose: TButton;
    procedure lbFilesDblClick(Sender: TObject);
    procedure SpinEdit1Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure bntSaveClick(Sender: TObject);
    procedure lbFilesKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
//    procedure Deletefile1Click(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
  private
    { Private declarations }
    function NewElement: boolean;
  public
    { Public declarations }
  end;

var
  frmNewMaterial: TfrmNewMaterial;

implementation

uses
  unit_helpers,
  unit_settings,
  math_complex,
  math_globals,
  System.UITypes;

{$R *.dfm}


procedure TfrmNewMaterial.bntSaveClick(Sender: TObject);
begin
  if NewElement then
    ShowMessage('Material ' + Edit1.Text + ' was created succefully.');
end;

procedure TfrmNewMaterial.btnClearClick(Sender: TObject);
begin
  Edit1.Text := '';
  Edit2.Text := '';
  SpinEdit1.Value := 1;
  stringGrid1.Cells[0,1] := '';
  stringGrid1.Cells[1,1] := '';
end;


//procedure TfrmNewMaterial.Deletefile1Click(Sender: TObject);
//var
//  Name: string;
//begin
//  Name := lbFiles.Items[lbFiles.ItemIndex];
//  if MessageDlg('File will be deleted! Do you want to continue?', mtWarning, [mbYes, mbNo], 0) = mrYes then
//  begin
//    lbFiles.Items.Delete(lbFiles.ItemIndex);
//    DeleteFile(Settings.HenkePath + Name + '.bin');
//  end;
//end;

procedure TfrmNewMaterial.FormCreate(Sender: TObject);
begin
  StringGrid1.Cells[0, 0] := 'Element';
  StringGrid1.Cells[1, 0] := 'Conc. at%';
end;

procedure TfrmNewMaterial.lbFilesDblClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TfrmNewMaterial.lbFilesKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = vk_Return  then lbFilesDblClick(Sender);
end;

function TfrmNewMaterial.NewElement: boolean;
var
  i, N: integer;
  s: string;
  e1: single;
  f1, f2: TComplex;
  Size: integer;
  Na, Nro, sNa: single;
  StreamIn, StreamOut : TMemoryStream;
  StrBuffer: PChar;

  function GetString(Stream: TMemoryStream): string;
  begin
    Stream.Read(size, SizeOf(size));
    StrBuffer := AllocMem(size);
    Stream.Read(StrBuffer^, size);
    Result := (StrBuffer);
    FreeMem(StrBuffer);
  end;

  procedure WriteString(const s: string);
  begin
    size := ByteLength(s) + 1;
    StreamOut.Write(size, SizeOf(size));
    StreamOut.Write(PChar(s)^, size);
  end;

begin
  Result := False;
  N := SpinEdit1.Value;

  sNa := 0;
  for I := 1 to N do
  begin
    ReadHenke(stringGrid1.Cells[0,i], 100, 0, f1, Na, Nro);
    sNa := sNa + Na * StrToFloat(stringGrid1.Cells[1,i])/100;
  end;

  try
    StreamIn := TMemoryStream.Create;
    StreamOut := TMemoryStream.Create;

    StreamIn.LoadFromFile(Settings.HenkePath + StringGrid1.Cells[0,1] + '.bin');

    s := GetString(StreamIn);
    WriteString(Edit1.Text);

    Size := SizeOf(Na);

    StreamIn.Read(Na, Size);
    StreamIn.Read(Nro, Size);

    Nro := StrToFloat(Edit2.Text);
    StreamOut.Write(sNa, Size);
    StreamOut.Write(Nro, Size);

    while StreamIn.Position < StreamIn.Size do
    begin
      StreamIn.Read(e1, Size);
      StreamIn.Read(f1.re, Size);
      StreamIn.Read(f1.im, Size);

      f1.Re := f1.Re*StrToFloat(stringGrid1.Cells[1,1])/100;
      f1.Im := f1.Im*StrToFloat(stringGrid1.Cells[1,1])/100;

      for I := 2 to N do
      begin
        ReadHenke(stringGrid1.Cells[0,i], e1, 0, f2, Na, Nro);
        f1.Re := f1.Re + f2.Re*StrToFloat(stringGrid1.Cells[1,i])/100;
        f1.Im := f1.Im + f2.Im*StrToFloat(stringGrid1.Cells[1,i])/100;
      end;

      StreamOut.Write(e1, Size);
      StreamOut.Write(f1.Re, Size);
      StreamOut.Write(f1.Im, Size);
    end;
    StreamOut.SaveToFile(Settings.HenkePath + Edit1.Text + '.bin');
    Result := True;
  finally
    StreamIn.Free;
    StreamOut.Free;
  end;
end;

procedure TfrmNewMaterial.SpinEdit1Change(Sender: TObject);
begin
  StringGrid1.RowCount := SpinEdit1.Value + 1;
end;

end.
