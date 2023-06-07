program XRayCalc3;

uses
  FastMM5,
  Vcl.Forms,
  frm_Main in 'forms\frm_Main.pas' {frmMain},
  unit_Types in 'units\unit_Types.pas',
  math_complex in 'math\math_complex.pas',
  unit_settings in 'units\unit_settings.pas',
  unit_helpers in 'units\unit_helpers.pas',
  unit_consts in 'units\unit_consts.pas',
  unit_XRCStructure in 'components\unit_XRCStructure.pas',
  unit_XRCLayerControl in 'components\unit_XRCLayerControl.pas',
  unit_XRCStackControl in 'components\unit_XRCStackControl.pas',
  unit_SMessages in 'components\unit_SMessages.pas',
  editor_Stack in 'components\editor_Stack.pas' {edtrStack},
  editor_Substrate in 'components\editor_Substrate.pas' {edtrSubstrate},
  unit_calc in 'math\unit_calc.pas',
  unit_materials in 'math\unit_materials.pas',
  math_globals in 'math\math_globals.pas',
  unit_XRCProjectTree in 'components\unit_XRCProjectTree.pas',
  editor_Layer in 'components\editor_Layer.pas' {edtrLayer},
  unit_FitHelpers in 'math\unit_FitHelpers.pas',
  unit_LFPSO_Base in 'math\unit_LFPSO_Base.pas',
  frm_Limits in 'forms\frm_Limits.pas' {frmLimits},
  editor_proj_item in 'editors\editor_proj_item.pas' {edtrProjectItem},
  frm_about in 'forms\frm_about.pas' {frmAbout},
  frm_MaterialsLibrary in 'forms\frm_MaterialsLibrary.pas' {frmMaterialsLibrary},
  unit_LFPSO_Periodic in 'math\unit_LFPSO_Periodic.pas',
  unit_LFPSO_Regular in 'math\unit_LFPSO_Regular.pas',
  frm_MaterialSelector in 'forms\frm_MaterialSelector.pas' {frmMaterialSelector},
  editor_Gradient in 'editors\editor_Gradient.pas' {edtrGradient},
  frm_ExtensionType in 'forms\frm_ExtensionType.pas' {frmExtensionSelector};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TedtrStack, edtrStack);
  Application.CreateForm(TedtrSubstrate, edtrSubstrate);
  Application.CreateForm(TedtrLayer, edtrLayer);
  Application.CreateForm(TfrmLimits, frmLimits);
  Application.CreateForm(TedtrProjectItem, edtrProjectItem);
  Application.CreateForm(TfrmAbout, frmAbout);
  Application.CreateForm(TfrmMaterialsLibrary, frmMaterialsLibrary);
  Application.CreateForm(TfrmMaterialSelector, frmMaterialSelector);
  Application.CreateForm(TedtrGradient, edtrGradient);
  Application.CreateForm(TfrmExtensionSelector, frmExtensionSelector);
  Application.Run;
end.
