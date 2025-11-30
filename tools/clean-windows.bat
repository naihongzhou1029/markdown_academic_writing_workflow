@echo off
REM Clean build artifacts on Windows using Batch script

setlocal

set PDF=paper.pdf
set COVER_PDF=cover.pdf
set PRINTED_PDF=printed.pdf
set TEMP_SRC=paper.tmp.md
set COVER_TEMP_TEX=ntust_cover_page.tmp.tex

REM Remove specific files
if exist "%PDF%" del /f /q "%PDF%"
if exist "%COVER_PDF%" del /f /q "%COVER_PDF%"
if exist "%PRINTED_PDF%" del /f /q "%PRINTED_PDF%"
if exist "%TEMP_SRC%" del /f /q "%TEMP_SRC%"
if exist "%COVER_TEMP_TEX%" del /f /q "%COVER_TEMP_TEX%"

REM Remove LaTeX intermediate files
del /f /q *.aux *.log *.out *.toc *.bbl *.blg *.bcf *.run.xml *.synctex.gz 2>nul
del /f /q *.fdb_latexmk *.fls *.xdv *.nav *.snm *.vrb *.lof *.lot *.loa *.lol 2>nul

REM Remove _minted* directories
for /d %%d in (_minted*) do (
    if exist "%%d" rmdir /s /q "%%d" 2>nul
)

echo Cleaned build outputs and LaTeX intermediates.

