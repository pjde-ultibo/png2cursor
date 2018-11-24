unit uMouseThread;

{$mode objfpc}{$H+}
{$hints off}

interface

uses
  Classes, SysUtils, Mouse;

type

  TMouseBtnEvent = procedure (BtnNo : integer; x, y : LongInt);
  TMouseEvent = procedure (x, y : LongInt);

  { TMouseThread }
  TMouseThread = class (TThread)
  private
    FOnMouseDown : TMouseBtnEvent;
    FOnMouseMove : TMouseEvent;
    FOnMouseUp : TMouseBtnEvent;
    MouseData : TMouseData;
    CursorX : LongInt;
    CursorY : LongInt;
    Buttons : array [1 .. 6] of boolean;
    procedure DoMouseUp (BtnNo : integer; x, y : LongInt);
    procedure DoMouseDown (BtnNo : integer; x, y : LongInt);
    procedure DoMouseMove (x, y : LongInt);
  protected
    procedure Execute; override;
  public
    procedure LoadCursor (fn : string); overload; // load cursor from file
    procedure LoadCursor (s : TStream); overload; // load cursor from stream
    procedure Start;
    constructor Create (x, y : LongWord);
    property OnMouseUp : TMouseBtnEvent read FOnMouseUp write FOnMouseUp;
    property OnMouseDown : TMouseBtnEvent read FOnMouseDown write FOnMouseDown;
    property OnMouseMove : TMouseEvent read FOnMouseMove write FOnMouseMove;

  end;

implementation

uses uLog, FPImage, FPReadPNG, Platform, GlobalConst, HeapManager;

//const
//  du : array [boolean] of string = ('DOWN', 'UP');

{ TMouseThread }

procedure TMouseThread.DoMouseUp (BtnNo: integer; x, y: LongInt);
begin
  if Assigned (FOnMouseUp) then FOnMouseUp (BtnNo, x, y);
end;

procedure TMouseThread.DoMouseDown (BtnNo: integer; x, y: LongInt);
begin
  if Assigned (FOnMouseDown) then FOnMouseDown (BtnNo, x, y);
end;

procedure TMouseThread.DoMouseMove (x, y: LongInt);
begin
  if Assigned (FOnMouseMove) then FOnMouseMove (x, y);
end;

procedure TMouseThread.Execute;
var
  i : integer;
  Current : array [1..6] of boolean;
  Count : LongWord;
begin
  while not Terminated do
    begin
      Count := 0;
      if MouseRead (@MouseData, SizeOf (TMouseData), Count) = ERROR_SUCCESS then
        begin
          CursorX := CursorX + MouseData.OffsetX;
          if CursorX < 0 then CursorX := 0;
          CursorY := CursorY + MouseData.OffsetY;
          if CursorY < 0 then CursorY := 0;
          Current[1] := (MouseData.Buttons and MOUSE_LEFT_BUTTON) > 0;
          Current[2] := (MouseData.Buttons and MOUSE_RIGHT_BUTTON) > 0;
          Current[3] := (MouseData.Buttons and MOUSE_MIDDLE_BUTTON) > 0;
          Current[4] := (MouseData.Buttons and MOUSE_SIDE_BUTTON) > 0;
          Current[5] := (MouseData.Buttons and MOUSE_EXTRA_BUTTON) > 0;
          Current[6] := (MouseData.Buttons and MOUSE_TOUCH_BUTTON) > 0;
          for i := 1 to 6 do
            begin
              if Current[i] <> Buttons[i] then
                begin
//                  Log ('Button ' + i.ToString + ' ' + du[Current[i]]);
                  Buttons[i] := Current[i];
                  if Buttons[i] then DoMouseDown (i, CursorX, CursorY)
                  else DoMouseUp (i, CursorX, CursorY);
                end;
            end;
          DoMouseMove (CursorX, CursorY);
          CursorSetState (true, CursorX, CursorY, false);
        end;
    end;
end;

constructor TMouseThread.Create (x, y : LongWord);
var
  i : integer;
begin
  inherited Create (true);
  CursorX := x;
  CursorY := y;
  for i := 1 to 6 do Buttons[i] := false;

  Start;
end;

procedure TMouseThread.LoadCursor (fn: string);
var
  f : TFileStream;
begin
  try
    f := TFileStream.Create (fn, fmOpenRead);
    LoadCursor (f);
    f.Free;
  finally
  end;

end;

procedure TMouseThread.LoadCursor (s: TStream);
var
  im : TFPCustomImage;
  i, j : LongWord;
  Size : LongWord;
  Cursor : PLongWord;
  Address  :LongWord;

begin
  im := TFPMemoryImage.Create (0,0);
  try
    im.LoadFromStream (s);
    if (im.Width > 0) and (im.Height > 0) then
      begin
        Size := im.Width * im.Height * 4;
        case BoardGetType of
          BOARD_TYPE_RPIA,
          BOARD_TYPE_RPIB,
          BOARD_TYPE_RPIA_PLUS,
          BOARD_TYPE_RPIB_PLUS,
          BOARD_TYPE_RPI_ZERO : Cursor := AllocSharedMem (Size);
          BOARD_TYPE_RPI2B,
          BOARD_TYPE_RPI3B    : Cursor := AllocNoCacheMem (Size);
          else                  Cursor := nil;
          end;
        if Cursor <> nil then
          begin
            for i := 0 to im.Width - 1do
              for j := 0 to im.Height - 1 do
                begin
                  Cursor[i + (j * im.Width)] :=
                    ((im.Colors[i, j].alpha div $100) shl 24) +
                    ((im.Colors[i, j].red div $100) shl 16) +
                    ((im.Colors[i, j].green div $100) shl 8) +
                     (im.Colors[i, j].blue div $100);
                end;
            Address := PhysicalToBusAddress (Cursor);
            CursorSetInfo (im.Width, im.Height, 0, 0, Pointer (Address), Size);
            FreeMem (Cursor);
          end;
      end;
  except on e: exception do
    Log ('Image Load Error ' + e.Message);
    end;
  im.free;
end;

procedure TMouseThread.Start;
begin
  CursorSetState (true, CursorX, CursorY, false);
  inherited Start;
end;


end.

