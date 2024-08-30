program WinBarDock;

uses
  Forms,
  windows,
  ApplicationMain in 'ApplicationMain.pas' {Form1},
  ConfigurationForm in 'ConfigurationForm.pas' {mycfg},
  core in 'core\core.pas',
  event in 'core\event.pas',
  InfoBarForm in 'InfoBarForm.pas' {bottomForm},
  u_json in 'core\u_json.pas',
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin

  Application.Initialize;
  Application.MainFormOnTaskbar := False;
  TStyleManager.TrySetStyle('Iceberg Classico');
  Application.CreateForm(TForm1, Form1);
  Application.Run;

end.
