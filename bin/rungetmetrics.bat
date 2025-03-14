@echo off
:: Program is used start a remote call to get the agents and sessions
setlocal 
:: Environment variables
CALL "%~dp0env_vars.bat"
CALL "%~dp0validate_env.bat"
IF ERRORLEVEL 1 (
    exit /b 1
)

:: Proceed with your program

set PROPATH=%APSVBENCH%
%DLC%\bin\_progres -b -p %APSVBENCH%\bench\rungetmetrics.p -param %ABLAPPNAME%
endlocal
