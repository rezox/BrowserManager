unit ufrmsettings;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls, StdCtrls;

type
  { TFrmSettings }
  TFrmSettings = class(TForm)
    BtnOK: TButton;
    BtnCancel: TButton;
    ChkAutorun: TCheckBox;
    Label1: TLabel;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TreeView1: TTreeView;
    procedure FormCreate(Sender: TObject);
    procedure TreeView1Change(Sender: TObject; Node: TTreeNode);
  end;

implementation

{$R *.lfm}

{ TFrmSettings }

procedure TFrmSettings.FormCreate(Sender: TObject);
var
  I: Integer;
  TreeNode: TTreeNode;
begin
  Caption := Application.Title + ' - Настройки';

  PageControl1.ShowTabs := False;

  PageControl1.ActivePage := TabSheet1;
  for I := 0 to PageControl1.PageCount - 1 do
  begin
    TreeNode := TreeView1.Items.Add(nil, PageControl1.Pages[I].Caption);
    TreeNode.Data := PageControl1.Pages[I];
    PageControl1.Pages[I].Tag := PtrInt(TreeNode);
  end;
  TreeView1.Selected := TTreeNode(Pointer(TabSheet1.Tag));
end;

procedure TFrmSettings.TreeView1Change(Sender: TObject; Node: TTreeNode);
begin
  PageControl1.ActivePage := TTabSheet(Node.Data);
  Label1.Caption := Node.Text;
end;

end.
