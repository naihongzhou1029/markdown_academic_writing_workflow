@echo off
REM Install dependencies on Windows using Chocolatey or winget

echo Installing required CLI tools on Windows...

REM Check for Chocolatey
where choco >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Using Chocolatey as package manager.
    choco install poppler --yes --no-progress
    choco install ghostscript --yes --no-progress
    echo All dependencies are installed.
    goto :end
)

REM Check for winget
where winget >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Using winget as package manager.
    winget install --id Poppler.Poppler --accept-package-agreements --accept-source-agreements --silent
    winget install --id ArtifexSoftware.Ghostscript --accept-package-agreements --accept-source-agreements --silent
    echo All dependencies are installed.
    goto :end
)

echo Neither Chocolatey nor winget found.
echo Please install one of the following:
echo   - Chocolatey: https://chocolatey.org/install
echo   - winget: Usually pre-installed on Windows 10/11
exit /b 1

:end
REM pandoc-crossref might not be available, provide instructions
where pandoc-crossref >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo pandoc-crossref not found. Install it via:
    echo   Download from: https://github.com/lierdakil/pandoc-crossref/releases
    echo   Or use Haskell Stack: stack install pandoc-crossref
)

