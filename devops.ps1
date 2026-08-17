# Development Operations Center (PowerShell)
# Windows wrapper that delegates to devops.sh on host bash.

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$OperationArgs
)

$ErrorActionPreference = "Stop"

$Operation = if ($OperationArgs.Count -gt 0) { $OperationArgs[0] } else { "help" }

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

if ($Operation -in @("help", "--help", "-h")) {
    Write-Host "Development Operations Center - devops.ps1"
    Write-Host ""
    Write-Host "Usage: ./devops.ps1 [operation]"
    Write-Host ""
    Write-Host "Available operations:"
    Write-Host "  help            - Show this help message [default]"
    Write-Host "  env             - Check environment and guide toolchain/Docker setup"
    Write-Host "  pdf             - Build the main paper PDF (paper.pdf)"
    Write-Host "  pdf_date        - Build the paper PDF with date suffix"
    Write-Host "  cover           - Build the cover page PDF"
    Write-Host "  printed         - Build the printed version (cover + paper)"
    Write-Host "  translate       - Run the translation pipeline: translate [step] [--force]"
    Write-Host "  set-api-key     - Save Gemini API key to OS credential manager"
    Write-Host "  get-api-key     - Check configured Gemini API key in OS credential manager"
    Write-Host "  delete-api-key  - Remove Gemini API key from OS credential manager"
    Write-Host "  tags            - Generate .tags from all Markdown files"
    Write-Host "  ref-list        - Extract references from PDF and copy to clipboard"
    Write-Host "  toc-list        - Extract table of contents from PDF and copy to clipboard"
    Write-Host "  clean           - Remove all generated files"
    Write-Host "  deps            - Show information about dependencies"
    exit 0
}

if (-not (Test-Command "bash")) {
    Write-Err "bash is not installed or not in PATH"
    Write-Err "Install Git for Windows (Git Bash) or WSL, then retry."
    exit 1
}

# Environment check, dependency info, and credential management operations do not require Docker
$dockerRequiredOps = @("pdf", "pdf_date", "cover", "printed", "translate", "tags", "ref-list", "toc-list", "clean")
if ($Operation -in $dockerRequiredOps -and -not (Test-Command "docker")) {
    Write-Err "Docker is not installed or not in PATH"
    exit 1
}

$argsForBash = @("./devops.sh") + $OperationArgs
Write-Info "Delegating to: bash ./devops.sh $($OperationArgs -join ' ')"
& bash $argsForBash
exit $LASTEXITCODE
