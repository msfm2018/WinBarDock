unit PopupMenuManager;

interface

uses
  Vcl.Menus, Vcl.Forms, System.Classes;

type
  TPopupMenuManager = class
  private
    FPopupMenu: TPopupMenu;
    FMenuItems: array of TMenuItem;
    FMenuLabels: array of string;
    FMenuHandlers: array of TNotifyEvent;
  public
    constructor Create(AOwner: TComponent; const MenuLabels: array of string; const MenuHandlers: array of TNotifyEvent);
    procedure InitializePopupMenu;
    procedure SetChecked(Index: Integer; Checked: Boolean);
    function GetPopupMenu: TPopupMenu;
  end;

implementation

constructor TPopupMenuManager.Create(AOwner: TComponent; const MenuLabels: array of string; const MenuHandlers: array of TNotifyEvent);
begin
  FPopupMenu := TPopupMenu.Create(AOwner);

  // 使用 SetLength 初始化动态数组
  SetLength(FMenuLabels, Length(MenuLabels));
  SetLength(FMenuHandlers, Length(MenuHandlers));
  SetLength(FMenuItems, Length(MenuLabels));

  // 复制静态数组内容到动态数组
  for var I := 0 to High(MenuLabels) do
  begin
    FMenuLabels[I] := MenuLabels[I];
    FMenuHandlers[I] := MenuHandlers[I];
  end;
end;

procedure TPopupMenuManager.InitializePopupMenu;
begin
  for var I := 0 to High(FMenuItems) do
  begin
    FMenuItems[I] := TMenuItem.Create(FPopupMenu.Owner);
    FMenuItems[I].Caption := FMenuLabels[I];
    FMenuItems[I].OnClick := FMenuHandlers[I];
    FPopupMenu.Items.Add(FMenuItems[I]);
  end;
end;

procedure TPopupMenuManager.SetChecked(Index: Integer; Checked: Boolean);
begin
  if (Index >= 0) and (Index < Length(FMenuItems)) then
    FMenuItems[Index].Checked := Checked;
end;

function TPopupMenuManager.GetPopupMenu: TPopupMenu;
begin
  Result := FPopupMenu;
end;

end.

