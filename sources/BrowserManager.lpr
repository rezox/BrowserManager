program BrowserManager;

{$mode objfpc}{$H+}

uses {$IFDEF UNIX} {$IFDEF UseCThreads}
  cthreads, {$ENDIF} {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Windows,
  SysUtils,
  Forms,
  uglobal,
  ufrmmain,
  ufrmdialog,
  ufrmsettings;

{$R *.res}

type
  TMapView = record
    Wnd: THandle;
  end;
  PMapView = ^TMapView;

var
  SA: TSecurityAttributes;
  SD: TSecurityDescriptor;
  MapFile: THandle;
  MapView: PMapView = nil;
  Cmd: Ansistring;
  CopyData: TCopyDataStruct;

begin
  InitializeSecurityDescriptor(@SD, SECURITY_DESCRIPTOR_REVISION);
  SetSecurityDescriptorDacl(@SD, True, nil, False);
  SA.nLength := SizeOf(TSecurityAttributes);
  SA.lpSecurityDescriptor := @SD;
  SA.bInheritHandle := False;

  MapFile := CreateFileMapping(INVALID_HANDLE_VALUE, @SA, PAGE_READWRITE, 0, SizeOf(TMapView), uglobal.AppMapName);
  if GetLastError = ERROR_ALREADY_EXISTS then
  begin
    if MapFile <> 0 then
    begin
      MapView := MapViewOfFile(MapFile, FILE_MAP_READ, 0, 0, 0);
      if MapView <> nil then
      begin
        if ParamCount > 0 then
        begin
          Cmd := MyGetCommandLine;
          CopyData.dwData := ParamCount;
          CopyData.cbData := Length(Cmd);
          CopyData.lpData := PAnsiChar(Cmd);
          SendMessage(MapView^.Wnd, WM_COPYDATA, 0, LPARAM(@CopyData));
        end;
        UnMapViewOfFile(MapView);
      end;
    end;
    CloseHandle(MapFile);
    Exit;
  end;

  RequireDerivedFormResource := True;
  Application.Title := 'TENROK Browser Manager';
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TFrmMain, FrmMain);
  Application.ShowMainForm := False;

  if MapFile <> 0 then
  begin
    MapView := MapViewOfFile(MapFile, FILE_MAP_WRITE, 0, 0, 0);
    if MapView <> nil then
      MapView^.Wnd := FrmMain.Handle;
  end;

  Application.Run;
end.
