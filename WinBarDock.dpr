program WinBarDock;

uses
  Forms,
  windows,
  core in 'core\core.pas',
  event in 'core\event.pas',
  u_json in 'core\u_json.pas',
  Vcl.Themes,
  Vcl.Styles,
  PopupMenuManager in 'core\PopupMenuManager.pas',
  ApplicationMain in 'src\ApplicationMain.pas' {Form1},
  ConfigurationForm in 'src\ConfigurationForm.pas' {CfgForm},
  InfoBarForm in 'src\InfoBarForm.pas' {bottomForm};

{$R *.res}

begin


  Application.Initialize;
  Application.MainFormOnTaskbar := False;
  TStyleManager.TrySetStyle('Iceberg Classico');
  Application.CreateForm(TForm1, Form1);
  Application.Run;




end.
