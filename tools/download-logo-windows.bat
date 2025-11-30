@echo off
REM Download NTUST logo on Windows using Batch script

setlocal

if "%~2"=="" (
    echo Usage: %~n0 ^<logo_file^> ^<logo_url^>
    exit /b 1
)

set LOGO_FILE=%~1
set LOGO_URL=%~2

echo Fetching NTUST logo...

REM Try PowerShell first (available on Windows 7+)
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%LOGO_URL%' -OutFile '%LOGO_FILE%' -UseBasicParsing" 2>nul
if %ERRORLEVEL% EQU 0 (
    echo Logo downloaded successfully to %LOGO_FILE%
    exit /b 0
)

REM Try curl if available (Windows 10 1803+)
where curl >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    curl -fsSL -o "%LOGO_FILE%" "%LOGO_URL%"
    if %ERRORLEVEL% EQU 0 (
        echo Logo downloaded successfully to %LOGO_FILE%
        exit /b 0
    )
)

echo Failed to download logo. Please ensure PowerShell or curl is available.
exit /b 1

