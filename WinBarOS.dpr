program WinBarOS;

uses
  Forms,
  windows,
  ApplicationMain in 'ApplicationMain.pas' {Form1},
  ConfigurationForm in 'ConfigurationForm.pas' {mycfg},
  core in 'core\core.pas',
  core_db in 'core\core_db.pas',
  event in 'core\event.pas',
  InfoBarForm in 'InfoBarForm.pas' {bottomForm};

{$R *.res}

begin

  Application.Initialize;
  Application.MainFormOnTaskbar := False;
  Application.CreateForm(TForm1, Form1);
  Application.Run;

end.
