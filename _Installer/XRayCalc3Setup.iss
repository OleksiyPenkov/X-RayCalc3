; X-Ray Calc 3 — InnoSetup Installer Script
; Run deploy.sh first to stage files into deploy/

#define MyAppName "X-Ray Calc 3"
#define MyAppVersion "3.7.0"
#define MyAppPublisher "Oleksiy Penkov"
#define MyAppExeName32 "XRayCalc3.exe"
#define MyAppExeName64 "XRayCalc3.x64.exe"
#define MyAppAssocExt ".xrcx"
#define MyAppAssocName "X-Ray Calc Project"
#define PreviewHandlerCLSID "{{B4B97522-5D4C-4B68-A498-E4C800F1B523}"

[Setup]
AppId={{A7D3E2F1-8B4C-4E5A-9F6D-1C2B3A4E5F60}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir=SetupOutput
OutputBaseFilename=XRayCalc3_Setup_{#MyAppVersion}
SetupIconFile=deploy\XRayCalc3_Icon.ico
UninstallDisplayIcon={app}\XRayCalc3_Icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin
ChangesAssociations=yes
LicenseFile=LICENSE
MinVersion=10.0

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
; --- Both executables (x32 is faster, x64 handles large models) ---
Source: "deploy\Win64\XRayCalc3.x64.exe";          DestDir: "{app}"; Flags: ignoreversion
Source: "deploy\Win32\XRayCalc3.exe";               DestDir: "{app}"; Flags: ignoreversion
Source: "deploy\Win64\XRCPreviewHandlerLib.dll";    DestDir: "{app}"; Flags: ignoreversion regserver 64bit

; --- Shared data files ---
Source: "deploy\Henke\*";                            DestDir: "{app}\Henke";            Flags: ignoreversion
Source: "deploy\Examples\*";                         DestDir: "{app}\Examples";          Flags: ignoreversion
Source: "deploy\Help\UserManual.html";               DestDir: "{app}\Help";              Flags: ignoreversion
Source: "deploy\Help\style.css";                     DestDir: "{app}\Help";              Flags: ignoreversion
Source: "deploy\Help\script.js";                     DestDir: "{app}\Help";              Flags: ignoreversion
Source: "deploy\Help\*.html";                        DestDir: "{app}\Help";              Flags: ignoreversion
Source: "deploy\Help\images\*";                      DestDir: "{app}\Help\images";       Flags: ignoreversion
Source: "deploy\XRayCalc3_Icon.ico";                 DestDir: "{app}";                   Flags: ignoreversion
Source: "deploy\XRayCalc3_x64_Icon.ico";             DestDir: "{app}";                   Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName} x64";        Filename: "{app}\XRayCalc3.x64.exe"; IconFilename: "{app}\XRayCalc3_x64_Icon.ico"
Name: "{group}\{#MyAppName} x32 (Fast)"; Filename: "{app}\XRayCalc3.exe"; IconFilename: "{app}\XRayCalc3_Icon.ico"
Name: "{group}\User Manual";             Filename: "{app}\Help\UserManual.html"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{commondesktop}\{#MyAppName} x64";        Filename: "{app}\XRayCalc3.x64.exe"; IconFilename: "{app}\XRayCalc3_x64_Icon.ico"; Tasks: desktopicon
Name: "{commondesktop}\{#MyAppName} x32 (Fast)"; Filename: "{app}\XRayCalc3.exe"; IconFilename: "{app}\XRayCalc3_Icon.ico"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Registry]
; --- .xrcx file association ---
Root: HKLM; Subkey: "Software\Classes\{#MyAppAssocExt}";                          ValueType: string; ValueData: "XRayCalc3.Project";    Flags: uninsdeletevalue
Root: HKLM; Subkey: "Software\Classes\XRayCalc3.Project";                         ValueType: string; ValueData: "{#MyAppAssocName}";     Flags: uninsdeletekey
Root: HKLM; Subkey: "Software\Classes\XRayCalc3.Project\DefaultIcon";             ValueType: string; ValueData: "{app}\XRayCalc3_Icon.ico,0"
Root: HKLM; Subkey: "Software\Classes\XRayCalc3.Project\shell\open\command";      ValueType: string; ValueData: """{app}\XRayCalc3.x64.exe"" ""%1"""

[Run]
Filename: "{app}\XRayCalc3.x64.exe"; Description: "Launch {#MyAppName} x64"; Flags: nowait postinstall skipifsilent unchecked
Filename: "{app}\XRayCalc3.exe"; Description: "Launch {#MyAppName} x32 (Fast)"; Flags: nowait postinstall skipifsilent unchecked

[Code]
// Notify Windows of file association change
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    // Notify shell of association change
    RegWriteStringValue(HKEY_LOCAL_MACHINE,
      'Software\Classes\{#MyAppAssocExt}', '', 'XRayCalc3.Project');
  end;
end;
