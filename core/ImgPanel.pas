unit ImgPanel;

interface

uses
    Types, ExtCtrls, Windows, Messages, Graphics, Controls, Classes, SysUtils;
type

    TImgPanel = class(TCustomPanel)
    private
        FPicture : TPicture;
        FTransparent : Boolean;
        FAutoSize : Boolean;
        FCaptionPosX: Integer;
        FCaptionPosY: Integer;

        FLastDrawCaptionRect : TRect;
        FStretch: boolean;
        FTitleBar: boolean;

        procedure ApplyAutoSize();
        procedure ApplyTransparent();
        procedure SetPicture(const Value: TPicture);
        procedure SetAutoSize(const Value: Boolean); reintroduce;
        procedure SetCaptionPosX(const Value: Integer);
        procedure SetCaptionPosY(const Value: Integer);
        procedure CMTEXTCHANGED(var Msg : TMessage); message CM_TEXTCHANGED;
        procedure WMERASEBKGND(var Msg : TMessage); message WM_ERASEBKGND;
        procedure SetStretch(const Value: boolean);
        procedure SetTitleBar(const Value: boolean);

    protected
        procedure Paint(); override;
        procedure ClearPanel(); virtual;
        procedure RepaintText(Rect : TRect); virtual;
        procedure PictureChanged(Sender: TObject); virtual;
        procedure SetTransparent(const Value: Boolean); virtual;
        procedure Resize(); override;

        procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;

    public
         extendA,extendB:string;
        constructor Create(AOwner: TComponent); override;
        destructor Destroy(); override;
        property CaptionPosX : Integer read FCaptionPosX write SetCaptionPosX;
        property CaptionPosY : Integer read FCaptionPosY write SetCaptionPosY;
    published
        property BevelOuter;
        property BevelInner;
        property BiDiMode;
        property BorderWidth;
        property Anchors;
        property Picture : TPicture read FPicture write SetPicture;
        property Transparent : Boolean Read FTransparent Write SetTransparent default false;
        property AutoSize : Boolean Read FAutoSize Write SetAutoSize;
        property Stretch :boolean read FStretch write SetStretch;
        property Parentfont;
        property Alignment;
        property Align;
        property Font;
        property TabStop;
        property TabOrder;
        property Caption;
        property Color;
        property Visible;
        property PopupMenu;

         property OnMouseLeave;
    property OnMouseEnter;

        property ParentColor;
        property OnCanResize;
        property OnClick;
        property OnConstrainedResize;
        property OnDockDrop;
        property OnDockOver;
        property OnDblClick;
        property OnDragDrop;
        property OnDragOver;
        property OnEndDock;
        property OnEndDrag;
        property OnEnter;
        property OnExit;
        property OnGetSiteInfo;
        property OnMouseDown;
        property OnMouseMove;
        property OnMouseUp;
        property OnResize;
        property OnStartDock;
        property OnStartDrag;
        property OnUnDock;
        property TitleBar :boolean read FTitleBar write SetTitleBar;

    end;

implementation

{ TsuiCustomPanel }
procedure DoTrans(Canvas : TCanvas; Control : TWinControl);
var
    DC : HDC;
    SaveIndex : HDC;
    Position: TPoint;
begin
    if Control.Parent <> nil then
    begin
{$R-}
        DC := Canvas.Handle;
        SaveIndex := SaveDC(DC);
        GetViewportOrgEx(DC, Position);
        SetViewportOrgEx(DC, Position.X - Control.Left, Position.Y - Control.Top, nil);
        IntersectClipRect(DC, 0, 0, Control.Parent.ClientWidth, Control.Parent.ClientHeight);
        Control.Parent.Perform(WM_ERASEBKGND, DC, 0);
        Control.Parent.Perform(WM_PAINT, DC, 0);
        RestoreDC(DC, SaveIndex);
{$R+}
    end;
end;

procedure TImgPanel.ApplyAutoSize;
begin
    if FAutoSize then
    begin
        if (
            (Align <> alTop) and
            (Align <> alBottom) and
            (Align <> alClient)
        ) then
            Width := FPicture.Width;

        if (
            (Align <> alLeft) and
            (Align <> alRight) and
            (Align <> alClient)
        ) then
            Height := FPicture.Height;
    end;
end;

procedure TImgPanel.ApplyTransparent;
begin
    if FPicture.Graphic.Transparent <> FTransparent then
        FPicture.Graphic.Transparent := FTransparent;
end;

procedure TImgPanel.ClearPanel;
begin
    Canvas.Brush.Color := Color;

    if ParentWindow <> 0 then
        Canvas.FillRect(ClientRect);
end;

procedure TImgPanel.CMTEXTCHANGED(var Msg: TMessage);
begin
    RepaintText(FLastDrawCaptionRect);
    Repaint();
end;

constructor TImgPanel.Create(AOwner: TComponent);
begin
    inherited Create(AOwner);

    FPicture := TPicture.Create();
    ASSERT(FPicture <> nil);

    FPicture.OnChange := PictureChanged;
    FCaptionPosX := -1;
    FCaptionPosY := -1;

    BevelInner := bvNone;
    BevelOuter := bvNone;

    Repaint();

end;

destructor TImgPanel.Destroy;
begin
    if FPicture <> nil then
    begin
        FPicture.Free();
        FPicture := nil;
    end;

    inherited;
end;

procedure TImgPanel.Paint;
var
    uDrawTextFlag : Cardinal;
    Rect : TRect;
    Buf : TBitmap;
begin
    Buf := TBitmap.Create();
    Buf.Height := Height;
    Buf.Width := Width;

    if FTransparent then
        DoTrans(Buf.Canvas, self);

    if Assigned(FPicture.Graphic) then
    begin
        if Stretch then
            Buf.Canvas.StretchDraw(ClientRect, FPicture.Graphic)
        else
            Buf.Canvas.Draw(0, 0, FPicture.Graphic);
    end
    else if not FTransparent then
    begin
        Buf.Canvas.Brush.Color := Color;
        Buf.Canvas.FillRect(ClientRect);
    end;

    Buf.Canvas.Brush.Style := bsClear;

    if Trim(Caption) <> '' then
    begin
        Buf.Canvas.Font := Font;

        if (FCaptionPosX <> -1) and (FCaptionPosY <> -1) then
        begin
            Buf.Canvas.TextOut(FCaptionPosX, FCaptionPosY, Caption);
            FLastDrawCaptionRect := Classes.Rect(
                FCaptionPosX,
                FCaptionPosY,
                FCaptionPosX + Buf.Canvas.TextWidth(Caption),
                FCaptionPosY + Buf.Canvas.TextWidth(Caption)
            );
        end
        else
        begin
            Rect := ClientRect;
            uDrawTextFlag := DT_CENTER;
            if Alignment = taRightJustify then
                uDrawTextFlag := DT_RIGHT
            else if Alignment = taLeftJustify then
                uDrawTextFlag := DT_LEFT;
            DrawText(Buf.Canvas.Handle, PChar(Caption), -1, Rect, uDrawTextFlag or DT_SINGLELINE or DT_VCENTER);
            FLastDrawCaptionRect := Rect;
        end;
    end;

    BitBlt(Canvas.Handle, 0, 0, Width, Height, Buf.Canvas.Handle, 0, 0, SRCCOPY);    
    Buf.Free();
end;

procedure TImgPanel.PictureChanged(Sender: TObject);
begin
    if FPicture.Graphic <> nil then
    begin
        if FAutoSize then
            ApplyAutoSize();
        ApplyTransparent();
    end;

    ClearPanel();
    RePaint();
end;

procedure TImgPanel.RepaintText(Rect: TRect);
begin
    // not implete
end;

procedure TImgPanel.Resize;
begin
    inherited;

    Repaint();
end;

procedure TImgPanel.SetAutoSize(const Value: Boolean);
begin
    FAutoSize := Value;

    if FPicture.Graphic <> nil then
        ApplyAutoSize();
end;

procedure TImgPanel.SetCaptionPosX(const Value: Integer);
begin
    FCaptionPosX := Value;

    RePaint();
end;

procedure TImgPanel.SetCaptionPosY(const Value: Integer);
begin
    FCaptionPosY := Value;

    RePaint();
end;

procedure TImgPanel.SetPicture(const Value: TPicture);
begin
    FPicture.Assign(Value);

    ClearPanel();
    Repaint();
end;

procedure TImgPanel.SetStretch(const Value: boolean);
begin
  FStretch := Value;
end;

procedure TImgPanel.SetTitleBar(const Value: boolean);
begin
  FTitleBar := Value;
end;

procedure TImgPanel.SetTransparent(const Value: Boolean);
begin
    FTransparent := Value;

    if FPicture.Graphic <> nil then
        ApplyTransparent();
    Repaint();
end;

procedure TImgPanel.WMERASEBKGND(var Msg: TMessage);
begin
    // do nothing;
end;

procedure TImgPanel.WMNCHitTest(var Message: TWMNCHitTest);
var
    pt:tpoint;
    pt1:tpoint;
begin
  inherited;
    {if FTitleBar then
    begin
        pt.X:=Message.XPos;
        pt.Y:=Message.YPos;
        pt:=ScreenToClient(pt);

        if ptInRect(ClientRect,pt) then
        begin
            Message.result:=HTCAPTION ;
        end;
    end;  }

end;

end.
