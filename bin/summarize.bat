@echo off
:: Program is used to run summary
::setlocal
::set DISPBANNER=no
::set APSVBENCH=C:\apps\apsvbench
::set PROPATH=%APSVBENCH%
CALL "%~dp0env_vars.bat"
CALL "%~dp0validate_env.bat"
IF ERRORLEVEL 1 (
    exit /b 1
)
%DLC%\bin\_progres -b -p %APSVBENCH%\bench\summarizetest.p -cpstream ISO8859-1 -param %1
