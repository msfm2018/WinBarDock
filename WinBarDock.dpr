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
  InfoBarForm in 'src\InfoBarForm.pas' {bottomForm},
  plug in 'core\plug.pas',
  utils in 'core\utils.pas',
  TaskbarList in 'core\TaskbarList.pas',
  ImgButton in 'core\ImgButton.pas',
  ImgPanel in 'core\ImgPanel.pas';

{$R *.res}

begin


  Application.Initialize;
  Application.MainFormOnTaskbar := true;
//  TStyleManager.TrySetStyle('Iceberg Classico');
  Application.CreateForm(TForm1, Form1);
  Application.Run;




end.
