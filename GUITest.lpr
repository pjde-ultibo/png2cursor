program GUITest;

{$mode delphi}
{$define use_tftp}
{$H+}

{ Todo

Where to begin.

Text vertical alignment needs work }


uses
  RaspberryPi3,
  GlobalConfig,
  GlobalConst,
  GlobalTypes,
  Platform,
  Threads,
  SysUtils,
  Classes,
  Console, GraphicsConsole,
  uMiniParser,
  uGUIControls,
  uFontInfo,
  FPReadPNG,
  uLog,
  FPImage,
  FrameBuffer,
  HeapManager,
  Mouse,
  Keyboard,
{$ifdef use_tftp}
  uTFTP, Winsock2,
{$endif}
  Ultibo
  { Add additional units here };

type

  { TPointerThread }

  TPointerThread = class (TThread)
    MouseData : TMouseData;
    CursorX : LongInt;
    CursorY : LongInt;
    Count : LongWord;
    Buttons : array [1 .. 6] of boolean;
    constructor Create (x, y : LongWord);
    procedure Execute; override;
  end;

var
  Console1, Console2, Console3 : TWindowHandle;
  ch : char;
  Pages : TPages;
  Images : TImageLib;
  GUI : TGUI;
  aPage : TMainPage;
  f : TFileStream;
  i : integer;
  im : TFPCustomImage;
  DefFrameBuff : PFrameBufferDevice;
  Properties : TWindowProperties;
  fi : TFontInfo;
  sz : integer;
  KB : PKeyboardDevice;
  PointerThread : TPointerThread;




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


{See the main program below for more info about what this function is for}
procedure CreateCursor;
var
  Row : LongWord;
  Col  :LongWord;
  Offset : LongWord;
  Size : LongWord;
  Cursor : PLongWord;
  Address  :LongWord;
begin
  {Make our cursor 32 x 32 pixels, each pixel is 4 bytes}
  Size := 32 * 32 * 4;
  {Allocate a block of memory to create our new mouse cursor.
   For different versions of the Raspberry Pi we need to allocate different
   types of memory when communicating with the graphics processor (GPU).
   Check what type of Raspberry Pi we have}
  case BoardGetType of
    BOARD_TYPE_RPIA,
    BOARD_TYPE_RPIB,
    BOARD_TYPE_RPIA_PLUS,
    BOARD_TYPE_RPIB_PLUS,
    BOARD_TYPE_RPI_ZERO :
      begin
        {We have an A/B/A+/B+ or Zero}
        {Allocate some Shared memory for our cursor}
        Cursor := AllocSharedMem (Size);
      end;
    BOARD_TYPE_RPI2B,
    BOARD_TYPE_RPI3B :
      begin
        {We have a 2B or 3B}
        {Allocate some No Cache memory instead}
        Cursor := AllocNoCacheMem (Size);
      end;
    else
      begin
        {No idea what board this is}
        Cursor := nil;
      end;
  end;

  {Check if we allocated some memory for our cursor}
  if Cursor <> nil then
    begin
      Cursor[0000] := $00000000; Cursor[0001] := $00000000; Cursor[0002] := $00000000; Cursor[0003] := $00000000; Cursor[0004] := $00000000; Cursor[0005] := $00000000; Cursor[0006] := $6E000000; Cursor[0007] := $DF000000;
      Cursor[0008] := $D9000000; Cursor[0009] := $4E000000; Cursor[0010] := $00000000; Cursor[0011] := $00000000; Cursor[0012] := $00000000; Cursor[0013] := $00000000; Cursor[0014] := $00000000; Cursor[0015] := $00000000;
      Cursor[0016] := $00000000; Cursor[0017] := $00000000; Cursor[0018] := $00000000; Cursor[0019] := $00000000; Cursor[0020] := $00000000; Cursor[0021] := $00000000; Cursor[0022] := $00000000; Cursor[0023] := $00000000;
      Cursor[0024] := $00000000; Cursor[0025] := $00000000; Cursor[0026] := $00000000; Cursor[0027] := $00000000; Cursor[0028] := $00000000; Cursor[0029] := $00000000; Cursor[0030] := $00000000; Cursor[0031] := $00000000;
      Cursor[0032] := $00000000; Cursor[0033] := $00000000; Cursor[0034] := $00000000; Cursor[0035] := $00000000; Cursor[0036] := $00000000; Cursor[0037] := $42000000; Cursor[0038] := $FF000000; Cursor[0039] := $FF000000;
      Cursor[0040] := $FF000000; Cursor[0041] := $FB000000; Cursor[0042] := $66000000; Cursor[0043] := $00000000; Cursor[0044] := $00000000; Cursor[0045] := $00000000; Cursor[0046] := $00000000; Cursor[0047] := $00000000;
      Cursor[0048] := $00000000; Cursor[0049] := $00000000; Cursor[0050] := $00000000; Cursor[0051] := $00000000; Cursor[0052] := $00000000; Cursor[0053] := $00000000; Cursor[0054] := $00000000; Cursor[0055] := $00000000;
      Cursor[0056] := $00000000; Cursor[0057] := $00000000; Cursor[0058] := $00000000; Cursor[0059] := $00000000; Cursor[0060] := $00000000; Cursor[0061] := $00000000; Cursor[0062] := $00000000; Cursor[0063] := $00000000;
      Cursor[0064] := $00000000; Cursor[0065] := $00000000; Cursor[0066] := $00000000; Cursor[0067] := $00000000; Cursor[0068] := $00000000; Cursor[0069] := $78000000; Cursor[0070] := $FF000000; Cursor[0071] := $F9000000;
      Cursor[0072] := $E5000000; Cursor[0073] := $FF000000; Cursor[0074] := $FF000000; Cursor[0075] := $7A000000; Cursor[0076] := $00000000; Cursor[0077] := $00000000; Cursor[0078] := $00000000; Cursor[0079] := $00000000;
      Cursor[0080] := $00000000; Cursor[0081] := $00000000; Cursor[0082] := $00000000; Cursor[0083] := $00000000; Cursor[0084] := $00000000; Cursor[0085] := $00000000; Cursor[0086] := $00000000; Cursor[0087] := $00000000;
      Cursor[0088] := $00000000; Cursor[0089] := $00000000; Cursor[0090] := $00000000; Cursor[0091] := $00000000; Cursor[0092] := $00000000; Cursor[0093] := $00000000; Cursor[0094] := $00000000; Cursor[0095] := $00000000;
      Cursor[0096] := $00000000; Cursor[0097] := $00000000; Cursor[0098] := $00000000; Cursor[0099] := $00000000; Cursor[0100] := $00000000; Cursor[0101] := $7C000000; Cursor[0102] := $FF000000; Cursor[0103] := $F1000000;
      Cursor[0104] := $22000000; Cursor[0105] := $DD000000; Cursor[0106] := $FF000000; Cursor[0107] := $FF000000; Cursor[0108] := $8D000000; Cursor[0109] := $00000000; Cursor[0110] := $00000000; Cursor[0111] := $00000000;
      Cursor[0112] := $00000000; Cursor[0113] := $00000000; Cursor[0114] := $00000000; Cursor[0115] := $00000000; Cursor[0116] := $00000000; Cursor[0117] := $00000000; Cursor[0118] := $00000000; Cursor[0119] := $00000000;
      Cursor[0120] := $00000000; Cursor[0121] := $00000000; Cursor[0122] := $00000000; Cursor[0123] := $00000000; Cursor[0124] := $00000000; Cursor[0125] := $00000000; Cursor[0126] := $00000000; Cursor[0127] := $00000000;
      Cursor[0128] := $00000000; Cursor[0129] := $00000000; Cursor[0130] := $00000000; Cursor[0131] := $00000000; Cursor[0132] := $00000000; Cursor[0133] := $7E000000; Cursor[0134] := $FF000000; Cursor[0135] := $F1000000;
      Cursor[0136] := $00000000; Cursor[0137] := $1A000000; Cursor[0138] := $D5000000; Cursor[0139] := $FF000000; Cursor[0140] := $FF000000; Cursor[0141] := $9F000000; Cursor[0142] := $04000000; Cursor[0143] := $00000000;
      Cursor[0144] := $00000000; Cursor[0145] := $00000000; Cursor[0146] := $00000000; Cursor[0147] := $00000000; Cursor[0148] := $00000000; Cursor[0149] := $00000000; Cursor[0150] := $00000000; Cursor[0151] := $00000000;
      Cursor[0152] := $00000000; Cursor[0153] := $00000000; Cursor[0154] := $00000000; Cursor[0155] := $00000000; Cursor[0156] := $00000000; Cursor[0157] := $00000000; Cursor[0158] := $00000000; Cursor[0159] := $00000000;
      Cursor[0160] := $00000000; Cursor[0161] := $00000000; Cursor[0162] := $00000000; Cursor[0163] := $00000000; Cursor[0164] := $00000000; Cursor[0165] := $7E000000; Cursor[0166] := $FF000000; Cursor[0167] := $F1000000;
      Cursor[0168] := $00000000; Cursor[0169] := $00000000; Cursor[0170] := $14000000; Cursor[0171] := $C9000000; Cursor[0172] := $FF000000; Cursor[0173] := $FF000000; Cursor[0174] := $AF000000; Cursor[0175] := $08000000;
      Cursor[0176] := $00000000; Cursor[0177] := $00000000; Cursor[0178] := $00000000; Cursor[0179] := $00000000; Cursor[0180] := $00000000; Cursor[0181] := $00000000; Cursor[0182] := $00000000; Cursor[0183] := $00000000;
      Cursor[0184] := $00000000; Cursor[0185] := $00000000; Cursor[0186] := $00000000; Cursor[0187] := $00000000; Cursor[0188] := $00000000; Cursor[0189] := $00000000; Cursor[0190] := $00000000; Cursor[0191] := $00000000;
      Cursor[0192] := $00000000; Cursor[0193] := $00000000; Cursor[0194] := $00000000; Cursor[0195] := $00000000; Cursor[0196] := $00000000; Cursor[0197] := $7E000000; Cursor[0198] := $FF000000; Cursor[0199] := $F1000000;
      Cursor[0200] := $00000000; Cursor[0201] := $00000000; Cursor[0202] := $00000000; Cursor[0203] := $0E000000; Cursor[0204] := $BF000000; Cursor[0205] := $FF000000; Cursor[0206] := $FF000000; Cursor[0207] := $BD000000;
      Cursor[0208] := $0C000000; Cursor[0209] := $00000000; Cursor[0210] := $00000000; Cursor[0211] := $00000000; Cursor[0212] := $00000000; Cursor[0213] := $00000000; Cursor[0214] := $00000000; Cursor[0215] := $00000000;
      Cursor[0216] := $00000000; Cursor[0217] := $00000000; Cursor[0218] := $00000000; Cursor[0219] := $00000000; Cursor[0220] := $00000000; Cursor[0221] := $00000000; Cursor[0222] := $00000000; Cursor[0223] := $00000000;
      Cursor[0224] := $00000000; Cursor[0225] := $00000000; Cursor[0226] := $00000000; Cursor[0227] := $00000000; Cursor[0228] := $00000000; Cursor[0229] := $7E000000; Cursor[0230] := $FF000000; Cursor[0231] := $F1000000;
      Cursor[0232] := $00000000; Cursor[0233] := $00000000; Cursor[0234] := $00000000; Cursor[0235] := $00000000; Cursor[0236] := $08000000; Cursor[0237] := $B3000000; Cursor[0238] := $FF000000; Cursor[0239] := $FF000000;
      Cursor[0240] := $C9000000; Cursor[0241] := $14000000; Cursor[0242] := $00000000; Cursor[0243] := $00000000; Cursor[0244] := $00000000; Cursor[0245] := $00000000; Cursor[0246] := $00000000; Cursor[0247] := $00000000;
      Cursor[0248] := $00000000; Cursor[0249] := $00000000; Cursor[0250] := $00000000; Cursor[0251] := $00000000; Cursor[0252] := $00000000; Cursor[0253] := $00000000; Cursor[0254] := $00000000; Cursor[0255] := $00000000;
      Cursor[0256] := $00000000; Cursor[0257] := $00000000; Cursor[0258] := $00000000; Cursor[0259] := $00000000; Cursor[0260] := $00000000; Cursor[0261] := $7E000000; Cursor[0262] := $FF000000; Cursor[0263] := $F1000000;
      Cursor[0264] := $00000000; Cursor[0265] := $00000000; Cursor[0266] := $00000000; Cursor[0267] := $00000000; Cursor[0268] := $00000000; Cursor[0269] := $04000000; Cursor[0270] := $A5000000; Cursor[0271] := $FF000000;
      Cursor[0272] := $FF000000; Cursor[0273] := $D5000000; Cursor[0274] := $1A000000; Cursor[0275] := $00000000; Cursor[0276] := $00000000; Cursor[0277] := $00000000; Cursor[0278] := $00000000; Cursor[0279] := $00000000;
      Cursor[0280] := $00000000; Cursor[0281] := $00000000; Cursor[0282] := $00000000; Cursor[0283] := $00000000; Cursor[0284] := $00000000; Cursor[0285] := $00000000; Cursor[0286] := $00000000; Cursor[0287] := $00000000;
      Cursor[0288] := $00000000; Cursor[0289] := $00000000; Cursor[0290] := $00000000; Cursor[0291] := $00000000; Cursor[0292] := $00000000; Cursor[0293] := $7E000000; Cursor[0294] := $FF000000; Cursor[0295] := $F1000000;
      Cursor[0296] := $00000000; Cursor[0297] := $00000000; Cursor[0298] := $00000000; Cursor[0299] := $00000000; Cursor[0300] := $00000000; Cursor[0301] := $00000000; Cursor[0302] := $02000000; Cursor[0303] := $97000000;
      Cursor[0304] := $FF000000; Cursor[0305] := $FF000000; Cursor[0306] := $DF000000; Cursor[0307] := $24000000; Cursor[0308] := $00000000; Cursor[0309] := $00000000; Cursor[0310] := $00000000; Cursor[0311] := $00000000;
      Cursor[0312] := $00000000; Cursor[0313] := $00000000; Cursor[0314] := $00000000; Cursor[0315] := $00000000; Cursor[0316] := $00000000; Cursor[0317] := $00000000; Cursor[0318] := $00000000; Cursor[0319] := $00000000;
      Cursor[0320] := $00000000; Cursor[0321] := $00000000; Cursor[0322] := $00000000; Cursor[0323] := $00000000; Cursor[0324] := $00000000; Cursor[0325] := $7E000000; Cursor[0326] := $FF000000; Cursor[0327] := $F1000000;
      Cursor[0328] := $00000000; Cursor[0329] := $00000000; Cursor[0330] := $00000000; Cursor[0331] := $00000000; Cursor[0332] := $00000000; Cursor[0333] := $00000000; Cursor[0334] := $00000000; Cursor[0335] := $00000000;
      Cursor[0336] := $87000000; Cursor[0337] := $FF000000; Cursor[0338] := $FF000000; Cursor[0339] := $E7000000; Cursor[0340] := $2E000000; Cursor[0341] := $00000000; Cursor[0342] := $00000000; Cursor[0343] := $00000000;
      Cursor[0344] := $00000000; Cursor[0345] := $00000000; Cursor[0346] := $00000000; Cursor[0347] := $00000000; Cursor[0348] := $00000000; Cursor[0349] := $00000000; Cursor[0350] := $00000000; Cursor[0351] := $00000000;
      Cursor[0352] := $00000000; Cursor[0353] := $00000000; Cursor[0354] := $00000000; Cursor[0355] := $00000000; Cursor[0356] := $00000000; Cursor[0357] := $7E000000; Cursor[0358] := $FF000000; Cursor[0359] := $F1000000;
      Cursor[0360] := $00000000; Cursor[0361] := $00000000; Cursor[0362] := $00000000; Cursor[0363] := $00000000; Cursor[0364] := $00000000; Cursor[0365] := $00000000; Cursor[0366] := $00000000; Cursor[0367] := $00000000;
      Cursor[0368] := $00000000; Cursor[0369] := $76000000; Cursor[0370] := $FF000000; Cursor[0371] := $FF000000; Cursor[0372] := $ED000000; Cursor[0373] := $38000000; Cursor[0374] := $00000000; Cursor[0375] := $00000000;
      Cursor[0376] := $00000000; Cursor[0377] := $00000000; Cursor[0378] := $00000000; Cursor[0379] := $00000000; Cursor[0380] := $00000000; Cursor[0381] := $00000000; Cursor[0382] := $00000000; Cursor[0383] := $00000000;
      Cursor[0384] := $00000000; Cursor[0385] := $00000000; Cursor[0386] := $00000000; Cursor[0387] := $00000000; Cursor[0388] := $00000000; Cursor[0389] := $7C000000; Cursor[0390] := $FF000000; Cursor[0391] := $F1000000;
      Cursor[0392] := $00000000; Cursor[0393] := $00000000; Cursor[0394] := $00000000; Cursor[0395] := $00000000; Cursor[0396] := $00000000; Cursor[0397] := $00000000; Cursor[0398] := $00000000; Cursor[0399] := $00000000;
      Cursor[0400] := $00000000; Cursor[0401] := $00000000; Cursor[0402] := $66000000; Cursor[0403] := $FD000000; Cursor[0404] := $FF000000; Cursor[0405] := $F3000000; Cursor[0406] := $44000000; Cursor[0407] := $00000000;
      Cursor[0408] := $00000000; Cursor[0409] := $00000000; Cursor[0410] := $00000000; Cursor[0411] := $00000000; Cursor[0412] := $00000000; Cursor[0413] := $00000000; Cursor[0414] := $00000000; Cursor[0415] := $00000000;
      Cursor[0416] := $00000000; Cursor[0417] := $00000000; Cursor[0418] := $00000000; Cursor[0419] := $00000000; Cursor[0420] := $00000000; Cursor[0421] := $7C000000; Cursor[0422] := $FF000000; Cursor[0423] := $F1000000;
      Cursor[0424] := $00000000; Cursor[0425] := $00000000; Cursor[0426] := $00000000; Cursor[0427] := $00000000; Cursor[0428] := $00000000; Cursor[0429] := $00000000; Cursor[0430] := $00000000; Cursor[0431] := $00000000;
      Cursor[0432] := $00000000; Cursor[0433] := $00000000; Cursor[0434] := $00000000; Cursor[0435] := $58000000; Cursor[0436] := $F9000000; Cursor[0437] := $FF000000; Cursor[0438] := $F7000000; Cursor[0439] := $50000000;
      Cursor[0440] := $00000000; Cursor[0441] := $00000000; Cursor[0442] := $00000000; Cursor[0443] := $00000000; Cursor[0444] := $00000000; Cursor[0445] := $00000000; Cursor[0446] := $00000000; Cursor[0447] := $00000000;
      Cursor[0448] := $00000000; Cursor[0449] := $00000000; Cursor[0450] := $00000000; Cursor[0451] := $00000000; Cursor[0452] := $00000000; Cursor[0453] := $7A000000; Cursor[0454] := $FF000000; Cursor[0455] := $F1000000;
      Cursor[0456] := $00000000; Cursor[0457] := $00000000; Cursor[0458] := $00000000; Cursor[0459] := $00000000; Cursor[0460] := $00000000; Cursor[0461] := $00000000; Cursor[0462] := $00000000; Cursor[0463] := $00000000;
      Cursor[0464] := $00000000; Cursor[0465] := $00000000; Cursor[0466] := $00000000; Cursor[0467] := $00000000; Cursor[0468] := $4C000000; Cursor[0469] := $F7000000; Cursor[0470] := $FF000000; Cursor[0471] := $FB000000;
      Cursor[0472] := $5C000000; Cursor[0473] := $00000000; Cursor[0474] := $00000000; Cursor[0475] := $00000000; Cursor[0476] := $00000000; Cursor[0477] := $00000000; Cursor[0478] := $00000000; Cursor[0479] := $00000000;
      Cursor[0480] := $00000000; Cursor[0481] := $00000000; Cursor[0482] := $00000000; Cursor[0483] := $00000000; Cursor[0484] := $00000000; Cursor[0485] := $7A000000; Cursor[0486] := $FF000000; Cursor[0487] := $F1000000;
      Cursor[0488] := $00000000; Cursor[0489] := $00000000; Cursor[0490] := $00000000; Cursor[0491] := $00000000; Cursor[0492] := $00000000; Cursor[0493] := $00000000; Cursor[0494] := $00000000; Cursor[0495] := $00000000;
      Cursor[0496] := $00000000; Cursor[0497] := $00000000; Cursor[0498] := $00000000; Cursor[0499] := $00000000; Cursor[0500] := $00000000; Cursor[0501] := $40000000; Cursor[0502] := $F1000000; Cursor[0503] := $FF000000;
      Cursor[0504] := $FD000000; Cursor[0505] := $66000000; Cursor[0506] := $00000000; Cursor[0507] := $00000000; Cursor[0508] := $00000000; Cursor[0509] := $00000000; Cursor[0510] := $00000000; Cursor[0511] := $00000000;
      Cursor[0512] := $00000000; Cursor[0513] := $00000000; Cursor[0514] := $00000000; Cursor[0515] := $00000000; Cursor[0516] := $00000000; Cursor[0517] := $7A000000; Cursor[0518] := $FF000000; Cursor[0519] := $F1000000;
      Cursor[0520] := $00000000; Cursor[0521] := $00000000; Cursor[0522] := $00000000; Cursor[0523] := $00000000; Cursor[0524] := $00000000; Cursor[0525] := $00000000; Cursor[0526] := $00000000; Cursor[0527] := $00000000;
      Cursor[0528] := $00000000; Cursor[0529] := $00000000; Cursor[0530] := $00000000; Cursor[0531] := $00000000; Cursor[0532] := $00000000; Cursor[0533] := $00000000; Cursor[0534] := $36000000; Cursor[0535] := $ED000000;
      Cursor[0536] := $FF000000; Cursor[0537] := $FD000000; Cursor[0538] := $3A000000; Cursor[0539] := $00000000; Cursor[0540] := $00000000; Cursor[0541] := $00000000; Cursor[0542] := $00000000; Cursor[0543] := $00000000;
      Cursor[0544] := $00000000; Cursor[0545] := $00000000; Cursor[0546] := $00000000; Cursor[0547] := $00000000; Cursor[0548] := $00000000; Cursor[0549] := $7A000000; Cursor[0550] := $FF000000; Cursor[0551] := $F1000000;
      Cursor[0552] := $00000000; Cursor[0553] := $00000000; Cursor[0554] := $00000000; Cursor[0555] := $00000000; Cursor[0556] := $00000000; Cursor[0557] := $00000000; Cursor[0558] := $00000000; Cursor[0559] := $00000000;
      Cursor[0560] := $00000000; Cursor[0561] := $00000000; Cursor[0562] := $00000000; Cursor[0563] := $00000000; Cursor[0564] := $08000000; Cursor[0565] := $1E000000; Cursor[0566] := $36000000; Cursor[0567] := $7C000000;
      Cursor[0568] := $FF000000; Cursor[0569] := $FF000000; Cursor[0570] := $7E000000; Cursor[0571] := $00000000; Cursor[0572] := $00000000; Cursor[0573] := $00000000; Cursor[0574] := $00000000; Cursor[0575] := $00000000;
      Cursor[0576] := $00000000; Cursor[0577] := $00000000; Cursor[0578] := $00000000; Cursor[0579] := $00000000; Cursor[0580] := $00000000; Cursor[0581] := $78000000; Cursor[0582] := $FF000000; Cursor[0583] := $F3000000;
      Cursor[0584] := $00000000; Cursor[0585] := $00000000; Cursor[0586] := $00000000; Cursor[0587] := $00000000; Cursor[0588] := $00000000; Cursor[0589] := $00000000; Cursor[0590] := $00000000; Cursor[0591] := $00000000;
      Cursor[0592] := $56000000; Cursor[0593] := $BF000000; Cursor[0594] := $D7000000; Cursor[0595] := $EF000000; Cursor[0596] := $FD000000; Cursor[0597] := $FF000000; Cursor[0598] := $FF000000; Cursor[0599] := $FF000000;
      Cursor[0600] := $FF000000; Cursor[0601] := $FF000000; Cursor[0602] := $5E000000; Cursor[0603] := $00000000; Cursor[0604] := $00000000; Cursor[0605] := $00000000; Cursor[0606] := $00000000; Cursor[0607] := $00000000;
      Cursor[0608] := $00000000; Cursor[0609] := $00000000; Cursor[0610] := $00000000; Cursor[0611] := $00000000; Cursor[0612] := $00000000; Cursor[0613] := $78000000; Cursor[0614] := $FF000000; Cursor[0615] := $F3000000;
      Cursor[0616] := $00000000; Cursor[0617] := $00000000; Cursor[0618] := $00000000; Cursor[0619] := $00000000; Cursor[0620] := $00000000; Cursor[0621] := $20000000; Cursor[0622] := $00000000; Cursor[0623] := $00000000;
      Cursor[0624] := $2C000000; Cursor[0625] := $FD000000; Cursor[0626] := $FF000000; Cursor[0627] := $FF000000; Cursor[0628] := $FF000000; Cursor[0629] := $FF000000; Cursor[0630] := $FF000000; Cursor[0631] := $FF000000;
      Cursor[0632] := $FD000000; Cursor[0633] := $A1000000; Cursor[0634] := $04000000; Cursor[0635] := $00000000; Cursor[0636] := $00000000; Cursor[0637] := $00000000; Cursor[0638] := $00000000; Cursor[0639] := $00000000;
      Cursor[0640] := $00000000; Cursor[0641] := $00000000; Cursor[0642] := $00000000; Cursor[0643] := $00000000; Cursor[0644] := $00000000; Cursor[0645] := $76000000; Cursor[0646] := $FF000000; Cursor[0647] := $F5000000;
      Cursor[0648] := $00000000; Cursor[0649] := $00000000; Cursor[0650] := $00000000; Cursor[0651] := $00000000; Cursor[0652] := $76000000; Cursor[0653] := $E7000000; Cursor[0654] := $08000000; Cursor[0655] := $00000000;
      Cursor[0656] := $00000000; Cursor[0657] := $B9000000; Cursor[0658] := $FF000000; Cursor[0659] := $FF000000; Cursor[0660] := $83000000; Cursor[0661] := $5A000000; Cursor[0662] := $42000000; Cursor[0663] := $2A000000;
      Cursor[0664] := $0A000000; Cursor[0665] := $00000000; Cursor[0666] := $00000000; Cursor[0667] := $00000000; Cursor[0668] := $00000000; Cursor[0669] := $00000000; Cursor[0670] := $00000000; Cursor[0671] := $00000000;
      Cursor[0672] := $00000000; Cursor[0673] := $00000000; Cursor[0674] := $00000000; Cursor[0675] := $00000000; Cursor[0676] := $00000000; Cursor[0677] := $76000000; Cursor[0678] := $FF000000; Cursor[0679] := $F5000000;
      Cursor[0680] := $00000000; Cursor[0681] := $00000000; Cursor[0682] := $00000000; Cursor[0683] := $89000000; Cursor[0684] := $FF000000; Cursor[0685] := $FF000000; Cursor[0686] := $60000000; Cursor[0687] := $00000000;
      Cursor[0688] := $00000000; Cursor[0689] := $44000000; Cursor[0690] := $FF000000; Cursor[0691] := $FF000000; Cursor[0692] := $70000000; Cursor[0693] := $00000000; Cursor[0694] := $00000000; Cursor[0695] := $00000000;
      Cursor[0696] := $00000000; Cursor[0697] := $00000000; Cursor[0698] := $00000000; Cursor[0699] := $00000000; Cursor[0700] := $00000000; Cursor[0701] := $00000000; Cursor[0702] := $00000000; Cursor[0703] := $00000000;
      Cursor[0704] := $00000000; Cursor[0705] := $00000000; Cursor[0706] := $00000000; Cursor[0707] := $00000000; Cursor[0708] := $00000000; Cursor[0709] := $76000000; Cursor[0710] := $FF000000; Cursor[0711] := $F7000000;
      Cursor[0712] := $00000000; Cursor[0713] := $02000000; Cursor[0714] := $99000000; Cursor[0715] := $FF000000; Cursor[0716] := $FF000000; Cursor[0717] := $FF000000; Cursor[0718] := $CF000000; Cursor[0719] := $00000000;
      Cursor[0720] := $00000000; Cursor[0721] := $00000000; Cursor[0722] := $CF000000; Cursor[0723] := $FF000000; Cursor[0724] := $DF000000; Cursor[0725] := $04000000; Cursor[0726] := $00000000; Cursor[0727] := $00000000;
      Cursor[0728] := $00000000; Cursor[0729] := $00000000; Cursor[0730] := $00000000; Cursor[0731] := $00000000; Cursor[0732] := $00000000; Cursor[0733] := $00000000; Cursor[0734] := $00000000; Cursor[0735] := $00000000;
      Cursor[0736] := $00000000; Cursor[0737] := $00000000; Cursor[0738] := $00000000; Cursor[0739] := $00000000; Cursor[0740] := $00000000; Cursor[0741] := $76000000; Cursor[0742] := $FF000000; Cursor[0743] := $F9000000;
      Cursor[0744] := $06000000; Cursor[0745] := $A7000000; Cursor[0746] := $FF000000; Cursor[0747] := $FF000000; Cursor[0748] := $F5000000; Cursor[0749] := $FF000000; Cursor[0750] := $FF000000; Cursor[0751] := $3E000000;
      Cursor[0752] := $00000000; Cursor[0753] := $00000000; Cursor[0754] := $5A000000; Cursor[0755] := $FF000000; Cursor[0756] := $FF000000; Cursor[0757] := $58000000; Cursor[0758] := $00000000; Cursor[0759] := $00000000;
      Cursor[0760] := $00000000; Cursor[0761] := $00000000; Cursor[0762] := $00000000; Cursor[0763] := $00000000; Cursor[0764] := $00000000; Cursor[0765] := $00000000; Cursor[0766] := $00000000; Cursor[0767] := $00000000;
      Cursor[0768] := $00000000; Cursor[0769] := $00000000; Cursor[0770] := $00000000; Cursor[0771] := $00000000; Cursor[0772] := $00000000; Cursor[0773] := $74000000; Cursor[0774] := $FF000000; Cursor[0775] := $FB000000;
      Cursor[0776] := $B5000000; Cursor[0777] := $FF000000; Cursor[0778] := $FF000000; Cursor[0779] := $C9000000; Cursor[0780] := $22000000; Cursor[0781] := $EF000000; Cursor[0782] := $FF000000; Cursor[0783] := $AD000000;
      Cursor[0784] := $00000000; Cursor[0785] := $00000000; Cursor[0786] := $04000000; Cursor[0787] := $E1000000; Cursor[0788] := $FF000000; Cursor[0789] := $CD000000; Cursor[0790] := $00000000; Cursor[0791] := $00000000;
      Cursor[0792] := $00000000; Cursor[0793] := $00000000; Cursor[0794] := $00000000; Cursor[0795] := $00000000; Cursor[0796] := $00000000; Cursor[0797] := $00000000; Cursor[0798] := $00000000; Cursor[0799] := $00000000;
      Cursor[0800] := $00000000; Cursor[0801] := $00000000; Cursor[0802] := $00000000; Cursor[0803] := $00000000; Cursor[0804] := $00000000; Cursor[0805] := $5C000000; Cursor[0806] := $FF000000; Cursor[0807] := $FF000000;
      Cursor[0808] := $FF000000; Cursor[0809] := $FF000000; Cursor[0810] := $BD000000; Cursor[0811] := $0C000000; Cursor[0812] := $00000000; Cursor[0813] := $8F000000; Cursor[0814] := $FF000000; Cursor[0815] := $FB000000;
      Cursor[0816] := $20000000; Cursor[0817] := $00000000; Cursor[0818] := $00000000; Cursor[0819] := $70000000; Cursor[0820] := $FF000000; Cursor[0821] := $FF000000; Cursor[0822] := $42000000; Cursor[0823] := $00000000;
      Cursor[0824] := $00000000; Cursor[0825] := $00000000; Cursor[0826] := $00000000; Cursor[0827] := $00000000; Cursor[0828] := $00000000; Cursor[0829] := $00000000; Cursor[0830] := $00000000; Cursor[0831] := $00000000;
      Cursor[0832] := $00000000; Cursor[0833] := $00000000; Cursor[0834] := $00000000; Cursor[0835] := $00000000; Cursor[0836] := $00000000; Cursor[0837] := $04000000; Cursor[0838] := $AD000000; Cursor[0839] := $FF000000;
      Cursor[0840] := $FF000000; Cursor[0841] := $A1000000; Cursor[0842] := $08000000; Cursor[0843] := $00000000; Cursor[0844] := $00000000; Cursor[0845] := $22000000; Cursor[0846] := $FD000000; Cursor[0847] := $FF000000;
      Cursor[0848] := $8B000000; Cursor[0849] := $00000000; Cursor[0850] := $00000000; Cursor[0851] := $0E000000; Cursor[0852] := $EF000000; Cursor[0853] := $FF000000; Cursor[0854] := $B5000000; Cursor[0855] := $00000000;
      Cursor[0856] := $00000000; Cursor[0857] := $00000000; Cursor[0858] := $00000000; Cursor[0859] := $00000000; Cursor[0860] := $00000000; Cursor[0861] := $00000000; Cursor[0862] := $00000000; Cursor[0863] := $00000000;
      Cursor[0864] := $00000000; Cursor[0865] := $00000000; Cursor[0866] := $00000000; Cursor[0867] := $00000000; Cursor[0868] := $00000000; Cursor[0869] := $00000000; Cursor[0870] := $00000000; Cursor[0871] := $24000000;
      Cursor[0872] := $22000000; Cursor[0873] := $00000000; Cursor[0874] := $00000000; Cursor[0875] := $00000000; Cursor[0876] := $00000000; Cursor[0877] := $00000000; Cursor[0878] := $B1000000; Cursor[0879] := $FF000000;
      Cursor[0880] := $ED000000; Cursor[0881] := $0A000000; Cursor[0882] := $00000000; Cursor[0883] := $00000000; Cursor[0884] := $89000000; Cursor[0885] := $FF000000; Cursor[0886] := $FD000000; Cursor[0887] := $1C000000;
      Cursor[0888] := $00000000; Cursor[0889] := $00000000; Cursor[0890] := $00000000; Cursor[0891] := $00000000; Cursor[0892] := $00000000; Cursor[0893] := $00000000; Cursor[0894] := $00000000; Cursor[0895] := $00000000;
      Cursor[0896] := $00000000; Cursor[0897] := $00000000; Cursor[0898] := $00000000; Cursor[0899] := $00000000; Cursor[0900] := $00000000; Cursor[0901] := $00000000; Cursor[0902] := $00000000; Cursor[0903] := $00000000;
      Cursor[0904] := $00000000; Cursor[0905] := $00000000; Cursor[0906] := $00000000; Cursor[0907] := $00000000; Cursor[0908] := $00000000; Cursor[0909] := $00000000; Cursor[0910] := $44000000; Cursor[0911] := $FF000000;
      Cursor[0912] := $FF000000; Cursor[0913] := $68000000; Cursor[0914] := $00000000; Cursor[0915] := $32000000; Cursor[0916] := $B7000000; Cursor[0917] := $FF000000; Cursor[0918] := $FF000000; Cursor[0919] := $32000000;
      Cursor[0920] := $00000000; Cursor[0921] := $00000000; Cursor[0922] := $00000000; Cursor[0923] := $00000000; Cursor[0924] := $00000000; Cursor[0925] := $00000000; Cursor[0926] := $00000000; Cursor[0927] := $00000000;
      Cursor[0928] := $00000000; Cursor[0929] := $00000000; Cursor[0930] := $00000000; Cursor[0931] := $00000000; Cursor[0932] := $00000000; Cursor[0933] := $00000000; Cursor[0934] := $00000000; Cursor[0935] := $00000000;
      Cursor[0936] := $00000000; Cursor[0937] := $00000000; Cursor[0938] := $00000000; Cursor[0939] := $00000000; Cursor[0940] := $00000000; Cursor[0941] := $00000000; Cursor[0942] := $00000000; Cursor[0943] := $D5000000;
      Cursor[0944] := $FF000000; Cursor[0945] := $DF000000; Cursor[0946] := $BF000000; Cursor[0947] := $FF000000; Cursor[0948] := $FF000000; Cursor[0949] := $FF000000; Cursor[0950] := $D5000000; Cursor[0951] := $04000000;
      Cursor[0952] := $00000000; Cursor[0953] := $00000000; Cursor[0954] := $00000000; Cursor[0955] := $00000000; Cursor[0956] := $00000000; Cursor[0957] := $00000000; Cursor[0958] := $00000000; Cursor[0959] := $00000000;
      Cursor[0960] := $00000000; Cursor[0961] := $00000000; Cursor[0962] := $00000000; Cursor[0963] := $00000000; Cursor[0964] := $00000000; Cursor[0965] := $00000000; Cursor[0966] := $00000000; Cursor[0967] := $00000000;
      Cursor[0968] := $00000000; Cursor[0969] := $00000000; Cursor[0970] := $00000000; Cursor[0971] := $00000000; Cursor[0972] := $00000000; Cursor[0973] := $00000000; Cursor[0974] := $00000000; Cursor[0975] := $62000000;
      Cursor[0976] := $FF000000; Cursor[0977] := $FF000000; Cursor[0978] := $FF000000; Cursor[0979] := $FF000000; Cursor[0980] := $F7000000; Cursor[0981] := $99000000; Cursor[0982] := $18000000; Cursor[0983] := $00000000;
      Cursor[0984] := $00000000; Cursor[0985] := $00000000; Cursor[0986] := $00000000; Cursor[0987] := $00000000; Cursor[0988] := $00000000; Cursor[0989] := $00000000; Cursor[0990] := $00000000; Cursor[0991] := $00000000;
      Cursor[0992] := $00000000; Cursor[0993] := $00000000; Cursor[0994] := $00000000; Cursor[0995] := $00000000; Cursor[0996] := $00000000; Cursor[0997] := $00000000; Cursor[0998] := $00000000; Cursor[0999] := $00000000;
      Cursor[1000] := $00000000; Cursor[1001] := $00000000; Cursor[1002] := $00000000; Cursor[1003] := $00000000; Cursor[1004] := $00000000; Cursor[1005] := $00000000; Cursor[1006] := $00000000; Cursor[1007] := $02000000;
      Cursor[1008] := $89000000; Cursor[1009] := $E9000000; Cursor[1010] := $DB000000; Cursor[1011] := $7C000000; Cursor[1012] := $16000000; Cursor[1013] := $00000000; Cursor[1014] := $00000000; Cursor[1015] := $00000000;
      Cursor[1016] := $00000000; Cursor[1017] := $00000000; Cursor[1018] := $00000000; Cursor[1019] := $00000000; Cursor[1020] := $00000000; Cursor[1021] := $00000000; Cursor[1022] := $00000000; Cursor[1023] := $00000000;
      Address := PhysicalToBusAddress (Cursor);

      {Now call Cursor Set Info to load our new cursor into the GPU}
      CursorSetInfo (32, 32, 0, 0, Pointer (Address), Size);

      {And finally free the memory that we allocated}
      FreeMem (Cursor);
    end;
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

function ReadByte (aStream : TStream) : byte;
begin
  if aStream.Position = aStream.Size then
    Result := 0
  else
    aStream.Read (Result, 1);
end;

function ReadDWord (aStream : TStream) : integer;
begin
  if aStream.Size - aStream.Position < 4 then
    Result := -1
  else
     Result := ReadByte (aStream) + ReadByte (aStream) * $100 +
               ReadByte (aStream) * $10000 + ReadByte (aStream) * $1000000;
end;

function display_string (s : string) : string;
var
  i : integer;
begin
  Result := '';
  for i := 1 to length (s) do
    if s[i] in [' ' .. '~'] then
      Result := Result + s[i]
    else
      Result := Result + '<' + ord (s[i]).ToString + '>';
end;

function ReadWord (aStream : TStream) : integer;
begin
  if aStream.Size - aStream.Position < 2 then
    Result := -1
  else
    Result := ReadByte (aStream) + ReadByte (aStream) * $100;
end;

function LoadFromStream (aStream : TStream) : boolean;
var
  DataSize, headerSize : integer;
  aWord, HeadCount : integer;
  CatNos, ResNos : integer;
  x : integer;
  anImage : TLibImage;
  DataStream : TMemoryStream;
  CatName, ResName : string;
begin
  Log1 ('Loading Stream.');
  DataSize := 0;
  HeaderSize := 0;
  Result := false;
  if (pages = nil) or (images = nil) then exit;
  while (true) do
    begin
      CatName := '';
      ResName := '';
      CatNos := 0;
      ResNos := 0;
      DataSize := ReadDWord (aStream);
      HeaderSize := ReadDWord (aStream);
      aWord := ReadWord (aStream);
      HeadCount := 10; // 10 bytes read so far
      if DataSize = 0 then
        begin
          if HeadCount < HeaderSize then aStream.Seek (HeaderSize - HeadCount, soFromCurrent);
          continue;
        end;
      if (DataSize = -1) or (HeaderSize = -1) or (aWord = -1) then
        begin
          Result := true;
          exit;
        end;
      if aWord = $ffff then
			  begin
				  CatNos := ReadWord (aStream);
				  HeadCount := HeadCount + 2;
			  end
			else
			  begin
				  while aWord <> $00 do
				    begin
					    CatName := CatName + Char (aWord and $ff);
					    aWord := ReadWord (aStream);
					    HeadCount := HeadCount + 2;
         	    if aWord = -1 then
                begin
                  Result := false;
                  exit;
                end;
            end;
				  if (HeadCount mod 4) <> 0 then
            begin
              ReadWord (aStream); // DWord boundary
              HeadCount := HeadCount + 2;
            end;
        end;
      aWord := ReadWord (aStream);
			HeadCount := HeadCount + 2;
      if aWord = $ffff then
        begin
 				  ResNos := ReadWord (aStream);
				  HeadCount := HeadCount + 2;
		    end
			else
		    begin
				  while aWord <> $00 do
            begin
              ResName := ResName + Char (aWord and $ff);
					    aWord := ReadWord (aStream);
					    HeadCount := HeadCount + 2;
					    if aWord = -1 then
                begin
                  Result := false;
                  exit;
                end;
            end;
          if (HeadCount mod 4) <> 0 then
            begin
              ReadWord (aStream); // DWord boundary
              HeadCount := HeadCount + 2;
            end;
        end;
      try
				if HeadCount < HeaderSize then aStream.Seek (HeaderSize - HeadCount, soFromCurrent);
 //       Log1 ('Cat Name "' + CatName + '" ResName "' + ResName + '"');
        if (CompareText (CatName, 'GUI') = 0) and (CompareText (ResName, 'GUI') = 0) then
				  begin
            DataStream := TMemoryStream.Create;
            DataStream.CopyFrom (aStream, DataSize);
            DataStream.Seek (0, soFromBeginning);
            Pages.LoadFromStream (DataStream);
            Log ('Pages Count ' + pages.Count.ToString);
            DataStream.Free;
          end
        else if CompareText (CatName, 'GUIIMAGES') = 0 then
          begin
            DataStream := TMemoryStream.Create;
            anImage := TLibImage.Create;
            anImage.Name := ResName;
            DataStream.CopyFrom (aStream, DataSize);
            DataStream.Seek (0, soFromBeginning);
            try
              anImage.Image.LoadFromStream (DataStream);
              Log1 ('Image ' + ResName + ' Loaded. Size ' + anImage.Image.Width.ToString + 'x' + anImage.Image.Height.ToString + '.');
              Images.Add (anImage);
            except on e: exception do
              begin
                Log1 ('Image ' + ResName + ' : ' + e.Message);
                anImage.Free;
              end;
            end;
            DataStream.Free;
          end
        else
					aStream.Seek (DataSize, soFromCurrent);
        x := 4 - (DataSize mod 4);
				if x <> 4 then aStream.Seek (x, soFromCurrent);
      except on e: exception do
        Log ('General : ' + e.Message);
      end;
    end;      // true
end;

{ TPointerThread }

constructor TPointerThread.Create (x, y : LongWord);
var
  i : integer;
begin
  inherited Create (true);
  CreateCursor;
  CursorX := x;
  CursorY := y;
  for i := 1 to 6 do Buttons[i] := false;
  CursorSetState (true, CursorX, CursorY, false);
  Start;
end;


const
  du : array [boolean] of string = ('DOWN', 'UP');

procedure TPointerThread.Execute;
var
  Extra : LongInt;
  aProp : TProp;
  i : integer;
  Current : array [1..6] of boolean;
begin
  while not Terminated do
    begin
      Count := 0;
      if MouseRead (@MouseData, SizeOf (TMouseData), Count) = ERROR_SUCCESS then
        begin
  //      Log2 ('Mouse OffsetX = ' + IntToStr(MouseData.OffsetX) + ' OffsetY = ' + IntToStr(MouseData.OffsetY) + ' Buttons = ' + Buttons);
          {Now update our mouse tracking for cursor X and Y}
          CursorX := CursorX + MouseData.OffsetX;
          if CursorX < 0 then CursorX := 0;
 //         if CursorX > (ScreenWidth - 1) then CursorX := ScreenWidth - 1;  }
          CursorY := CursorY + MouseData.OffsetY;
          if CursorY < 0 then CursorY := 0;
   //       if CursorY > (ScreenHeight - 1) then CursorY := ScreenHeight - 1;  }
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
                  if Buttons[i] then GUI.DoMouseDown (GUI, i, [], CursorX - GUI.Left, CursorY - GUI.Top)
                  else GUI.DoMouseUp (GUI, i, [], CursorX - GUI.Left, CursorY - GUI.Top);
                  GUI.RefreshCanvas;
                  GUI.Canvas.Flush (DefFrameBuff);
                end;
            end;
          CursorSetState (true, CursorX, CursorY, false);
        end;
    end;
end;

begin
  Console1 := ConsoleWindowCreate (ConsoleDeviceGetDefault, CONSOLE_POSITION_LEFT, true);
  Console2 := ConsoleWindowCreate (ConsoleDeviceGetDefault, CONSOLE_POSITION_TOPRIGHT, false);
  Console3 := GraphicsWindowCreate (ConsoleDeviceGetDefault, CONSOLE_POSITION_BOTTOMRIGHT);
  SetLogProc (@Log1);
  Log1 ('Sneak Previews of GUI Controls.');
  WaitForSDDrive;

  Log1 ('SD Drive Ready.');

{$ifdef use_tftp}
  IPAddress := WaitForIPComplete;
  Log2 ('TFP Syntax : tftp -i ' + IPAddress + ' put kernel7.img');
  SetOnMsg (@Msg2);
{$endif}

  ch := #0;
  DefFrameBuff := FramebufferDeviceGetDefault;

  Pages := TPages.Create;
  Images := TImageLib.Create;
  GUI := TGUI.Create;
  GUI.Pages := Pages;
  Pages.PngLib := Images;

  if GraphicsWindowGetProperties (Console3, @Properties) = ERROR_SUCCESS then
    begin
      GUI.Left := Properties.X1;
      GUI.Top := Properties.Y1;
    end;

  CollectFonts (true);
  Log (Fonts.Count.ToString + ' Font(s) loaded.');



  PointerThread := TPointerThread.Create (GUI.Left, GUI.Top);



  while true do
    begin
      if ConsoleReadChar (ch, nil) then
        case (ch) of
          '1' :
            begin
              f := TFileStream.Create ('test1.res', fmOpenRead);
              f.Seek (0, soFromBeginning);
              LoadFromStream (f);
              Log ('Default Page ' + Pages.DefaultPage);
              Log ('Project Size ' +  Pages.ProjectWidth.ToString + ' x ' + Pages.ProjectHeight.ToString);
              Log ('There are ' + Images.Count.ToString + ' images loaded.');

              GUI.Width := Pages.ProjectWidth;
              GUI.Height := Pages.ProjectHeight;

              if Pages.Count > 0 then
                begin
                  aPage := Pages.GetPage (Pages.DefaultPage);
                  if aPage <> nil then
                    GUI.Page := aPage
                  else
                    GUI.Page := Pages[0];
                end;
              GUI.RefreshCanvas;
              GUI.Canvas.Flush (DefFrameBuff);
              f.Free;
            end;
          '2' :
            begin
              im := TFPMemoryImage.create (0,0);
              try
                im.LoadFromFile ('b1-2.png');
                Log ('loaded');
              except on e: exception do
                Log ('im Load Error ' + e.Message);
              end;
              im.free;
            end;
          '3' :
            begin
              im := TFPMemoryImage.create (0,0);
              try
                im.LoadFromFile ('abc.png');
                Log ('loaded');
              except on e: exception do
                Log ('im Load Error ' + e.Message);
              end;
               im.free;
            end;
          '4' :
            begin
              for i := 0 to Fonts.Count - 1 do
                begin
                  with TFontInfo (Fonts[i]) do
                    Log ('F: ' + FileName + ' FN: ' + FamilyName + ' SFN: ' + SubFamilyName + ' MJV: ' + MajorVersion.ToString + ' MNV: ' + MinorVersion.ToString);
                end;
            end;
          '5' :
            begin
              sz := 0;
              fi := GetFont ('10B-Arial', sz);
              if fi = nil then Log ('Font Not Found')
              else Log ('Font Found ' + fi.FamilyName + ' ' + fi.SubFamilyName + ' Size ' + sz.ToString);
            end;
          '6' :
            begin
              sz := 0;
              fi := GetFont ('24I-Arial', sz);
              if fi = nil then Log ('Font Not Found')
              else Log ('Font Found ' + fi.FamilyName + ' ' + fi.SubFamilyName + ' Size ' + sz.ToString);
            end;
          '7' :
            begin
              sz := 0;
              fi := GetFont ('12BI-Arial', sz);
              if fi = nil then Log ('Font Not Found')
              else Log ('Font Found ' + fi.FamilyName + ' ' + fi.SubFamilyName + ' Size ' + sz.ToString);
            end;
          '8' : Log (Fonts.Count.ToString);
          else
            begin
              Log ('Keyboards ' + KeyboardGetCount.ToString);
              KB := KeyboardDeviceFindByDescription (USBKEYBOARD_KEYBOARD_DESCRIPTION);
              if KB = nil then Log ('No Keyboard')
              else Log ('Keyboard found ' + kb^.Modifiers.ToHexString (8));
            end;
        end;
    end;
  ThreadHalt (0);
end.

