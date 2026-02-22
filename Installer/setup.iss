[Setup]
AppName=StarLib Editor
AppVersion=1.0.0
AppPublisher=StarLib
AppPublisherURL=https://github.com/luckiyee/StarLib
DefaultDirName={autopf}\StarLib Editor
DefaultGroupName=StarLib Editor
UninstallDisplayIcon={app}\StarLibEditor.exe
OutputDir=..\Installer
OutputBaseFilename=StarLibEditor_Setup
Compression=lzma2/ultra64
SolidCompression=yes
SetupIconFile=..\Editor\Assets\Icons\starlib.ico
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
WizardStyle=modern
DisableProgramGroupPage=yes
DisableWelcomePage=no
LicenseFile=
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog


[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "..\Build\StarLibEditor.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Build\StarLibEditor.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Build\StarLibEditor.deps.json"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Build\StarLibEditor.runtimeconfig.json"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Build\StarLibEditor.pdb"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Build\CommunityToolkit.Mvvm.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Build\ICSharpCode.AvalonEdit.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Build\MoonSharp.Interpreter.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Build\Newtonsoft.Json.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Build\Assets\*"; DestDir: "{app}\Assets"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\Main\StarLib.lua"; DestDir: "{app}\StarLib"; Flags: ignoreversion

[Icons]
Name: "{group}\StarLib Editor"; Filename: "{app}\StarLibEditor.exe"
Name: "{autodesktop}\StarLib Editor"; Filename: "{app}\StarLibEditor.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional options:"

[Run]
Filename: "{app}\StarLibEditor.exe"; Description: "Launch StarLib Editor"; Flags: nowait postinstall skipifsilent

[Code]
function IsDotNet10Installed(): Boolean;
var
  ResultCode: Integer;
begin
  Result := Exec('dotnet', '--list-runtimes', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) and (ResultCode = 0);
end;

function InitializeSetup(): Boolean;
var
  ResultCode: Integer;
begin
  Result := True;
  if not IsDotNet10Installed() then
  begin
    if MsgBox('StarLib Editor requires .NET 10 Desktop Runtime.' + #13#10 + #13#10 +
              'Would you like to download it now?', mbConfirmation, MB_YESNO) = IDYES then
    begin
      ShellExec('open', 'https://dotnet.microsoft.com/download/dotnet/10.0', '', '', SW_SHOWNORMAL, ewNoWait, ResultCode);
    end;
  end;
end;
