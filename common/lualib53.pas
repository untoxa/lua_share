{*
** $Id: lua.h,v 1.325 2014/12/26 17:24:27 roberto Exp $
** Lua - A Scripting Language
** Lua.org, PUC-Rio, Brazil (http://www.lua.org)
** See Copyright Notice at the end of this file
*}

{$ifdef FPC}
  {$mode DELPHI}
{$else}
  {$define MSWINDOWS}
{$endif}

unit lualib53;

interface

{$ifdef MSWINDOWS}
uses windows;
{$endif}

{$ifdef FPC}
  {$ifdef CPU32}
    type size_t         = cardinal;
  {$else}
    {$ifdef CPU64}
      type size_t       = QWord;
    {$else}
      PLATFORM IS NOT SUPPORTED
    {$endif}
  {$endif}
{$else}
  type size_t         = cardinal;
       ppansichar     = ^ppansichar;
{$endif}


const
  LUA_LIBRARY = 'lua53.dll'; {Do not Localize}

{*
** luaconf.h
*}
  LUA_IDSIZE = 60;
  LUA_EXTRASPACE = sizeof(pointer);
  LUAI_FIRSTPSEUDOIDX = -1001000;

{*
** lua.h
*}
  LUA_VERSION_MAJOR   = '5';
  LUA_VERSION_MINOR   = '3';
  LUA_VERSION_NUM     = 503;
  LUA_VERSION_RELEASE = '0';

  LUA_VERSION_    = 'Lua ' + LUA_VERSION_MAJOR + '.' + LUA_VERSION_MINOR;
  LUA_RELEASE     = LUA_VERSION_ + '.' + LUA_VERSION_RELEASE;
  LUA_COPYRIGHT   = LUA_RELEASE + '  Copyright (C) 1994-2015 Lua.org, PUC-Rio';
  LUA_AUTHORS	  = 'R. Ierusalimschy, L. H. de Figueiredo, W. Celes';


{* mark for precompiled code ('<esc>Lua') *}
  LUA_SIGNATURE	= #$1b'Lua';

{* option for multiple returns in 'lua_pcall' and 'lua_call' *}
  LUA_MULTRET	= -1;


{*
** pseudo-indices
*}
   LUA_REGISTRYINDEX = LUAI_FIRSTPSEUDOIDX;

{* thread status *}
  LUA_OK         = 0;
  LUA_YIELD_     = 1;
  LUA_ERRRUN     = 2;
  LUA_ERRSYNTAX	 = 3;
  LUA_ERRMEM	 = 4;
  LUA_ERRGCMM	 = 5;
  LUA_ERRERR	 = 6;

{*
** basic types
*}
  LUA_TNONE          = (-1);

  LUA_TNIL	     = 0;
  LUA_TBOOLEAN	     = 1;
  LUA_TLIGHTUSERDATA = 2;
  LUA_TNUMBER	     = 3;
  LUA_TSTRING	     = 4;
  LUA_TTABLE	     = 5;
  LUA_TFUNCTION	     = 6;
  LUA_TUSERDATA	     = 7;
  LUA_TTHREAD	     = 8;

  LUA_NUMTAGS	     = 9;


{* minimum Lua stack available to a C function *}
  LUA_MINSTACK	     = 20;


{* predefined values in the registry *}
  LUA_RIDX_MAINTHREAD	= 1;
  LUA_RIDX_GLOBALS	= 2;
  LUA_RIDX_LAST		= LUA_RIDX_GLOBALS;

{*
** Comparison and arithmetic functions
*}

  LUA_OPADD  = 0; {* ORDER TM, ORDER OP *}
  LUA_OPSUB  = 1;
  LUA_OPMUL  = 2;
  LUA_OPMOD  = 3;
  LUA_OPPOW  = 4;
  LUA_OPDIV  = 5;
  LUA_OPIDIV = 6;
  LUA_OPBAND = 7;
  LUA_OPBOR  = 8;
  LUA_OPBXOR = 9;
  LUA_OPSHL  = 10;
  LUA_OPSHR  = 11;
  LUA_OPUNM  = 12;
  LUA_OPBNOT = 13;

  LUA_OPEQ  = 0;
  LUA_OPLT  = 1;
  LUA_OPLE  = 2;

{*
** garbage-collection function and options
*}

  LUA_GCSTOP	   = 0;
  LUA_GCRESTART	   = 1;
  LUA_GCCOLLECT	   = 2;
  LUA_GCCOUNT	   = 3;
  LUA_GCCOUNTB	   = 4;
  LUA_GCSTEP	   = 5;
  LUA_GCSETPAUSE   = 6;
  LUA_GCSETSTEPMUL = 7;
  LUA_GCISRUNNING  = 9;

{*
** Event codes
*}
  LUA_HOOKCALL     = 0;
  LUA_HOOKRET      = 1;
  LUA_HOOKLINE     = 2;
  LUA_HOOKCOUNT	   = 3;
  LUA_HOOKTAILCALL = 4;


{*
** Event masks
*}
 LUA_MASKCALL =	(1 SHL LUA_HOOKCALL);
 LUA_MASKRET = (1 SHL LUA_HOOKRET);
 LUA_MASKLINE =	(1 SHL LUA_HOOKLINE);
 LUA_MASKCOUNT = (1 SHL LUA_HOOKCOUNT);

{*
**  lualib.h
*}
  LUA_COLIBNAME = 'coroutine';
  LUA_TABLIBNAME = 'table';
  LUA_IOLIBNAME = 'io';
  LUA_OSLIBNAME	= 'os';
  LUA_STRLIBNAME = 'string';
  LUA_UTF8LIBNAME = 'utf8';
  LUA_BITLIBNAME = 'bit32';
  LUA_MATHLIBNAME = 'math';
  LUA_DBLIBNAME = 'debug';
  LUA_LOADLIBNAME = 'package';

{*
** lauxlib.h
*}

  LUAL_NUMSIZES = sizeof(size_t)*16 + sizeof(Double);

{* pre-defined references *}
  LUA_NOREF  = -2;
  LUA_REFNIL = -1;

{*
@@ LUAL_BUFFERSIZE is the buffer size used by the lauxlib buffer system.
** CHANGE it if it uses too much C-stack space.
*}
  LUAL_BUFFERSIZE = Integer($80 * sizeof(Pointer) * sizeof(size_t));

{*
** A file handle is a userdata with metatable 'LUA_FILEHANDLE' and
** initial structure 'luaL_Stream' (it may contain other fields
** after that initial structure).
*}

  LUA_FILEHANDLE = 'FILE*';

type
  lua_State = Pointer;
  ptrdiff_t = size_t;

{* type of numbers in Lua *}
   lua_Number   = Double;
   plua_Number  = ^lua_Number;

{* type for integer functions *}
  lua_Integer  = Int64;//NativeInt;

{* unsigned integer type *}
   lua_Unsigned = Int64; //NativeUInt;

{* type for continuation-function contexts *}
  lua_KContext = ptrdiff_t;


{*
** Type for C functions registered with Lua
*}
  lua_CFunction = function(L: lua_State): Integer; cdecl;

{*
** Type for continuation functions
*}
  lua_KFunction = function(L: lua_State; status: Integer; ctx: lua_KContext): Integer; cdecl;


{*
** Type for functions that read/write blocks when loading/dumping Lua chunks
*}
  lua_Reader = function(L: lua_State; ud: Pointer; var sz: size_t): Pointer; cdecl;
  lua_Writer = function(L: lua_State; p: Pointer; sz: size_t; ud: Pointer): Integer; cdecl;

{*
** Type for memory-allocation functions
*}
  lua_Alloc = function(ud: Pointer; ptr: Pointer; osize: size_t; nsize: size_t): Pointer; cdecl;


{*
** generic extra include file
*}
{#if defined(LUA_USER_H)
#include LUA_USER_H
#endif}


{*
** RCS ident string
*}
//extern const char lua_ident[];

 lua_Debug = record            (* activation record *)
    event: Integer;
    name: pansichar;           (* (n) *)
    namewhat: pansichar;       (* (n) `global', `local', `field', `method' *)
    what: pansichar;           (* (S) `Lua', `C', `main', `tail'*)
    source: pansichar;         (* (S) *)
    currentline: Integer;      (* (l) *)
    linedefined: Integer;      (* (S) *)
    lastlinedefined: Integer;  (* (S) *)
    nups: Byte;                (* (u) number of upvalues *)
    nparams: Byte;             (* (u) number of parameters *)
    isvararg: ByteBool;        (* (u) *)
    istailcall: ByteBool;      (* (t) *)
    short_src: array[0..LUA_IDSIZE - 1] of ansichar; (* (S) *)
    (* private part *)
    i_ci: Pointer;             (* active function *)  // ptr to struct CallInfo
 end;
 Plua_Debug = ^lua_Debug;


{* Functions to be called by the debugger in specific events *}
  lua_Hook = procedure(L: lua_State; ar: Plua_Debug); cdecl;

   luaL_Reg = record
      name: pansichar;
      func: lua_CFunction;
   end;
   PluaL_Reg = ^luaL_Reg;

{*
** Generic Buffer manipulation
*}

   luaL_Buffer = record
     b: pansichar; {* buffer address *}
     size: size_t;  {* buffer size *}
     n: size_t;  {* number of characters in buffer *}
     L: lua_State;
     initb: array[0..LUAL_BUFFERSIZE - 1] of Byte;  {* initial buffer *}
   end;

   Plual_Buffer = ^lual_Buffer;

{*
** File handles for IO library
*}
   luaL_Stream = record
     f: Pointer; {* stream (NULL for incompletely created streams) *}
     closef: lua_CFunction; {* to close stream (NULL for closed streams) *}
   end;

// Use procedure entries as variables (only if dynamic library)
var
{*
** state manipulation
*}
  lua_newstate: function(f: lua_Alloc; ud: Pointer): lua_State; cdecl;
  lua_close: procedure (L: lua_State); cdecl;
  lua_newthread: function(L: lua_State): lua_State; cdecl;
  lua_atpanic: function(L: lua_State; panicf: lua_CFunction): lua_CFunction; cdecl;
  lua_version: function(L: lua_State): plua_Number; cdecl;

{*
** basic stack manipulation
*}
  lua_absindex: function(L: lua_State; idx: Integer): Integer; cdecl;
  lua_gettop: function(L: lua_State): Integer; cdecl;
  lua_settop: procedure(L: lua_State; idx: Integer); cdecl;
  lua_pushvalue: procedure(L: lua_State; idx: Integer); cdecl;
  lua_rotate: procedure(L: lua_State; idx: Integer; n: Integer); cdecl;
  lua_copy: procedure(L: lua_State; fromidx: Integer; toidx: Integer); cdecl;
  lua_checkstack: function(L: lua_State; n: Integer): Integer; cdecl;
  lua_xmove: procedure(from: lua_State; to_: lua_State; n: Integer); cdecl;

{*
** access functions (stack -> C)
*}
  lua_isnumber: function(L: lua_State; idx: Integer): LongBool; cdecl;
  lua_isstring: function(L: lua_State; idx: Integer): LongBool; cdecl;
  lua_iscfunction: function(L: lua_State; idx: Integer): LongBool; cdecl;
  lua_isinteger: function(L: lua_State; idx: Integer): LongBool; cdecl;
  lua_isuserdata: function(L: lua_State; idx: Integer): LongBool; cdecl;
  lua_type: function(L: lua_State; idx: Integer): Integer; cdecl;
  lua_typename: function(L: lua_State; tp: Integer): pansichar; cdecl;

  lua_tonumberx: function(L: lua_State; idx: Integer; var isnum: LongBool): lua_Number; cdecl;
  lua_tointegerx: function(L: lua_State; idx: Integer; var isnum: LongBool): lua_Integer; cdecl;
  lua_toboolean: function(L: lua_State; idx: Integer): longbool; cdecl;
  lua_tolstring: function(L: lua_State; idx: Integer; var len: size_t): pansichar; cdecl;
  lua_rawlen: function(L: lua_State; idx: Integer): size_t; cdecl;
  lua_tocfunction: function(L: lua_State; idx: Integer): lua_CFunction; cdecl;
  lua_touserdata: function(L: lua_State; idx: Integer): Pointer; cdecl;
  lua_tothread: function(L: lua_State; idx: Integer): lua_State; cdecl;
  lua_topointer: function(L: lua_State; idx: Integer): Pointer; cdecl;

{*
** Comparison and arithmetic functions
*}
  lua_arith: procedure(L: lua_State; op: Integer); cdecl;
  lua_rawequal: function(L: lua_State; idx1: Integer; idx2: Integer): Integer; cdecl;
  lua_compare: function(L: lua_State; idx1: Integer; idx2: Integer; op: Integer): Integer; cdecl;

{*
** push functions (C -> stack)
*}
  lua_pushnil: procedure(L: lua_State); cdecl;
  lua_pushnumber: procedure(L: lua_State; n: lua_Number); cdecl;
  lua_pushinteger: procedure(L: lua_State; n: lua_Integer); cdecl;
  lua_pushlstring: function(L: lua_State; s: pansichar; len: size_t): pansichar; cdecl;
  lua_pushstring: function(L: lua_State; s: pansichar): pansichar; cdecl;
  lua_pushvfstring: function(L: lua_State; fmt: pansichar; argp: Pointer): pansichar; cdecl;
  lua_pushfstring: function(L: lua_State; fmt: pansichar; args: array of const): pansichar; cdecl;
  lua_pushcclosure: procedure(L: lua_State; fn: lua_CFunction; n: Integer); cdecl;
  lua_pushboolean: procedure(L: lua_State; b: longbool); cdecl;
  lua_pushlightuserdata: procedure(L: lua_State; p: Pointer); cdecl;
  lua_pushthread: function(L: lua_State): Integer; cdecl;

{*
** get functions (Lua -> stack)
*}
  lua_getglobal: function(L: lua_State; const name: pansichar): Integer; cdecl;
  lua_gettable: function(L: lua_State; idx: Integer): Integer; cdecl;
  lua_getfield: function(L: lua_State; idx: Integer; k: pansichar): Integer; cdecl;
  lua_geti: function(L: lua_State; idx: Integer; n: lua_Integer): Integer; cdecl;
  lua_rawget: function(L: lua_State; idx: Integer): Integer; cdecl;
  lua_rawgeti: function(L: lua_State; idx: Integer; n: lua_Integer): Integer; cdecl;
  lua_rawgetp: function(L: lua_State; idx: Integer; p: Pointer): Integer; cdecl;

  lua_createtable: procedure(L: lua_State; narr: Integer; nrec: Integer); cdecl;
  lua_newuserdata: function(L: lua_State; sz: size_t): Pointer; cdecl;
  lua_getmetatable: function(L: lua_State; objindex: Integer): Integer; cdecl;
  lua_getuservalue: function(L: lua_State; idx: Integer): Integer; cdecl;

{*
** set functions (stack -> Lua)
*}
  lua_setglobal: procedure(L: lua_State; name: pansichar); cdecl;
  lua_settable: procedure(L: lua_State; idx: Integer); cdecl;
  lua_setfield: procedure(L: lua_State; idx: Integer; k: pansichar); cdecl;
  lua_seti: procedure(L: lua_State; idx: Integer; n: lua_Integer); cdecl;
  lua_rawset: procedure(L: lua_State; idx: Integer); cdecl;
  lua_rawseti: procedure(L: lua_State; idx: Integer; n: lua_Integer); cdecl;
  lua_rawsetp: procedure(L: lua_State; idx: Integer; p: Pointer); cdecl;
  lua_setmetatable: function(L: lua_State; objindex: Integer): Integer; cdecl;
  lua_setuservalue: procedure(L: lua_State; idx: Integer); cdecl;

{*
** 'load' and 'call' functions (load and run Lua code)
*}
  lua_callk: procedure(L: lua_State; nargs: Integer; nresults: Integer; ctx: lua_KContext; k: lua_KFunction); cdecl;

  lua_pcallk: function(L: lua_State; nargs: Integer; nresults: Integer; errfunc: Integer;
    ctx: lua_KContext; k: lua_KFunction): Integer; cdecl;

  lua_load: function(L: lua_State; reader: lua_Reader; dt: Pointer; const chunkname: pansichar;
    const mode: pansichar): Integer; cdecl;

  lua_dump: function(L: lua_State; writer: lua_Writer; data: Pointer; strip: Integer): Integer; cdecl;

{*
** coroutine functions
*}
  lua_yieldk: function(L: lua_State; nresults: Integer; ctx: lua_KContext; k: lua_KFunction): Integer; cdecl;
  lua_resume: function(L: lua_State; from: lua_State; narg: Integer): Integer; cdecl;
  lua_status: function(L: lua_State): Integer; cdecl;
  lua_isyieldable: function(L: lua_State): Integer; cdecl;

{*
** garbage-collection function and options
*}
  lua_gc: function(L: lua_State; what: Integer; data: Integer): Integer; cdecl;

{*
** miscellaneous functions
*}
  lua_error: function(L: lua_State): Integer; cdecl;
  lua_next: function(L: lua_State; idx: Integer): Integer; cdecl;

  lua_concat: procedure(L: lua_State; n: Integer); cdecl;
  lua_len: procedure(L: lua_State; idx: Integer); cdecl;

  lua_stringtonumber: function(L: lua_State; const s: pansichar): size_t; cdecl;

  lua_getallocf: function(L: lua_State; var ud: Pointer): lua_Alloc; cdecl;
  lua_setallocf: procedure(L: lua_State; f: lua_Alloc; ud: Pointer); cdecl;

{*
** ======================================================================
** Debug API
** ======================================================================
*}
  lua_getstack: function(L: lua_State; level: Integer; ar: Plua_Debug): Integer; cdecl;
  lua_getinfo: function(L: lua_State; const what: pansichar; ar: Plua_Debug): Integer; cdecl;
  lua_getlocal: function(L: lua_State; const ar: Plua_Debug; n: Integer): pansichar; cdecl;
  lua_setlocal: function(L: lua_State; const ar: Plua_Debug; n: Integer): pansichar; cdecl;
  lua_getupvalue: function(L: lua_State; funcindex, n: Integer): pansichar; cdecl;
  lua_setupvalue: function(L: lua_State; funcindex, n: Integer): pansichar; cdecl;
  lua_upvalueid: function(L: lua_State; fidx, n: Integer): Pointer; cdecl;
  lua_upvaluejoin: procedure(L: lua_State; fix1, n1, fidx2, n2: Integer); cdecl;
  lua_sethook: procedure(L: lua_State; func: lua_Hook; mask: Integer; count: Integer); cdecl;
  lua_gethook: function(L: lua_State): lua_Hook; cdecl;
  lua_gethookmask: function(L: lua_State): Integer; cdecl;
  lua_gethookcount: function(L: lua_State): Integer; cdecl;

{*
** ======================================================================
** lualib.h
** ======================================================================
*}
  luaopen_base: function(L: lua_State): Integer; cdecl;
  luaopen_coroutine: function(L: lua_State): Integer; cdecl;
  luaopen_table: function(L: lua_State): Integer; cdecl;
  luaopen_io: function(L: lua_State): Integer; cdecl;
  luaopen_os: function(L: lua_State): Integer; cdecl;
  luaopen_string: function(L: lua_State): Integer; cdecl;
  luaopen_utf8: function(L: lua_State): Integer; cdecl;
  luaopen_bit32: function(L: lua_State): Integer; cdecl;
  luaopen_math: function(L: lua_State): Integer; cdecl;
  luaopen_debug: function(L: lua_State): Integer; cdecl;
  luaopen_package: function(L: lua_State): Integer; cdecl;

 {* open all previous libraries *}
  luaL_openlibs: procedure(L: lua_State); cdecl;

{*
** ======================================================================
** lauxlib.h
** ======================================================================
*}
  luaL_checkversion_: procedure(L: lua_State; ver: lua_Number; sz: size_t); cdecl;
  luaL_getmetafield: function(L: lua_State; obj: Integer; e: pansichar): Integer; cdecl;
  luaL_callmeta: function(L: lua_State; obj: Integer; e: pansichar): Integer; cdecl;
  luaL_tolstring: function(L: lua_State; idx: Integer; var len: size_t): pansichar; cdecl;
  luaL_argerror: function(L: lua_State; arg: Integer; extramsg: pansichar): Integer; cdecl;
  luaL_checklstring: function(L: lua_State; arg: Integer; var l_: size_t): pansichar; cdecl;
  luaL_optlstring: function(L: lua_State; arg: Integer; const def: pansichar; var l_: size_t): pansichar; cdecl;
  luaL_checknumber: function(L: lua_State; arg: Integer): lua_Number; cdecl;
  luaL_optnumber: function(L: lua_State; arg: Integer; def: lua_Number): lua_Number; cdecl;
  luaL_checkinteger: function(L: lua_State; arg: Integer): lua_Integer; cdecl;
  luaL_optinteger: function(L: lua_State; arg: Integer; def: lua_Integer): lua_Integer; cdecl;

  luaL_checkstack: procedure(L: lua_State; sz: Integer; const msg: pansichar); cdecl;
  luaL_checktype: procedure(L: lua_State; arg: Integer; t: Integer); cdecl;
  luaL_checkany: procedure(L: lua_State; arg: Integer); cdecl;

  luaL_newmetatable: function(L: lua_State; const tname: pansichar): Integer; cdecl;
  luaL_setmetatable: procedure(L: lua_State; const tname: pansichar); cdecl;
  luaL_testudata: procedure(L: lua_State; ud: Integer; const tname: pansichar); cdecl;
  luaL_checkudata: function(L: lua_State; ud: Integer; const tname: pansichar): Pointer; cdecl;

  luaL_where: procedure(L: lua_State; lvl: Integer); cdecl;
  luaL_error: function(L: lua_State; fmt: pansichar; args: array of const): Integer; cdecl;

  luaL_checkoption: function(L: lua_State; arg: Integer; const def: pansichar; const lst: ppansichar): Integer; cdecl;
  luaL_fileresult: function(L: lua_State; stat: Integer; fname: pansichar): Integer; cdecl;
  luaL_execresult: function(L: lua_State; stat: Integer): Integer; cdecl;


  luaL_ref: function(L: lua_State; t: Integer): Integer; cdecl;
  luaL_unref: procedure(L: lua_State; t: Integer; ref: Integer); cdecl;
  luaL_loadfilex: function(L: lua_State; const filename: pansichar; const mode: pansichar): Integer; cdecl;

  luaL_loadbufferx: function(L: lua_State; const buff: pansichar; sz: size_t;
                                   const name: pansichar; const mode: pansichar): Integer; cdecl;
  luaL_loadstring: function(L: lua_State; const s: pansichar): Integer; cdecl;

  luaL_newstate: function(): lua_State; cdecl;
  luaL_len: function(L: lua_State; idx: Integer): lua_Integer; cdecl;

  luaL_gsub: function(L: lua_State; const s: pansichar; const p: pansichar; const r: pansichar): pansichar; cdecl;
  luaL_setfuncs: procedure(L: lua_State; const l_: PluaL_Reg; nup: Integer); cdecl;

  luaL_getsubtable: function(L: lua_State; idx: Integer; const fname: pansichar): Integer; cdecl;

  luaL_traceback: procedure(L: lua_State; L1: lua_State; const msg: pansichar; level: Integer); cdecl;

  luaL_requiref: procedure(L: lua_State; const modname: pansichar; openf: lua_CFunction; glb: Integer); cdecl;

{*
** ======================================================
** Generic Buffer manipulation
** ======================================================
*}
  luaL_buffinit: procedure(L: lua_State; B: PluaL_Buffer); cdecl;
  luaL_prepbuffsize: function(B: Plual_buffer; sz: size_t): Pointer; cdecl;
  luaL_addlstring: procedure(B: Plual_buffer; const s: pansichar; l: size_t); cdecl;
  luaL_addstring: procedure(B: Plual_buffer; const s: pansichar); cdecl;
  luaL_addvalue: procedure(B: Plual_buffer); cdecl;
  luaL_pushresult: procedure(B: Plual_buffer); cdecl;
  luaL_pushresultsize: procedure(B: Plual_buffer; sz: size_t); cdecl;
  luaL_buffinitsize: function(L: lua_State; B: Plual_buffer; sz: size_t): Pointer; cdecl;

{* ====================================================== *}


{* compatibility with old module system */
#if defined(LUA_COMPAT_MODULE)

LUALIB_API void (luaL_pushmodule) (L: lua_State; const char *modname,
                                   int sizehint);
LUALIB_API void (luaL_openlib) (L: lua_State; const char *libname,
                                const luaL_Reg *l, int nup);

#define luaL_register(L,n,l)	(luaL_openlib(L,(n),(l),0))

#endif}


{*
** {============================================================
** Compatibility with deprecated conversions
** =============================================================
*/
#if defined(LUA_COMPAT_APIINTCASTS)

#define luaL_checkunsigned(L,a)	((lua_Unsigned)luaL_checkinteger(L,a))
#define luaL_optunsigned(L,a,d)	\
	((lua_Unsigned)luaL_optinteger(L,a,(lua_Integer)(d)))

#define luaL_checkint(L,n)	((int)luaL_checkinteger(L, (n)))
#define luaL_optint(L,n,d)	((int)luaL_optinteger(L, (n), (d)))

#define luaL_checklong(L,n)	((long)luaL_checkinteger(L, (n)))
#define luaL_optlong(L,n,d)	((long)luaL_optinteger(L, (n), (d)))

#endif
}


{*
** ==============================================================
** some useful macros
** ==============================================================
*}
function lua_getextraspace(L: lua_State): pointer;
function lua_tonumber(L: lua_State; idx: Integer): lua_Number;
function lua_tointeger(L: lua_State; idx: Integer): lua_Integer;
procedure lua_pop(L: lua_State; n: Integer);
procedure lua_newtable(L: lua_state);
procedure lua_register(L: lua_State; const n: pansichar; f: lua_CFunction);
procedure lua_pushcfunction(L: lua_State; f: lua_CFunction);
function lua_isfunction(L: lua_State; n: Integer): Boolean;
function lua_istable(L: lua_State; n: Integer): Boolean;
function lua_islightuserdata(L: lua_State; n: Integer): Boolean;
function lua_isnil(L: lua_State; n: Integer): Boolean;
function lua_isboolean(L: lua_State; n: Integer): Boolean;
function lua_isthread(L: lua_State; n: Integer): Boolean;
function lua_isnone(L: lua_State; n: Integer): Boolean;
function lua_isnoneornil(L: lua_State; n: Integer): Boolean;
procedure lua_pushliteral(L: lua_State; s: pansichar);
procedure lua_pushglobaltable(L: lua_State);
function lua_tostring(L: lua_State; i: Integer): pansichar;
procedure lua_insert(L: lua_State; idx: Integer);
procedure lua_remove(L: lua_State; idx: Integer);
procedure lua_replace(L: lua_State; idx: Integer);

{*
** ===============================================================
** some useful lauxlib macros
** ===============================================================
*}

procedure luaL_newlibtable(L: lua_State; lr: array of luaL_Reg); overload;
procedure luaL_newlibtable(L: lua_State; lr: PluaL_Reg); overload;
procedure luaL_newlib(L: lua_State; lr: array of luaL_Reg); overload;
procedure luaL_newlib(L: lua_State; lr: PluaL_Reg); overload;
procedure luaL_argcheck(L: lua_State; cond: Boolean; arg: Integer; extramsg: pansichar);
function luaL_checkstring(L: lua_State; n: Integer): pansichar;
function luaL_optstring(L: lua_State; n: Integer; d: pansichar): pansichar;
function luaL_typename(L: lua_State; i: Integer): pansichar;
function luaL_dofile(L: lua_State; const fn: pansichar): Integer;
function luaL_dostring(L: lua_State; const s: pansichar): Integer;
procedure luaL_getmetatable(L: lua_State; n: pansichar);
function luaL_loadbuffer(L: lua_State; const s: pansichar; sz: size_t; const n: pansichar): Integer;
{

#define luaL_addchar(B,c) \
  ((void)((B)->n < (B)->size || luaL_prepbuffsize((B), 1)), \
   ((B)->b[(B)->n++] = (c)))

procedure luaL_addsize(B: PluaL_Buffer; s: pansichar);

#define B,s)	((B)->n += (s))}


{*
** ==============================================================
** other macros needed
** ==============================================================
*}
procedure lua_call(L: lua_State; nargs: Integer; nresults: Integer);
function lua_pcall(L: lua_State; nargs: Integer; nresults: Integer; errfunc: Integer): Integer;
function lua_yield(L: lua_State; nresults: Integer): Integer;
function lua_upvalueindex(i: Integer): Integer;
procedure luaL_checkversion(L: lua_State);
function lual_loadfile(L: lua_State; const filename: pansichar): Integer;
function luaL_prepbuffer(B: Plual_buffer): pansichar;

{*
** ==================================================================
** "Abstraction Layer" for basic report of messages and errors
** ==================================================================
*}

{* print a string *
#if !defined(lua_writestring)
#define lua_writestring(s,l)   fwrite((s), sizeof(char), (l), stdout)
#endif

/* print a newline and flush the output */
#if !defined(lua_writeline)
#define lua_writeline()        (lua_writestring("\n", 1), fflush(stdout))
#endif

/* print an error message */
#if !defined(lua_writestringerror)
#define lua_writestringerror(s,p) \
        (fprintf(stderr, (s), (p)), fflush(stderr))
#endif
}

{*
** ==============================================================
** compatibility macros for unsigned conversions
** ===============================================================
*/
#if defined(LUA_COMPAT_APIINTCASTS)

#define lua_pushunsigned(L,n)	lua_pushinteger(L, (lua_Integer)(n))
#define lua_tounsignedx(L,i,is)	((lua_Unsigned)lua_tointegerx(L,i,is))
#define lua_tounsigned(L,i)	lua_tounsignedx(L,(i),NULL)

#endif
* ============================================================== *}

{* ====================================================================== *}

(*
** Dynamic library manipulation
*)
function  GetProcAddr(fHandle: THandle; const aname: ansistring; bErrorIfNotExists: Boolean = True): pointer;
procedure SetLuaLibFileName( newLuaLibFileName: ansistring);
function  GetLuaLibFileName(): ansistring;
function  LoadLuaLib(newLuaLibFileName: ansistring = ''): HMODULE;
function  InitializeLuaLib(ALibHandle: HMODULE): HMODULE;
procedure FreeLuaLib();
function  LuaLibLoaded: Boolean;

implementation

uses sysutils;

function lua_getextraspace(L: lua_State): pointer;
begin result:= pointer(pAnsiChar(L) - LUA_EXTRASPACE); end;

function lua_tonumber(L: lua_State; idx: Integer): lua_Number;
var tmp : longbool;
begin Result := lua_tonumberx(L, idx, tmp); end;

function lua_tointeger(L: lua_State; idx: Integer): lua_Integer;
var tmp : longbool;
begin Result := lua_tointegerx(L, idx, tmp); end;

procedure lua_pop(L: lua_State; n: Integer);
begin lua_settop(L, -(n)-1); end;

procedure lua_newtable(L: lua_state);
begin lua_createtable(L, 0, 0); end;

procedure lua_register(L: lua_State; const n: pansichar; f: lua_CFunction);
begin lua_pushcfunction(L, f); lua_setglobal(L, n); end;

procedure lua_pushcfunction(L: lua_State; f: lua_CFunction);
begin lua_pushcclosure(L, f, 0); end;

function lua_isfunction(L: lua_State; n: Integer): Boolean;
begin Result := (lua_type(L, n) = LUA_TFUNCTION); end;

function lua_istable(L: lua_State; n: Integer): Boolean;
begin Result := (lua_type(L, n) = LUA_TTABLE); end;

function lua_islightuserdata(L: lua_State; n: Integer): Boolean;
begin Result := (lua_type(L, n) = LUA_TLIGHTUSERDATA); end;

function lua_isnil(L: lua_State; n: Integer): Boolean;
begin Result := (lua_type(L, n) = LUA_TNIL); end;

function lua_isboolean(L: lua_State; n: Integer): Boolean;
begin Result := (lua_type(L, n) = LUA_TBOOLEAN); end;

function lua_isthread(L: lua_State; n: Integer): Boolean;
begin Result := (lua_type(L, n) = LUA_TTHREAD); end;

function lua_isnone(L: lua_State; n: Integer): Boolean;
begin Result := (lua_type(L, n) = LUA_TNONE); end;

function lua_isnoneornil(L: lua_State; n: Integer): Boolean;
begin Result := (lua_type(L, n) <= 0); end;

procedure lua_pushliteral(L: lua_State; s: pansichar);
begin lua_pushlstring(L, s, Length(s)); end;

procedure lua_pushglobaltable(L: lua_State);
begin lua_rawgeti(L, LUA_REGISTRYINDEX, LUA_RIDX_GLOBALS); end;

function lua_tostring(L: lua_State; i: Integer): pansichar;
var tmp : size_t;
begin Result := lua_tolstring(L, i, tmp); end;

procedure lua_insert(L: lua_State; idx: Integer);
begin lua_rotate(L, idx, 1); end;

procedure lua_remove(L: lua_State; idx: Integer);
begin lua_rotate(L, idx, -1); lua_pop(L, 1); end;

procedure lua_replace(L: lua_State; idx: Integer);
begin lua_copy(L, -1, idx); lua_pop(L, 1); end;

procedure lua_call(L: lua_State; nargs: Integer; nresults: Integer);
begin lua_callk(L, nargs, nresults, 0, NIL); end;

function lua_pcall(L: lua_State; nargs: Integer; nresults: Integer; errfunc: Integer): Integer;
begin Result := lua_pcallk(L, nargs, nresults, errfunc, 0, NIL); end;

function lua_yield(L: lua_State; nresults: Integer): Integer;
begin Result := lua_yieldk(L, nresults, 0, NIL); end;

function lua_upvalueindex(i: Integer): Integer;
begin Result := LUA_REGISTRYINDEX - i; end;

{*
** ===============================================================
** some useful lauxlib macros
** ===============================================================
*}

procedure luaL_newlibtable(L: lua_State; lr: array of luaL_Reg); overload;
begin lua_createtable(L, 0, High(lr)); end;

procedure luaL_newlibtable(L: lua_State; lr: PluaL_Reg); overload;
var
  n: Integer;
begin
  n := 0;
  while lr^.name <> nil do
  begin
    inc(n);
    inc(lr);
  end;
  lua_createtable(L, 0, n);
end;

procedure luaL_newlib(L: lua_State; lr: array of luaL_Reg); overload;
begin
  luaL_newlibtable(L, lr);
  luaL_setfuncs(L, @lr, 0);
end;

procedure luaL_newlib(L: lua_State; lr: PluaL_Reg); overload;
begin
  luaL_newlibtable(L, lr);
  luaL_setfuncs(L, lr, 0);
end;

procedure luaL_argcheck(L: lua_State; cond: Boolean; arg: Integer; extramsg: pansichar);
begin
  if not cond then luaL_argerror(L, arg, extramsg);
end;


function luaL_checkstring(L: lua_State; n: Integer): pansichar;
var tmp : size_t;
begin Result := luaL_checklstring(L, n, tmp); end;

function luaL_optstring(L: lua_State; n: Integer; d: pansichar): pansichar;
var tmp : size_t;
begin Result := luaL_optlstring(L, n, d, tmp); end;

function luaL_typename(L: lua_State; i: Integer): pansichar;
begin Result := lua_typename(L, lua_type(L, i)); end;

function luaL_dofile(L: lua_State; const fn: pansichar): Integer;
begin
   Result := luaL_loadfile(L, fn);
   if Result = 0 then
      Result := lua_pcall(L, 0, LUA_MULTRET, 0);
end;


function luaL_dostring(L: lua_State; const s: pansichar): Integer;
begin
   Result := luaL_loadstring(L, s);
   if Result = 0 then
      Result := lua_pcall(L, 0, LUA_MULTRET, 0);
end;

procedure luaL_getmetatable(L: lua_State; n: pansichar);
begin lua_getfield(L, LUA_REGISTRYINDEX, n); end;

function luaL_loadbuffer(L: lua_State; const s: pansichar; sz: size_t; const n: pansichar): Integer;
begin Result := luaL_loadbufferx(L, s, sz, n, NIL); end;


procedure luaL_checkversion(L: lua_State);
begin luaL_checkversion_(L, LUA_VERSION_NUM, LUAL_NUMSIZES); end;

function lual_loadfile(L: lua_State; const filename: pansichar): Integer;
begin Result := luaL_loadfilex(L, filename, NIL); end;

function luaL_prepbuffer(B: Plual_buffer): pansichar;
begin Result := luaL_prepbuffsize(B, LUAL_BUFFERSIZE); end;

var
  fLibHandle: HMODULE = 0;
  fLibLoaded: boolean = false;
  fLuaLibFileName: ansistring = LUA_LIBRARY;

(*
** Dynamic library manipulation
*)

function GetProcAddr(fHandle: THandle; const aname: ansistring; bErrorIfNotExists: Boolean = True): pointer;
begin
  Result := GetProcAddress(fHandle, PAnsiChar(aname));
  if bErrorIfNotExists and ( Result = nil ) then
     Raise Exception.CreateFmt('Unable to locate function "%s"', [aname]);
end;

procedure SetLuaLibFileName(newLuaLibFileName: ansistring);
begin fLuaLibFileName := newLuaLibFileName; end;

function GetLuaLibFileName(): ansistring;
begin Result := fLuaLibFileName; end;

function LuaLibLoaded: Boolean;
begin Result := fLibHandle <> 0; end;

function  InitializeLuaLib(ALibHandle: HMODULE): HMODULE;
begin
  lua_newstate := GetProcAddr(ALibHandle, 'lua_newstate');
  lua_close := GetProcAddr(ALibHandle, 'lua_close');
  lua_newthread := GetProcAddr(ALibHandle, 'lua_newthread');
  lua_atpanic := GetProcAddr(ALibHandle, 'lua_atpanic');
  lua_version := GetProcAddr(ALibHandle, 'lua_version');

  lua_absindex := GetProcAddr(ALibHandle, 'lua_absindex');
  lua_gettop := GetProcAddr(ALibHandle, 'lua_gettop');
  lua_settop := GetProcAddr(ALibHandle, 'lua_settop');
  lua_pushvalue := GetProcAddr(ALibHandle, 'lua_pushvalue');
  lua_rotate := GetProcAddr(ALibHandle, 'lua_rotate');
  lua_copy := GetProcAddr(ALibHandle, 'lua_copy');
  lua_checkstack := GetProcAddr(ALibHandle, 'lua_checkstack');
  lua_xmove  := GetProcAddr(ALibHandle, 'lua_xmove');

  lua_isnumber := GetProcAddr(ALibHandle, 'lua_isnumber');
  lua_isstring := GetProcAddr(ALibHandle, 'lua_isstring');
  lua_iscfunction := GetProcAddr(ALibHandle, 'lua_iscfunction');
  lua_isinteger := GetProcAddr(ALibHandle, 'lua_isinteger');
  lua_isuserdata := GetProcAddr(ALibHandle, 'lua_isuserdata');
  lua_type  := GetProcAddr(ALibHandle, 'lua_type');
  lua_typename := GetProcAddr(ALibHandle, 'lua_typename');

  lua_tonumberx := GetProcAddr(ALibHandle, 'lua_tonumberx');
  lua_tointegerx := GetProcAddr(ALibHandle, 'lua_tointegerx');
  lua_toboolean := GetProcAddr(ALibHandle, 'lua_toboolean');
  lua_tolstring := GetProcAddr(ALibHandle, 'lua_tolstring');
  lua_rawlen := GetProcAddr(ALibHandle, 'lua_rawlen');
  lua_tocfunction := GetProcAddr(ALibHandle, 'lua_tocfunction');
  lua_touserdata := GetProcAddr(ALibHandle, 'lua_touserdata');
  lua_tothread := GetProcAddr(ALibHandle, 'lua_tothread');
  lua_topointer := GetProcAddr(ALibHandle, 'lua_topointer');

  lua_arith := GetProcAddr(ALibHandle, 'lua_arith');
  lua_rawequal := GetProcAddr(ALibHandle, 'lua_rawequal');
  lua_compare := GetProcAddr(ALibHandle, 'lua_compare');

  lua_pushnil := GetProcAddr(ALibHandle, 'lua_pushnil');
  lua_pushnumber := GetProcAddr(ALibHandle, 'lua_pushnumber');
  lua_pushinteger := GetProcAddr(ALibHandle, 'lua_pushinteger');
  lua_pushlstring := GetProcAddr(ALibHandle, 'lua_pushlstring');
  lua_pushstring := GetProcAddr(ALibHandle, 'lua_pushstring');
  lua_pushvfstring := GetProcAddr(ALibHandle, 'lua_pushvfstring');
  lua_pushfstring := GetProcAddr(ALibHandle, 'lua_pushfstring');
  lua_pushcclosure := GetProcAddr(ALibHandle, 'lua_pushcclosure');
  lua_pushboolean := GetProcAddr(ALibHandle, 'lua_pushboolean');
  lua_pushlightuserdata := GetProcAddr(ALibHandle, 'lua_pushlightuserdata');
  lua_pushthread := GetProcAddr(ALibHandle, 'lua_pushthread');

  lua_getglobal := GetProcAddr(ALibHandle, 'lua_getglobal');
  lua_gettable := GetProcAddr(ALibHandle, 'lua_gettable');
  lua_getfield := GetProcAddr(ALibHandle, 'lua_getfield');
  lua_geti := GetProcAddr(ALibHandle, 'lua_geti');
  lua_rawget := GetProcAddr(ALibHandle, 'lua_rawget');
  lua_rawgeti := GetProcAddr(ALibHandle, 'lua_rawgeti');
  lua_rawgetp := GetProcAddr(ALibHandle, 'lua_rawgetp');

  lua_createtable := GetProcAddr(ALibHandle, 'lua_createtable');
  lua_newuserdata := GetProcAddr(ALibHandle, 'lua_newuserdata');
  lua_getmetatable := GetProcAddr(ALibHandle, 'lua_getmetatable');
  lua_getuservalue := GetProcAddr(ALibHandle, 'lua_getuservalue');

  lua_setglobal := GetProcAddr(ALibHandle, 'lua_setglobal');
  lua_settable := GetProcAddr(ALibHandle, 'lua_settable');
  lua_setfield := GetProcAddr(ALibHandle, 'lua_setfield');
  lua_seti := GetProcAddr(ALibHandle, 'lua_seti');
  lua_rawset := GetProcAddr(ALibHandle, 'lua_rawset');
  lua_rawseti := GetProcAddr(ALibHandle, 'lua_rawseti');
  lua_rawsetp := GetProcAddr(ALibHandle, 'lua_rawsetp');
  lua_setmetatable := GetProcAddr(ALibHandle, 'lua_setmetatable');
  lua_setuservalue := GetProcAddr(ALibHandle, 'lua_setuservalue');

  lua_callk := GetProcAddr(ALibHandle, 'lua_callk');
  lua_pcallk := GetProcAddr(ALibHandle, 'lua_pcallk');
  lua_load := GetProcAddr(ALibHandle, 'lua_load');
  lua_dump := GetProcAddr(ALibHandle, 'lua_dump');

  lua_yieldk := GetProcAddr(ALibHandle, 'lua_yieldk');
  lua_resume := GetProcAddr(ALibHandle, 'lua_resume');
  lua_status := GetProcAddr(ALibHandle, 'lua_status');
  lua_isyieldable := GetProcAddr(ALibHandle, 'lua_isyieldable');

  lua_gc := GetProcAddr(ALibHandle, 'lua_gc');

  lua_error := GetProcAddr(ALibHandle, 'lua_error');
  lua_next := GetProcAddr(ALibHandle, 'lua_next');
  lua_concat := GetProcAddr(ALibHandle, 'lua_concat');
  lua_len := GetProcAddr(ALibHandle, 'lua_len');

  lua_stringtonumber := GetProcAddr(ALibHandle, 'lua_stringtonumber');
  lua_getallocf := GetProcAddr(ALibHandle, 'lua_getallocf');
  lua_setallocf := GetProcAddr(ALibHandle, 'lua_setallocf');

  lua_getstack := GetProcAddr(ALibHandle, 'lua_getstack');
  lua_getinfo := GetProcAddr(ALibHandle, 'lua_getinfo');
  lua_getlocal := GetProcAddr(ALibHandle, 'lua_getlocal');
  lua_setlocal := GetProcAddr(ALibHandle, 'lua_setlocal');
  lua_getupvalue := GetProcAddr(ALibHandle, 'lua_getupvalue');
  lua_setupvalue := GetProcAddr(ALibHandle, 'lua_setupvalue');
  lua_upvalueid := GetProcAddr(ALibHandle, 'lua_upvalueid');
  lua_upvaluejoin := GetProcAddr(ALibHandle, 'lua_upvaluejoin');

  lua_sethook := GetProcAddr(ALibHandle, 'lua_sethook');
  lua_gethook := GetProcAddr(ALibHandle, 'lua_gethook');
  lua_gethookmask := GetProcAddr(ALibHandle, 'lua_gethookmask');
  lua_gethookcount := GetProcAddr(ALibHandle, 'lua_gethookcount');

  luaopen_base := GetProcAddr(ALibHandle, 'luaopen_base');
  luaopen_coroutine := GetProcAddr(ALibHandle, 'luaopen_coroutine');
  luaopen_table := GetProcAddr(ALibHandle, 'luaopen_table');
  luaopen_io := GetProcAddr(ALibHandle, 'luaopen_io');
  luaopen_os := GetProcAddr(ALibHandle, 'luaopen_os');
  luaopen_string := GetProcAddr(ALibHandle, 'luaopen_string');
  luaopen_utf8 := GetProcAddr(ALibHandle, 'luaopen_utf8');
  luaopen_bit32 := GetProcAddr(ALibHandle, 'luaopen_bit32');
  luaopen_math := GetProcAddr(ALibHandle, 'luaopen_math');
  luaopen_debug := GetProcAddr(ALibHandle, 'luaopen_debug');
  luaopen_package := GetProcAddr(ALibHandle, 'luaopen_package');

  luaL_openlibs := GetProcAddr(ALibHandle, 'luaL_openlibs');

  luaL_checkversion_ := GetProcAddr(ALibHandle, 'luaL_checkversion_');
  luaL_getmetafield := GetProcAddr(ALibHandle, 'luaL_getmetafield');
  luaL_callmeta := GetProcAddr(ALibHandle, 'luaL_callmeta');
  luaL_tolstring := GetProcAddr(ALibHandle, 'luaL_tolstring');
  luaL_argerror := GetProcAddr(ALibHandle, 'luaL_argerror');
  luaL_checklstring := GetProcAddr(ALibHandle, 'luaL_checklstring');
  luaL_optlstring := GetProcAddr(ALibHandle, 'luaL_optlstring');
  luaL_checknumber := GetProcAddr(ALibHandle, 'luaL_checknumber');
  luaL_optnumber := GetProcAddr(ALibHandle, 'luaL_optnumber');
  luaL_checkinteger := GetProcAddr(ALibHandle, 'luaL_checkinteger');
  luaL_optinteger := GetProcAddr(ALibHandle, 'luaL_optinteger');

  luaL_checkstack := GetProcAddr(ALibHandle, 'luaL_checkstack');
  luaL_checktype := GetProcAddr(ALibHandle, 'luaL_checktype');
  luaL_checkany := GetProcAddr(ALibHandle, 'luaL_checkany');

  luaL_newmetatable := GetProcAddr(ALibHandle, 'luaL_newmetatable');
  luaL_setmetatable := GetProcAddr(ALibHandle, 'luaL_setmetatable');
  luaL_testudata := GetProcAddr(ALibHandle, 'luaL_testudata');
  luaL_checkudata := GetProcAddr(ALibHandle, 'luaL_checkudata');

  luaL_where := GetProcAddr(ALibHandle, 'luaL_where');
  luaL_error := GetProcAddr(ALibHandle, 'luaL_error');

  luaL_checkoption := GetProcAddr(ALibHandle, 'luaL_checkoption');
  luaL_fileresult := GetProcAddr(ALibHandle, 'luaL_fileresult');
  luaL_execresult := GetProcAddr(ALibHandle, 'luaL_execresult');

  luaL_ref := GetProcAddr(ALibHandle, 'luaL_ref');
  luaL_unref := GetProcAddr(ALibHandle, 'luaL_unref');

  luaL_loadfilex := GetProcAddr(ALibHandle, 'luaL_loadfilex');
  luaL_loadbufferx := GetProcAddr(ALibHandle, 'luaL_loadbufferx');
  luaL_loadstring := GetProcAddr(ALibHandle, 'luaL_loadstring');
  luaL_newstate := GetProcAddr(ALibHandle, 'luaL_newstate');
  luaL_len := GetProcAddr(ALibHandle, 'luaL_len');

  luaL_gsub := GetProcAddr(ALibHandle, 'luaL_gsub');
  luaL_setfuncs := GetProcAddr(ALibHandle, 'luaL_setfuncs');

  luaL_getsubtable := GetProcAddr(ALibHandle, 'luaL_getsubtable');
  luaL_traceback := GetProcAddr(ALibHandle, 'luaL_traceback');
  luaL_requiref := GetProcAddr(ALibHandle, 'luaL_requiref');

  luaL_buffinit := GetProcAddr(ALibHandle, 'luaL_buffinit');
  luaL_prepbuffsize := GetProcAddr(ALibHandle, 'luaL_prepbuffsize');
  luaL_addlstring := GetProcAddr(ALibHandle, 'luaL_addlstring');
  luaL_addstring := GetProcAddr(ALibHandle, 'luaL_addstring');
  luaL_addvalue := GetProcAddr(ALibHandle, 'luaL_addvalue');
  luaL_pushresult := GetProcAddr(ALibHandle, 'luaL_pushresult');
  luaL_pushresultsize := GetProcAddr(ALibHandle, 'luaL_pushresultsize');
  luaL_buffinitsize := GetProcAddr(ALibHandle, 'luaL_buffinitsize');

  fLibHandle:= ALibHandle;
  result:= ALibHandle;
end;

procedure FreeLuaLib();
begin
  lua_newstate := nil;
  lua_close := nil;
  lua_newthread := nil;
  lua_atpanic := nil;
  lua_version := nil;

  lua_absindex := nil;
  lua_gettop := nil;
  lua_settop := nil;
  lua_pushvalue := nil;
  lua_rotate := nil;
  lua_copy := nil;
  lua_checkstack := nil;
  lua_xmove  := nil;

  lua_isnumber := nil;
  lua_isstring := nil;         
  lua_iscfunction := nil;      
  lua_isinteger := nil;        
  lua_isuserdata := nil;       
  lua_type  := nil;            
  lua_typename := nil;

  lua_tonumberx := nil;        
  lua_tointegerx := nil;       
  lua_toboolean := nil;        
  lua_tolstring := nil;        
  lua_rawlen := nil;           
  lua_tocfunction := nil;      
  lua_touserdata := nil;       
  lua_tothread := nil;         
  lua_topointer := nil;        

  lua_arith := nil;            
  lua_rawequal := nil;
  lua_compare := nil;          

  lua_pushnil := nil;          
  lua_pushnumber := nil;       
  lua_pushinteger := nil;      
  lua_pushlstring := nil;      
  lua_pushstring := nil;       
  lua_pushvfstring := nil;     
  lua_pushfstring := nil;      
  lua_pushcclosure := nil;     
  lua_pushboolean := nil;      
  lua_pushlightuserdata := nil;
  lua_pushthread := nil;       

  lua_getglobal := nil;        
  lua_gettable := nil;         
  lua_getfield := nil;         
  lua_geti := nil;             
  lua_rawget := nil;           
  lua_rawgeti := nil;          
  lua_rawgetp := nil;          

  lua_createtable := nil;      
  lua_newuserdata := nil;      
  lua_getmetatable := nil;     
  lua_getuservalue := nil;     

  lua_setglobal := nil;
  lua_settable := nil;         
  lua_setfield := nil;         
  lua_seti := nil;             
  lua_rawset := nil;           
  lua_rawseti := nil;          
  lua_rawsetp := nil;          
  lua_setmetatable := nil;     
  lua_setuservalue := nil;     

  lua_callk := nil;
  lua_pcallk := nil;           
  lua_load := nil;             
  lua_dump := nil;             

  lua_yieldk := nil;           
  lua_resume := nil;           
  lua_status := nil;           
  lua_isyieldable := nil;      

  lua_gc := nil;               

  lua_error := nil;            
  lua_next := nil;             
  lua_concat := nil;           
  lua_len := nil;              

  lua_stringtonumber := nil;   
  lua_getallocf := nil;        
  lua_setallocf := nil;        

  lua_getstack := nil;         
  lua_getinfo := nil;          
  lua_getlocal := nil;         
  lua_setlocal := nil;         
  lua_getupvalue := nil;
  lua_setupvalue := nil;       
  lua_upvalueid := nil;        
  lua_upvaluejoin := nil;      

  lua_sethook := nil;          
  lua_gethook := nil;
  lua_gethookmask := nil;      
  lua_gethookcount := nil;     

  luaopen_base := nil;         
  luaopen_coroutine := nil;    
  luaopen_table := nil;        
  luaopen_io := nil;
  luaopen_os := nil;           
  luaopen_string := nil;       
  luaopen_utf8 := nil;         
  luaopen_bit32 := nil;        
  luaopen_math := nil;         
  luaopen_debug := nil;        
  luaopen_package := nil;      

  luaL_openlibs := nil;        

  luaL_checkversion_ := nil;   
  luaL_getmetafield := nil;    
  luaL_callmeta := nil;        
  luaL_tolstring := nil;       
  luaL_argerror := nil;        
  luaL_checklstring := nil;    
  luaL_optlstring := nil;      
  luaL_checknumber := nil;     
  luaL_optnumber := nil;       
  luaL_checkinteger := nil;    
  luaL_optinteger := nil;      

  luaL_checkstack := nil;      
  luaL_checktype := nil;       
  luaL_checkany := nil;        

  luaL_newmetatable := nil;    
  luaL_setmetatable := nil;
  luaL_testudata := nil;       
  luaL_checkudata := nil;      

  luaL_where := nil;           
  luaL_error := nil;           

  luaL_checkoption := nil;     
  luaL_fileresult := nil;      
  luaL_execresult := nil;      

  luaL_ref := nil;             
  luaL_unref := nil;           

  luaL_loadfilex := nil;       
  luaL_loadbufferx := nil;     
  luaL_loadstring := nil;      
  luaL_newstate := nil;        
  luaL_len := nil;             

  luaL_gsub := nil;            
  luaL_setfuncs := nil;        

  luaL_getsubtable := nil;     
  luaL_traceback := nil;       
  luaL_requiref := nil;        

  luaL_buffinit := nil;        
  luaL_prepbuffsize := nil;    
  luaL_addlstring := nil;      
  luaL_addstring := nil;       
  luaL_addvalue := nil;        
  luaL_pushresult := nil;      
  luaL_pushresultsize := nil;  
  luaL_buffinitsize := nil;    

  if fLibLoaded and (fLibHandle <> 0) then FreeLibrary(fLibHandle);

  fLibHandle := 0;
  fLibLoaded := false;
end;

function LoadLuaLib(newLuaLibFileName: ansistring): HMODULE;
var hlib: HMODULE;
begin
  FreeLuaLib();

  if newLuaLibFileName <> '' then
     SetLuaLibFileName( newLuaLibFileName );

  if not FileExists( GetLuaLibFileName() ) then begin
     Result := 0;
     exit;
  end;

  hlib := LoadLibrary( PChar(GetLuaLibFileName()));

  if (hlib = 0) then begin
     Result := 0;
     exit;
  end else fLibLoaded:= true;

  Result := InitializeLuaLib(hlib);
end;


{******************************************************************************
* Copyright (C) 1994-2015 Lua.org, PUC-Rio.
*
* Permission is hereby granted, free of charge, to any person obtaining
* a copy of this software and associated documentation files (the
* "Software"), to deal in the Software without restriction, including
* without limitation the rights to use, copy, modify, merge, publish,
* distribute, sublicense, and/or sell copies of the Software, and to
* permit persons to whom the Software is furnished to do so, subject to
* the following conditions:
*
* The above copyright notice and this permission notice shall be
* included in all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
******************************************************************************}
end.
