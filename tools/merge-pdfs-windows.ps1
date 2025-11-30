# Merge PDFs on Windows using Ghostscript or PDFtk

param(
    [Parameter(Mandatory=$true)]
    [string]$CoverPdf,
    
    [Parameter(Mandatory=$true)]
    [string]$PaperPdf,
    
    [Parameter(Mandatory=$true)]
    [string]$Output
)

$ErrorActionPreference = "Stop"

# Try Ghostscript first
if (Get-Command gs -ErrorAction SilentlyContinue) {
    & gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile="$Output" "$CoverPdf" "$PaperPdf"
    Write-Host "Created $Output (cover + paper) with Ghostscript (gs)."
    exit 0
}

# Try PDFtk if available
if (Get-Command pdftk -ErrorAction SilentlyContinue) {
    & pdftk "$CoverPdf" "$PaperPdf" cat output "$Output"
    Write-Host "Created $Output (cover + paper) with PDFtk."
    exit 0
}

# Try poppler's pdfunite if available (from Chocolatey/winget installation)
if (Get-Command pdfunite -ErrorAction SilentlyContinue) {
    & pdfunite "$CoverPdf" "$PaperPdf" "$Output"
    Write-Host "Created $Output (cover + paper) with pdfunite."
    exit 0
}

Write-Host "No PDF merging tool found. Install one of the following:" -ForegroundColor Red
Write-Host "  - Ghostscript: choco install ghostscript or winget install ArtifexSoftware.Ghostscript" -ForegroundColor Yellow
Write-Host "  - PDFtk: choco install pdftk or winget install PDFtk.PDFtk" -ForegroundColor Yellow
Write-Host "  - Poppler: choco install poppler or winget install Poppler.Poppler" -ForegroundColor Yellow
exit 1

