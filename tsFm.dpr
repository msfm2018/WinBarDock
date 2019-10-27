program tsFm;

uses
  Forms, windows,
  tsForm in 'tsForm.pas' {Form1};

{$R *.res}

begin
//ReportMemoryLeaksOnShutdown:=    DebugHook<>0;
  Application.Initialize;
  Application.MainFormOnTaskbar := False;
  Application.CreateForm(TForm1, Form1);
  Application.Run;

end.
