unit frame_InfoView;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms,
  RzEdit,
  unit_xrfx_package;

type
  TframeInfoView = class(TFrame)
    mmoInfo: TRzMemo;
  public
    procedure LoadManifestInfo(const M: TXRFXManifest);
    procedure Clear;
  end;

implementation

{$R *.dfm}

procedure TframeInfoView.LoadManifestInfo(const M: TXRFXManifest);
var
  i: Integer;
begin
  mmoInfo.Lines.Clear;
  mmoInfo.Lines.Add('Figure of Merit: ' + Format('%.6f', [M.FoM]));
  mmoInfo.Lines.Add('Created: ' + M.Created);
  mmoInfo.Lines.Add('Generator: ' + M.Generator);
  mmoInfo.Lines.Add('Substrate: ' + M.Substrate);
  mmoInfo.Lines.Add('');
  mmoInfo.Lines.Add('--- Structure ---');
  mmoInfo.Lines.Add('Type: ' + M.Structure.StructureType);
  mmoInfo.Lines.Add(Format('d = %.2f A', [M.Structure.D]));
  mmoInfo.Lines.Add(Format('gamma = %.3f', [M.Structure.Gamma]));
  mmoInfo.Lines.Add(Format('N = %d', [M.Structure.N]));
  mmoInfo.Lines.Add(Format('sigma = %.2f A', [M.Structure.Sigma]));
  mmoInfo.Lines.Add('');
  mmoInfo.Lines.Add('--- Target Lines ---');
  for i := 0 to High(M.TargetLines) do
    mmoInfo.Lines.Add('  ' + M.TargetLines[i]);
  mmoInfo.Lines.Add('');
  mmoInfo.Lines.Add('--- Element Pool ---');
  for i := 0 to High(M.ElementPool) do
    mmoInfo.Lines.Add('  ' + M.ElementPool[i]);
  mmoInfo.Lines.Add('');
  mmoInfo.Lines.Add('--- Optimizer ---');
  mmoInfo.Lines.Add(Format('Population: %d', [M.Optimizer.Population]));
  mmoInfo.Lines.Add(Format('Iterations: %d', [M.Optimizer.Iterations]));
  mmoInfo.Lines.Add(Format('Stagnation limit: %d', [M.Optimizer.StagnationLimit]));
  mmoInfo.Lines.Add('');
  mmoInfo.Lines.Add('--- Per-Element Results ---');
  for i := 0 to High(M.PerElement) do
    mmoInfo.Lines.Add(Format('  %s: peak R = %.4f, FWHM = %.3f',
      [M.PerElement[i].Line, M.PerElement[i].PeakR, M.PerElement[i].FWHM]));
end;

procedure TframeInfoView.Clear;
begin
  mmoInfo.Lines.Clear;
end;

end.
