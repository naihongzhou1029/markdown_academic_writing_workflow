# Add Mermaid Diagram Rendering to PDF Output

## Status: ✅ Completed

## Overview

This document tracks the implementation of Mermaid diagram rendering support in the PDF build workflow. Mermaid code blocks in Markdown files are automatically converted to PNG images using `mermaid-cli` (already installed in Docker) and replaced with image references before Pandoc conversion.

## Implementation Details

### 1. Mermaid Processing Script

Created `tools/process-mermaid.sh` that:
- Takes input and output Markdown file paths as arguments
- Optionally accepts an images directory path (defaults to `images/`)
- Parses Markdown to find all ` ```mermaid ... ``` ` code blocks
- For each Mermaid block:
  - Extracts the Mermaid code content
  - Generates sequential filenames (e.g., `mermaid-1.png`, `mermaid-2.png`)
  - Saves the Mermaid code to a temporary `.mmd` file
  - Runs `mmdc -i <temp.mmd> -o images/<filename>.png -s 3` to generate high-resolution PNG (3x scale for crisp text)
  - Replaces the code block with `![Mermaid diagram](images/<filename>.png)`
- Ensures the `images/` directory exists before processing
- Handles errors gracefully: if `mmdc` fails, keeps the original code block and logs a warning
- Handles edge cases like unclosed Mermaid blocks

**Key Features:**
- Sequential naming: `mermaid-1.png`, `mermaid-2.png`, etc.
- Error handling: preserves original code blocks if conversion fails
- Linux-compatible: runs inside Docker container
- Uses dark theme with transparent background for better PDF integration
- High-resolution output: Uses `-s 3` scale factor (3x) for crisp text rendering in PDFs

### 2. Makefile Updates

#### Variables Added
- `PROCESS_MERMAID_SCRIPT := tools/process-mermaid.sh` - Path to Mermaid processing script
- `MERMAID_TEMP_SRC = paper.mermaid.tmp.md` - Intermediate file for Mermaid-processed Markdown

#### English Build (`$(PDF)` target)
Updated workflow:
1. Process Mermaid diagrams: `$(SRC)` → `$(MERMAID_TEMP_SRC)`
2. Replace fonts: `$(MERMAID_TEMP_SRC)` → `$(TEMP_SRC)`
3. Continue with existing Pandoc and LaTeX compilation steps
4. Clean up both intermediate files

#### Traditional Chinese Build (`$(ZH_TW_PDF)` target)
Updated workflow:
1. Create symlinks for bibliography and CSL files
2. Create symlink for `images/` directory
3. Process Mermaid diagrams: `$(ZH_TW_SRC)` → `$(ZH_TW_DIR)/paper.mermaid.tmp.md`
4. Replace fonts: `$(ZH_TW_DIR)/paper.mermaid.tmp.md` → `$(ZH_TW_DIR)/paper.tmp.md`
5. Continue with existing Pandoc and LaTeX compilation steps
6. Clean up intermediate files including Mermaid-processed file

#### Clean Target
Updated to remove:
- Generated Mermaid images: `images/mermaid-*.png`
- Mermaid intermediate file: `$(MERMAID_TEMP_SRC)`

### 3. Integration Points

**Processing Order:**
1. Mermaid processing (converts code blocks to images)
2. Font replacement (replaces font names in YAML metadata)
3. Pandoc conversion (converts Markdown to LaTeX)
4. LaTeX compilation (generates final PDF)

**Image Storage:**
- English build: Images stored in root `images/` directory
- Traditional Chinese build: Images stored in root `images/` directory, accessed via symlink from `zh_tw/images/`

## File Structure

```
.
├── Dockerfile (modified - adds Puppeteer/Chrome setup)
├── Makefile (modified - adds Mermaid processing step)
├── tools/
│   └── process-mermaid.sh (new - Mermaid processing script)
├── images/
│   └── mermaid-*.png (generated during build)
└── plans/
    └── add_mermaid_support.md (this file)
```

**Docker Image Structure:**
- `/opt/puppeteer-cache/`: Browser installation directory
- `/etc/puppeteer-config.json`: Puppeteer configuration with executablePath

## Dependencies

- **mermaid-cli**: Installed globally in Docker container (`@mermaid-js/mermaid-cli`)
- **Puppeteer/Chrome Headless Shell**: Installed via `npx puppeteer browsers install chrome-headless-shell` during Docker build
- **Node.js/npm**: Required for mermaid-cli and Puppeteer, installed via apt-get
- **System Libraries**: Required for Chromium (libnss3, libatk1.0-0, libgbm1, etc.) installed via apt-get
- **libasound2**: Audio library for Chromium (handles both Ubuntu 24.04 variant `libasound2t64`)

## Usage

Mermaid diagrams are automatically processed during normal PDF builds:

```bash
# English build (processes Mermaid diagrams automatically)
./make-docker.sh printed

# Traditional Chinese build (processes Mermaid diagrams automatically)
./make-docker.sh zh_tw
```

**Mermaid Syntax in Markdown:**
```markdown
```mermaid
flowchart LR
    A[Start] --> B[End]
```
```

This will be automatically converted to:
```markdown
![Mermaid diagram](images/mermaid-1.png)
```

## Docker Configuration

### Puppeteer/Chrome Setup

The Dockerfile configures Puppeteer to work in a Docker environment:

1. **Install Chrome Headless Shell**: Uses `npx puppeteer browsers install chrome-headless-shell` to install the exact browser version that Puppeteer expects
2. **System-wide Cache Directory**: Installs browser in `/opt/puppeteer-cache` with permissions accessible to all users
3. **Puppeteer Configuration File**: Creates `/etc/puppeteer-config.json` with:
   - `executablePath`: Points to the installed Chrome headless shell executable
   - `args`: Includes `--no-sandbox` and `--disable-setuid-sandbox` for Docker compatibility
4. **Environment Variables**:
   - `PUPPETEER_CACHE_DIR=/opt/puppeteer-cache`: Tells Puppeteer where to find the browser
   - `PUPPETEER_CONFIG_FILE=/etc/puppeteer-config.json`: Points to the configuration file

### Key Implementation Details

- **Browser Installation**: Chrome headless shell is installed during Docker image build at `/opt/puppeteer-cache/chrome-headless-shell/linux-<version>/chrome-headless-shell-linux64/chrome-headless-shell`
- **Configuration Resolution**: The Dockerfile automatically finds the installed browser executable and writes it to the config file
- **Permission Handling**: All files and directories are set with appropriate permissions (755 for files/dirs, 644 for config) to ensure accessibility when running as non-root user
- **Script Fallback**: The processing script checks for `/etc/puppeteer-config.json` first, and falls back to a temporary config if needed

## Known Issues and Resolutions

### Initial Issues Encountered

1. **"Could not find Chrome" Error**
   - **Cause**: Puppeteer couldn't locate the browser because it was installed as root but container runs as different user
   - **Resolution**: Installed browser in system-wide location (`/opt/puppeteer-cache`) with proper permissions, and configured `executablePath` in Puppeteer config

2. **Permission Denied on Config File**
   - **Cause**: Script tried to delete `/etc/puppeteer-config.json` which is read-only for non-root users
   - **Resolution**: Script now checks if system config exists and only cleans up temporary configs it creates

3. **Browser Version Mismatch**
   - **Cause**: Puppeteer expects specific browser version, system Chromium package didn't match
   - **Resolution**: Use Puppeteer's own browser installer (`npx puppeteer browsers install`) to get exact version needed

4. **Fuzzy Text in Diagrams**
   - **Cause**: Default PNG resolution from mermaid-cli was too low, causing text to appear blurry compared to vector-rendered LaTeX text
   - **Resolution**: Added `-s 3` scale factor to `mmdc` command, generating 3x resolution images for crisp text rendering in PDFs

### Current Status

✅ **Resolved**: All issues have been addressed. The implementation:
- Installs Chrome headless shell via Puppeteer's installer
- Configures Puppeteer with explicit executable path
- Sets proper permissions for multi-user access
- Handles errors gracefully with detailed logging

## Testing Notes

- Verify Mermaid diagrams render correctly in final PDF
- Check that image paths are correct for both English and Chinese builds
- Ensure generated images are cleaned up on `make clean`
- Test with multiple Mermaid diagrams in a single document
- Verify error handling when mermaid-cli is unavailable or fails
- Verify text in diagrams is crisp and readable (3x scale factor should provide high-quality output)

## Completion Date

- Initial implementation: 2025-01-27
- Puppeteer/Chrome configuration finalized: 2025-01-27
- Resolution/quality improvement (3x scale): 2025-01-27

## Summary

The Mermaid diagram rendering feature is fully implemented and tested. The implementation includes:

1. ✅ Mermaid processing script that extracts code blocks and converts them to PNG images
2. ✅ Docker configuration for Puppeteer/Chrome headless shell installation
3. ✅ Integration into both English and Traditional Chinese build workflows
4. ✅ Proper error handling and fallback mechanisms
5. ✅ Clean target updated to remove generated images

The feature is production-ready and automatically processes Mermaid diagrams during PDF builds.

