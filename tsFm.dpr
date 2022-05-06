program tsFm;

uses
  Forms,
  windows,
  tsForm in 'tsForm.pas' {Form1},
  cfgForm in 'cfgForm.pas' {mycfg},
  u_debug in 'u_debug.pas',
  bottomForm in 'bottomForm.pas' {bottomFrm},
  core in 'core\core.pas',
  event in 'core\event.pas';

{$R *.res}

begin

  Application.Initialize;
  Application.MainFormOnTaskbar := False;
  Application.CreateForm(TForm1, Form1);
  Application.Run;

end.
