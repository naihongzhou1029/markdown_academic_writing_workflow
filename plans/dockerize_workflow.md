# Dockerize Workflow: Remove OS-Specific Scripts

## Status: ✅ Completed

## Overview

This document tracks the refactoring of the project to use Docker exclusively, removing all OS-specific scripts for Windows and macOS, and simplifying the build system to assume all toolchains run inside the `dalibo/pandocker` Docker container.

## Implementation Progress

### ✅ 1. Remove OS-Specific Scripts

**Windows Scripts Removed (13 files):**
- `tools/deps-windows.ps1`
- `tools/postprocess-translated-md-windows.ps1`
- `tools/replace-fonts-windows.ps1`
- `tools/translate-windows.ps1`
- `tools/postprocess-translated-tex-windows.ps1`
- `tools/merge-pdfs-windows.ps1`
- `tools/fix-latex-csl-windows.ps1`
- `tools/download-logo-windows.ps1`
- `tools/detect-fonts-windows.ps1`
- `tools/create-symlinks-windows.ps1`
- `tools/copy-logo-windows.ps1`
- `tools/cleanup-temp-windows.ps1`
- `tools/clean-windows.ps1`

**macOS/Darwin Scripts Removed (13 files):**
- `tools/deps-darwin.sh`
- `tools/postprocess-translated-md-darwin.sh`
- `tools/translate-darwin.sh`
- `tools/replace-fonts-darwin.sh`
- `tools/postprocess-translated-tex-darwin.sh`
- `tools/merge-pdfs-darwin.sh`
- `tools/fix-latex-csl-darwin.sh`
- `tools/download-logo-darwin.sh`
- `tools/detect-fonts-darwin.sh`
- `tools/create-symlinks-darwin.sh`
- `tools/copy-logo-darwin.sh`
- `tools/cleanup-temp-darwin.sh`
- `tools/clean-darwin.sh`

**OS Detection Utilities Removed:**
- `tools/detect-os.sh`
- `tools/detect-os.ps1`
- `tools/pandoc-crossref.exe` (Windows binary)

**Remaining Scripts:**
- All Linux scripts (`tools/*-linux.sh`) remain, as they work inside Docker containers

### ✅ 2. Simplify Makefile

**Removed:**
- OS detection logic (lines 27-85)
- Windows-specific conditionals throughout the file
- OS-specific script variable assignments
- Windows PowerShell command invocations
- OS-specific font fallback values

**Simplified:**
- Direct assignment of Linux script paths
- Unconditional use of Linux scripts (no OS branching)
- Simplified font detection using Linux script directly
- Removed all `ifeq ($(IS_WINDOWS),1)` conditionals
- Removed all `ifeq ($(OS_TYPE),...)` conditionals

**Key Changes:**
- Script variables now directly point to Linux scripts
- Font detection uses `bash $(FONT_DETECT_SCRIPT)` unconditionally
- All targets use `bash` to invoke scripts
- `deps` target updated with note about Docker
- `clean` target simplified to use Linux script only

### ✅ 3. Create Docker Wrapper Scripts

**Primary Wrapper:**
- `make-docker.sh` - Bash script for Linux/macOS/WSL
  - Uses `docker run --rm` for ephemeral containers
  - Automatically removes container after build
  - Preserves file ownership with `-u $(id -u):$(id -g)`
  - Mounts current directory as `/workspace`
  - Passes all arguments to `make`

**Windows Wrappers:**
- `make-docker.bat` - Windows CMD batch script
  - Simplified path handling for Windows
  - Uses `%CD%` for current directory
  - Compatible with Docker Desktop on Windows
  
- `make-docker.ps1` - PowerShell script
  - Proper parameter handling for make arguments
  - Uses `Get-Location` for current directory
  - Array-based Docker command construction

**Features:**
- All wrappers create ephemeral containers (`--rm` flag)
- Containers are automatically removed after execution
- File ownership preserved where possible
- All make targets and arguments supported

### ✅ 4. Update Documentation

**README.md Updates:**
- Updated "Toolchain Requirements" section to document Docker-based approach
- Removed OS-specific installation instructions
- Updated "Basic Usage" section with Docker wrapper instructions
- Added usage examples for all three wrapper scripts (`.sh`, `.bat`, `.ps1`)
- Added note about WSL Docker credential configuration
- Updated translation section to mention Docker container requirements

**AGENTS.md Updates:**
- Updated to reflect Docker-only approach
- Removed OS-specific dependency guidance
- Updated build command references to use `./make-docker.sh`
- Added note about scripts running inside Docker container
- Removed references to OS-specific installation

### ✅ 5. Additional Enhancements

**Terminal Profile Configuration:**
- Added terminal profiles to `markdown_academic_writing_workflow.code-workspace`
- Configured profiles for:
  - Command Prompt (Windows CMD)
  - PowerShell
  - PowerShell (x86)
  - WSL (set as default)
- Enables easy terminal switching in Cursor/VS Code

## File Summary

### Removed Files (29 total)
- 13 Windows PowerShell scripts
- 13 macOS/Darwin shell scripts
- 2 OS detection utilities
- 1 Windows binary

### Created Files (3 total)
- `make-docker.sh` - Primary Docker wrapper (Linux/macOS/WSL)
- `make-docker.bat` - Windows CMD wrapper
- `make-docker.ps1` - PowerShell wrapper

### Modified Files (4 total)
- `Makefile` - Simplified to Linux-only, removed OS detection
- `README.md` - Updated for Docker-based workflow
- `AGENTS.md` - Updated for Docker-only approach
- `markdown_academic_writing_workflow.code-workspace` - Added terminal profiles

### Remaining Files
- All `tools/*-linux.sh` scripts (13 files) - Work inside Docker containers

## Docker Container Details

**Container Image:** `dalibo/pandocker:stable`

**Includes:**
- Pandoc with `--citeproc` support
- `pandoc-crossref` filter
- LaTeX distribution (TeX Live) with XeLaTeX
- Make and other build utilities
- All necessary fonts and dependencies
- `curl` and `jq` for translation scripts

**Container Behavior:**
- Ephemeral containers (automatically removed after execution)
- Current directory mounted as `/workspace`
- File ownership preserved with `-u $(id -u):$(id -g)`
- All toolchains available at runtime

## Usage

### Linux/macOS/WSL
```bash
./make-docker.sh
./make-docker.sh zh_tw
./make-docker.sh clean
```

### Windows CMD
```cmd
make-docker.bat
make-docker.bat zh_tw
make-docker.bat clean
```

### Windows PowerShell
```powershell
./make-docker.ps1
./make-docker.ps1 zh_tw
./make-docker.ps1 clean
```

## WSL Docker Configuration Notes

If encountering Docker credential errors in WSL (e.g., `docker-credential-desktop: executable file not found`):

1. Ensure Docker Desktop is running on Windows
2. Enable WSL integration in Docker Desktop settings
3. Configure Docker credentials if needed:
   ```bash
   # Edit ~/.docker/config.json and remove "credsStore" line if problematic
   ```

## Benefits

- **Consistency**: Uniform build environment across all platforms
- **Simplicity**: No OS-specific installation or configuration needed
- **Portability**: Team members can replicate build environment easily
- **Maintainability**: Reduced codebase (29 fewer files)
- **Reproducibility**: Same container image ensures identical toolchain versions

## Migration Notes

- All existing Make targets remain functional
- Build commands now use Docker wrappers instead of direct `make`
- No changes required to `paper.md` or other source files
- Translation pipeline (`zh_tw` target) works identically inside container
- All Linux scripts continue to work as before (now inside container)

## Testing Recommendations

1. Test Docker wrapper on Linux: `./make-docker.sh`
2. Test Docker wrapper on macOS: `./make-docker.sh`
3. Test Docker wrapper on WSL: `./make-docker.sh`
4. Test Windows CMD wrapper: `make-docker.bat`
5. Test Windows PowerShell wrapper: `./make-docker.ps1`
6. Verify all targets work: `pdf`, `cover`, `printed`, `zh_tw`, `clean`
7. Verify file ownership is preserved after builds
8. Verify containers are automatically removed after execution

## Completion Date

Implementation completed: 2025-01-27

## Related Documentation

- `README.md` - User-facing documentation for Docker-based workflow
- `AGENTS.md` - Agent guidelines for Docker-only approach
- `make-docker.sh` - Primary Docker wrapper script
- `make-docker.bat` - Windows CMD wrapper script
- `make-docker.ps1` - PowerShell wrapper script


