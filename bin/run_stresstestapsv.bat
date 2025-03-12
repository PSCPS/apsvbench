@echo off
:: Program is used to run a command or script multiple times simultaneously
setlocal
:: Environment variables
CALL "%~dp0env_vars.bat"
CALL "%~dp0validate_env.bat"
IF ERRORLEVEL 1 (
    exit /b 1
)

:: Proceed with your program

set PROPATH=%APSVBENCH%
%DLC%\bin\_progres -b -p %APSVBENCH%\bench\stressapsv.p -param %1:%2
