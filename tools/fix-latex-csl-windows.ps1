# Fix LaTeX CSLReferences formatting issue on Windows

param(
    [Parameter(Mandatory=$true)]
    [string]$LatexFile
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $LatexFile)) {
    Write-Error "LaTeX file not found: $LatexFile"
    exit 1
}

$content = Get-Content -Path $LatexFile -Raw
$content = $content -replace '}\\% \\AtEndEnvironment{CSLReferences}', "}`n\AtEndEnvironment{CSLReferences}"
Set-Content -Path $LatexFile -Value $content -NoNewline

