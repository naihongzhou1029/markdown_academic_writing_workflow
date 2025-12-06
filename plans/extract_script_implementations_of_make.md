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
- `tools/deps.sh` - Linux (apt-get) ✅
- `tools/deps-windows.ps1` - Windows (Chocolatey/winget) ✅ **NEW**
- `tools/deps-windows.bat` - Windows Batch version ✅ **NEW**

**Windows Implementation Details:**
- Supports both Chocolatey and winget package managers
- Installs poppler and ghostscript
- Provides instructions for pandoc-crossref installation

### ✅ 4. Font Detection Scripts
- `tools/detect-fonts-darwin.sh` - macOS font detection ✅
- `tools/detect-fonts.sh` - Linux font detection (fc-list) ✅
- `tools/detect-fonts-windows.ps1` - Windows PowerShell font detection ✅ **NEW**
- `tools/detect-fonts-windows.bat` - Windows Batch font detection ✅ **NEW**

**Windows Implementation Details:**
- Scans Windows Fonts directory (`%SystemRoot%\Fonts`)
- Detects Simplified Chinese fonts (Noto, SimSun, SimHei, Microsoft YaHei)
- Detects Traditional Chinese fonts (Noto, MingLiU, Microsoft JhengHei)
- Falls back to common Windows CJK fonts

### ✅ 5. PDF Merging Scripts
- `tools/merge-pdfs-darwin.sh` - macOS (pdfunite/gs) ✅
- `tools/merge-pdfs.sh` - Linux (pdfunite/gs) ✅
- `tools/merge-pdfs-windows.ps1` - Windows PowerShell (gs/pdftk/pdfunite) ✅ **NEW**
- `tools/merge-pdfs-windows.bat` - Windows Batch (gs/pdftk/pdfunite) ✅ **NEW**

**Windows Implementation Details:**
- Tries Ghostscript (gs) first
- Falls back to PDFtk if available
- Falls back to pdfunite (from poppler) if available
- Provides installation instructions if none found

### ✅ 6. Logo Download Scripts
- `tools/download-logo-darwin.sh` - macOS (curl) ✅
- `tools/download-logo.sh` - Linux (curl) ✅
- `tools/download-logo-windows.ps1` - Windows PowerShell (Invoke-WebRequest) ✅ **NEW**
- `tools/download-logo-windows.bat` - Windows Batch (PowerShell/curl) ✅ **NEW**

**Windows Implementation Details:**
- Uses PowerShell `Invoke-WebRequest` as primary method
- Falls back to curl.exe if available (Windows 10 1803+)

### ✅ 7. Clean Scripts
- `tools/clean-darwin.sh` - macOS cleanup ✅
- `tools/clean.sh` - Linux cleanup ✅
- `tools/clean-windows.ps1` - Windows PowerShell cleanup ✅ **NEW**
- `tools/clean-windows.bat` - Windows Batch cleanup ✅ **NEW**

**Windows Implementation Details:**
- Uses PowerShell `Remove-Item` for file deletion
- Handles LaTeX intermediate files with wildcards
- Removes `_minted*` directories recursively

### ✅ 8. Font Replacement Scripts
- `tools/replace-fonts-darwin.sh` - macOS font replacement ✅
- `tools/replace-fonts.sh` - Linux font replacement ✅
- `tools/replace-fonts-windows.ps1` - Windows PowerShell font replacement ✅ **NEW**

**Purpose:** Replace font names in markdown/LaTeX files (e.g., "PingFang SC" → detected font)

### ✅ 9. LaTeX CSLReferences Fix Scripts
- `tools/fix-latex-csl-darwin.sh` - macOS LaTeX CSL fix ✅
- `tools/fix-latex-csl.sh` - Linux LaTeX CSL fix ✅
- `tools/fix-latex-csl-windows.ps1` - Windows PowerShell LaTeX CSL fix ✅ **NEW**

**Purpose:** Fix LaTeX formatting issue with CSLReferences environment

### ✅ 10. Create Symlinks Scripts
- `tools/create-symlinks-darwin.sh` - macOS symlink creation ✅
- `tools/create-symlinks.sh` - Linux symlink creation ✅
- `tools/create-symlinks-windows.ps1` - Windows PowerShell symlink creation ✅ **NEW**

**Purpose:** Create symbolic links for dependencies in target directory

### ✅ 11. Copy Logo Scripts
- `tools/copy-logo-darwin.sh` - macOS logo copy/symlink ✅
- `tools/copy-logo.sh` - Linux logo copy/symlink ✅
- `tools/copy-logo-windows.ps1` - Windows PowerShell logo copy/symlink ✅ **NEW**

**Purpose:** Copy or create symlink for logo file in target directory

### ✅ 12. Translation Scripts
- `tools/translate-darwin.sh` - macOS translation (Gemini API) ✅
- `tools/translate.sh` - Linux translation (Gemini API) ✅
- `tools/translate-windows.ps1` - Windows PowerShell translation (Gemini API) ✅ **NEW**

**Purpose:** Translate markdown and LaTeX files from English to Traditional Chinese using Gemini LLM API

**Recent Improvements:**
- Enhanced prompts for LaTeX files to explicitly instruct translation of ALL English text
- Prompts now specifically mention translating content inside `\newcommand` definitions, labels, and all natural language text
- Better handling of LaTeX command structure preservation while ensuring complete translation

### ✅ 13. Post-process Translated Markdown Scripts
- `tools/postprocess-translated-md-darwin.sh` - macOS post-processing ✅
- `tools/postprocess-translated-md.sh` - Linux post-processing ✅
- `tools/postprocess-translated-md-windows.ps1` - Windows PowerShell post-processing ✅ **NEW**

**Purpose:** Post-process translated markdown with font replacements, label translations, and indentation fixes

**Recent Improvements:**
- Fixed Python unicode escape issues (using raw strings for regex patterns)
- Enhanced indentation fixing for LaTeX code blocks

### ✅ 14. Post-process Translated LaTeX Scripts
- `tools/postprocess-translated-tex-darwin.sh` - macOS post-processing ✅
- `tools/postprocess-translated-tex.sh` - Linux post-processing ✅
- `tools/postprocess-translated-tex-windows.ps1` - Windows PowerShell post-processing ✅ **NEW**

**Purpose:** Replace font names in translated LaTeX files and check for untranslated content

**Recent Improvements:**
- Removed substitution logic (translation is handled by LLM, not post-processing)
- Added warning checks for potentially untranslated content
- Fixed regex escaping issues with proper error handling

### ✅ 15. Cleanup Temp Files Scripts
- `tools/cleanup-temp-darwin.sh` - macOS temp file cleanup ✅
- `tools/cleanup-temp.sh` - Linux temp file cleanup ✅
- `tools/cleanup-temp-windows.ps1` - Windows PowerShell temp file cleanup ✅ **NEW**

**Purpose:** Remove temporary files created during build process

### ✅ 16. Makefile Updates (Phase 2)
- Replaced remaining inline shell scripts with calls to extracted scripts
- Added script variable definitions for all new scripts
- Updated PDF generation target to use replace-fonts and fix-latex-csl scripts
- Updated cover generation target to use replace-fonts script
- Updated zh_tw PDF generation to use create-symlinks, replace-fonts, and fix-latex-csl scripts
- Updated zh_tw cover generation to use copy-logo and replace-fonts scripts
- Updated translation post-processing to use postprocess-translated-md and postprocess-translated-tex scripts
- Updated cleanup operations to use cleanup-temp script
- Maintained backward compatibility with existing targets

### ✅ 17. Recent Improvements and Fixes (Phase 3)
- **Translation Enhancement:**
  - Enhanced translation prompts in `translate-darwin.sh` and `translate.sh` to explicitly instruct LLM to translate ALL English text, including content inside LaTeX `\newcommand` definitions and labels
  - Translation prompts now specifically mention translating titles, names, labels, and text within command definitions

- **Post-processing Refinements:**
  - Removed substitution logic from `postprocess-translated-tex` scripts (translation should be done by LLM, not post-processing)
  - Added warning checks to detect potentially untranslated content (title, labels)
  - Fixed regex escaping issues with proper error handling

- **Build Process Improvements:**
  - Added images directory symlink creation in `zh_tw` PDF generation (fixes missing image files during build)
  - Updated `clean` target to remove `zh_tw/` directory
  - Fixed font variable quoting in Makefile to handle font names with spaces

## File Summary

### Created Files (49 total - Phase 1: 25, Phase 2: 24)

#### OS Detection (3 files)
- `tools/detect-os.sh`
- `tools/detect-os.ps1`
- `tools/detect-os.bat`

#### Dependency Installation (4 files)
- `tools/deps-darwin.sh`
- `tools/deps.sh`
- `tools/deps-windows.ps1`
- `tools/deps-windows.bat`

#### Font Detection (4 files)
- `tools/detect-fonts-darwin.sh`
- `tools/detect-fonts.sh`
- `tools/detect-fonts-windows.ps1`
- `tools/detect-fonts-windows.bat`

#### PDF Merging (4 files)
- `tools/merge-pdfs-darwin.sh`
- `tools/merge-pdfs.sh`
- `tools/merge-pdfs-windows.ps1`
- `tools/merge-pdfs-windows.bat`

#### Logo Download (4 files)
- `tools/download-logo-darwin.sh`
- `tools/download-logo.sh`
- `tools/download-logo-windows.ps1`
- `tools/download-logo-windows.bat`

#### Clean Scripts (4 files)
- `tools/clean-darwin.sh`
- `tools/clean.sh`
- `tools/clean-windows.ps1`
- `tools/clean-windows.bat`

#### Font Replacement (3 files) - Phase 2
- `tools/replace-fonts-darwin.sh`
- `tools/replace-fonts.sh`
- `tools/replace-fonts-windows.ps1`

#### LaTeX CSLReferences Fix (3 files) - Phase 2
- `tools/fix-latex-csl-darwin.sh`
- `tools/fix-latex-csl.sh`
- `tools/fix-latex-csl-windows.ps1`

#### Create Symlinks (3 files) - Phase 2
- `tools/create-symlinks-darwin.sh`
- `tools/create-symlinks.sh`
- `tools/create-symlinks-windows.ps1`

#### Copy Logo (3 files) - Phase 2
- `tools/copy-logo-darwin.sh`
- `tools/copy-logo.sh`
- `tools/copy-logo-windows.ps1`

#### Translation (3 files) - Phase 2
- `tools/translate-darwin.sh`
- `tools/translate.sh`
- `tools/translate-windows.ps1`

#### Post-process Translated Markdown (3 files) - Phase 2
- `tools/postprocess-translated-md-darwin.sh`
- `tools/postprocess-translated-md.sh`
- `tools/postprocess-translated-md-windows.ps1`

#### Post-process Translated LaTeX (3 files) - Phase 2
- `tools/postprocess-translated-tex-darwin.sh`
- `tools/postprocess-translated-tex.sh`
- `tools/postprocess-translated-tex-windows.ps1`

#### Cleanup Temp Files (3 files) - Phase 2
- `tools/cleanup-temp-darwin.sh`
- `tools/cleanup-temp.sh`
- `tools/cleanup-temp-windows.ps1`

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

Phase 1 completed: 2025-01-27
Phase 2 completed: 2025-01-27
Phase 3 (Improvements & Fixes) completed: 2025-11-30

## Recent Changes (2025-11-30)

### Translation System Improvements
- Enhanced LLM translation prompts to ensure comprehensive translation of LaTeX files
- Removed post-processing substitutions in favor of proper LLM translation
- Added validation checks to warn about potentially untranslated content

### Build Process Fixes
- Fixed missing images directory issue in `zh_tw` PDF generation
- Improved font variable handling for names with spaces
- Enhanced error handling in post-processing scripts

### Code Quality
- Fixed Python regex escaping issues
- Improved error handling and warnings
- Better separation of concerns (translation vs. post-processing)

