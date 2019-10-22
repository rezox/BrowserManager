unit ufrmdialog;

{$mode objfpc}{$H+}

interface

uses
  Windows, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls, StdCtrls;

type
  { TFrmDialog }
  TFrmDialog = class(TForm)
    BtnOK: TButton;
    BtnCancel: TButton;
    CheckBox1: TCheckBox;
    ImageList1: TImageList;
    LabeledEdit1: TLabeledEdit;
    LvBrowsers: TListView;
    procedure BtnCancelClick(Sender: TObject);
    procedure BtnOKClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure LvBrowsersKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  end;

implementation

{$R *.lfm}

uses
  uglobal, synacode;

{ TFrmDialog }

procedure TFrmDialog.FormCreate(Sender: TObject);
begin
  Caption := uglobal.AppTitle;
end;

procedure TFrmDialog.FormShow(Sender: TObject);
begin
  LvBrowsers.SetFocus;
end;

procedure TFrmDialog.BtnOKClick(Sender: TObject);
var
  LI: TListItem;
  Url: String;
  Prog: String;
begin
  LI := LvBrowsers.Selected;
  if Assigned(LI) then
  begin
    Url := EncodeUrl(LabeledEdit1.Text);
    Prog := LI.SubItems[0];
    if ShellExecute(0, 'open', PChar(Prog), PChar(Url), PChar(ExtractFilePath(Prog)), 1) > 32 then // успех
    begin
      // если возвращается число в диапазоне 0..32, то значит ошибка
    end;
    Close;
  end;
end;

procedure TFrmDialog.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caFree;
end;

procedure TFrmDialog.BtnCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TFrmDialog.LvBrowsersKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_RETURN:
      if Assigned(LvBrowsers.Selected) then
        BtnOK.Click;
  end;
end;

end.

