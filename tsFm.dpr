program tsFm;

uses
  Forms,
  windows,
  tsForm in 'tsForm.pas' {Form1},
  cfgForm in 'cfgForm.pas' {mycfg};

{$R *.res}

begin

  Application.Initialize;
  Application.MainFormOnTaskbar := False;
  Application.CreateForm(TForm1, Form1);

  Application.Run;

end.
