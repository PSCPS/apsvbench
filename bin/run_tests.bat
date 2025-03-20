@echo off
:: Program is used to kick off multiple simultaneous OpenEdge sessions to test an appserver
:: Environment variables
CALL "%~dp0env_vars.bat"
CALL "%~dp0validate_env.bat"
IF ERRORLEVEL 1 (
    exit /b 1
)
echo Checking server resources before run...
CALL "%~dp0rungetagentsessions.bat" 
CALL "%~dp0runresetmetrics.bat" 

setlocal enabledelayedexpansion

:: Check if two parameters are provided
if "%~1"=="" (
    echo Usage: %~nx0 "[a | b]" number_of_instances [repetitions]
    exit /b 1
)

if "%~2"=="" (
    echo Usage: %~nx0 "[a | b]" number_of_instances [repetitions]
    exit /b 1
)

:: Set parameters
set "command=%~1"
set "count=%~2"
set "repetitions=%~3"

:: Validate that count is a number
for /f "delims=0123456789" %%i in ("%count%") do (
    echo Error: Second parameter must be a number
    exit /b 1
)

if "%repetitions%"=="" set "repetitions=1"

:: Ensure our results directory exists
IF NOT EXIST "%APSVBENCH%\results" (
    echo "Creating %APSVBENCH%\results folder"
    mkdir "%APSVBENCH%\results"
)

echo TestId: %command%
echo Starting concurrent execution...

:: Loop to start the processes and write output to their respective log files
:: Pre-create empty log files for each batch process
for /l %%i in (1,1,%count%) do (
    set "log_file=%APSVBENCH%\results\log_%%i.txt"
    echo. > !log_file!
    start /b cmd /c %~dp0run_stresstestapsv.bat %%i %repetitions% %command% >> !log_file! 2>&1
)

echo Awaiting completion...
:: Wait for all processes to complete by monitoring the "done" word in their log files
:WAIT_LOOP
set "active=0"
for /l %%i in (1,1,%count%) do (
    set "log_file=%APSVBENCH%\results\log_%%i.txt"
    
    :: Attempt to read the last line of the log file. Ignore errors if the file is being written to.
    set "last_line="
    for /f "tokens=* delims=" %%a in ('type !log_file! 2^>nul') do (
        set "last_line=%%a"
    )
    
    :: Check if the last line is "done"
    if /i "!last_line!" neq "done" (
        set "active=1"
    )
)

if !active! GTR 0 (
    set /p="." <nul
    timeout /t 1 > nul
    goto WAIT_LOOP
)
endlocal

CALL "%~dp0summarize.bat" %2:%3

