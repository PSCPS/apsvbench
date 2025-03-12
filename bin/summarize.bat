@echo off
:: Program is used to run summary
setlocal
::set DISPBANNER=no
set APSVBENCH=C:\apps\apsvbench
set PROPATH=%APSVBENCH%
%DLC%\bin\_progres -b -p c:\apps\apsvbench\bench\summarizetest.p -param %1
