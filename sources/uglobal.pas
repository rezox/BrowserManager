unit uglobal;

{$mode objfpc}{$H+}

interface

uses
  Windows, SysUtils, Forms;

const
  AppCompany = 'TENROK';
  AppName = 'Browser Manager';
  AppMapName = 'Local\{C061573C-A5B2-4415-929F-ABFFF0221186}';

function MyGetCommandline: AnsiString;
function IsAutorun: Boolean;
procedure SetAutorun(Value: Boolean);

{$IFDEF UNICODE}
function PrivateExtractIcons(lpszFileName: LPCTSTR; nIconIndex: Integer; cxIcon: Integer; cyIcon: Integer;
  phicon: PHANDLE; piconid: PUINT; nIcons: UINT; flags: UINT): UINT; stdcall; external 'user32.dll' Name 'PrivateExtractIconsW';
{$ELSE}
function PrivateExtractIcons(lpszFileName: LPCTSTR; nIconIndex: Integer; cxIcon: Integer; cyIcon: Integer;
  phicon: PHANDLE; piconid: PUINT; nIcons: UINT; flags: UINT): UINT; stdcall; external 'user32.dll' Name 'PrivateExtractIconsA';
{$ENDIF}

var
  AppVersion: String;
  AppTitle: String;
  AppDataPath: String;

resourcestring
  rsSettings = 'Settings';
  rsForHost = 'for host';
  rsForPage = 'for page';
  rsBrowserNotFound = 'Browser executable not found!';

implementation

uses
  Registry;

function MyGetCommandline: AnsiString;
begin
  if ParamCount = 1 then
    Result := AnsiString(ParamStr(1))
  else
    Result := '';
end;

const
  RunKey = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Run';

function IsAutorun: Boolean;
var
  Reg: TRegistry;
begin
  Result := False;
  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_CURRENT_USER;
  Reg.Access := KEY_READ;
  if Reg.OpenKey(RunKey, False) then
  begin
    Result := Reg.ValueExists(AppName);
    Reg.CloseKey;
  end;
  Reg.Free;
end;

procedure SetAutorun(Value: Boolean);
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_CURRENT_USER;
  Reg.Access := KEY_WRITE;
  if Value then
  begin
    if Reg.OpenKey(RunKey, True) then
      Reg.WriteString(AppName, Application.ExeName);
  end
  else
  if Reg.OpenKey(RunKey, False) then
    Reg.DeleteValue(AppName);
  Reg.Free;
end;

function GetBuildInfoString(var Major, Minor, Rev, Build: Word): String;
var
  VerInfoSize: DWORD;
  VerInfo: Pointer;
  VerValueSize: DWORD;
  VerValue: PVSFixedFileInfo;
  Dummy: DWORD;
begin
  Major := 0;
  Minor := 0;
  Rev := 0;
  Build := 0;
  Result := '';
  VerInfoSize := GetFileVersionInfoSize(PChar(Application.ExeName), Dummy);
  if VerInfoSize > 0 then
  begin
    GetMem(VerInfo, VerInfoSize);
    try
      if GetFileVersionInfo(PChar(Application.ExeName), 0, VerInfoSize, VerInfo) then
        if VerQueryValue(VerInfo, '\', Pointer(VerValue), VerValueSize) then
        begin
          with VerValue^ do
          begin
            Major := dwFileVersionMS shr 16;
            Minor := dwFileVersionMS and $FFFF;
            Rev := dwFileVersionLS shr 16;
            Build := dwFileVersionLS and $FFFF;
          end;
          //Result := Format('%d.%d Build %d', [Major, Minor, Build]);
          Result := Format('%d.%d.%d Build %d', [Major, Minor, Rev, Build]);
        end;
    finally
      FreeMem(VerInfo, VerInfoSize);
    end;
  end;
end;

var
  Major: Word;
  Minor: Word;
  Rev: Word;
  Build: Word;

initialization

  AppVersion := GetBuildInfoString(Major, Minor, Rev, Build);
  AppTitle := AppName + ' v' + AppVersion;
  AppDataPath := IncludeTrailingBackslash(SysUtils.GetEnvironmentVariable('APPDATA')) + AppCompany + '\' + AppName + '\';
  if not ForceDirectories(AppDataPath) then
  begin
    AppDataPath := ExtractFilePath(Application.ExeName) + 'data\';
    ForceDirectories(AppDataPath);
  end;

end.
