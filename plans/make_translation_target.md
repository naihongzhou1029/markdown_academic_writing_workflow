# Translation Target for Makefile

## Status: ✅ Completed

## Overview

This document tracks the implementation of the `zh_tw` Makefile target that translates academic documents to Traditional Chinese using the Gemini API, builds PDFs from translated files, and cleans up intermediate translation files. Only the final PDFs are kept.

## Implementation Details

### 1. Makefile Variables

- `LLM_MODEL` (default: `gemini-2.5-flash`) - Configurable LLM model name
- `API_KEY_FILE` (default: `.api_key`) - Hidden file storing Gemini API key
- `ZH_TW_DIR` (default: `zh_tw`) - Output directory for Traditional Chinese translations
- `ZH_TW_SRC` - Intermediate translated markdown file
- `ZH_TW_COVER` - Intermediate translated LaTeX cover file
- `ZH_TW_PDF` - Final PDF output from translated markdown
- `ZH_TW_COVER_PDF` - Final PDF output from translated cover

### 2. Translation Scripts

Created OS-specific translation helper scripts:

- `tools/translate-darwin.sh` - macOS translation script using curl and jq
- `tools/translate-linux.sh` - Linux translation script using curl and jq
- `tools/translate-windows.ps1` - Windows PowerShell translation script using curl and PowerShell's built-in JSON parsing

**Key Features:**
- Interactive API key prompting if `.api_key` file doesn't exist
- Secure API key storage with proper file permissions (chmod 600 on Unix)
- Preserves citation syntax (e.g., `[@citation_key]`)
- Preserves cross-reference syntax (e.g., `@tbl:label`, `@fig:label`, `@eq:label`)
- Translates reference labels (e.g., "Figure" → "圖", "Table" → "表格")
- Preserves YAML metadata block structure in Markdown
- Preserves LaTeX commands and structure in .tex files
- Strips markdown code fences from LaTeX output if present

### 3. zh_tw Target Workflow

1. **Translation Phase:**
   - Creates `zh_tw/` directory if it doesn't exist
   - Translates `paper.md` → `zh_tw/paper.md` using Gemini API
   - Translates `ntust_cover_page.tex` → `zh_tw/ntust_cover_page.tex` using Gemini API

2. **Post-Processing Phase:**
   - Updates YAML metadata in translated markdown:
     - Changes `CJKmainfont` from "PingFang SC" to detected Traditional Chinese font
     - Translates `figPrefix` and `tblPrefix` to Traditional Chinese
     - Fixes YAML multiline block indentation using Python script
   - Updates LaTeX font settings in translated cover page

3. **PDF Building Phase:**
   - Builds `zh_tw/paper.pdf` from translated markdown (similar to existing `pdf` target)
   - Builds `zh_tw/cover.pdf` from translated cover LaTeX (similar to existing `cover` target)
   - Creates symbolic links for bibliography and CSL files in `zh_tw/` directory

4. **Cleanup Phase:**
   - Removes intermediate translation files (`zh_tw/paper.md`, `zh_tw/ntust_cover_page.tex`)
   - Removes LaTeX intermediate files (`.aux`, `.log`, `.tex` files)
   - Only final PDFs remain in `zh_tw/` directory

5. **Progress Tracking:**
   - Updates this file to mark status as completed

### 4. Windows Dependencies

Updated `tools/deps-windows.ps1` to include:
- `curl` installation (usually pre-installed on Windows 10/11, but can be installed via Chocolatey/winget if missing)
- `jq` installation (optional, since PowerShell uses built-in JSON parsing via `ConvertFrom-Json`)

### 5. Error Handling

- Checks for `.api_key` file existence at script start
- Prompts user interactively if API key file is missing
- Validates API response status
- Handles translation failures gracefully with clear error messages
- Preserves original files on error
- Only cleans up intermediate files if PDF generation succeeds
- Sets appropriate file permissions on `.api_key` (chmod 600 for Unix, hidden file attribute for Windows)

## File Structure

```
.
├── Makefile (modified)
├── .api_key (created interactively, gitignored)
├── tools/
│   ├── translate-darwin.sh (new)
│   ├── translate-linux.sh (new)
│   ├── translate-windows.ps1 (new)
│   └── deps-windows.ps1 (modified)
├── zh_tw/ (created by target)
│   ├── paper.pdf (final output)
│   └── cover.pdf (final output)
└── plans/
    └── make_translation_target.md (this file)
```

## API Key Configuration

The API key is stored in a hidden file `.api_key` in the project root. If the file doesn't exist when running the translation target, the script will:

1. Prompt the user to enter their Gemini API key
2. Save it to `.api_key` with appropriate permissions:
   - Unix: `chmod 600` (owner read/write only)
   - Windows: Hidden file attribute

**Security Note:** The `.api_key` file is added to `.gitignore` to prevent accidental commits.

## Usage

To translate documents to Traditional Chinese:

```bash
make zh_tw
```

This will:
1. Translate `paper.md` and `ntust_cover_page.tex` to Traditional Chinese
2. Build PDFs from the translated files
3. Clean up intermediate translation files
4. Output final PDFs in `zh_tw/` directory

## Dependencies

- **Unix (Darwin/Linux):**
  - `curl` - for API calls
  - `jq` - for JSON parsing
  - `python3` - for YAML indentation fix

- **Windows:**
  - `curl.exe` - usually pre-installed on Windows 10/11
  - PowerShell - built-in (uses `ConvertFrom-Json` instead of jq)

- **All platforms:**
  - Gemini API key
  - All existing dependencies for PDF generation (pandoc, xelatex, etc.)

## Testing Notes

- Test translation on sample documents before running on full paper
- Verify that citations and cross-references are preserved correctly
- Check that Traditional Chinese fonts are properly applied
- Ensure intermediate files are cleaned up after PDF generation
- Verify YAML metadata block indentation is correct

## Completion Date

Implementation completed: 2025-01-27

