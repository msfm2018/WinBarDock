program dTool;

uses
  Forms,
  windows,
  main in 'main.pas' {Form1},
  cfg_form in 'cfg_form.pas' {mycfg},
  u_debug in 'u_debug.pas',
  core in 'core\core.pas',
  core_db in 'core\core_db.pas',
  event in 'core\event.pas',
  bottom_form in 'bottom_form.pas' {bottomForm};

{$R *.res}

begin

  Application.Initialize;
  Application.MainFormOnTaskbar := False;
  Application.CreateForm(TForm1, Form1);
  Application.Run;

end.