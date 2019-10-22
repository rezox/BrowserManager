unit ufrmmain;

{$mode objfpc}{$H+}

interface

uses
  Windows, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls, StdCtrls, Menus, ActnList, StrUtils;

type
  { TFrmMain }
  TFrmMain = class(TForm)
    ActQuit: TAction;
    ActionList1: TActionList;
    MenuItem1: TMenuItem;
    PopupMenu1: TPopupMenu;
    TrayIcon1: TTrayIcon;
    procedure ActQuitExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    procedure GetBrowsers;
    procedure ProcessCommandline(S: Ansistring);
  end;

type
  // Элемент списка Browsers
  TBrowser = class
    Name: String;
    ExePath: String;
    Icon: TIcon;
  public
    constructor Create(AName: String; AExePath: String; ADefaultIcon: String = '');
    destructor Destroy; override;
  end;

var
  FrmMain: TFrmMain;
  Browsers: TThreadList;

implementation

{$R *.lfm}

uses
  Registry, uglobal, ufrmdialog, synacode;

{ TFrmMain }

var
  PrevWndProc: Windows.WNDPROC;

function WndCallback(Wnd: HWND; Msg: UINT; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
var
  S: String;
  Len: Integer;
  CDS: TCopyDataStruct;
begin
  Result := 0;
  case Msg of
    WM_COPYDATA:
    begin
      CDS := PCopyDataStruct(LParam)^;
      Len := CDS.cbData div SizeOf(Char);
      SetLength(S, Len);
      Move(PChar(CDS.lpData)^, PChar(S)^, Len * SizeOf(Char));
      FrmMain.ProcessCommandline(S);
      Result := 1;
      Exit;
    end;
  end;
  Result := Windows.CallWindowProc(PrevWndProc, Wnd, Msg, WParam, LParam);
end;

procedure TFrmMain.FormCreate(Sender: TObject);
begin
  Caption := uglobal.AppName;

  Browsers := TThreadList.Create;

  GetBrowsers;

  // WM_COPYDATA
  PrevWndProc := Windows.WNDPROC(SetWindowLongPtr(Self.Handle, GWL_WNDPROC, PtrInt(@WndCallback)));

  // Обрабатываем параметры текущей командной строки.
  ProcessCommandline(MyGetCommandline);
end;

procedure TFrmMain.ActQuitExecute(Sender: TObject);
begin
  Self.Close;
end;

procedure TFrmMain.FormDestroy(Sender: TObject);
var
  List: TList;
  I: Integer;
begin
  // Очищаем список
  List := Browsers.LockList;
  try
    for I := List.Count - 1 downto 0 do
      TBrowser(List.Items[I]).Free;
    List.Clear;
  finally
    Browsers.UnlockList;
  end;
  Browsers.Free;
end;

procedure TFrmMain.GetBrowsers;
const
  Key = 'SOFTWARE\Clients\StartMenuInternet\';
var
  List: TList;
  I: Integer;
  KClientPath: String;
  Founded: Boolean;
  Reg: TRegistry;
  Names: TStringList;
  S: String;
  sName: String;
  sDefaultIcon: String = '';
  sExePath: String;
begin
  List := Browsers.LockList;
  try
    // Очищаем список
    for I := List.Count - 1 downto 0 do
      TBrowser(List.Items[I]).Free;
    List.Clear;

    // Заполняем
    KClientPath := GetKClientPath(HKEY_CURRENT_USER, 'Software\Microsoft\Windows\CurrentVersion\Uninstall\KClient_is1');
    if KClientPath <> '' then
      List.Add(TBrowser.Create('KClient', KClientPath));

    KClientPath := GetKClientPath(HKEY_LOCAL_MACHINE, 'Software\Microsoft\Windows\CurrentVersion\Uninstall\KClient_is1');
    if KClientPath <> '' then
      List.Add(TBrowser.Create('KClient', KClientPath));

    KClientPath := GetKClientPath(HKEY_LOCAL_MACHINE, 'Software\Microsoft\Windows\CurrentVersion\Uninstall\KClient (x64)_is1');
    if KClientPath <> '' then
      List.Add(TBrowser.Create('KClient', KClientPath));

    KClientPath := GetKClientPath(HKEY_LOCAL_MACHINE, 'Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\KClient_is1');
    if KClientPath <> '' then
    begin
      // Проверяем наличие
      Founded := False;
      for I := List.Count - 1 downto 0 do
      begin
        if (TBrowser(List.Items[I]).ExePath = KClientPath) then
        begin
          Founded := True;
          Break;
        end;
      end;
      if not Founded then
        List.Add(TBrowser.Create('KClient', KClientPath));
    end;

    // Загружаем список браузеров из реестра.
    Reg := TRegistry.Create;
    try
      Reg.RootKey := HKEY_LOCAL_MACHINE;
      if Reg.OpenKeyReadOnly(Key) then
      begin
        Names := TStringList.Create;
        Reg.GetKeyNames(Names);
        Reg.CloseKey;

        for I := 0 to Names.Count - 1 do
        begin
          S := Key + Names[I] + '\';
          if Reg.OpenKeyReadOnly(S) then
          begin
            sName := Reg.ReadString(''); // Имя браузера
            Reg.CloseKey;

            if Reg.OpenKeyReadOnly(S + 'sDefaultIcon') then
            begin
              sDefaultIcon := Reg.ReadString(''); // Иконка
              Reg.CloseKey;
            end;

            if Reg.OpenKeyReadOnly(S + 'shell\open\command') then
            begin
              sExePath := Reg.ReadString('').Trim(['"']); // Путь для запуска
              Reg.CloseKey;
            end;

            List.Add(TBrowser.Create(sName, sExePath, sDefaultIcon));
          end;
        end;

        Names.Free;
      end;
    finally
      Reg.Free;
    end;

  finally
    Browsers.UnlockList;
  end;
end;

procedure TFrmMain.ProcessCommandline(S: Ansistring);
var
  FrmDialog: TFrmDialog;
  List: TList;
  I: Integer;
  B: TBrowser;
  LI: TListItem;
  Prog: string;
begin
  if S <> '' then
  begin
    FrmDialog := TFrmDialog.Create(Self);
    FrmDialog.LabeledEdit1.Text := S;
    List := Browsers.LockList;
    try
      for I := 0 to List.Count - 1 do
      begin
        B := TBrowser(List.Items[I]);
        LI := FrmDialog.ListView1.Items.Add;
        LI.Caption := B.Name;
        LI.SubItems.Add(B.ExePath);
        LI.ImageIndex := FrmDialog.ImageList1.AddIcon(B.Icon);
      end;
    finally
       Browsers.UnlockList;
    end;
    if FrmDialog.ShowModal = mrOK then
    begin
      LI := FrmDialog.ListView1.Selected;
      if LI <> nil then
      begin
        S := EncodeUrl(S);
        Prog := LI.SubItems[0];
        if ShellExecute(0, 'open', PChar(Prog), PChar(S), PChar(ExtractFilePath(Prog)), 1) > 32 then // успех
        begin
          // если возвращается число в диапазоне 0..32, то значит ошибка
        end;
      end;
    end;
  end;
end;

{ TBrowser }

Operator in (const AText: String; const AValues: array of String): Boolean;
begin
  Result := AnsiIndexStr(AText, AValues) <> -1;
end;

constructor TBrowser.Create(AName: String; AExePath: String; ADefaultIcon: String = '');
var
  FileName: String;
  nIconIndex: Integer = 0;
  hIcon: THandle;
  nIconId: DWORD;
  M: TStringArray;
  Images: array[0..1] of string = ('ico', 'png');
begin
  inherited Create;

  Name := AName;
  ExePath := AExePath;
  Icon := TIcon.Create;

  if (ADefaultIcon <> '') then
  begin
    M := ADefaultIcon.Split(',');
    FileName := M[0]; // TODO: Check if M[0] is image file
    if Length(M) = 2 then
      nIconIndex := StrToIntDef(M[1], 0);
  end
  else
    FileName := ExePath;

  if ExtractFileExt(FileName) in Images then
  begin
    Icon.LoadFromFile(FileName);
  end
  else
  begin
    if PrivateExtractIcons(LPCTSTR(FileName), nIconIndex, 48, 48, @hIcon, @nIconId, 1, LR_LOADFROMFILE) <> 0 then
      try
        Icon.Handle := hIcon;
        //Icon.SaveToFile(ExtractFilePath(ParamStr(0)) + IntToStr(I) + '.ico');
      finally
        DestroyIcon(hIcon);
      end;
  end;
end;

destructor TBrowser.Destroy;
begin
  Icon.Free;
  inherited;
end;

end.
