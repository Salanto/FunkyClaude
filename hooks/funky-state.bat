@echo off
REM funky-state.bat -- Windows equivalent of funky-state.sh
REM
REM Usage:  funky-state.bat working   (or: idle)
REM
REM Writes a single keyword into FunkyClaude's state file:
REM   working -> Claude is thinking/working  -> video plays
REM   idle    -> Claude is waiting for input -> video pauses
REM
REM The state file defaults to %USERPROFILE%\.funkyclaude\state and can be
REM overridden with the FUNKYCLAUDE_STATE_FILE environment variable (keep it in
REM sync with whatever you pass the app via --state-file).

setlocal EnableExtensions

set "STATE=%~1"
if /I "%STATE%"=="working"  goto :working
if /I "%STATE%"=="thinking" goto :working
if /I "%STATE%"=="busy"     goto :working
set "STATE=idle"
goto :write
:working
set "STATE=working"

:write
set "STATEFILE=%FUNKYCLAUDE_STATE_FILE%"
if "%STATEFILE%"=="" set "STATEFILE=%USERPROFILE%\.funkyclaude\state"
for %%F in ("%STATEFILE%") do set "STATEDIR=%%~dpF"
if not exist "%STATEDIR%" mkdir "%STATEDIR%"

> "%STATEFILE%" echo %STATE%

endlocal
