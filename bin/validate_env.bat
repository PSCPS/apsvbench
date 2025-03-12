@echo off

:: Check if APSVBENCH is defined and not empty
IF NOT DEFINED APSVBENCH (
    echo ERROR: APSVBENCH is not set in env_vars.bat.
    exit /b 1
)

IF "%APSVBENCH%"=="" (
    echo ERROR: APSVBENCH is empty in env_vars.bat.
    exit /b 1
)

:: Check if APSVCONNECTSTRING is defined and not empty
IF NOT DEFINED APSVCONNECTSTRING (
    echo ERROR: APSVCONNECTSTRING is not set in env_vars.bat.
    exit /b 1
)

IF "%APSVCONNECTSTRING%"=="" (
    echo ERROR: APSVCONNECTSTRING is empty in env_vars.bat.
    exit /b 1
)

:: If we reach here, the variables are set and not empty
exit /b 0
