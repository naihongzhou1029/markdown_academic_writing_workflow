# Clean build artifacts on Windows using PowerShell

param(
    [string]$Pdf = "paper.pdf",
    [string]$CoverPdf = "cover.pdf",
    [string]$PrintedPdf = "printed.pdf",
    [string]$TempSrc = "paper.tmp.md",
    [string]$CoverTempTex = "ntust_cover_page.tmp.tex"
)

$ErrorActionPreference = "Continue"

# Remove specific files
$filesToRemove = @(
    $Pdf,
    $CoverPdf,
    $PrintedPdf,
    $TempSrc,
    $CoverTempTex
)

foreach ($file in $filesToRemove) {
    if (Test-Path $file) {
        Remove-Item -Path $file -Force -ErrorAction SilentlyContinue
    }
}

# Remove LaTeX intermediate files
$latexPatterns = @(
    "*.aux", "*.log", "*.out", "*.toc", "*.bbl", "*.blg", "*.bcf",
    "*.run.xml", "*.synctex.gz", "*.fdb_latexmk", "*.fls", "*.xdv",
    "*.nav", "*.snm", "*.vrb", "*.lof", "*.lot", "*.loa", "*.lol"
)

foreach ($pattern in $latexPatterns) {
    Get-ChildItem -Path . -Filter $pattern -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
}

# Remove _minted* directories
Get-ChildItem -Path . -Directory -Filter "_minted*" -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Cleaned build outputs and LaTeX intermediates."

