unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Math,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Winapi.ShellAPI, Vcl.ComCtrls, Vcl.Grids, Vcl.ValEdit, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Buttons, System.IniFiles, Vcl.Imaging.pngimage, System.JSON,
  ImgButton, System.Generics.Collections, Vcl.Menus, Winapi.Dwmapi,
  winapi.UxTheme, ImgPanel, Vcl.Mask, System.Hash, System.ImageList, Vcl.ImgList;

type
  TForm1 = class(TForm)
    ScrollBox1: TScrollBox;
    Panel1: TPanel;
    procedure FormShow(Sender: TObject);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
  private
    procedure PanelMouseEnter(Sender: TObject);
    procedure PanelMouseLeave(Sender: TObject);
    procedure show_aapp(Path, FileName: string);

    procedure closebtnClick(Sender: TObject);
    procedure resetbtnClick(Sender: TObject);
    procedure PanelExeClick(sender: TObject);
    { Private declarations }
  public
    { Public declarations }
  end;

  TStartMenuApp = record
    Name: string;
    Path: string;
  end;

  TStartMenuApps = class
  public
    class function GetApps: TArray<TStartMenuApp>;
  end;

var
  Form1: TForm1;
  closebtn: TImgButton;
  resetbtn: TImgButton;

const
  dllName = './Project7.dll';

function GetStartMenuApps: pchar; cdecl; external './startMenuApps.dll';

function SystemShutdown(reboot: Boolean): boolean; stdcall; external dllName;

         //��ʼ��ť
function OpenStartOnMonitor(): boolean; stdcall; external dllName;

implementation

{$R *.dfm}

procedure TForm1.show_aapp(Path, FileName: string);
var
  Panel: TImgPanel;
  Image: TImage;
  Label1: TLabel;
  FileIcon: TIcon;
  FilePath: string;
begin
  FilePath := Path; // 'C:\Windows\System32\notepad.exe';


  FileIcon := TIcon.Create;
  try
    // ��ȡͼ��   GetFileIcon1(PChar(FilePath));//
    FileIcon.Handle := ExtractIcon(HInstance, PChar(FilePath), 0);

    ScrollBox1.VertScrollBar.Visible := True;  // ���ô�ֱ������

    // ����һ��Panel����ʾͼ����ı�
    Panel := TImgPanel.Create(Scrollbox1);
    Panel.Parent := ScrollBox1;

    Panel.Align := alTop;
    Panel.Height := 60;  // ����Panel�ĸ߶�
    Panel.BevelOuter := bvNone; // ��ѡ���Ƴ��߿�
    Panel.ParentColor := False;
    Panel.StyleElements := [seClient];
    Panel.extendA := FileName;
    Panel.extendB := Path; //
    // ������ʾͼ���Image�ؼ�
    Image := TImage.Create(Self);
    Image.Parent := Panel;
    Image.Picture.Icon := FileIcon;
    Image.Width := 32;   // ����ͼ��Ĵ�С
    Image.Height := 32;

    // ������ʾ�ı���Label�ؼ�
    Label1 := TLabel.Create(Self);
    Label1.Parent := Panel;
    Label1.Caption := FileName;
    Label1.AutoSize := True;

//    // �ֶ�����Image��Label��λ��ʹ���Ǿ���
//    Image.Left := (Panel.Width - Image.Width - Label1.Width - 10) div 2;
//    Image.Top := (Panel.Height - Image.Height) div 2;
//
//    Label1.Left := Image.Left + Image.Width + 10;  // ͼ����ı�֮��ļ��
//    Label1.Top := (Panel.Height - Label1.Height) div 2;


    Image.Left := 10; // (Panel.Width - Image.Width - Label1.Width - 10) div 2;  // ͼ�����
    Image.Top := (Panel.Height - Image.Height) div 2;  // ͼ�괹ֱ����
//
    Label1.Left := Image.Left + Image.Width + 10;  // ͼ����ı�֮��ļ��
    Label1.Top := (Panel.Height - Label1.Height) div 2;  // �ı���ֱ����

     // ��������¼��������
    Panel.OnMouseEnter := PanelMouseEnter;
    Panel.OnMouseLeave := PanelMouseLeave;
    Panel.ParentBackground := False;
    Panel.OnClick := PanelExeClick;
  finally
    FileIcon.Free;
  end;

end;

procedure TForm1.FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  if WheelDelta < 0 then
    ScrollBox1.Perform(WM_VSCROLL, SB_LINEDOWN, 0)
  else
    ScrollBox1.Perform(WM_VSCROLL, SB_LINEUP, 0);
  if ActiveControl is TComboBox then
    if not TComboBox(ActiveControl).DroppedDown then
      Handled := True;
end;

procedure SetWindowCornerPreference(hWnd: hWnd);
var
  cornerPreference: Integer;
begin
  cornerPreference := DWMWCP_ROUND;  // ����ΪԲ��

  // ���� DwmSetWindowAttribute API ���ô��ڵĽ���ƫ��
  if DwmSetWindowAttribute(hWnd, DWMWA_WINDOW_CORNER_PREFERENCE, @cornerPreference, SizeOf(cornerPreference)) <> S_OK then
  begin

  end;
end;

function GetTaskBarHandle: hWnd;
begin
  Result := FindWindow('Shell_TrayWnd', nil);  // Find the taskbar window handle
end;

procedure TForm1.FormShow(Sender: TObject);
var
  Apps: TArray<TStartMenuApp>;
  App: TStartMenuApp;
var
  ScreenHeight, TaskbarHeight: Integer;
  TaskbarPosition: TRect;
begin
  // Get screen height
  ScreenHeight := GetSystemMetrics(SM_CYSCREEN);

  // Get taskbar position (you might need to check if it's on top, left, right, or bottom)
  if GetWindowRect(GetTaskBarHandle, TaskbarPosition) then
  begin
    TaskbarHeight := TaskbarPosition.Bottom - TaskbarPosition.Top;

    // Position window to be on the left and just above the taskbar
    Left := 5;  // Position on the left side of the screen
    Top := TaskbarHeight + (ScreenHeight div 10); // ScreenHeight - TaskbarHeight - (ScreenHeight div 10);  // 60% screen height from the top, leaving space for the taskbar
    Height := ScreenHeight - TaskbarHeight - Top;  // 60% of screen height

    // Optionally set the width of the window
    Width := 300;  // Adjust width as per your design
  end;
  Apps := TStartMenuApps.GetApps;
  for App in Apps do

    show_aapp(App.Path, App.Name);

  SetWindowCornerPreference(Handle);

  closebtn := TImgButton.Create(self);
  closebtn.Parent := Panel1;
  closebtn.SetBounds(width - 42, 0, 32, 32);
  closebtn.Image.LoadFromFile(ExtractFilePath(ParamStr(0)) + '/imgapp/close_hover.png');
  closebtn.Image1.LoadFromFile(ExtractFilePath(ParamStr(0)) + '/imgapp/close.png');
  closebtn.OnClick := closebtnClick;

  resetbtn := TImgButton.Create(self);
  resetbtn.Parent := Panel1;
  resetbtn.SetBounds(width - 82, 0, 32, 32);
  resetbtn.Image.LoadFromFile(ExtractFilePath(ParamStr(0)) + '/imgapp/reset_hover.png');
  resetbtn.Image1.LoadFromFile(ExtractFilePath(ParamStr(0)) + '/imgapp/reset.png');
  resetbtn.OnClick := resetbtnClick;
end;

procedure TForm1.PanelExeClick(sender: TObject);
var
  s: string;
begin
  s := TImgPanel(sender).extendB;
  ShellExecute(handle, 'open', PChar(s), nil, nil, SW_ShowNormal);
end;

procedure TForm1.resetbtnClick(Sender: TObject);
begin
  SystemShutdown(True);
end;

procedure TForm1.closebtnClick(Sender: TObject);
begin
  SystemShutdown(false);
end;

procedure TForm1.PanelMouseEnter(Sender: TObject);
begin
  (Sender as TImgPanel).color := $f5f5f5;

end;

procedure TForm1.PanelMouseLeave(Sender: TObject);
begin

  (Sender as TImgPanel).color := clBtnFace;

end;

class function TStartMenuApps.GetApps: TArray<TStartMenuApp>;
var
  AppsJSON: string;
  JSONArray: TJSONArray;
  JSONValue: TJSONValue;
  App: TStartMenuApp;
  AppList: TArray<TStartMenuApp>;
  I: Integer;
begin
  // Call DLL function
  AppsJSON := string(GetStartMenuApps);

  // Parse JSON string
  JSONArray := TJSONObject.ParseJSONValue(AppsJSON) as TJSONArray;
  try
    SetLength(AppList, JSONArray.Count);
    for I := 0 to JSONArray.Count - 1 do
    begin
      JSONValue := JSONArray.Items[I];
      App.Name := JSONValue.GetValue<string>('name');
      App.Path := JSONValue.GetValue<string>('path');
      AppList[I] := App;
    end;
  finally
    JSONArray.Free;
  end;

  Result := AppList;
end;

end.

