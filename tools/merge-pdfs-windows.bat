@echo off
REM Merge PDFs on Windows using Ghostscript or PDFtk

setlocal

if "%~3"=="" (
    echo Usage: %~n0 ^<cover.pdf^> ^<paper.pdf^> ^<output.pdf^>
    exit /b 1
)

set COVER_PDF=%~1
set PDF=%~2
set OUTPUT=%~3

REM Try Ghostscript first
where gs >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile="%OUTPUT%" "%COVER_PDF%" "%PDF%"
    echo Created %OUTPUT% (cover + paper) with Ghostscript (gs).
    exit /b 0
)

REM Try PDFtk if available
where pdftk >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    pdftk "%COVER_PDF%" "%PDF%" cat output "%OUTPUT%"
    echo Created %OUTPUT% (cover + paper) with PDFtk.
    exit /b 0
)

REM Try poppler's pdfunite if available
where pdfunite >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    pdfunite "%COVER_PDF%" "%PDF%" "%OUTPUT%"
    echo Created %OUTPUT% (cover + paper) with pdfunite.
    exit /b 0
)

echo No PDF merging tool found. Install one of the following:
echo   - Ghostscript: choco install ghostscript or winget install ArtifexSoftware.Ghostscript
echo   - PDFtk: choco install pdftk or winget install PDFtk.PDFtk
echo   - Poppler: choco install poppler or winget install Poppler.Poppler
exit /b 1

