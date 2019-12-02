@echo off
IF NOT DEFINED PROJECT_ROOT (set PROJECT_ROOT=%~dp0.\)

@del /Q /F %PROJECT_ROOT%\units\*.* >nul
@mkdir %PROJECT_ROOT%\exe >nul
@mkdir %PROJECT_ROOT%\units >nul
@dcc32 lua_share.dpr
@dcc32 lua_share_rpc.dpr
@dcc32 lua_share_server.dpr
@del /Q /F %PROJECT_ROOT%\units\*.* >nul

@copy /b /y lua\*.lua %PROJECT_ROOT%\exe\
@copy /b /y readme.md %PROJECT_ROOT%\exe\
