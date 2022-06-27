unit event;

interface

type
  TEventDefine = record
    isLeftClick: Boolean;
    y: Integer;
    x: Integer;
  end;

procedure restore_state();

var
  EventDef: TEventDefine;

implementation

procedure restore_state();
begin
  with EventDef do
  begin
    Y := 0;
    X := 0;
    isLeftClick := False;
  end;
end;

end.

