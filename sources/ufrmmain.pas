unit ufrmmain;

{$mode objfpc}{$H+}

interface

uses
  Windows, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls, StdCtrls, Menus, ActnList, StrUtils;

type
  { TFrmMain }
  TFrmMain = class(TForm)
    ActSettings: TAction;
    ActExit: TAction;
    ActionList1: TActionList;
    MiExit: TMenuItem;
    MiSettings: TMenuItem;
    PopupMenu1: TPopupMenu;
    TrayIcon1: TTrayIcon;
    procedure ActExitExecute(Sender: TObject);
    procedure ActSettingsExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    procedure GetBrowsers;
    procedure ProcessCommandline(Data: Ansistring);
  end;

type
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
  Registry, uglobal, ufrmdialog, ufrmsettings;

{ TFrmMain }

var
  PrevWndProc: Windows.WNDPROC;

function WndCallback(Wnd: HWND; Msg: UINT; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
var
  CopyData: TCopyDataStruct;
  Data: String;
  Len: Integer;
begin
  Result := 0;
  case Msg of
    WM_COPYDATA:
    begin
      CopyData := PCopyDataStruct(LParam)^;
      Len := CopyData.cbData div SizeOf(Char);
      SetLength(Data, Len);
      Move(PChar(CopyData.lpData)^, PChar(Data)^, Len * SizeOf(Char));
      FrmMain.ProcessCommandline(Data);
      Result := 1;
      Exit;
    end;
  end;
  Result := Windows.CallWindowProc(PrevWndProc, Wnd, Msg, WParam, LParam);
end;

procedure TFrmMain.FormCreate(Sender: TObject);
begin
  Caption := Application.Title;
  TrayIcon1.Hint := uglobal.AppTitle;

  Browsers := TThreadList.Create;

  GetBrowsers;

  // WM_COPYDATA
  PrevWndProc := Windows.WNDPROC(SetWindowLongPtr(Self.Handle, GWL_WNDPROC, PtrInt(@WndCallback)));

  ProcessCommandline(MyGetCommandline);
end;

procedure TFrmMain.ActExitExecute(Sender: TObject);
begin
  Self.Close;
end;

procedure TFrmMain.ActSettingsExecute(Sender: TObject);
begin
  with TFrmSettings.Create(Self) do
  begin
    if ShowModal = mrOk then
    begin
      //*
    end;
    Free;
  end;
end;

procedure TFrmMain.FormDestroy(Sender: TObject);
var
  List: TList;
  I: Integer;
begin
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
  Reg: TRegistry;
  Names: TStringList;
  S: String;
  sName: String;
  sDefaultIcon: String = '';
  sExePath: String;
begin
  List := Browsers.LockList;
  try
    for I := List.Count - 1 downto 0 do
      TBrowser(List.Items[I]).Free;
    List.Clear;

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
            sName := Reg.ReadString('');
            Reg.CloseKey;

            if Reg.OpenKeyReadOnly(S + 'sDefaultIcon') then
            begin
              sDefaultIcon := Reg.ReadString('');
              Reg.CloseKey;
            end;

            if Reg.OpenKeyReadOnly(S + 'shell\open\command') then
            begin
              sExePath := Reg.ReadString('').Trim(['"']);
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

procedure TFrmMain.ProcessCommandline(Data: Ansistring);
var
  List: TList;
  I: Integer;
  B: TBrowser;
  LI: TListItem;
begin
  if Data <> '' then
  begin
    with TFrmDialog.Create(Self) do
    begin
      LabeledEdit1.Text := Data;
      List := Browsers.LockList;
      try
        for I := 0 to List.Count - 1 do
        begin
          B := TBrowser(List.Items[I]);
          LI := LvBrowsers.Items.Add;
          LI.Caption := B.Name;
          LI.SubItems.Add(B.ExePath);
          LI.ImageIndex := ImageList1.AddIcon(B.Icon);
        end;
      finally
        Browsers.UnlockList;
      end;
      Show;
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
  Images: array[0..1] of String = ('ico', 'png');
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
