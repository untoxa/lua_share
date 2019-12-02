{__$define global_objects}

unit mmf_ipc;

interface

uses  windows;

{$ifdef global_objects}
const names_prefix        = 'Global\';
{$else}
const names_prefix        = 'Local\';
{$endif}

const ClientMutexName     = names_prefix + '{95494550-C095-4C3E-A061-27C6747C8DBB}';

      EventNameSend       = names_prefix + '{E1D4868B-0D20-432B-ADFC-704C05641287}';
      EventNameReceive    = names_prefix + '{043FE61B-D80D-4B71-B969-BEB62BA51CCF}';

      mmfDataNameSend     = names_prefix + '{D6ADBDCA-8A35-4460-B036-4EA9DF90A34C}';
      mmfDataNameReceive  = names_prefix + '{7804AE81-AE77-4ABA-9670-AD4F0B8958E3}';

type  tIPCSendReceive     = class(tObject)
      private
        fDataLen          : longint;
        fMMFIn            : THandle;
        fDataIn           : pAnsiChar;
        fMMFOut           : THandle;
        fDataOut          : pAnsiChar;
      protected
        function    createmmf(const aname: ansistring; adatalen: longint; var ahandle: THandle; var adata: pAnsiChar): boolean;
        function    openmmf(const aname: ansistring; adatalen: longint; var ahandle: THandle; var adata: pAnsiChar): boolean;
        procedure   closemmf(var ahandle: THandle; var adata: pAnsiChar);
      public
        constructor create(adatalen: longint);
        destructor  destroy; override;

        function    open: boolean; virtual;
        procedure   close; virtual;

        property    maxdatalen: longint read fDataLen;
      end;

      tIPCServer          = class(tIPCSendReceive)
      private
        FEvReadyIn        : THandle;
        FEvReadyOut       : THandle;
        FOpened           : boolean;
      protected
        function    processdata(input: pAnsiChar; inputsize: longint; output: pAnsiChar; var outputsize: longint; aref: pointer): boolean; virtual;
      public
        function    open: boolean; override;
        procedure   close; override;

        function    process(atimeout: longint; aref: pointer): boolean;

        property    opened: boolean read FOpened;
      end;

      tIPCClient          = class(tIPCSendReceive)
      private
        FMutex            : THandle;
        FEvReadyIn        : THandle;
        FEvReadyOut       : THandle;
        FOpened           : boolean;
      public
        function    open: boolean; override;
        procedure   close; override;

        function    send_receive(output: pAnsiChar; outputsize: longint; input: pAnsiChar; var inputsize: longint; atimeout: longint): boolean;

        property    opened: boolean read FOpened;
      end;

implementation

{ tIPCSendReceive }

constructor tIPCSendReceive.create(adatalen: longint);
begin
  inherited create;
  fDataLen:= adatalen;
  fMMFIn:= 0; fDataIn:= nil;
  fMMFOut:= 0; fDataOut:= nil;
end;

destructor tIPCSendReceive.destroy;
begin
  close;
  inherited destroy;
end;

function tIPCSendReceive.createmmf(const aname: ansistring; adatalen: longint; var ahandle: THandle; var adata: pAnsiChar): boolean;
var sd : SECURITY_DESCRIPTOR;
    sa : SECURITY_ATTRIBUTES;
begin
  adata:= nil;
  InitializeSecurityDescriptor(@sd, SECURITY_DESCRIPTOR_REVISION);
  SetSecurityDescriptorDacl(@sd, true, nil, false);

  sa.nLength:= sizeof(sa);
  sa.lpSecurityDescriptor:= @sd;
  sa.bInheritHandle:= false;

  ahandle:= CreateFileMapping(INVALID_HANDLE_VALUE, @sa, PAGE_READWRITE, 0, adatalen, pAnsiChar(aname));
  if (ahandle <> 0) then adata := MapViewOfFile(ahandle, FILE_MAP_WRITE, 0, 0, 0);
  result:= assigned(adata);
end;

function tIPCSendReceive.openmmf(const aname: ansistring; adatalen: longint; var ahandle: THandle; var adata: pAnsiChar): boolean;
begin
  adata:= nil;
  ahandle := OpenFileMapping(FILE_MAP_WRITE, False, pAnsiChar(aname));
  if (ahandle <> 0) then adata := MapViewOfFile(ahandle, FILE_MAP_WRITE, 0, 0, 0);
  result:= assigned(adata);
end;

procedure tIPCSendReceive.closemmf(var ahandle: THandle; var adata: pAnsiChar);
begin
  if assigned(adata) then begin
    UnmapViewOfFile(adata);
    adata:= nil;
  end;
  if (ahandle <> 0) then begin
    CloseHandle(ahandle);
    ahandle:= 0;
  end;
end;

function tIPCSendReceive.open: boolean;
begin result:= false; end;

procedure tIPCSendReceive.close;
begin end;

{ tIPCServer }

function tIPCServer.open: boolean;
begin
  close;
  FEvReadyIn  := CreateEvent(nil, False, False, EventNameReceive);
  FEvReadyOut := CreateEvent(nil, False, False, EventNameSend);
  result      := (FEvReadyIn <> 0) and (FEvReadyOut <> 0);
  if result then
    result:= createmmf(mmfDataNameReceive, maxdatalen, fMMFIn, fDataIn) and
             createmmf(mmfDataNameSend, maxdatalen, fMMFOut, fDataOut);
  FOpened:= result;
end;

procedure tIPCServer.close;
begin
  if (FEvReadyIn <> 0) then CloseHandle(FEvReadyIn);
  FEvReadyIn:= 0;
  if (FEvReadyOut <> 0) then CloseHandle(FEvReadyOut);
  FEvReadyOut:= 0;
  closemmf(fMMFIn, fDataIn);
  closemmf(fMMFOut, fDataOut);
  FOpened:= false;
end;

function tIPCServer.processdata(input: pAnsiChar; inputsize: longint; output: pAnsiChar; var outputsize: longint; aref: pointer): boolean;
begin result:= false; end;

function tIPCServer.process(atimeout: longint; aref: pointer): boolean;
begin
  result:= FOpened;
  if result and (WaitForSingleObject(FEvReadyIn, atimeout) = WAIT_OBJECT_0) then try
    result:= processdata(fDataIn + sizeof(longint), plongint(fDataIn)^, fDataOut + sizeof(longint), plongint(fDataOut)^, aref);
    if not result then plongint(fDataOut)^:= 0;
  finally SetEvent(FEvReadyOut); end;
end;

{ tIPCClient }

function tIPCClient.open: boolean;
begin
  close;
  FMutex      := CreateMutex(nil, False, ClientMutexName);
  FEvReadyIn  := OpenEvent(EVENT_ALL_ACCESS, False, EventNameSend);
  FEvReadyOut := OpenEvent(EVENT_ALL_ACCESS, False, EventNameReceive);
  result      := (FMutex <> 0) and (FEvReadyIn <> 0) and (FEvReadyOut <> 0);
  if result then
    result:= openmmf(mmfDataNameSend, maxdatalen, fMMFIn, fDataIn) and
             openmmf(mmfDataNameReceive, maxdatalen, fMMFOut, fDataOut);
  FOpened:= result;
end;

procedure tIPCClient.close;
begin
  if (FEvReadyIn <> 0) then CloseHandle(FEvReadyIn);
  FEvReadyIn:= 0;
  if (FEvReadyOut <> 0) then CloseHandle(FEvReadyOut);
  FEvReadyOut:= 0;
  if (FMutex <> 0) then CloseHandle(FMutex);
  FMutex:= 0;
  closemmf(fMMFIn, fDataIn);
  closemmf(fMMFOut, fDataOut);
  FOpened:= false;
end;

function tIPCClient.send_receive(output: pAnsiChar; outputsize: longint; input: pAnsiChar; var inputsize: longint; atimeout: longint): boolean;
begin
  result:= FOpened;
  if result then begin
    result:= (WaitForSingleObject(FMutex, atimeout) = WAIT_OBJECT_0);
    if result then try
      plongint(fDataOut)^:= outputsize;
      system.move(output^, (fDataOut + sizeof(longint))^, outputsize);
      SetEvent(FEvReadyOut);
      result:= (WaitForSingleObject(FEvReadyIn, atimeout) = WAIT_OBJECT_0);
      if result then begin
        inputsize:= plongint(fDataIn)^;
        system.move((fDataIn + sizeof(longint))^, input^, inputsize);
      end else inputsize:= 0;
    finally ReleaseMutex(FMutex); end;
  end;
end;

end.
