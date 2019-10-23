#define AppCopyright       'Copyright (C) ' + GetDateTimeString('yyyy', '', '') + ' TENROK'
#define AppName            'BrowserManager'
#define AppExeName         'BrowserManager.exe'
#define AppExePath         '..\build\win32\' + AppExeName
#define AppVersion         GetFileVersion(AppExePath)
#define AppVerName         AppName
#define OutputBaseFilename StringChange(AppName, ' ', '') + '-' + AppVersion + '-x86'

[Setup]
AppCopyright={#AppCopyright}
AppId={#AppVerName}
AppName={#AppName}
AppPublisher=TENROK
AppPublisherURL=http://tenrok.ru
AppVerName={#AppVerName}
AppVersion={#AppVersion}
DefaultDirName={pf}\TENROK\{#AppName}
DefaultGroupName=TENROK\{#AppName}
OutputBaseFilename={#OutputBaseFilename}
OutputDir=.
PrivilegesRequired=admin
SetupIconFile=setup-icon.ico
Uninstallable=yes
UninstallDisplayIcon={app}\{#AppExeName}
UninstallFilesDir={app}\uninst
VersionInfoCopyright=TENROK LLC
VersionInfoVersion={#AppVersion}
WizardImageFile=compiler:WizModernImage-IS.bmp
WizardSmallImageFile=compiler:WizModernSmallImage-IS.bmp

[Files]
Source: "..\build\win64\{#AppExeName}"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#AppVerName}"; Filename: "{app}\{#AppExeName}"; WorkingDir: "{app}"
;Name: "{commondesktop}\{#AppVerName}"; Filename: "{app}\{#AppExeName}"; WorkingDir: "{app}"

[Languages]
Name: "en"; MessagesFile: "compiler:Default.isl"
Name: "ru"; MessagesFile: "compiler:Languages\Russian.isl"

[Registry]
Root: HKCR; Subkey: "BrowserManagerHTML"; ValueType: string; ValueName: ""; ValueData: "BrowserManager HTML Document"; Flags: uninsdeletekey
Root: HKCR; Subkey: "BrowserManagerHTML\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\{#AppExeName},0"                 
Root: HKCR; Subkey: "BrowserManagerHTML\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#AppExeName}"" ""%1"""
Root: HKCR; Subkey: "BrowserManagerURL"; ValueType: string; ValueName: ""; ValueData: "BrowserManager HTML Document"; Flags: uninsdeletekey
Root: HKCR; Subkey: "BrowserManagerURL\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\{#AppExeName},0"                 
Root: HKCR; Subkey: "BrowserManagerURL\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#AppExeName}"" ""%1"""
Root: HKLM; Subkey: "Software\TENROK\{#AppName}\Capabilities"; ValueType: string; ValueName: "ApplicationDescription"; ValueData: "BrowserManager as default browser"
Root: HKLM; Subkey: "Software\TENROK\{#AppName}\Capabilities"; ValueType: string; ValueName: "ApplicationIcon"; ValueData: "{app}\{#AppExeName},0"
Root: HKLM; Subkey: "Software\TENROK\{#AppName}\Capabilities"; ValueType: string; ValueName: "ApplicationName"; ValueData: "{#AppName}"
Root: HKLM; Subkey: "Software\TENROK\{#AppName}\Capabilities\FileAssociations"; ValueType: string; ValueName: ".htm"; ValueData: "BrowserManagerHTML"
Root: HKLM; Subkey: "Software\TENROK\{#AppName}\Capabilities\FileAssociations"; ValueType: string; ValueName: ".html"; ValueData: "BrowserManagerHTML"
Root: HKLM; Subkey: "Software\TENROK\{#AppName}\Capabilities\URLAssociations"; ValueType: string; ValueName: "http"; ValueData: "BrowserManagerURL"
Root: HKLM; Subkey: "Software\TENROK\{#AppName}\Capabilities\URLAssociations"; ValueType: string; ValueName: "https"; ValueData: "BrowserManagerURL"
Root: HKLM; Subkey: "Software\TENROK\{#AppName}\Capabilities\URLAssociations"; ValueType: string; ValueName: "ftp"; ValueData: "BrowserManagerURL"
Root: HKLM; Subkey: "Software\TENROK\{#AppName}\Capabilities\Startmenu"; ValueType: string; ValueName: "StartMenuInternet"; ValueData: "{app}\{#AppExeName}"
Root: HKLM; Subkey: "Software\RegisteredApplications"; ValueType: string; ValueName: "{#AppName}"; ValueData: "Software\TENROK\{#AppName}\Capabilities"

[Code]
function GetUninstallString(): String;
var
	sUnInstPath: String;
	sUnInstallString: String;
begin
	sUnInstPath := ExpandConstant('SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{#emit SetupSetting("AppId")}_is1');
	sUnInstallString := '';
	if not RegQueryStringValue(HKLM, sUnInstPath, 'UninstallString', sUnInstallString) then
		RegQueryStringValue(HKCU, sUnInstPath, 'UninstallString', sUnInstallString);
	if IsWin64 then
	begin
		sUnInstPath := ExpandConstant('SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\{#emit SetupSetting("AppId")}_is1');
		RegQueryStringValue(HKLM, sUnInstPath, 'UninstallString', sUnInstallString);
	end;
	Result := sUnInstallString;
end;

function IsUpgrade(): Boolean;
begin
	Result := (GetUninstallString() <> '');
end;

function UnInstallOldVersion(): Integer;
var
	sUnInstallString: String;
	iResultCode: Integer;
begin
	// Return Values:
	// 1 - uninstall string is empty
	// 2 - error executing the UnInstallString
	// 3 - successfully executed the UnInstallString

	// default return value
	Result := 0;

	// get the uninstall string of the old app
	sUnInstallString := GetUninstallString();
	if sUnInstallString <> '' then
	begin
		sUnInstallString := RemoveQuotes(sUnInstallString);
		if Exec(sUnInstallString, '/SILENT /NORESTART /SUPPRESSMSGBOXES', '', SW_HIDE, ewWaitUntilTerminated, iResultCode) then
			Result := 3
		else
			Result := 2;
	end
	else
		Result := 1;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
	case CurStep of
		ssInstall:
			begin
				if (IsUpgrade()) then
					UnInstallOldVersion();
			end;
	end;
end;