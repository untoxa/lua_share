@echo off
@echo FPC x86 compiling disabled
@goto :eof

IF NOT DEFINED PROJECT_ROOT (set PROJECT_ROOT=%~dp0.\)

@del /Q /F %PROJECT_ROOT%\units\*.* >nul
@mkdir %PROJECT_ROOT%\exe >nul
@mkdir %PROJECT_ROOT%\exe\x86 >nul
@mkdir %PROJECT_ROOT%\units >nul
@ppc386.exe -B -Mdelphi -Ur -Xs -Fi%PROJECT_ROOT% -Fu%PROJECT_ROOT%\common\ -FE%PROJECT_ROOT%\exe\x86\ -FU%PROJECT_ROOT%\units\ lua_share.dpr
@ppc386.exe -B -Mdelphi -Ur -Xs -Fi%PROJECT_ROOT% -Fu%PROJECT_ROOT%\common\ -FE%PROJECT_ROOT%\exe\x86\ -FU%PROJECT_ROOT%\units\ lua_share_rpc.dpr
@ppc386.exe -B -Mdelphi -Ur -Xs -Fi%PROJECT_ROOT% -Fu%PROJECT_ROOT%\common\ -FE%PROJECT_ROOT%\exe\x86\ -FU%PROJECT_ROOT%\units\ lua_share_server.dpr
@del /Q /F %PROJECT_ROOT%\units\*.* >nul

@copy /b /y lua\*.lua %PROJECT_ROOT%\exe\x86\
@copy /b /y readme.md %PROJECT_ROOT%\exe\x86\
