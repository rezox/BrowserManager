unit uglobal;

{$mode objfpc}{$H+}

interface

uses
  Windows, SysUtils, Registry;

const
  AppName = 'KORNET Browser Manager';
  AppMapName = 'Local\{D7588826-4DB4-48ED-BE33-0C797D7A45A4}';

function MyGetCommandline: Ansistring;
function GetKClientPath(RootKey: HKEY; Key: String): String;
function GetKClientPath: String;

{$IFDEF UNICODE}
function PrivateExtractIcons(szFileName: LPCTSTR; nIconIndex: Integer; cxIcon: Integer; cyIcon: Integer;
  phicon: PHANDLE; piconid: PUINT; nIcons: UINT; flags: UINT): UINT; stdcall; external 'user32.dll' Name 'PrivateExtractIconsW';
{$ELSE}
function PrivateExtractIcons(szFileName: LPCTSTR; nIconIndex: Integer; cxIcon: Integer; cyIcon: Integer;
  phicon: PHANDLE; piconid: PUINT; nIcons: UINT; flags: UINT): UINT; stdcall; external 'user32.dll' Name 'PrivateExtractIconsA';
{$ENDIF}

implementation

function MyGetCommandline: Ansistring;
begin
  if ParamCount = 1 then
    Result := Ansistring(ParamStr(1))
  else
    Result := '';
end;

// Возвращает путь к kclient.exe
function GetKClientPath(RootKey: HKEY; Key: String): String;
var
  Reg: TRegistry;
  FileName: String;
  InstallLocation, DisplayVersion: String;
begin
  Result := '';
  Reg := TRegistry.Create;
  try
    Reg.RootKey := RootKey;
    if Reg.OpenKeyReadOnly(Key) then
    begin
      InstallLocation := IncludeTrailingBackslash(StringReplace(Reg.ReadString('InstallLocation'), '\\', '\', [rfReplaceAll]));
      FileName := InstallLocation + 'kclient.exe';
      if FileExists(FileName) then
        Result := FileName
      else
      begin
        DisplayVersion := Reg.ReadString('DisplayVersion');
        FileName := InstallLocation + DisplayVersion + '\' + 'kclient.exe';
        if FileExists(FileName) then
          Result := FileName;
      end;
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
end;

function GetKClientPath: String;
begin
  Result := GetKClientPath(HKEY_CURRENT_USER, 'Software\Microsoft\Windows\CurrentVersion\Uninstall\KClient_is1');
  if Result = '' then
    Result := GetKClientPath(HKEY_LOCAL_MACHINE, 'Software\Microsoft\Windows\CurrentVersion\Uninstall\KClient_is1');
  if Result = '' then
    Result := GetKClientPath(HKEY_LOCAL_MACHINE, 'Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\KClient_is1');
end;

end.

