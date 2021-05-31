unit bottomForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,Winapi.ShellAPI;

type
  TbottomFrm = class(TForm)
    FlowPanel1: TFlowPanel;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    Button8: TButton;
    Button9: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  bottomFrm: TbottomFrm;

implementation

{$R *.dfm}

procedure TbottomFrm.Button1Click(Sender: TObject);
begin
var  s:='https://'+TButton(Sender).Caption;
  Winapi.ShellAPI.ShellExecute(application.Handle, nil, PChar(s), nil, nil, SW_SHOWNORMAL)   ;
end;

procedure TbottomFrm.Button9Click(Sender: TObject);
begin
  bottomFrm.Close;
  bottomFrm:=nil;
end;

end.
