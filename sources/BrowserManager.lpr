program BrowserManager;

{$mode objfpc}{$H+}

uses {$IFDEF UNIX} {$IFDEF UseCThreads}
  cthreads, {$ENDIF} {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Windows,
  SysUtils,
  Forms,
  ufrmmain,
  uglobal,
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
  // Создаем дескриптор безопасности
  InitializeSecurityDescriptor(@SD, SECURITY_DESCRIPTOR_REVISION);
  // DACL не установлен - объект незащищен
  SetSecurityDescriptorDacl(@SD, True, nil, False);
  // Настраиваем атрибуты безопасности, передавая туда указатель на дескриптор безопасности SD и создаем объект
  SA.nLength := SizeOf(TSecurityAttributes);
  SA.lpSecurityDescriptor := @SD;
  SA.bInheritHandle := False;

  // Если FileMapping есть, то происходит OpenFileMapping.
  MapFile := CreateFileMapping(INVALID_HANDLE_VALUE, @SA, PAGE_READWRITE, 0, SizeOf(TMapView), uglobal.AppMapName);

  // Если найдена запущенная копия программы, то посылаем параметры командной строки.
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

  // Сохраняем дескриптор главной формы.
  if MapFile <> 0 then
  begin
    MapView := MapViewOfFile(MapFile, FILE_MAP_WRITE, 0, 0, 0);
    if MapView <> nil then
      MapView^.Wnd := FrmMain.Handle;
  end;

  Application.Run;
end.
