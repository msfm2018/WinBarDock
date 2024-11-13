unit InfoBarForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Winapi.ShellAPI, Vcl.ComCtrls, ActiveX, shlobj, u_json,
  System.JSON, u_debug, comobj, Vcl.ImgList, Vcl.Menus, System.ImageList,
  Vcl.StdCtrls;

type
  TbottomForm = class(TForm)
    LVexeinfo: TListView;
    ImgList: TImageList;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    Panel1: TPanel;
    Panel2: TPanel;
    Button1: TButton;
    Button2: TButton;
    procedure FormShow(Sender: TObject);
    procedure LVexeinfoDblClick(Sender: TObject);
    procedure action_translator(Sender: TObject);
    procedure LVexeinfoMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    into_snap_windows: Boolean;
    procedure WndProc(var Msg: TMessage); override;
    procedure DragFileInfo(Msg: TMessage);
    procedure AddExeInfo(Path, ExeName: string);
    function Show_app(Path, FileName: string): Boolean;
    function GetExeName(FileName: string): string;
    function ExeFromLink(lnkName: string): string;
    function ChangeFileName(FileName: string): string;
    procedure LoadIco;
    procedure CreateDefaultFile;
    procedure snap_top_windows;

  end;

var
  bottomForm: TbottomForm;

function SystemShutdown(reboot: Boolean): boolean; stdcall; external './dll/Project7.dll';

implementation

{$R *.dfm}

uses
  core;

procedure sort_layout(hwnd: hwnd; uMsg, idEvent: UINT; dwTime: DWORD); stdcall;
begin
  bottomForm.snap_top_windows();
end;

procedure TbottomForm.snap_top_windows();
var
  lp: tpoint;
begin
  if g_core.nodes.is_configuring then
    exit;

  SetWindowPos(Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);

  GetCursorPos(lp);
  if not PtInRect(self.BoundsRect, lp) and not into_snap_windows then
  begin
    into_snap_windows := true;

    if g_core.json.Config.layout = 'left' then
    begin
      bottomForm.Left := -bottomForm.Width + 4;
    end
    else
    begin

      if left < Screen.WorkAreaWidth - bottomForm.Width then
      begin
        top := 0;
        Left := Screen.WorkAreaWidth - bottomForm.Width + 40;

      end;
    end;

    into_snap_windows := false;

  end
  else if g_core.json.Config.layout = 'left' then
  begin
    bottomForm.Left := 0;
  end
  else
    Left := Screen.WorkAreaWidth - bottomForm.Width
end;

procedure TbottomForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  KillTimer(Handle, 10);
end;

procedure TbottomForm.FormShow(Sender: TObject);
begin
  g_core.utils.round_rect(width, height, Handle);
  into_snap_windows := false;
  SetTimer(Handle, 10, 100, @sort_layout);
  DragAcceptFiles(Handle, True);

  CreateDefaultFile();
  LoadIco();
//    SetWindowCornerPreference(Handle);
end;

procedure TbottomForm.WndProc(var Msg: TMessage);
begin
  inherited;
  if Msg.Msg = WM_DROPFILES then
  begin
    DragFileInfo(Msg);
  end;
end;

procedure TbottomForm.CreateDefaultFile;
var
  sysdir: pchar;
  SysTemDir: string;
begin
  Getmem(sysdir, 100);
  try
    getsystemdirectory(sysdir, 100);
    SysTemDir := string(sysdir);
  finally
    Freemem(sysdir, 100);
  end;

  if LVexeinfo.Items.Count = 0 then
  begin
    AddExeInfo(SysTemDir + '\notepad.exe', 'notepad');
    AddExeInfo(SysTemDir + '\calc.exe', 'calc');
    AddExeInfo(SysTemDir + '\mspaint.exe', 'mspaint');
    AddExeInfo(SysTemDir + '\cmd.exe', 'cmd');
    AddExeInfo(SysTemDir + '\mstsc.exe', 'mstsc');
  end;

end;

procedure TbottomForm.DragFileInfo(Msg: TMessage);
var
  i, number: integer;
  arrFileName: array[0..255] of Char;
  pFileName: PChar;
  strFileName: string;
begin
  pFileName := @arrFileName;
  number := DragQueryFile(Msg.wParam, $FFFFFFFF, nil, 0);

  for i := 0 to number - 1 do
  begin
    DragQueryFile(Msg.wParam, i, pFileName, 255);
    strFileName := StrPas(arrFileName);
    if Pos('.lnk', strFileName) > 0 then
      AddExeInfo(ExeFromLink(strFileName), GetExeName(strFileName))
    else
      AddExeInfo(strFileName, GetExeName(strFileName));
  end;
  DragFinish(Msg.wParam);
end;

function TbottomForm.ExeFromLink(lnkName: string): string;
var
  aObj: IUnknown;
  MyPFile: IPersistFile;
  MyLink: IShellLink;
  WFileName: WideString;
  FileName: array[0..255] of char;
  pfd: WIN32_FIND_DATA;
begin
  aObj := CreateComObject(CLSID_ShellLink);
  MyPFile := aObj as IPersistFile;
  MyLink := aObj as IShellLink;

  WFileName := lnkName;
  MyPFile.Load(PWChar(WFileName), 0);

  MyLink.GetPath(FileName, 255, pfd, SLGP_UNCPRIORITY);

  Result := string(FileName);
end;

function TbottomForm.GetExeName(FileName: string): string;
begin
  result := ExtractFileName(FileName);
  exit;
end;

procedure TbottomForm.LVexeinfoDblClick(Sender: TObject);
var
  IP: Integer;
  FilePath: string;
  arr: array[0..MAX_PATH + 1] of Char;
  SysyTem: string;
begin
  if LVexeinfo.Selected = nil then
    Exit;

  GetSystemDirectory(arr, MAX_PATH);
  SysyTem := Copy(arr, 1, 3);

  FilePath := LVexeinfo.Selected.SubItems.Text;
  IP := Pos(#13#10, FilePath);
  FilePath := Copy(FilePath, 1, IP - 1);

  ShellExecute(0, nil, PChar(FilePath), nil, PChar(FilePath), SW_NORMAL);

end;

procedure TbottomForm.LVexeinfoMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  ReleaseCapture;
  SendMessage(handle, WM_SYSCOMMAND, SC_MOVE + HTCaption, 0);
end;

procedure TbottomForm.action_translator(Sender: TObject);
var
  IP: Integer;
  FilePath: string;
  i: Integer;
  Node: TListItem;
begin
  if LVexeinfo.Selected = Nil then
    Exit;

  Node := TListItem.Create(NIl);

  if LVexeinfo.SelCount > 0 then
    if MessageBox(handle, 'delete', 'ok', MB_ICONQUESTION + MB_YESNO) <> IDYes then
      Exit;

  for i := LVexeinfo.Items.Count - 1 downto 0 do
  begin
    if not LVexeinfo.Items[i].Selected then
      Continue;

    Node := LVexeinfo.Items[i];

    FilePath := LVexeinfo.Items[i].SubItems.Text;
    IP := Pos(#13#10, FilePath);
    FilePath := Copy(FilePath, 1, IP - 1);

    FilePath := ExtractFileName(FilePath);

    del_json_value('ini', FilePath.ToUpper);
    Node.Delete;
  end;

end;

procedure TbottomForm.AddExeInfo(Path, ExeName: string);
var
  FileName: string;
begin

  if (Path = '') or (not (FileExists(Path)) or DirectoryExists(Path)) then
    Exit;

  FileName := ExtractFileName(Path);

  var c := FileName.Split(['.'])[0].ToUpper;
  var va := get_json_value('ini', c);

  if (va <> '') then
    exit;

  FileName := ChangeFileName(FileName);

  set_json_value('ini', FileName.ToUpper, Path);
  Show_app(Path, FileName);
end;

procedure TbottomForm.Button1Click(Sender: TObject);
begin
  SystemShutdown(True);
end;

procedure TbottomForm.Button2Click(Sender: TObject);
begin
  SystemShutdown(false);
end;

procedure TbottomForm.LoadIco;
var
  i: Integer;
  Pair: TJSONPair;
begin
  for i := 0 to LVexeinfo.Items.Count - 1 do
  begin
    LVexeinfo.Items.Delete(0);
  end;

  var iniObj := g_jsonobj.GetValue('ini') as TJSONObject;
  if Assigned(iniObj) then
  begin
    try
      for Pair in iniObj do
      begin
        var Key := Pair.JsonString.Value;

        Show_app(iniObj.GetValue(Key).GetValue<string>, Key);
      end;
    finally

    end;
  end;

end;

function TbottomForm.ChangeFileName(FileName: string): string;
begin
  if UpperCase(FileName) = 'NOTEPAD.EXE' then
    Result := 'NOTEPAD'
  else if UpperCase(FileName) = 'CALC.EXE' then
    Result := 'CALC'
  else if UpperCase(FileName) = 'MSPAINT.EXE' then
    Result := 'MSPAINT'
  else if UpperCase(FileName) = 'CMD.EXE' then
    Result := 'CMD'
  else if UpperCase(FileName) = 'MSTSC.EXE' then
    Result := 'MSTSC'
  else
    Result := FileName;
end;

function TbottomForm.Show_app(Path, FileName: string): Boolean;
var
  pIco: TIcon;
  bmpIco: TBitmap;
  IconIndex: word;
  item: TListItem;
  FilePath: string;
begin
  Result := True;
  FilePath := Path;

  if ((FileExists(Path) or DirectoryExists(Path))) and ((FileName) <> '') then
  begin
    IconIndex := 0;
    pIco := TIcon.Create;
    pIco.Handle := ExtractAssociatedIcon(Application.Handle, PChar(FilePath), IconIndex);
    if pIco.Handle > 0 then
    begin
      bmpIco := TBitmap.Create;
      bmpIco.PixelFormat := pf32bit;
      bmpIco.Height := pIco.Height;
      bmpIco.Width := pIco.Width;
      bmpIco.Canvas.Draw(0, 0, pIco);
      pIco.ReleaseHandle;

      item := LVexeinfo.Items.Add;
      item.Caption := (FileName);
      item.SubItems.Add(Path);
      item.ImageIndex := ImgList.Add(bmpIco, bmpIco);

    end;
  end
end;

end.

