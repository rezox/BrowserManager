unit ufrmdialog;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls, StdCtrls;

type
  { TFrmDialog }
  TFrmDialog = class(TForm)
    Button1: TButton;
    Button2: TButton;
    CheckBox1: TCheckBox;
    ImageList1: TImageList;
    LabeledEdit1: TLabeledEdit;
    ListView1: TListView;
  end;

implementation

{$R *.lfm}

end.

