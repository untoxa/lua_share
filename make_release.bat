@echo off
IF NOT DEFINED PROJECT_ROOT (set PROJECT_ROOT=%~dp0.\)
IF NOT DEFINED RELEASE_ROOT (set RELEASE_ROOT=%PROJECT_ROOT%\release\)

@call build_x86.bat
@call build_x64.bat

@del /F /Q %RELEASE_ROOT%

@mkdir %RELEASE_ROOT% >nul
@mkdir %RELEASE_ROOT%\examples >nul
@mkdir %RELEASE_ROOT%\quik7 >nul
@mkdir %RELEASE_ROOT%\quik7\scripts >nul
@mkdir %RELEASE_ROOT%\quik8 >nul
@mkdir %RELEASE_ROOT%\quik8\scripts >nul

@copy /b /y %PROJECT_ROOT%\lua\*_test_share_*.lua %RELEASE_ROOT%\examples\
@copy /b /y %PROJECT_ROOT%\readme.md %RELEASE_ROOT%
@copy /b /y %PROJECT_ROOT%\LICENSE %RELEASE_ROOT%

@copy /b /y %PROJECT_ROOT%\lua\lua_share_server.lua  %RELEASE_ROOT%\quik7\
@copy /b /y %PROJECT_ROOT%\lua\lua_share_boot.lua %RELEASE_ROOT%\quik7\scripts\

@copy /b /y %PROJECT_ROOT%\lua\lua_share_server.lua  %RELEASE_ROOT%\quik8\
@copy /b /y %PROJECT_ROOT%\lua\lua_share_boot.lua %RELEASE_ROOT%\quik8\scripts\

@copy /b /y %PROJECT_ROOT%\exe\x64\lua_share_server.exe %RELEASE_ROOT%\quik8\
@copy /b /y %PROJECT_ROOT%\exe\x64\lua_share.dll %RELEASE_ROOT%\quik8\scripts\
@copy /b /y %PROJECT_ROOT%\exe\x64\lua_share_rpc.dll %RELEASE_ROOT%\quik8\scripts\

@copy /b /y %PROJECT_ROOT%\exe\x86\lua_share_server.exe %RELEASE_ROOT%\quik7\
@copy /b /y %PROJECT_ROOT%\exe\x86\lua_share.dll %RELEASE_ROOT%\quik7\scripts\
@copy /b /y %PROJECT_ROOT%\exe\x86\lua_share_rpc.dll %RELEASE_ROOT%\quik7\scripts\

cd %RELEASE_ROOT%
7z a -r -sdel lua_share_binaries.zip .\
 