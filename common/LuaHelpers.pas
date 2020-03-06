unit LuaHelpers;

interface

uses  windows, classes, sysutils,
      LuaLib;

const LUA_TANY           = LUA_TNONE;

const LIST_KEYVALUE      = true;
      LIST_STRINGS       = false;

type  TLuaState          = Lua_State;

      TLuaContext        = class;
      TLuaTable          = class;

      TLuaField          = class(tObject)
      private
        fContext         : TLuaContext;
        fFieldType       : integer;
        fNumber          : double;
        fBool            : boolean;
        fString          : ansistring;
        fTable           : TLuaTable;
        fIndex           : integer;
        fPointer         : pointer;

        function    getabsindex(AIndex: integer): integer;
        function    fExtractField(AIndex: integer): TLuaField;
        function    fGetField(AIndex: integer; const AName: ansistring): TLuaField;
      public
        constructor create(AContext: TLuaContext);
        destructor  destroy; override;
        function    AsBoolean(const adefault: boolean = false): boolean;
        function    AsInteger(const adefault: int64 = 0): int64;
        function    AsNumber(const adefault: double = 0.0): double;
        function    AsString(const adefault: ansistring = ''): ansistring;
        function    AsUserData: pointer;
        function    AsTable: TLuaTable;

        function    IsFunction: boolean;
        function    IsLightUserData: boolean;
        function    IsUserData: boolean;
        function    IsTable: boolean;

        property    FieldType: integer read fFieldType;
        property    FieldByName[AIndex: integer; const AName: ansistring]: TLuaField read fGetField; default;
      end;

      TLuaTable          = class(tObject)
      private
        fContext         : TLuaContext;
        fField           : TLuaField;
        fIndex           : integer;
        fPopSize         : integer;
        fCurField        : TLuaField;
        fStackAlloc      : boolean;

        function    getabsindex(AIndex: integer): integer;
        procedure   fSetIndex(AIndex: integer);
        function    fGetFieldByName(const AName: ansistring): TLuaField;
        function    fGetField: TLuaField;
        function    fGetSelf: TLuaTable;
      protected
        property    Field: TLuaField read fGetField;
      public
        constructor create(AContext: TLuaContext); overload;
        constructor create(AContext: TLuaContext; AIndex: integer); overload;
        constructor create(AContext: TLuaContext; ALuaTable: TLuaTable; const AName: ansistring); overload;
        constructor create(AContext: TLuaContext; const AGlobalName: ansistring); overload;
        destructor  destroy; override;

        function    FindFirst: boolean;
        function    FindNext: boolean;
        procedure   FindClose;

        function    FindField(const AName: ansistring): boolean;

        function    CallMethodSafe(const AName: ansistring; const AArgs: array of const; AResCount: integer; var error: ansistring; AResType: integer = LUA_TNONE): boolean;

        property    CurrentTable: TLuaTable read fGetSelf;
        property    Index: integer read fIndex write fSetIndex;
        property    FieldByName[const AName: ansistring]: TLuaField read fGetFieldByName; default;
        property    CurrentField: TLuaField read fCurField;
        property    Context: TLuaContext read fContext;
      end;

      TLuaContext        = class(tObject)
      private
        fLuaState        : TLuaState;
        fField           : TLuaField;
        function    fGetStackByIndex(AIndex: integer): TLuaField;
        function    fGetGlobalByName(const AName: ansistring): TLuaField;
        function    fGetSelf: TLuaContext;
      public
        constructor create(ALuaState: TLuaState);
        destructor  destroy; override;

        procedure   SetLuaState(ALuaState: TLuaState);

        function    StackSize: longint;

        function    PushArgs(const aargs: array of const; avalueslist: boolean): integer; overload;
        function    PushArgs(const aargs: array of const): integer; overload;
        function    PushArgs(aargs: tStringList): integer; overload;

        function    PushTable(aKVTable: tStringList; avalueslist: boolean): integer; overload;
        function    PushTable(const aargs: array of const): integer; overload;  // aargs must look like: ['name1', value1, 'name2', value2]

        function    Call(const AName: ansistring; const AArgs: array of const; AResCount: integer; AResType: integer = LUA_TANY): boolean;

        function    CallSafe(const AName: ansistring; const AArgs: array of const; AResCount: integer; var error: ansistring; AResType: integer): boolean; overload;
        function    CallSafe(const AName: ansistring; const AArgs: array of const; AResCount: integer; var error: ansistring): boolean; overload;
        function    CallSafe(const AName: ansistring; aargs: tStringList; AResCount: integer; var error: ansistring; AResType: integer): boolean; overload;
        function    CallSafe(const AName: ansistring; aargs: tStringList; AResCount: integer; var error: ansistring): boolean; overload;

        function    ExecuteSafe(const AScript: ansistring; AResCount: integer; var error: ansistring): boolean;

        function    ExecuteFileSafe(const AFileName: ansistring; AResCount: integer; var error: ansistring): boolean;

        procedure   CleanUp(ACount: integer);

        procedure   SetGlobal(AIndex: integer; const AName: ansistring);
        procedure   ResetGlobal(const AName: ansistring);

        property    CurrentContext: TLuaContext read fGetSelf;
        property    CurrentState: TLuaState read fLuaState;
        property    Stack[AIndex: integer]: TLuaField read fGetStackByIndex; default;
        property    Globals[const AName: ansistring]: TLuaField read fGetGlobalByName;
      end;

      TOnTableItemEx     = function(ATable: TLuaTable): boolean of object;
      TLuaFunction       = function(AContext: TLuaContext): integer of object;

      TFuncList          = class(TList)
      protected
        procedure   Notify(Ptr: Pointer; Action: TListNotification); override;
        procedure   RegisterMethod(const AName: ansistring; AMethod: tLuaFunction);
      end;

      TLuaClass         = class(TObject)
      private
        fFuncs          : TFuncList;
        fStartCount     : integer;

        function    fGetSelf: TLuaClass;
      protected
        procedure   PushMethod(ALuaState: TLuaState; AMethod: tLuaFunction);
      public
        constructor create(hLib: HMODULE; const ALibName: ansistring = '');
        destructor  destroy; override;

        procedure   StartRegister;
        procedure   RegisterMethod(const AName: ansistring; AMethod: tLuaFunction);
        function    StopRegister(ALuaState: TLuaState; const ALibName: ansistring; aleave_table: boolean = false): integer;

        procedure   RegisterGlobalMethod(ALuaState: TLuaState; const AName: ansistring; AMethod: tLuaFunction);

        property    CurrentLuaClass: TLuaClass read fGetSelf;
      end;

implementation

{ misc functions }

function  StrToFloatDef(const astr: ansistring; adef: extended): extended;
begin if not TextToFloat(pAnsiChar(astr), result, fvExtended) then result:= adef; end;

{ TLuaField }

constructor TLuaField.create(AContext: TLuaContext);
begin
  inherited create;
  fContext:= AContext;
  fTable:= nil;
  fFieldType:= LUA_TNONE;
  fNumber:= 0;
  fBool:= false;
  setlength(fString, 0);
end;

destructor TLuaField.destroy;
begin
  if assigned(fTable) then freeandnil(fTable);
  inherited destroy;
end;

function TLuaField.getabsindex(AIndex: integer): integer;
begin
  if ((AIndex = LUA_GLOBALSINDEX) or (AIndex = LUA_REGISTRYINDEX)) then result := AIndex
  else if (AIndex < 0) then result := AIndex + lua_gettop(fContext.CurrentState) + 1
  else result := AIndex;
end;

function TLuaField.fExtractField(AIndex: integer): TLuaField;
var len : cardinal;
begin
  fFieldType:= lua_type(fContext.CurrentState, AIndex);
  case fFieldType of
    LUA_TNUMBER        : fNumber := lua_tonumber(fContext.CurrentState, AIndex);
    LUA_TBOOLEAN       : fBool := lua_toboolean(fContext.CurrentState, AIndex);
    LUA_TSTRING        : begin
                           len:= 0;
                           SetString(fString, lua_tolstring(fContext.CurrentState, AIndex, len), len);
                         end;
    LUA_TUSERDATA,                     
    LUA_TLIGHTUSERDATA : fPointer:= lua_touserdata(fContext.CurrentState, AIndex);
    LUA_TTABLE         : begin
                           if not assigned(fTable) then fTable:= TLuaTable.create(fContext, AIndex)
                                                   else fTable.Index:= AIndex;
                         end;
    LUA_TFUNCTION      : fIndex:= getabsindex(aindex);
    else                 fFieldType:= LUA_TNONE;
  end;
  result:= Self;
end;

function TLuaField.fGetField(AIndex: integer; const AName: ansistring): TLuaField;
begin
  result:= Self;
  lua_pushstring(fContext.CurrentState, pAnsiChar(AName));
  lua_gettable(fContext.CurrentState, AIndex);
  try
    case lua_type(fContext.CurrentState, -1) of
      LUA_TTABLE : fFieldType:= LUA_TNONE;
      else         result:= fExtractField(-1) // only simple types allowed
    end;
  finally lua_pop(fContext.CurrentState, 1); end;
end;

function TLuaField.AsBoolean(const adefault: boolean): boolean;
begin
  case fFieldType of
    LUA_TBOOLEAN : result:= fBool;
    LUA_TNUMBER  : result:= (fNumber <> 0);
    LUA_TSTRING  : result:= (AnsiCompareText(fString, 'TRUE') = 0);
    else           result:= adefault;
  end;
end;

function TLuaField.AsInteger(const adefault: int64): int64;
begin result:= round(AsNumber(adefault)); end;

function TLuaField.AsNumber(const adefault: double): double;
begin
  case fFieldType of
    LUA_TBOOLEAN : result:= integer(fBool);
    LUA_TNUMBER  : result:= fNumber;
    LUA_TSTRING  : result:= StrToFloatDef(fString, adefault);
    else           result:= adefault;
  end;
end;

function TLuaField.AsString(const adefault: ansistring): ansistring;
const boolval : array[boolean] of ansistring = ('FALSE', 'TRUE');
begin
  case fFieldType of
    LUA_TBOOLEAN : result:= boolval[fBool];
    LUA_TNUMBER  : result:= FloatToStr(fNumber);
    LUA_TSTRING  : result:= fString;
    else           result:= adefault;
  end;
end;

function TLuaField.AsUserData: pointer;
begin
  case fFieldType of
    LUA_TUSERDATA,
    LUA_TLIGHTUSERDATA: result:= fPointer;
    else                result:= nil;
  end;
end;

function TLuaField.AsTable: TLuaTable;
begin
  if (fFieldType = LUA_TTABLE) then result:= fTable
                               else result:= nil;
end;

function TLuaField.IsFunction: boolean;
begin result:= (fFieldType = LUA_TFUNCTION); end;

function TLuaField.IsUserData: boolean;
begin result:= (fFieldType = LUA_TUSERDATA); end;

function TLuaField.IsLightUserData: boolean;
begin result:= (fFieldType = LUA_TLIGHTUSERDATA); end;

function TLuaField.IsTable: boolean;
begin result:= (fFieldType = LUA_TTABLE); end;

{ TLuaTable }

constructor TLuaTable.create(AContext: TLuaContext);
begin
  inherited create;
  fContext:= AContext;
  fField:= nil;
  fCurField:= nil;
  fIndex:= 0;
  fStackAlloc:= false;
  fPopSize:= 0;
end;

constructor TLuaTable.create(AContext: TLuaContext; AIndex: integer);
begin
  inherited create;
  fContext:= AContext;
  fField:= nil;
  fCurField:= nil;
  fIndex:= getabsindex(AIndex);
  fStackAlloc:= false;
  fPopSize:= 0;
end;

constructor TLuaTable.create(AContext: TLuaContext; ALuaTable: TLuaTable; const AName: ansistring);
begin
  inherited create;
  fContext:= AContext;
  fField:= nil;
  fCurField:= nil;
  fIndex:= 0;
  fStackAlloc:= false;
  fPopSize:= 0;

  lua_pushstring(fContext.CurrentState, pAnsiChar(AName));
  lua_gettable(fContext.CurrentState, ALuaTable.Index);
  if lua_istable(fContext.CurrentState, -1) then begin
    fIndex:= getabsindex(-1);
    fStackAlloc:= true;
  end else begin
    lua_pop(fContext.CurrentState, 1);
    raise Exception.CreateFmt('Field %s is not a table', [AName]);
  end;
end;

constructor TLuaTable.create(AContext: TLuaContext; const AGlobalName: ansistring);
begin
  inherited create;
  fContext:= AContext;
  fField:= nil;
  fCurField:= nil;
  fIndex:= 0;
  fStackAlloc:= false;
  fPopSize:= 0;

  lua_getglobal(fContext.CurrentState, pAnsiChar(AGlobalName));
  if lua_istable(fContext.CurrentState, -1) then begin
    fIndex:= getabsindex(-1);
    fStackAlloc:= true;
  end else begin
    lua_pop(fContext.CurrentState, 1);
    raise Exception.CreateFmt('Global %s is not a table', [AGlobalName]);
  end;
end;

destructor TLuaTable.destroy;
begin
  if fStackAlloc then lua_pop(fContext.CurrentState, 1);
  fCurField:= nil;
  if assigned(fField) then freeandnil(fField);
  inherited destroy;
end;

function TLuaTable.getabsindex(AIndex: integer): integer;
begin
  if ((AIndex = LUA_GLOBALSINDEX) or (AIndex = LUA_REGISTRYINDEX)) then result := AIndex
  else if (AIndex < 0) then result := AIndex + lua_gettop(fContext.CurrentState) + 1
  else result := AIndex;
end;

procedure TLuaTable.fSetIndex(AIndex: integer);
begin fIndex:= getabsindex(AIndex); end;

function TLuaTable.fGetField: TLuaField;
begin
  if not assigned(fField) then fField:= TLuaField.create(fContext);
  result:= fField;
end;

function TLuaTable.fGetFieldByName(const AName: ansistring): TLuaField;
begin result:= Field.FieldByName[fIndex, AName]; end;

function TLuaTable.fGetSelf: TLuaTable;
begin result:= Self; end;

function TLuaTable.FindFirst: boolean;
begin
  FindClose;
  lua_pushnil(fContext.CurrentState);
  lua_pushnil(fContext.CurrentState);  // imitate "value"
  result:= FindNext;
end;

function TLuaTable.FindNext: boolean;
begin
  lua_pop(fContext.CurrentState, 1);   // pop previous "value"
  result:= (lua_next(fContext.CurrentState, Index) <> 0);
  if result then begin
    fCurField:= Field.fExtractField(-1);
    fPopSize:= 2;                      // leave "key" on stack, need to cleanup if findclose()
  end else begin
    fCurField:= nil;
    fPopSize:= 0;                      // no need to cleanup, stack is empty
  end;
end;

procedure TLuaTable.FindClose;
begin
  if (fPopSize > 0) then lua_pop(fContext.CurrentState, fPopSize);
  fPopSize:= 0;
end;

function TLuaTable.FindField(const AName: ansistring): boolean;
begin
  lua_pushstring(fContext.CurrentState, pAnsiChar(AName));
  lua_gettable(fContext.CurrentState, Index);
  fCurField:= Field.fExtractField(-1);
  fPopSize:= 1;
  result:= true;
end;

function TLuaTable.CallMethodSafe(const AName: ansistring; const AArgs: array of const; AResCount: integer; var error: ansistring; AResType: integer): boolean;
var len: cardinal;
begin
  if (AResCount < 0) then AResCount:= LUA_MULTRET;
  lua_pushstring(fContext.CurrentState, pAnsiChar(AName));
  lua_rawget(fContext.CurrentState, Index);
  if (lua_type(fContext.CurrentState, -1) = LUA_TFUNCTION) then begin
    lua_pushvalue(fContext.CurrentState, Index);
    fContext.PushArgs(AArgs);
    if (lua_pcall(fContext.CurrentState, length(aargs) + 1, AResCount, 0) = 0) then begin
      if (AResType <> LUA_TNONE) then begin
        result:= (lua_type(fContext.CurrentState, -1) = AResType);
        if not result and (AResCount > 0) then lua_pop(fContext.CurrentState, AResCount);
      end else result:= true;
    end else begin
      len:= 0;
      SetString(error, lua_tolstring(fContext.CurrentState, -1, len), len);
      lua_pop(fContext.CurrentState, 1);
      result:= false;
    end;
  end else begin
    lua_pop(fContext.CurrentState, 1);
    error:= format('Method %s is not a function', [AName]);
    result:= false;
  end;
end;

{ TLuaContext }

constructor TLuaContext.create(ALuaState: TLuaState);
begin
  inherited create;
  fLuaState:= ALuaState;
  fField:= nil;
end;

destructor TLuaContext.destroy;
begin
  if assigned(fField) then freeandnil(fField);
  inherited destroy;
end;

procedure TLuaContext.SetLuaState(ALuaState: TLuaState);
begin fLuaState:= ALuaState; end;

function TLuaContext.StackSize: longint;
begin result:= lua_gettop(fLuaState); end;

function TLuaContext.fGetStackByIndex(AIndex: integer): TLuaField;
begin
  if not assigned(fField) then fField:= TLuaField.create(Self);
  result:= fField.fExtractField(AIndex);
end;

function TLuaContext.fGetGlobalByName(const AName: ansistring): TLuaField;
begin
  if not assigned(fField) then fField:= TLuaField.create(Self);
  lua_getglobal(fLuaState, pAnsiChar(AName));
  result:= fField.fExtractField(-1);  // may be problems with tables?
  lua_pop(fLuaState, 1);
end;

function TLuaContext.fGetSelf: TLuaContext;
begin result:= Self; end;

function TLuaContext.PushArgs(const aargs: array of const; avalueslist: boolean): integer;
var i : integer;
begin
  for i:= 0 to length(aargs) - 1 do begin
    with aargs[i] do begin
      case vType of
        vtInteger    : lua_pushinteger(fLuaState, vInteger);
        vtInt64      : lua_pushnumber(fLuaState, vInt64^);
        vtPChar      : lua_pushstring(fLuaState, pAnsiChar(vPChar));
        vtAnsiString : lua_pushstring(fLuaState, pAnsiChar(vAnsiString));
        vtExtended   : lua_pushnumber(fLuaState, vExtended^);
        vtBoolean    : lua_pushboolean(fLuaState, vBoolean);
        vtObject     : if assigned(vObject) then begin
                         if (vObject is tStringList) then PushTable(tStringList(vObject), avalueslist)
                                                     else lua_pushnil(fLuaState);
                       end else lua_pushnil(fLuaState);
        else           lua_pushnil(fLuaState);
      end;
    end;
  end;
  result:= length(aargs);
end;

function TLuaContext.PushArgs(const aargs: array of const): integer;
begin result:= PushArgs(aargs, LIST_KEYVALUE); end;

function TLuaContext.PushArgs(aargs: tStringList): integer;
var i : integer;
begin
  if assigned(aargs) then begin
    for i:= 0 to aargs.count - 1 do
      lua_pushstring(fLuaState, pAnsiChar(aargs[i]));
    result:= aargs.Count;
  end else result:= 0;
end;

function TLuaContext.PushTable(aKVTable: tStringList; avalueslist: boolean): integer;
var tmp : ansistring;
    p   : pAnsiChar;
    i   : integer;
begin
  result:= 0;
  if assigned(aKVTable) then with aKVTable do begin
    lua_createtable(fLuaState, Count, 0);
    for i := 0 to count - 1 do begin
      if avalueslist then begin
        tmp:= Names[i];
        lua_pushstring(fLuaState, pAnsiChar(tmp));
        tmp:= Values[tmp];
        if (length(tmp) > 0) and (tmp[1]='"') then begin
          p:= pAnsiChar(tmp);
          tmp:= AnsiExtractQuotedStr(p, '"');
        end;
        lua_pushstring(fLuaState, pAnsiChar(tmp));
      end else begin
        lua_pushinteger(fLuaState, i);
        lua_pushstring(fLuaState, pAnsiChar(strings[i]));
      end;
      lua_settable(fLuaState, -3);
    end;
    result:= 1;
  end;
end;

function TLuaContext.PushTable(const aargs: array of const): integer;
var i, count : integer;
begin
  count:= (length(aargs) div 2) * 2;                   // must be even, if not - last pair is not pushed!
  lua_createtable(fLuaState, count div 2, 0);
  for i:= 0 to count - 1 do begin
    with aargs[i] do
      case vType of
        vtInteger    : lua_pushinteger(fLuaState, vInteger);
        vtInt64      : lua_pushnumber(fLuaState, vInt64^);
        vtPChar      : lua_pushstring(fLuaState, pAnsiChar(vPChar));
        vtAnsiString : lua_pushstring(fLuaState, pAnsiChar(vAnsiString));
        vtExtended   : lua_pushnumber(fLuaState, vExtended^);
        vtBoolean    : lua_pushboolean(fLuaState, vBoolean);
        else           lua_pushnil(fLuaState);
      end;
    if (i mod 2 = 1) then lua_settable(fLuaState, -3); // set on every odd i
  end;
  result:= 1;
end;

function TLuaContext.Call(const AName: ansistring; const AArgs: array of const; AResCount: integer; AResType: integer): boolean;
begin
  if (AResCount < 0) then AResCount:= LUA_MULTRET;
  lua_getglobal(fLuaState, pAnsiChar(AName));                                // get function index
  if (lua_type(fLuaState, -1) = LUA_TFUNCTION) then begin
    PushArgs(aargs);                                                         // push parameters
    lua_call(fLuaState, length(aargs), AResCount);                           // call function
    if (AResType <> LUA_TNONE) then begin
      result:= (lua_type(fLuaState, -1) = AResType);
      if not result and (AResCount > 0) then lua_pop(fLuaState, AResCount);  // cleanup stack if unexpected type returned
    end else result:= true;
  end else begin
    lua_pop(fLuaState, 1);
    result:= false;
  end;
end;

function TLuaContext.CallSafe(const AName: ansistring; const AArgs: array of const; AResCount: integer; var error: ansistring; AResType: integer): boolean;
var len: cardinal;
begin
  if (AResCount < 0) then AResCount:= LUA_MULTRET;
  lua_getglobal(fLuaState, pAnsiChar(AName));                                // get function index
  if (lua_type(fLuaState, -1) = LUA_TFUNCTION) then begin
    len:= PushArgs(aargs);                                                   // push parameters
    if (lua_pcall(fLuaState, len, AResCount, 0) = 0) then begin              // call function in "protected mode"
      if (AResType <> LUA_TNONE) then begin
        result:= (lua_type(fLuaState, -1) = AResType);
        if not result and (AResCount > 0) then lua_pop(fLuaState, AResCount);// cleanup stack if unexpected type returned
      end else result:= true;
    end else begin
      len:= 0;
      SetString(error, lua_tolstring(fLuaState, -1, len), len);
      lua_pop(fLuaState, 1);
      result:= false;
    end;
  end else begin
    lua_pop(fLuaState, 1);
    error:= format('Global %s is not a function', [AName]);
    result:= false;
  end;
end;

function TLuaContext.CallSafe(const AName: ansistring; const AArgs: array of const; AResCount: integer; var error: ansistring): boolean; 
begin result:= CallSafe(AName, aargs, AResCount, error, LUA_TANY); end;

function TLuaContext.CallSafe(const AName: ansistring; aargs: tStringList; AResCount: integer; var error: ansistring; AResType: integer): boolean;
var len: cardinal;
begin
  if (AResCount < 0) then AResCount:= LUA_MULTRET;
  lua_getglobal(fLuaState, pAnsiChar(AName));                                // get function index
  if (lua_type(fLuaState, -1) = LUA_TFUNCTION) then begin
    len:= PushArgs(aargs);                                                   // push parameters
    if (lua_pcall(fLuaState, len, AResCount, 0) = 0) then begin              // call function in "protected mode"
      if (AResType <> LUA_TNONE) then begin
        result:= (lua_type(fLuaState, -1) = AResType);
        if not result and (AResCount > 0) then lua_pop(fLuaState, AResCount);// cleanup stack if unexpected type returned
      end else result:= true;
    end else begin
      len:= 0;
      SetString(error, lua_tolstring(fLuaState, -1, len), len);
      lua_pop(fLuaState, 1);
      result:= false;
    end;
  end else begin
    lua_pop(fLuaState, 1);
    error:= format('Global %s is not a function', [AName]);
    result:= false;
  end;
end;

function TLuaContext.CallSafe(const AName: ansistring; aargs: tStringList; AResCount: integer; var error: ansistring): boolean;
begin result:= CallSafe(AName, aargs, AResCount, error, LUA_TANY); end;

function TLuaContext.ExecuteSafe(const AScript: ansistring; AResCount: integer; var error: ansistring): boolean;
var len: cardinal;
begin
  result:= (luaL_loadstring(fLuaState, pAnsiChar(AScript)) = 0);
  if result then begin
    result:= (lua_pcall(fLuaState, 0, AResCount, 0) = 0);
    if not result then begin
      len:= 0;
      SetString(error, lua_tolstring(fLuaState, -1, len), len);
      lua_pop(fLuaState, 1);
      result:= false;
    end;
  end else error:= 'Script loading failed';
end;

function TLuaContext.ExecuteFileSafe(const AFileName: ansistring; AResCount: integer; var error: ansistring): boolean;
var len: cardinal;
begin
  result:= (luaL_loadfile(fLuaState, pAnsiChar(AFileName)) = 0);
  if result then begin
    result:= (lua_pcall(fLuaState, 0, AResCount, 0) = 0);
    if not result then begin
      len:= 0;
      SetString(error, lua_tolstring(fLuaState, -1, len), len);
      lua_pop(fLuaState, 1);
      result:= false;
    end;
  end else error:= 'Script loading failed';
end;

procedure TLuaContext.CleanUp(ACount: integer);
begin lua_pop(fLuaState, ACount); end;

procedure TLuaContext.SetGlobal(AIndex: integer; const AName: ansistring);
begin
  lua_pushvalue(fLuaState, AIndex);
  lua_setglobal(fLuaState, pAnsiChar(AName));
end;

procedure TLuaContext.ResetGlobal(const AName: ansistring);
begin
  lua_pushnil(fLuaState);
  lua_setglobal(fLuaState, pAnsiChar(AName));
end;

{ TFuncProxyObject }

type  TFuncProxyObject   = class(TObject)
      private
        FName            : ansistring;
        FMethod          : tLuaFunction;
      public
        constructor Create(const AName: ansistring; AMethod: tLuaFunction); reintroduce;
        function    Call(astate: TLuaState): integer;

        property    Name: ansistring read FName;
        property    Method: tLuaFunction read FMethod;
      end;

constructor TFuncProxyObject.Create(const AName: ansistring; AMethod: tLuaFunction);
begin
  inherited create;
  fname:= aname;
  fmethod:= amethod;
end;

function TFuncProxyObject.Call(astate: TLuaState): integer;
begin if assigned(FMethod) then result:= FMethod(astate) else result:= 0; end;

{ LuaProxyFunction }

function LuaProxyFunction(astate: Lua_State): Integer; cdecl;
var func: tLuaFunction;
begin
  TMethod(func).Data:= lua_topointer(astate, lua_upvalueindex(1));
  TMethod(func).Code:= lua_topointer(astate, lua_upvalueindex(2));
  if assigned(func) then begin
    with TLuaContext.create(astate) do try
      result:= func(CurrentContext);
    finally free; end;
  end else result:= 0;
end;

{ TFuncList }

procedure TFuncList.Notify(Ptr: Pointer; Action: TListNotification);
begin if (Action = lnDeleted) and assigned(Ptr) then TFuncProxyObject(Ptr).free; end;

procedure TFuncList.RegisterMethod(const AName: ansistring; AMethod: tLuaFunction);
begin add(TFuncProxyObject.Create(AName, AMethod)); end;

{ TLuaClass }

constructor TLuaClass.create(hLib: HMODULE; const ALibName: ansistring);
begin
  inherited create;
  fStartCount:= 0;
  fFuncs:= TFuncList.create;

  if (not LuaLibLoaded) then
    if (hLib <> 0) then InitializeLuaLib(hLib)
                   else LoadLuaLib(ALibName);
end;

destructor TLuaClass.destroy;
begin
  if assigned(fFuncs) then freeandnil(fFuncs);
  inherited destroy;
end;

function TLuaClass.fGetSelf: TLuaClass;
begin result:= Self; end;

procedure TLuaClass.PushMethod(ALuaState: TLuaState; AMethod: tLuaFunction);
begin
  lua_pushlightuserdata(ALuaState, TMethod(AMethod).Data);
  lua_pushlightuserdata(ALuaState, TMethod(AMethod).Code);
  lua_pushcclosure(ALuaState, LuaProxyFunction, 2);
end;

procedure TLuaClass.StartRegister;
begin fStartCount:= fFuncs.Count; end;

procedure TLuaClass.RegisterMethod(const AName: ansistring; AMethod: tLuaFunction);
begin fFuncs.RegisterMethod(AName, AMethod); end;

function TLuaClass.StopRegister(ALuaState: TLuaState; const ALibName: ansistring; aleave_table: boolean): integer;
var i   : integer;
    obj : TFuncProxyObject;
begin
  result:= 0;
  if assigned(ALuaState) then
    with fFuncs do try
      if count > fStartCount then begin
        lua_newtable(ALuaState);
        for i:= fStartCount to count - 1 do begin
          obj:= TFuncProxyObject(items[i]);
          lua_pushstring(ALuaState, pAnsiChar(obj.Name));
          lua_pushlightuserdata(ALuaState, TMethod(obj.Method).Data);
          lua_pushlightuserdata(ALuaState, TMethod(obj.Method).Code);
          lua_pushcclosure(ALuaState, LuaProxyFunction, 2);
          lua_settable(ALuaState, -3);
          inc(result);
        end;
        if (length(ALibName) > 0) then begin
          lua_pushvalue(ALuaState, -1);
          lua_setglobal(ALuaState, pAnsiChar(ALibName));
        end;
        if not aleave_table then lua_pop(ALuaState, 1);
      end;
    finally clear; end;
end;

procedure TLuaClass.RegisterGlobalMethod(ALuaState: TLuaState; const AName: ansistring; AMethod: tLuaFunction);
begin
  if assigned(ALuaState) then begin
    if assigned(AMethod) then begin
      lua_pushlightuserdata(ALuaState, TMethod(AMethod).Data);
      lua_pushlightuserdata(ALuaState, TMethod(AMethod).Code);
      lua_pushcclosure(ALuaState, LuaProxyFunction, 2);
    end else lua_pushnil(ALuaState);
    lua_setglobal(ALuaState, pAnsiChar(AName));
  end;
end;

end.
