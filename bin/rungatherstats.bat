@echo off
:: Program is used start a remote call to begin collecting server stats
setlocal
:: Environment variables
CALL "%~dp0env_vars.bat"
CALL "%~dp0validate_env.bat"
IF ERRORLEVEL 1 (
    exit /b 1
)
setlocal enabledelayedexpansion

:: Proceed with your program

set PROPATH=%APSVBENCH%
%DLC%\bin\_progres -b -p %APSVBENCH%\bench\rungatherstats.p
