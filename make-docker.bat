@echo off
REM Docker wrapper for make - runs make inside dalibo/pandocker container (Windows CMD version)
REM
REM This script uses a derived image with jq and curl pre-installed to avoid
REM installing them on every translation run. The container is automatically removed
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

REM Base image name and tag
set "BASE_IMAGE_NAME=dalibo/pandocker"
set "BASE_IMAGE_TAG=latest-full"
set "BASE_IMAGE=%BASE_IMAGE_NAME%:%BASE_IMAGE_TAG%"

REM Derived image name (with jq and curl pre-installed)
set "DERIVED_IMAGE_NAME=pandocker-with-tools"
set "DERIVED_IMAGE_TAG=latest"
set "DERIVED_IMAGE=%DERIVED_IMAGE_NAME%:%DERIVED_IMAGE_TAG%"

REM Check if base image exists, pull if needed
docker images --format "{{.Repository}}:{{.Tag}}" | findstr /C:"%BASE_IMAGE%" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Base image %BASE_IMAGE% not found locally. Pulling...
    docker pull %BASE_IMAGE%
    if %ERRORLEVEL% NEQ 0 (
        echo Error: Failed to pull %BASE_IMAGE%
        echo Please check your Docker connection and try again.
        exit /b 1
    )
)

REM Check if derived image exists, build if needed
docker images --format "{{.Repository}}:{{.Tag}}" | findstr /C:"%DERIVED_IMAGE%" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Derived image %DERIVED_IMAGE% not found. Building from Dockerfile...
    if not exist "%WORK_DIR%\Dockerfile" (
        echo Error: Dockerfile not found in %WORK_DIR%
        echo Please create a Dockerfile that extends %BASE_IMAGE% and installs jq and curl.
        exit /b 1
    )
    docker build -t %DERIVED_IMAGE% -f "%WORK_DIR%\Dockerfile" "%WORK_DIR%"
    if %ERRORLEVEL% NEQ 0 (
        echo Error: Failed to build derived image %DERIVED_IMAGE%
        exit /b 1
    )
    echo Derived image built successfully.
)

REM Use the derived image instead of base image
set "IMAGE=%DERIVED_IMAGE%"

REM Run make inside the container
REM --rm: automatically remove container after execution
REM --entrypoint="": override container entrypoint to run make directly
REM -v: mount current directory as /workspace in container
REM -w: set working directory in container
docker run --rm --entrypoint="" -v "%WORK_DIR%":/workspace -w /workspace %IMAGE% /usr/bin/make %*

endlocal

