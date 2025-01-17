unit event;

interface
    uses    winapi.Windows;
type
  TMouseEvent  = record
    isLeftClick: Boolean;
    y: Integer;
    x: Integer;
  end;

procedure restore_state();

var
  EventDef: TMouseEvent ;

implementation

procedure restore_state();
begin
  with EventDef do
  begin
    y := 0;
    x := 0;
    isLeftClick := False;
  end;
end;

end.
