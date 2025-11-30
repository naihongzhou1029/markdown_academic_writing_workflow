# Extract Script Implementations from Makefile

## Status: ✅ Completed

## Overview

This document tracks the progress of extracting shell script implementations from the Makefile into separate OS-specific scripts in the `tools/` directory, and adding Windows support for all targets.

## Implementation Progress

### ✅ 1. Tools Directory Structure
- Created `tools/` directory
- Created `plans/` directory for documentation

### ✅ 2. OS Detection Helpers
- `tools/detect-os.sh` - Unix OS detection (Darwin/Linux)
- `tools/detect-os.ps1` - Windows PowerShell OS detection
- `tools/detect-os.bat` - Windows Batch OS detection

### ✅ 3. Dependency Installation Scripts
- `tools/deps-darwin.sh` - macOS (Homebrew) ✅
- `tools/deps-linux.sh` - Linux (apt-get) ✅
- `tools/deps-windows.ps1` - Windows (Chocolatey/winget) ✅ **NEW**
- `tools/deps-windows.bat` - Windows Batch version ✅ **NEW**

**Windows Implementation Details:**
- Supports both Chocolatey and winget package managers
- Installs poppler and ghostscript
- Provides instructions for pandoc-crossref installation

### ✅ 4. Font Detection Scripts
- `tools/detect-fonts-darwin.sh` - macOS font detection ✅
- `tools/detect-fonts-linux.sh` - Linux font detection (fc-list) ✅
- `tools/detect-fonts-windows.ps1` - Windows PowerShell font detection ✅ **NEW**
- `tools/detect-fonts-windows.bat` - Windows Batch font detection ✅ **NEW**

**Windows Implementation Details:**
- Scans Windows Fonts directory (`%SystemRoot%\Fonts`)
- Detects Simplified Chinese fonts (Noto, SimSun, SimHei, Microsoft YaHei)
- Detects Traditional Chinese fonts (Noto, MingLiU, Microsoft JhengHei)
- Falls back to common Windows CJK fonts

### ✅ 5. PDF Merging Scripts
- `tools/merge-pdfs-darwin.sh` - macOS (pdfunite/gs) ✅
- `tools/merge-pdfs-linux.sh` - Linux (pdfunite/gs) ✅
- `tools/merge-pdfs-windows.ps1` - Windows PowerShell (gs/pdftk/pdfunite) ✅ **NEW**
- `tools/merge-pdfs-windows.bat` - Windows Batch (gs/pdftk/pdfunite) ✅ **NEW**

**Windows Implementation Details:**
- Tries Ghostscript (gs) first
- Falls back to PDFtk if available
- Falls back to pdfunite (from poppler) if available
- Provides installation instructions if none found

### ✅ 6. Logo Download Scripts
- `tools/download-logo-darwin.sh` - macOS (curl) ✅
- `tools/download-logo-linux.sh` - Linux (curl) ✅
- `tools/download-logo-windows.ps1` - Windows PowerShell (Invoke-WebRequest) ✅ **NEW**
- `tools/download-logo-windows.bat` - Windows Batch (PowerShell/curl) ✅ **NEW**

**Windows Implementation Details:**
- Uses PowerShell `Invoke-WebRequest` as primary method
- Falls back to curl.exe if available (Windows 10 1803+)

### ✅ 7. Clean Scripts
- `tools/clean-darwin.sh` - macOS cleanup ✅
- `tools/clean-linux.sh` - Linux cleanup ✅
- `tools/clean-windows.ps1` - Windows PowerShell cleanup ✅ **NEW**
- `tools/clean-windows.bat` - Windows Batch cleanup ✅ **NEW**

**Windows Implementation Details:**
- Uses PowerShell `Remove-Item` for file deletion
- Handles LaTeX intermediate files with wildcards
- Removes `_minted*` directories recursively

### ✅ 8. Makefile Updates
- Replaced inline shell scripts with calls to extracted scripts
- Added OS detection to call appropriate script
- Maintained backward compatibility with existing targets
- Font detection now uses script output parsing
- All targets now delegate to OS-specific scripts

## File Summary

### Created Files (25 total)

#### OS Detection (3 files)
- `tools/detect-os.sh`
- `tools/detect-os.ps1`
- `tools/detect-os.bat`

#### Dependency Installation (4 files)
- `tools/deps-darwin.sh`
- `tools/deps-linux.sh`
- `tools/deps-windows.ps1`
- `tools/deps-windows.bat`

#### Font Detection (4 files)
- `tools/detect-fonts-darwin.sh`
- `tools/detect-fonts-linux.sh`
- `tools/detect-fonts-windows.ps1`
- `tools/detect-fonts-windows.bat`

#### PDF Merging (4 files)
- `tools/merge-pdfs-darwin.sh`
- `tools/merge-pdfs-linux.sh`
- `tools/merge-pdfs-windows.ps1`
- `tools/merge-pdfs-windows.bat`

#### Logo Download (4 files)
- `tools/download-logo-darwin.sh`
- `tools/download-logo-linux.sh`
- `tools/download-logo-windows.ps1`
- `tools/download-logo-windows.bat`

#### Clean Scripts (4 files)
- `tools/clean-darwin.sh`
- `tools/clean-linux.sh`
- `tools/clean-windows.ps1`
- `tools/clean-windows.bat`

#### Documentation (1 file)
- `plans/extract_script_implementations_of_make.md` (this file)

### Modified Files (1 file)
- `Makefile` - Updated to use extracted scripts

## Windows Support Summary

All targets now have Windows support:
- ✅ Dependency installation (Chocolatey/winget)
- ✅ Font detection (Windows Fonts directory scanning)
- ✅ PDF merging (Ghostscript/PDFtk/pdfunite)
- ✅ Logo download (PowerShell/curl)
- ✅ Clean (PowerShell/Batch)

## Notes

- All shell scripts have been made executable (`chmod +x`)
- Windows scripts support both PowerShell (.ps1) and Batch (.bat) formats
- Makefile maintains Unix compatibility (primary use case)
- Windows users can run scripts directly or use Make with appropriate shell
- Error handling and fallback mechanisms are implemented in all scripts

## Testing Recommendations

1. Test on macOS: `make deps`, `make pdf`, `make cover`, `make printed`, `make clean`
2. Test on Linux: Same as macOS
3. Test on Windows: Run PowerShell/Batch scripts directly or via appropriate shell
4. Verify font detection works correctly on each OS
5. Verify PDF merging works with available tools
6. Verify logo download works on each OS

## Completion Date

All tasks completed: 2025-01-27

