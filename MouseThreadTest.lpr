program MouseThreadTest;

{$mode objfpc}{$H+}
{$define use_tftp}
{
   Generic Mouse / Cursor unit
   2018 pjde
}

uses
  RaspberryPi3,
  GlobalConfig,
  GlobalConst,
  GlobalTypes,
  Platform,
  Threads,
  SysUtils,
  Classes,
  Console, uLog,
{$ifdef use_tftp}
  uTFTP, Winsock2,
{$endif}
  Ultibo, uMouseThread
  { Add additional units here };

var
  Console1, Console2, Console3 : TWindowHandle;
  ch : char;
  MouseThread : TMouseThread;
{$ifdef use_tftp}
  IPAddress : string;
{$endif}

procedure Log1 (s : string);
begin
  ConsoleWindowWriteLn (Console1, s);
end;

procedure Log2 (s : string);
begin
  ConsoleWindowWriteLn (Console2, s);
end;

procedure Log3 (s : string);
begin
  ConsoleWindowWriteLn (Console3, s);
end;

procedure Msg2 (Sender : TObject; s : string);
begin
  Log2 (s);
end;

procedure WaitForSDDrive;
begin
  while not DirectoryExists ('C:\') do sleep (500);
end;

procedure DoMouseUp (BtnNo : integer; x, y : LongInt);
begin
  ConsoleWindowSetXY (Console3, 1, 1);
  Log3 ('Btn ' + BtnNo.ToString + ' UP @ ' + x.ToString + ',' + y.ToString + '    ');

end;

procedure DoMouseDown (BtnNo : integer; x, y : LongInt);
begin
  ConsoleWindowSetXY (Console3, 1, 1);
  Log3 ('Btn ' + BtnNo.ToString + ' DOWN @ ' + x.ToString + ',' + y.ToString + '    ');
end;

procedure DoMouseMove (x, y : LongInt);
begin
  ConsoleWindowSetXY (Console3, 1, 2);
  Log3 ('Mouse MOVE @ ' + x.ToString + ',' + y.ToString + '    ');
end;

{$ifdef use_tftp}
function WaitForIPComplete : string;
var
  TCP : TWinsock2TCPClient;
begin
  TCP := TWinsock2TCPClient.Create;
  Result := TCP.LocalAddress;
  if (Result = '') or (Result = '0.0.0.0') or (Result = '255.255.255.255') then
    begin
      while (Result = '') or (Result = '0.0.0.0') or (Result = '255.255.255.255') do
        begin
          sleep (1000);
          Result := TCP.LocalAddress;
        end;
    end;
  TCP.Free;
end;
{$endif}

begin
  Console1 := ConsoleWindowCreate (ConsoleDeviceGetDefault, CONSOLE_POSITION_LEFT, true);
  Console2 := ConsoleWindowCreate (ConsoleDeviceGetDefault, CONSOLE_POSITION_TOPRIGHT, false);
  Console3 := ConsoleWindowCreate (ConsoleDeviceGetDefault, CONSOLE_POSITION_BOTTOMRIGHT, false);
  SetLogProc (@Log1);
  Log1 ('Mouse / Cursor Test.');
  WaitForSDDrive;
  Log1 ('SD Drive Ready.');

{$ifdef use_tftp}
  IPAddress := WaitForIPComplete;
  Log2 ('TFP Syntax : tftp -i ' + IPAddress + ' put kernel7.img');
  SetOnMsg (@Msg2);
{$endif}

  ch := #0;
  MouseThread := TMouseThread.Create (0, 0);
  MouseThread.LoadCursor ('cursor-32.png');
  MouseThread.OnMouseDown := @DoMouseDown;
  MouseThread.OnMouseUp := @DoMouseUp;
  MouseThread.OnMouseMove := @DoMouseMove;
  MouseThread.Start;
  while true do
    begin
      if ConsoleReadChar (ch, nil) then
        case (ch) of
          'C', 'c' : ConsoleWindowClear (Console1);
        end;
    end;
  ThreadHalt (0);

end.

