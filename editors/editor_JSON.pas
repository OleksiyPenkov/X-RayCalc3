unit editor_JSON;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, SynEditHighlighter, SynEditCodeFolding,
  SynHighlighterJSON, SynEditExport, SynExportHTML, RzPanel, SynEdit, Vcl.Menus, XSuperObject,
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

function FormatJson (InString: WideString): string;

var
  frmJsonEditor: TfrmJsonEditor;

implementation

{$R *.dfm}

function FormatJson(InString: WideString): string; // Input string is "InString"
var
  Json : ISuperObject;
begin
  Json := TSuperObject.Create(InString);
  Result := Json.AsJson(true, false); //Here comes your result: pretty-print JSON
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
