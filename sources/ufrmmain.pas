unit ufrmmain;

{$mode objfpc}{$H+}

interface

uses
  Windows, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls, StdCtrls, Menus, ActnList, StrUtils,
  sqlite3conn, sqldb, sqlite3dyn, DB, LCLTranslator;

type
  { TFrmMain }
  TFrmMain = class(TForm)
    ActSettings: TAction;
    ActExit: TAction;
    ActionList1: TActionList;
    MiExit: TMenuItem;
    MiSettings: TMenuItem;
    PopupMenu1: TPopupMenu;
    SQLite3Connection1: TSQLite3Connection;
    SQLQuery1: TSQLQuery;
    SQLTransaction1: TSQLTransaction;
    TrayIcon1: TTrayIcon;
    procedure ActExitExecute(Sender: TObject);
    procedure ActSettingsExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    procedure GetBrowsers;
    procedure ProcessCommandline(Data: AnsiString);
  public
    procedure CreateRule(URL: String; BrowserId: String);
  end;

var
  FrmMain: TFrmMain;
  Settings: TStringList;

const
  // Settings names
  SN_DbVersion = 'db.version';
  SN_StateCreateRule = 'stateCreateRule';

implementation

{$R *.lfm}

uses
  Registry, synacode, synautil, uglobal, ufrmdialog, ufrmsettings;

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
var
  bCreateTables: Boolean;
  Names: TStringList;
  Reg: TRegistry;
  I: Integer;
  N: String;
begin
  SetDefaultLang(GetDefaultLang);

  Caption := Application.Title;
  TrayIcon1.Hint := Application.Title;

  SQLiteDefaultLibrary := 'sqlite3.dll';

  // Create or connect to database
  SQLite3Connection1.DatabaseName := uglobal.AppDataPath + 'main.db';
  bCreateTables := not FileExists(SQLite3Connection1.DatabaseName);
  SQLite3Connection1.Open;
  SQLTransaction1.Active := True;
  if bCreateTables then
  begin
    // Create system table
    SQLQuery1.SQL.Text := 'CREATE TABLE `system` (`name` TEXT, `value` TEXT, UNIQUE (`name`) ON CONFLICT REPLACE);';
    SQLQuery1.ExecSQL;

    // Insert version of DB schema
    SQLQuery1.SQL.Text := 'INSERT INTO `system` (`name`, `value`) VALUES (:name, :value);';
    SQLQuery1.Params.ParseSQL(SQLQuery1.SQL.Text, True);
    SQLQuery1.Params.ParamByName('name').Value := SN_DbVersion;
    SQLQuery1.Params.ParamByName('value').Value := '1';
    SQLQuery1.ExecSQL;

    // Create table for settings
    {SQLQuery1.SQL.Text := 'CREATE TABLE `settings` (`name` TEXT, `value` TEXT, UNIQUE (`name`) ON CONFLICT REPLACE);';
    SQLQuery1.ExecSQL;}

    // Create table for browsers
    SQLQuery1.SQL.Text := 'CREATE TABLE `browsers` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `name` TEXT, ' +
      '`path` TEXT, `icon` BLOB, UNIQUE (`path`) ON CONFLICT IGNORE);';
    SQLQuery1.ExecSQL;

    // Create table for rules
    SQLQuery1.SQL.Text := 'CREATE TABLE `rules` (`url` TEXT PRIMARY KEY, `browser_id` INTEGER NOT NULL);';
    SQLQuery1.ExecSQL;

    SQLTransaction1.Commit;
  end
  else
  begin
    // Here scripts for check and upgrade DB schema
  end;

  // Load settings.
  Settings := TStringList.Create;
  {SQLQuery1.SQL.Text := 'SELECT * FROM `settings`;';
  SQLQuery1.ExecSQL;
  SQLQuery1.Open;
  while not SQLQuery1.EOF do
  begin
    Settings.Add(SQLQuery1.FieldByName('name').AsString + '=' + SQLQuery1.FieldByName('value').AsString);
    SQLQuery1.Next;
  end;
  SQLQuery1.Close;}
  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_CURRENT_USER;
  if Reg.OpenKeyReadOnly('SOFTWARE\' + AppCompany + '\' + AppName) then
  begin
    Names := TStringList.Create;
    Reg.GetValueNames(Names);
    for I := 0 to Names.Count - 1 do
    begin
      N := Names[I];
      Settings.Add(N + '=' + Reg.ReadString(N));
    end;
    Names.Free;
  end
  else
  begin
    Settings.Add(SN_StateCreateRule + '=0');
  end;
  Reg.Free;

  // Get browsers and insert into DB
  GetBrowsers;

  // WM_COPYDATA
  PrevWndProc := Windows.WNDPROC(SetWindowLongPtr(Self.Handle, GWL_WNDPROC, PtrInt(@WndCallback)));

  ProcessCommandline(MyGetCommandline);
end;

procedure TFrmMain.FormDestroy(Sender: TObject);
begin
  Settings.Free;
end;

procedure TFrmMain.ActExitExecute(Sender: TObject);
begin
  Self.Close;
end;

procedure TFrmMain.ActSettingsExecute(Sender: TObject);
var
  //Values: String;
  Reg: TRegistry;
  I: Integer;
begin
  with TFrmSettings.Create(Self) do
  begin
    ChkAutorun.Checked := IsAutorun;
    ChkStateCreateRule.Checked := StrToBoolDef(Settings.Values[SN_StateCreateRule], False);

    if ShowModal = mrOk then
    begin
      SetAutorun(ChkAutorun.Checked);

      Settings.Values[SN_StateCreateRule] := BoolToStr(ChkStateCreateRule.Checked);

      // Save settings
      {Values := '';
      for I := 0 to Settings.Count - 1 do
      begin
        Values += '("' + Settings.Names[I] + '","' + Settings.ValueFromIndex[I] + '")';
        if I <> Settings.Count - 1 then
          Values += ',';
      end;
      if Values <> '' then
      begin
        SQLite3Connection1.ExecuteDirect('INSERT INTO `settings` (`name`, `value`) VALUES ' + Values + ';');
        SQLTransaction1.Commit;
      end;}
      Reg := TRegistry.Create;
      Reg.RootKey := HKEY_CURRENT_USER;
      if Reg.OpenKey('SOFTWARE\' + AppCompany + '\' + AppName, True) then
      begin
        for I := 0 to Settings.Count - 1 do
          Reg.WriteString(Settings.Names[I], Settings.ValueFromIndex[I]);
      end;
      Reg.Free;
    end;
    Free;
  end;
end;

procedure TFrmMain.ProcessCommandline(Data: AnsiString);
var
  sUrl, sProt, sUser, sPass, sHost, sPort, sPath, sPara: String;
  bFounded: Boolean;
  Prog: String;
  LI: TListItem;
  MS: TMemoryStream;
  BlobField: TBlobField;
  Ico: TIcon;
begin
  if Data <> '' then
  begin
    sUrl := EncodeUrl(Data);
    ParseURL(sUrl, sProt, sUser, sPass, sHost, sPort, sPath, sPara);

    // Find rule
    SQLQuery1.SQL.Text := 'SELECT r.*, b.name, b."path" FROM rules r ' + 'INNER JOIN browsers b ON (b.id = r.browser_id) ' +
      'WHERE r.url = :url OR r.url = :host';
    SQLQuery1.Params.ParseSQL(SQLQuery1.SQL.Text, True);
    SQLQuery1.Params.ParamByName('url').Value := sUrl;
    SQLQuery1.Params.ParamByName('host').Value := sHost;
    SQLQuery1.ExecSQL;
    SQLQuery1.Open;
    bFounded := not SQLQuery1.EOF;
    if bFounded then
    begin
      SQLQuery1.First;
      Prog := SQLQuery1.FieldByName('path').AsString;
      bFounded := FileExists(Prog);
    end;
    SQLQuery1.Close;

    if bFounded then
    begin
      if ShellExecute(0, 'open', PChar(Prog), PChar(sUrl), PChar(ExtractFilePath(Prog)), 1) > 32 then
      begin
        // Error
      end;
      Exit;
    end;

    with TFrmDialog.Create(Self) do
    begin
      EdURL.Text := Data;

      // Load browsers from DB
      SQLQuery1.SQL.Text := 'SELECT * FROM `browsers`';
      SQLQuery1.Params.Clear;
      SQLQuery1.ExecSQL;
      SQLQuery1.Open;
      while not SQLQuery1.EOF do
      begin
        LI := LvBrowsers.Items.Add;
        LI.Caption := SQLQuery1.FieldByName('name').AsString;
        LI.SubItems.Add(SQLQuery1.FieldByName('path').AsString);
        LI.SubItems.Add(SQLQuery1.FieldByName('id').AsString); // Hidden column
        // Load icon
        MS := TMemoryStream.Create;
        try
          BlobField := SQLQuery1.FieldByName('icon') as TBlobField;
          BlobField.SaveToStream(MS);
          MS.Position := 0;
          Ico := TIcon.Create;
          Ico.LoadFromStream(MS);
          LI.ImageIndex := ImageList1.AddIcon(Ico);
          Ico.Free;
        finally
          MS.Free;
        end;
        SQLQuery1.Next;
      end;
      SQLQuery1.Close;

      // Show form
      Show;
    end;
  end;
end;

{Operator in (const AText: String; const AValues: array of String): Boolean;
begin
  Result := AnsiIndexStr(AText, AValues) <> -1;
end;}

procedure TFrmMain.GetBrowsers;
const
  Key = 'SOFTWARE\Clients\StartMenuInternet\';
var
  Reg: TRegistry;
  Names: TStringList;
  I: Integer;
  SubKey: String;
  sName: String;
  sIcon: String = '';
  sPath: String;
  MS: TMemoryStream;
  Ico: TIcon;
  SA: TStringArray;
  FileName: String;
  ImageTypes: array[0..1] of String = ('ico', 'png');
  nIconIndex: Integer = 0;
  hIcon: THandle;
  nIconId: DWORD;
begin
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKeyReadOnly(Key) then
    begin
      Names := TStringList.Create;
      Reg.GetKeyNames(Names);
      Reg.CloseKey;

      if Names.Count > 0 then
      begin
        SQLQuery1.SQL.Text := 'INSERT INTO `browsers` (`name`, `path`, `icon`) VALUES (:name, :path, :icon);';
        SQLQuery1.Params.ParseSQL(SQLQuery1.SQL.Text, True);
      end;

      for I := 0 to Names.Count - 1 do
      begin
        SubKey := Key + Names[I] + '\';
        if Reg.OpenKeyReadOnly(SubKey) then
        begin
          sName := Reg.ReadString('');
          Reg.CloseKey;

          // Get default icon
          if Reg.OpenKeyReadOnly(SubKey + 'DefaultIcon') then
          begin
            sIcon := Reg.ReadString('');
            Reg.CloseKey;
          end;

          // Get executable path
          if Reg.OpenKeyReadOnly(SubKey + 'shell\open\command') then
          begin
            sPath := Reg.ReadString('').Trim(['"']);
            Reg.CloseKey;
          end;

          if not FileExists(sPath) then
            Continue;

          MS := TMemoryStream.Create;
          try
            Ico := TIcon.Create;
            if sIcon <> '' then
            begin
              SA := sIcon.Split(',');
              FileName := SA[0]; // TODO: Check if SA[0] is image file
              if Length(SA) = 2 then
                nIconIndex := StrToIntDef(SA[1], 0);
            end
            else
            begin
              FileName := sPath;
            end;
            if ExtractFileExt(FileName) in ImageTypes then
            begin
              Ico.LoadFromFile(FileName);
            end
            else
            begin
              if PrivateExtractIcons(LPCTSTR(FileName), nIconIndex, 48, 48, @hIcon, @nIconId, 1, LR_LOADFROMFILE) <> 0 then
                try
                  Ico.Handle := hIcon;
                finally
                  DestroyIcon(hIcon);
                end;
            end;
            Ico.SaveToStream(MS);
            Ico.Free;

            MS.Position := 0;

            SQLQuery1.Params.ParamByName('name').Value := sName;
            SQLQuery1.Params.ParamByName('path').Value := sPath;
            SQLQuery1.Params.ParamByName('icon').LoadFromStream(MS, ftBlob);
            SQLQuery1.ExecSQL;

          finally
            MS.Free;
          end;
        end;
      end;

      if Names.Count > 0 then
        SQLTransaction1.Commit;

      Names.Free;
    end;
  finally
    Reg.Free;
  end;
end;

procedure TFrmMain.CreateRule(URL: String; BrowserId: String);
begin
  SQLQuery1.SQL.Text := 'INSERT INTO `rules` (`url`, `browser_id`) VALUES (:url, :browser_id) ' +
    'ON CONFLICT(`url`) DO UPDATE SET `browser_id` = :browser_id';
  SQLQuery1.Params.ParseSQL(SQLQuery1.SQL.Text, True);
  SQLQuery1.Params.ParamByName('url').Value := URL;
  SQLQuery1.Params.ParamByName('browser_id').Value := BrowserId;
  SQLQuery1.ExecSQL;
  SQLTransaction1.Commit;
end;

end.
