unit plug;

interface

uses
  Windows, SysUtils;

procedure load_plug;

implementation

procedure load_plug;
var
  wszExtraLibPath: string;
  hExtra: HMODULE;
  ep_extra_entrypoint: procedure;
begin

  wszExtraLibPath := ExtractFilePath(ParamStr(0)) + 'plug\ep_extra.dll';

  if FileExists(wszExtraLibPath) then
  begin
    hExtra := LoadLibraryW(PChar(wszExtraLibPath));
    if hExtra <> 0 then
    begin
      ep_extra_entrypoint := GetProcAddress(hExtra, 'ep_extra_EntryPoint');
      if Assigned(ep_extra_entrypoint) then
      begin
        ep_extra_entrypoint();
      end;
    end
    else
    begin
      OutputDebugString('load plug error');
    end;
  end;
end;

end.

