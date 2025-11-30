# Post-process translated LaTeX file on Windows

param(
    [Parameter(Mandatory=$true)]
    [string]$LatexFile,
    
    [Parameter(Mandatory=$true)]
    [string]$OldFont,
    
    [Parameter(Mandatory=$true)]
    [string]$NewFont
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $LatexFile)) {
    Write-Error "LaTeX file not found: $LatexFile"
    exit 1
}

$content = Get-Content -Path $LatexFile -Raw
$content = $content -replace [regex]::Escape($OldFont), $NewFont
Set-Content -Path $LatexFile -Value $content -NoNewline

