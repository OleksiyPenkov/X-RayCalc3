unit frm_XRFMain;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.Grids,
  Vcl.CheckLst;

type
  TfrmXRFMain = class(TForm)
    pnlSidebar: TPanel;
    sbConfig: TScrollBox;
    pnlButtons: TPanel;
    splMain: TSplitter;
    pnlCharts: TPanel;
    // Targets
    grpTargets: TGroupBox;
    clbTargets: TCheckListBox;
    sgWeights: TStringGrid;
    // Element Pool
    grpElements: TGroupBox;
    clbElements: TCheckListBox;
    // Structure
    grpStructure: TGroupBox;
    lblDMin: TLabel;
    lblDMax: TLabel;
    lblGammaMin: TLabel;
    lblGammaMax: TLabel;
    lblNMin: TLabel;
    lblNMax: TLabel;
    lblSigma: TLabel;
    lblDensityMin: TLabel;
    lblDensityMax: TLabel;
    edDMin: TEdit;
    edDMax: TEdit;
    edGammaMin: TEdit;
    edGammaMax: TEdit;
    edNMin: TEdit;
    edNMax: TEdit;
    edSigma: TEdit;
    edDensityMin: TEdit;
    edDensityMax: TEdit;
    cbPureElements: TCheckBox;
    // Fitness
    grpFitness: TGroupBox;
    lblWR: TLabel;
    lblWFWHM: TLabel;
    lblRMinThreshold: TLabel;
    lblThetaMin: TLabel;
    lblDeltaTheta: TLabel;
    lblPolarization: TLabel;
    edWR: TEdit;
    edWFWHM: TEdit;
    edRMinThreshold: TEdit;
    edThetaMin: TEdit;
    edDeltaTheta: TEdit;
    cmbPolarization: TComboBox;
    // Optimizer
    grpOptimizer: TGroupBox;
    lblPopulation: TLabel;
    lblIterations: TLabel;
    lblTolerance: TLabel;
    lblStagnationLimit: TLabel;
    lblW1: TLabel;
    lblW2: TLabel;
    lblJammingMax: TLabel;
    lblCheckpointEvery: TLabel;
    edPopulation: TEdit;
    edIterations: TEdit;
    edTolerance: TEdit;
    edStagnationLimit: TEdit;
    edW1: TEdit;
    edW2: TEdit;
    edJammingMax: TEdit;
    edCheckpointEvery: TEdit;
    // Substrate
    grpSubstrate: TGroupBox;
    lblSubstrate: TLabel;
    edSubstrate: TEdit;
    // Paths
    grpPaths: TGroupBox;
    lblHenkePath: TLabel;
    lblOutputDir: TLabel;
    edHenkePath: TEdit;
    edOutputDir: TEdit;
    btnBrowseHenke: TButton;
    btnBrowseOutput: TButton;
    // Results (hidden by default)
    grpResults: TGroupBox;
    sgResults: TStringGrid;
    btnSaveStructure: TButton;
    btnSaveCurves: TButton;
    btnExportXRC: TButton;
    // Control buttons
    btnStart: TButton;
    btnStop: TButton;
    btnLoadConfig: TButton;
    btnSaveConfig: TButton;
    lblProgress: TLabel;
    // Dialogs
    dlgOpen: TOpenDialog;
    dlgSave: TSaveDialog;
    dlgSaveStructure: TSaveDialog;
  private
  public
  end;

var
  frmXRFMain: TfrmXRFMain;

implementation

{$R *.dfm}

end.
