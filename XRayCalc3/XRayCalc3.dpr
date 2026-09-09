program XRayCalc3;

uses
  FastMM5,
  Vcl.Forms,
  unit_CrashReport in 'Units\unit_CrashReport.pas',
  frm_CrashReport in 'Forms\frm_CrashReport.pas' {frmCrashReport},
  frm_Main in 'Forms\frm_Main.pas' {frmMain},
  frame_CalcSettings in 'Views\frame_CalcSettings.pas' {frmCalcSettings: TFrame},
  frame_ChartInfo in 'Views\frame_ChartInfo.pas' {frmChartInfo: TFrame},
  frame_ChartPages in 'Views\frame_ChartPages.pas' {frmChartPages: TFrame},
  frame_StructurePanel in 'Views\frame_StructurePanel.pas' {frmStructurePanel: TFrame},
  frame_ProjectPanel in 'Views\frame_ProjectPanel.pas' {frmProjectPanel: TFrame},
  unit_Types in 'Units\unit_Types.pas',
  math_complex in '..\Shared\Math\math_complex.pas',
  unit_SeriesIO in 'Units\unit_SeriesIO.pas',
  unit_DataProcessing in 'Units\unit_DataProcessing.pas',
  unit_FileUtils in 'Units\unit_FileUtils.pas',
  unit_helpers in 'Units\unit_helpers.pas',
  unit_consts in 'Units\unit_consts.pas',
  unit_XRCStructure in 'Components\unit_XRCStructure.pas',
  unit_XRCLayerControl in 'Components\unit_XRCLayerControl.pas',
  unit_XRCStackControl in 'Components\unit_XRCStackControl.pas',
  unit_SMessages in 'Components\unit_SMessages.pas',
  editor_Stack in 'Components\editor_Stack.pas' {edtrStack},
  unit_calc in '..\Shared\Math\unit_calc.pas',
  unit_materials in '..\Shared\Math\unit_materials.pas',
  math_globals in '..\Shared\Math\math_globals.pas',
  unit_XRCProjectTree in 'Components\unit_XRCProjectTree.pas',
  editor_Layer in 'Components\editor_Layer.pas' {edtrLayer},
  unit_LFPSO_Base in 'LFPSO\unit_LFPSO_Base.pas',
  frm_Limits in 'Forms\frm_Limits.pas' {frmLimits},
  editor_proj_item in 'Editors\editor_proj_item.pas' {edtrProjectItem},
  frm_about in 'Forms\frm_about.pas' {frmAbout},
  frm_NewMaterial in 'Forms\frm_NewMaterial.pas' {frmNewMaterial},
  unit_LFPSO_Periodic in 'LFPSO\unit_LFPSO_Periodic.pas',
  frm_MaterialSelector in 'Forms\frm_MaterialSelector.pas' {frmMaterialSelector},
  editor_ProfileFunction in 'Editors\editor_ProfileFunction.pas' {edtrProfileFunction},
  frm_ExtensionType in 'Forms\frm_ExtensionType.pas' {frmExtensionSelector},
  Vcl.Themes,
  Vcl.Styles,
  editor_HenkeTable in 'Editors\editor_HenkeTable.pas' {edtrHenkeTable},
  editor_JSON in 'Editors\editor_JSON.pas' {frmJsonEditor},
  unit_LFPSO_Poly in 'LFPSO\unit_LFPSO_Poly.pas',
  unit_SavitzkyGolay in '..\Shared\Math\unit_SavitzkyGolay.pas',
  unit_ProfileCalc in '..\Shared\Math\unit_ProfileCalc.pas',
  frm_Benchmark in 'Forms\frm_Benchmark.pas' {frmBenchmark},
  unit_files_list in 'Components\unit_files_list.pas',
  unit_Config in 'Units\unit_Config.pas',
  frm_settings in 'Forms\frm_settings.pas' {frmSettings},
  editor_ProfileTable in 'Editors\editor_ProfileTable.pas' {edtrProfileTable},
  unit_XRCGrid in 'Components\unit_XRCGrid.pas',
  unit_sys_helpers in 'Units\unit_sys_helpers.pas',
  unit_LFPSO_Irregular in 'LFPSO\unit_LFPSO_Irregular.pas',
  frm_FitSettings in 'Forms\frm_FitSettings.pas' {frmFitSettings},
  unit_AutoCompleteEdit in 'Components\unit_AutoCompleteEdit.pas',
  MHLButtonedEdit in 'Components\MHLButtonedEdit.pas',
  unit_StaticTip in 'Components\unit_StaticTip.pas',
  unit_ProfilesManager in 'Units\unit_ProfilesManager.pas',
  unit_RecentProjects in 'Units\unit_RecentProjects.pas',
  unit_ChartManager in 'Units\unit_ChartManager.pas',
  unit_CalcOrchestrator in 'Units\unit_CalcOrchestrator.pas',
  unit_StaleExtDialog in 'Units\unit_StaleExtDialog.pas',
  unit_BatchRunner in 'Units\unit_BatchRunner.pas',
  unit_XRCPanel in 'Components\unit_XRCPanel.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.OnException := TExceptionHelper.HandleException;
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TedtrStack, edtrStack);
  Application.CreateForm(TedtrLayer, edtrLayer);
  Application.CreateForm(TfrmLimits, frmLimits);
  Application.CreateForm(TedtrProjectItem, edtrProjectItem);
  Application.CreateForm(TfrmAbout, frmAbout);
  Application.CreateForm(TfrmNewMaterial, frmNewMaterial);
  Application.CreateForm(TfrmMaterialSelector, frmMaterialSelector);
  Application.CreateForm(TedtrProfileFunction, edtrProfileFunction);
  Application.CreateForm(TfrmExtensionSelector, frmExtensionSelector);
  Application.CreateForm(TedtrHenkeTable, edtrHenkeTable);
  Application.CreateForm(TfrmJsonEditor, frmJsonEditor);
  Application.CreateForm(TfrmBenchmark, frmBenchmark);
  Application.CreateForm(TfrmSettings, frmSettings);
  Application.CreateForm(TedtrProfileTable, edtrProfileTable);
  Application.CreateForm(TfrmFitSettings, frmFitSettings);
  Application.Run;
end.
