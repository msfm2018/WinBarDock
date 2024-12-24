program startx;

uses
  Vcl.Forms,
  Unit1 in 'Unit1.pas' {Form1},
  ImgPanel in 'ImgPanel.pas',
  ImgButton in 'ImgButton.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
