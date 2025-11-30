@echo off
REM Detect fonts on Windows using Batch script
REM This is a simplified version - PowerShell version is recommended

set MAIN_FONT=Times New Roman
set CJK_FONT_SC=Microsoft YaHei
set CJK_FONT_TC=Microsoft JhengHei

REM Check if fonts exist in Windows Fonts directory
set FONTS_DIR=%SystemRoot%\Fonts

if exist "%FONTS_DIR%\msyh.ttc" set CJK_FONT_SC=Microsoft YaHei
if exist "%FONTS_DIR%\simsun.ttc" set CJK_FONT_SC=SimSun
if exist "%FONTS_DIR%\msjh.ttc" set CJK_FONT_TC=Microsoft JhengHei
if exist "%FONTS_DIR%\mingliu.ttc" set CJK_FONT_TC=MingLiU

echo CJK_FONT_SC=%CJK_FONT_SC%
echo CJK_FONT_TC=%CJK_FONT_TC%
echo MAIN_FONT=%MAIN_FONT%

