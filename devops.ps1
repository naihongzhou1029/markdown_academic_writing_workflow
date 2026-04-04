# Development Operations Center (PowerShell)
# Windows wrapper that delegates to devops.sh on host bash.

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$TargetArgs
)

$ErrorActionPreference = "Stop"

$Target = if ($TargetArgs.Count -gt 0) { $TargetArgs[0] } else { "help" }

function Write-Info { param([string]$Msg) Write-Host "[INFO] $Msg" -ForegroundColor Green }
function Write-Err { param([string]$Msg) Write-Host "[ERROR] $Msg" -ForegroundColor Red }

function Test-Command {
    param([string]$Name)
    try {
        Get-Command $Name -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

if ($Target -in @("help", "--help", "-h")) {
    Write-Host "Development Operations Center - devops.ps1"
    Write-Host ""
    Write-Host "Usage: ./devops.ps1 [target]"
    Write-Host ""
    Write-Host "Available targets:"
    Write-Host "  help      - Show this help message [default]"
    Write-Host "  pdf       - Build the main paper PDF (paper.pdf)"
    Write-Host "  pdf_date  - Build the paper PDF with date suffix"
    Write-Host "  cover     - Build the cover page PDF"
    Write-Host "  printed   - Build the printed version (cover + paper)"
    Write-Host "  zh_tw     - Run the Traditional Chinese translation pipeline"
    Write-Host "  tags      - Generate .tags from all Markdown files"
    Write-Host "  clean     - Remove all generated files"
    Write-Host "  deps      - Show information about dependencies"
    exit 0
}

if (-not (Test-Command "docker")) {
    Write-Err "Docker is not installed or not in PATH"
    exit 1
}

if (-not (Test-Command "bash")) {
    Write-Err "bash is not installed or not in PATH"
    Write-Err "Install Git for Windows (Git Bash) or WSL, then retry."
    exit 1
}

$argsForBash = @("./devops.sh", $Target)
Write-Info "Delegating to: bash ./devops.sh $Target"
& bash $argsForBash
exit $LASTEXITCODE
