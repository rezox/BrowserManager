unit ufrmdialog;

{$mode objfpc}{$H+}

interface

uses
  Windows, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls, StdCtrls;

type
  { TFrmDialog }
  TFrmDialog = class(TForm)
    BtnGo: TButton;
    BtnCancel: TButton;
    ChbCreateRule: TCheckBox;
    ComboBox1: TComboBox;
    ImageList1: TImageList;
    EdURL: TLabeledEdit;
    LvBrowsers: TListView;
    procedure BtnCancelClick(Sender: TObject);
    procedure BtnGoClick(Sender: TObject);
    procedure ChbCreateRuleChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure LvBrowsersDblClick(Sender: TObject);
    procedure LvBrowsersKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  end;

implementation

{$R *.lfm}

uses
  uglobal, synacode, synautil, ufrmmain;

{ TFrmDialog }

procedure TFrmDialog.FormCreate(Sender: TObject);
begin
  Caption := uglobal.AppTitle;
end;

procedure TFrmDialog.FormShow(Sender: TObject);
begin
  LvBrowsers.SetFocus;
end;

procedure TFrmDialog.LvBrowsersDblClick(Sender: TObject);
begin
  BtnGo.Click;
end;

procedure TFrmDialog.BtnGoClick(Sender: TObject);
var
  LI: TListItem;
  sUrl, sProt, sUser, sPass, sHost, sPort, sPath, sPara: String;
  BrowserId: String;
  Prog: String;
begin
  LI := LvBrowsers.Selected;
  if Assigned(LI) then
  begin
    sUrl := EncodeUrl(EdURL.Text);

    // Create rule
    if ChbCreateRule.Checked then
    begin
      BrowserId := LI.SubItems[1];
      case ComboBox1.ItemIndex of
        0: // host
          begin
            ParseURL(sUrl, sProt, sUser, sPass, sHost, sPort, sPath, sPara);
            FrmMain.CreateRule(sHost, BrowserId);
          end;
        1: // page
          begin
            FrmMain.CreateRule(sUrl, BrowserId);
          end;
      end;
    end;

    // Open URL in browser
    Prog := LI.SubItems[0];
    if ShellExecute(0, 'open', PChar(Prog), PChar(sUrl), PChar(ExtractFilePath(Prog)), 1) > 32 then
    begin
      // Error
    end;

    Close;
  end;
end;

procedure TFrmDialog.BtnCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TFrmDialog.ChbCreateRuleChange(Sender: TObject);
begin
  ComboBox1.Enabled := ChbCreateRule.Checked;
end;

procedure TFrmDialog.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caFree;
end;

procedure TFrmDialog.LvBrowsersKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_RETURN: BtnGo.Click;
  end;
end;

end.

