(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2025 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit editor_JSON;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, SynEditHighlighter, SynEditCodeFolding,
  SynHighlighterJSON, SynEditExport, SynExportHTML, RzPanel, SynEdit, Vcl.Menus,
  Vcl.ExtCtrls, RzButton;

type
  TfrmJsonEditor = class(TForm)
    rzstsbr1: TRzStatusBar;
    pmMain: TPopupMenu;
    Editor: TSynEdit;
    MainToolBar: TRzToolbar;
    SynExporterHTML: TSynExporterHTML;
    SynJSONSyn: TSynJSONSyn;
    btnSave: TRzBitBtn;
  private
    { Private declarations }
  public
    { Public declarations }
    function Edit(var InString: string): Boolean;
  end;

  function FormatJson(const InString: String): string;

var
  frmJsonEditor: TfrmJsonEditor;

implementation

{$R *.dfm}
uses
  json, REST.Json;

function FormatJson(const InString: String): string;
var
  tmpJson: TJsonAncestor;
begin
  tmpJson := TJSONObject.ParseJSONValue(InString);
  Result := tmpJson.Format(4);
  FreeAndNil(tmpJson);
end;

{ TfrmJsonEditor }

function TfrmJsonEditor.Edit(var InString: string): Boolean;
begin
  Result := False;
  Editor.Text := FormatJson(InString);
  if ShowModal = mrOk then
  begin
    Result := True;
    InString := Editor.Text;
  end;
end;

end.
