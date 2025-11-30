# Install dependencies on Windows using Chocolatey or winget

$ErrorActionPreference = "Stop"

Write-Host "Installing required CLI tools on Windows..."

# Check for package manager
$packageManager = $null
if (Get-Command choco -ErrorAction SilentlyContinue) {
    $packageManager = "choco"
    Write-Host "Using Chocolatey as package manager."
} elseif (Get-Command winget -ErrorAction SilentlyContinue) {
    $packageManager = "winget"
    Write-Host "Using winget as package manager."
} else {
    Write-Host "Neither Chocolatey nor winget found." -ForegroundColor Red
    Write-Host "Please install one of the following:" -ForegroundColor Yellow
    Write-Host "  - Chocolatey: https://chocolatey.org/install" -ForegroundColor Yellow
    Write-Host "  - winget: Usually pre-installed on Windows 10/11" -ForegroundColor Yellow
    exit 1
}

# Install packages
if ($packageManager -eq "choco") {
    # Check if running as administrator
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host "Chocolatey requires administrator privileges. Please run as administrator." -ForegroundColor Red
        exit 1
    }
    
    choco install poppler --yes --no-progress
    choco install ghostscript --yes --no-progress
    
    # pandoc-crossref might not be available in Chocolatey, provide instructions
    if (-not (Get-Command pandoc-crossref -ErrorAction SilentlyContinue)) {
        Write-Host "pandoc-crossref not found. Install it via:" -ForegroundColor Yellow
        Write-Host "  Download from: https://github.com/lierdakil/pandoc-crossref/releases" -ForegroundColor Yellow
        Write-Host "  Or use Haskell Stack: stack install pandoc-crossref" -ForegroundColor Yellow
    }
} elseif ($packageManager -eq "winget") {
    winget install --id Poppler.Poppler --accept-package-agreements --accept-source-agreements --silent
    winget install --id ArtifexSoftware.Ghostscript --accept-package-agreements --accept-source-agreements --silent
    
    # pandoc-crossref might not be available in winget, provide instructions
    if (-not (Get-Command pandoc-crossref -ErrorAction SilentlyContinue)) {
        Write-Host "pandoc-crossref not found. Install it via:" -ForegroundColor Yellow
        Write-Host "  Download from: https://github.com/lierdakil/pandoc-crossref/releases" -ForegroundColor Yellow
        Write-Host "  Or use Haskell Stack: stack install pandoc-crossref" -ForegroundColor Yellow
    }
}

Write-Host "All dependencies are installed."

