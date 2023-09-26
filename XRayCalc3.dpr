program XRayCalc3;

uses
  FastMM5,
  Vcl.Forms,
  frm_Main in 'forms\frm_Main.pas' {frmMain},
  unit_Types in 'units\unit_Types.pas',
  math_complex in 'math\math_complex.pas',
  unit_helpers in 'units\unit_helpers.pas',
  unit_consts in 'units\unit_consts.pas',
  unit_XRCStructure in 'components\unit_XRCStructure.pas',
  unit_XRCLayerControl in 'components\unit_XRCLayerControl.pas',
  unit_XRCStackControl in 'components\unit_XRCStackControl.pas',
  unit_SMessages in 'components\unit_SMessages.pas',
  editor_Stack in 'components\editor_Stack.pas' {edtrStack},
  unit_calc in 'math\unit_calc.pas',
  unit_materials in 'math\unit_materials.pas',
  math_globals in 'math\math_globals.pas',
  unit_XRCProjectTree in 'components\unit_XRCProjectTree.pas',
  editor_Layer in 'components\editor_Layer.pas' {edtrLayer},
  unit_LFPSO_Base in 'LFPSO\unit_LFPSO_Base.pas',
  frm_Limits in 'forms\frm_Limits.pas' {frmLimits},
  editor_proj_item in 'editors\editor_proj_item.pas' {edtrProjectItem},
  frm_about in 'forms\frm_about.pas' {frmAbout},
  frm_NewMaterial in 'forms\frm_NewMaterial.pas' {frmNewMaterial},
  unit_LFPSO_Periodic in 'LFPSO\unit_LFPSO_Periodic.pas',
  frm_MaterialSelector in 'forms\frm_MaterialSelector.pas' {frmMaterialSelector},
  editor_ProfileFunction in 'editors\editor_ProfileFunction.pas' {edtrProfileFunction},
  frm_ExtensionType in 'forms\frm_ExtensionType.pas' {frmExtensionSelector},
  Vcl.Themes,
  Vcl.Styles,
  editor_HenkeTable in 'editors\editor_HenkeTable.pas' {edtrHenkeTable},
  editor_JSON in 'editors\editor_JSON.pas' {frmJsonEditor},
  unit_LFPSO_Poly in 'LFPSO\unit_LFPSO_Poly.pas',
  unit_SavitzkyGolay in 'math\unit_SavitzkyGolay.pas',
  frm_Benchmark in 'forms\frm_Benchmark.pas' {frmBenchmark},
  unit_files_list in 'components\unit_files_list.pas',
  unit_Config in 'units\unit_Config.pas',
  frm_settings in 'forms\frm_settings.pas' {frmSettings},
  editor_ProfileTable in 'editors\editor_ProfileTable.pas' {edtrProfileTable},
  unit_XRCGrid in 'components\unit_XRCGrid.pas',
  unit_sys_helpers in 'units\unit_sys_helpers.pas',
  unit_LFPSO_Irregular in 'LFPSO\unit_LFPSO_Irregular.pas',
  frm_FitSettings in 'forms\frm_FitSettings.pas' {frmFitSettings};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
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
  Application.CreateForm(TfrmSettings, frmSettings);
  Application.CreateForm(TedtrProfileTable, edtrProfileTable);
  Application.CreateForm(TfrmFitSettings, frmFitSettings);
  Application.Run;
end.
