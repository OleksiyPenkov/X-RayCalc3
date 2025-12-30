unit XRCPreviewHandler;

interface

uses
  PreviewHandler, Classes, VCL.Controls, VCL.StdCtrls, frame_Chart;

const
  {$REGION 'Unique ClassID of your PreviewHandler'}
  ///	<summary>Unique ClassID of your PreviewHandler</summary>
  ///	<remarks>Don't forget to create a new one. Best use Ctrl-G.</remarks>
  {$ENDREGION}
  CLASS_MyPreviewHandler: TGUID = '{35AA91DC-A25A-4003-81F2-42C7B87CF8B2}';

type
  {$REGION 'Sample PreviewHandler'}
  ///	<summary>Sample PreviewHandler</summary>
  ///	<remarks>A sample PreviewHandler. You only have to derive from
  ///	TFilePreviewHandler or TStreamPreviewHandler and override some methods.</remarks>
  {$ENDREGION}
  TMyPreviewHandler = class(TFilePreviewHandler)
  private
    FChart: TfrmChart;
  protected
  public
    constructor Create(AParent: TWinControl); override;
    procedure Unload; override;
    procedure DoPreview(const FilePath: string); override;
  end;

implementation

uses
  SysUtils;

constructor TMyPreviewHandler.Create(AParent: TWinControl);
begin
  inherited;
  FChart := TfrmChart.Create(AParent);
  FChart.Parent := AParent;
  FChart.Align := alClient;
end;

procedure TMyPreviewHandler.DoPreview(const FilePath: string);
begin
  FChart.LoadCurves(FilePath);
end;

procedure TMyPreviewHandler.Unload;
begin
  FChart.Clear;
  inherited;
end;

initialization
  { Register your PreviewHandler with the ClassID, name, descripton and file extension }
  TMyPreviewHandler.Register(CLASS_MyPreviewHandler, 'xrcxfile', 'X-Ray Calc Project Preview Handler', '.xrcx');
end.



