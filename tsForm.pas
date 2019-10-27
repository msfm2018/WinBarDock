unit tsForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  core, Winapi.Dwmapi, u_debug, Winapi.ShellAPI,
  Dialogs, Registry, ExtCtrls, Vcl.StdCtrls, Vcl.Imaging.pngimage,
  inifiles, FileCtrl, Vcl.Imaging.jpeg;

type
  TForm1 = class(TForm)
    bg: TImage;
    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Image111MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormShow(Sender: TObject);

    procedure FormDestroy(Sender: TObject);
  private
    FAltF4Key, FShowkeyid: Word;
    procedure hotkey(var Msg: tmsg); message WM_HOTKEY;
    procedure do_click(Sender: TObject);
    procedure move_windows(h: thandle);

  end;

var
  Form1: TForm1;
  pic_num: integer;

implementation

{$R *.dfm}

const
  VisHeight: Integer = 9; // 露头高度
  snapValue: Integer = 40; // 吸附距离
  img_width = 72;

  Original_HeightWidth = 134; // 110; // 144;

var
  h: HDC;
  a, b, rate: Real;

  img_arr_position: array of integer;
  img_arr: array of timage;

var
  click_ing: Boolean = false;
  oldy: Integer = 0;
  oldx: Integer = 0;

procedure run_exe(n: string);
var
  s: string;
begin
  s := ExtractFilePath(paramstr(0)) + 'third-party\' + n;
  ShellExecute(0, 'open', PChar(s), nil, nil, SW_SHOW);
  sleep(500);
end;

procedure TForm1.FormCreate(Sender: TObject);
VAR
  I: Integer;
  arr_split: TArray<string>;
  exe_split: TArray<string>;
begin
  // ctrl+b   屏幕快照
  if FindAtom('ZWXhotKey') = 0 then
  begin
    FShowkeyid := GlobalAddAtom('ZWXhotKey');
    RegisterHotKey(Handle, FShowkeyid, MOD_CONTROL, $42);
  end;

  var
  Filename := ExtractFilePath(Paramstr(0)) + 'cfg.ini';
  var
  myinifile := Tinifile.Create(Filename);

  var bgv:=myinifile.ReadString('config', 'bg', 'bg');
   // bg.Picture.LoadFromFile('img\'+bgv+'.png');
 bg.Picture.LoadFromFile(ExtractFilePath(Paramstr(0))+'img\'+bgv+'.png');


  pic_Num := myinifile.ReadInteger('config', 'count', 0);

  setlength(img_arr_position, pic_Num + 1); // 因为0开始 所以+1

  setlength(img_arr, pic_Num);
  for I := 1 to pic_Num do
  begin
    img_arr[i] := timage.Create(self);

    img_arr[i].Name := 'image' + i.ToString;
    img_arr[i].SetBounds(35 + (i - 1) * 75, 2, 72, 72);
    var
    imgv := myinifile.ReadString('config', i.ToString, '1');
    arr_split := imgv.Split([';']);
    img_arr[i].Hint := arr_split[1]; // 可执行文件
    img_arr[i].Picture.LoadFromFile('img\' + arr_split[0] + '.png');
    img_arr[i].Stretch := true;
    img_arr[i].Parent := self;
    img_arr[i].OnMouseMove := Image111MouseMove;
    img_arr[i].OnMouseDown := FormMouseDown;
    img_arr[i].OnClick := do_click;

  end;
  myinifile.Free;

  for I := 1 to pic_num do
    img_arr_position[I] := TImage(Form1.FindComponent('image' + inttostr(I))).Left;

  h := GetDC(0);
  BorderStyle := bsNone;

  form1.width := pic_num * 75 + 80;
end;

procedure TForm1.do_click(Sender: TObject);
var
  arr_exe: tarray<string>;
  i: integer;
begin
  arr_exe := timage(sender).Hint.Split([',']);
  for I := 0 to high(arr_exe) do
    run_exe(arr_exe[i]);

  click_ing := false;
end;

procedure TForm1.FormPaint(Sender: TObject);
var
  lp: tpoint;
  I: Integer;
begin

  GetCursorPos(lp);
  if not PtInRect(self.BoundsRect, lp) then
  begin
    for I := 0 to ControlCount - 1 do
    begin
      if (Controls[I] is TImage) and (Controls[I].Name <> 'bg') then
      begin
        TImage(Controls[I]).Width := Round(Original_HeightWidth) div 2;
        TImage(Controls[I]).Height := Round(Original_HeightWidth) div 2;
      end;
    end;

    for I := 1 to pic_Num do
      TImage(Form1.FindComponent('image' + inttostr(I))).Left := img_arr_position[I];

    if Top < snapValue then
    begin
      Top := -(Height - VisHeight) - 5;

      Left := Screen.Width div 2 - Width div 2;
    end;

  end
  else if Top < snapValue then
    Top := 0;
  Invalidate; // 竟然内存泄漏

  if DwmCompositionEnabled then
  else
  begin
    begin
      AlphaBlend := true;

      self.Parent.Perform(WM_ERASEBKGND, h, 0);
      BitBlt(Form1.Canvas.Handle, 0, 0, ClientWidth, ClientHeight, h, self.Left, self.Top, SRCCOPY);
    end;
  end;

  //inherited;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  form1.Left := g_core.db.syspara.GetInteger('left');
  form1.Top := g_core.db.syspara.GetInteger('top');

  SetWindowLong(Handle, GWL_EXSTYLE, GetWindowLong(Handle, GWL_EXSTYLE) and (not WS_EX_APPWINDOW));
  ShowWindow(Application.Handle, SW_HIDE);
  SetWindowPos(Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);

end;

procedure TForm1.hotkey(var Msg: tmsg);
begin
  if (Msg.message = FShowkeyid) then
    run_exe('ps.exe');

end;

procedure TForm1.Image111MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  aCompent: TComponent;
  lp: tpoint;
  I: Integer;
begin
  if (ssleft in Shift) and (click_ing = true) then
  begin

    if (X <> oldx) or (Y <> oldy) then
    begin
      oldx := X;
      oldy := Y;
      move_windows(Handle);
      g_core.db.syspara.SetVarValue('left', Left);
      g_core.db.syspara.SetVarValue('top', Top);
    end
    else
      do_click(self);

  end
  else
  begin
    GetCursorPos(lp);
    for I := 1 to pic_Num do
    begin
      aCompent := Form1.FindComponent('image' + inttostr(I));
      if aCompent = nil then
        continue;

      if i = 1 then
        img_arr[i + 1].Left := img_arr_position[i + 1] - Round((TImage(aCompent).Width - img_width) * rate)
      else
      begin
        var
        next_Compent := Form1.FindComponent('image' + inttostr(I + 1));
        if next_Compent <> nil then
          TImage(next_Compent).Left := img_arr_position[i + 1] + Round((TImage(aCompent).Width - img_width) * rate);

        var
        pre_Compent := Form1.FindComponent('image' + inttostr(I - 1));
        if pre_Compent <> nil then
          TImage(pre_Compent).Left := img_arr_position[i - 1] - Round((TImage(aCompent).Width - img_width) * rate)
      end;

      a := TImage(aCompent).Left - ScreenToClient(lp).X + TImage(aCompent).Width / 2;
      b := ScreenToClient(lp).Y - TImage(aCompent).Top - TImage(aCompent).Height / 2;

      rate := 1 - sqrt(a * a + b * b) / 350;

      if (rate < 0.5) then
        rate := 0.5;

      TImage(aCompent).Width := Round(Original_HeightWidth * rate);
      TImage(aCompent).Height := Round(Original_HeightWidth * rate);
    end;
  end;
end;

procedure TForm1.FormDestroy(Sender: TObject);
var i:integer;
begin
  UnregisterHotKey(Handle, FShowkeyid);
  GlobalDeleteAtom(FShowkeyid);

  ReleaseDC(0, h);

//   for I := 1 to pic_Num do
//  begin
//  if img_arr[i]<>nil then
//
//   FreeAndNil( img_arr[i]);//.Free;
//  end;

end;

procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  click_ing := true;
  oldy := Y;
  oldx := X;

end;

procedure tform1.move_windows(h: thandle);
begin

  ReleaseCapture; // 释放鼠标控制区域
  SendMessage(h, WM_SYSCOMMAND, SC_MOVE + HTCaption, 0); // 发送移动标题栏消息

end;

end.
