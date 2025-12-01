# Install dependencies on Windows using Chocolatey

$ErrorActionPreference = "Stop"

Write-Host "Installing required CLI tools on Windows..."

# Require Chocolatey as the single package manager
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Chocolatey (choco) not found." -ForegroundColor Red
    Write-Host "Please install Chocolatey from:" -ForegroundColor Yellow
    Write-Host "  https://chocolatey.org/install" -ForegroundColor Yellow
    exit 1
}

Write-Host "Using Chocolatey as package manager."

# Check for curl (usually pre-installed on Windows 10/11)
if (-not (Get-Command curl -ErrorAction SilentlyContinue)) {
    Write-Host "curl not found. It will be installed if a package manager is available." -ForegroundColor Yellow
}

# Install packages using Chocolatey
    # Check if running as administrator
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host "Chocolatey requires administrator privileges. Please run as administrator." -ForegroundColor Red
        exit 1
    }
    
    choco install poppler --yes --no-progress
    choco install ghostscript --yes --no-progress

    # Install pandoc (core tool), if missing
    if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
        choco install pandoc --yes --no-progress
    }
    
    # Install curl if not available
    if (-not (Get-Command curl -ErrorAction SilentlyContinue)) {
        choco install curl --yes --no-progress
    }
    
    # Install jq (optional, PowerShell uses built-in JSON parsing, but useful for other tools)
    if (-not (Get-Command jq -ErrorAction SilentlyContinue)) {
        choco install jq --yes --no-progress
    }
    
# Install pandoc-crossref (not available via Chocolatey)
    if (-not (Get-Command pandoc-crossref -ErrorAction SilentlyContinue)) {
    # Prefer using a locally provided binary in tools if present.
    $localExe = Join-Path $PSScriptRoot "pandoc-crossref.exe"
    if (Test-Path $localExe) {
        Write-Host "pandoc-crossref not found on PATH. Installing from local tools/pandoc-crossref.exe..." -ForegroundColor Yellow

        try {
            # Prefer installing alongside pandoc.exe if available, otherwise fall back to a standard location.
            $installDir = $null
            $pandocCmd = Get-Command pandoc -ErrorAction SilentlyContinue
            if ($pandocCmd) {
                $installDir = Split-Path -Parent $pandocCmd.Source
            } else {
                $installDir = Join-Path $env:ProgramFiles "Pandoc"
                if (-not (Test-Path $installDir)) {
                    New-Item -ItemType Directory -Path $installDir | Out-Null
                }
            }

            Write-Host "Copying pandoc-crossref.exe to $installDir" -ForegroundColor Yellow
            Copy-Item -Path $localExe -Destination (Join-Path $installDir "pandoc-crossref.exe") -Force
        } catch {
            Write-Host "Automatic installation of pandoc-crossref from local tools folder failed: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Please ensure pandoc-crossref.exe is placed in a directory on your PATH (e.g. alongside pandoc.exe)." -ForegroundColor Yellow
        }
    } else {
        Write-Host "pandoc-crossref not found on PATH and tools/pandoc-crossref.exe is missing." -ForegroundColor Yellow
        Write-Host "Please download it from:" -ForegroundColor Yellow
        Write-Host "  https://github.com/lierdakil/pandoc-crossref/releases" -ForegroundColor Yellow
        Write-Host "and place pandoc-crossref.exe either in tools/ or in a directory on your PATH (e.g. alongside pandoc.exe)." -ForegroundColor Yellow
    }
}

if (Get-Command pandoc-crossref -ErrorAction SilentlyContinue) {
Write-Host "All dependencies are installed."
} else {
    Write-Host "Core dependencies installed. pandoc-crossref is still missing from PATH." -ForegroundColor Yellow
}

