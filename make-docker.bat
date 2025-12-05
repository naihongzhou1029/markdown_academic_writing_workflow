@echo off
REM Docker wrapper for make - runs make inside dalibo/pandocker container (Windows CMD version)
REM
REM This script creates an ephemeral container that is automatically removed
REM after the build completes. All toolchains (pandoc, xelatex, make, etc.)
REM are available inside the container.

setlocal

REM Get the current directory
set "WORK_DIR=%CD%"
set "API_KEY_FILE=%WORK_DIR%\.api_key"

REM Require API key file before running translation targets
set "ARGS= %* "
echo %ARGS% | findstr /I "zh_tw translate" >nul
if %ERRORLEVEL%==0 (
    if not exist "%API_KEY_FILE%" (
        echo Error: API key file not found: %API_KEY_FILE%
        echo Create it with your Gemini API key before running translation targets.
        echo Example: echo ^<your-key^>^> "%API_KEY_FILE%"
        exit /b 1
    )
)

REM Image name and tag
set "IMAGE_NAME=dalibo/pandocker"
set "IMAGE_TAG=latest-full"
set "IMAGE=%IMAGE_NAME%:%IMAGE_TAG%"

REM Check if the image exists locally
docker images --format "{{.Repository}}:{{.Tag}}" | findstr /C:"%IMAGE%" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Checking for alternative dalibo/pandocker images...
    docker images --format "{{.Repository}}:{{.Tag}}" | findstr /C:"%IMAGE_NAME%:" >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        echo.
        echo Warning: Image %IMAGE% not found locally.
        echo Available dalibo/pandocker images:
        docker images --format "  {{.Repository}}:{{.Tag}}" | findstr /C:"%IMAGE_NAME%:"
        echo.
        echo Pulling %IMAGE%...
        docker pull %IMAGE%
        if %ERRORLEVEL% NEQ 0 (
            echo Error: Failed to pull %IMAGE%
            echo Please check your Docker connection and try again.
            exit /b 1
        )
    ) else (
        echo.
        echo Image %IMAGE% not found locally. Pulling...
        docker pull %IMAGE%
        if %ERRORLEVEL% NEQ 0 (
            echo Error: Failed to pull %IMAGE%
            echo Please check your Docker connection and try again.
            exit /b 1
        )
    )
)

REM Run make inside the dalibo/pandocker container
REM --rm: automatically remove container after execution
REM --entrypoint="": override container entrypoint to run make directly
REM -v: mount current directory as /workspace in container
REM -w: set working directory in container
docker run --rm --entrypoint="" -v "%WORK_DIR%":/workspace -w /workspace %IMAGE% /usr/bin/make %*

endlocal

