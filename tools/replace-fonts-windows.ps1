# Replace font names in markdown/LaTeX files on Windows

param(
    [Parameter(Mandatory=$true)]
    [string]$InputFile,
    
    [Parameter(Mandatory=$true)]
    [string]$OutputFile,
    
    [Parameter(Mandatory=$true)]
    [string[]]$Replacements
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $InputFile)) {
    Write-Error "Input file not found: $InputFile"
    exit 1
}

if ($Replacements.Count % 2 -ne 0) {
    Write-Error "Replacements must be provided in pairs (old_font, new_font)"
    exit 1
}

$content = Get-Content -Path $InputFile -Raw

# Apply all replacements
for ($i = 0; $i -lt $Replacements.Count; $i += 2) {
    $oldFont = $Replacements[$i]
    $newFont = $Replacements[$i + 1]
    $content = $content -replace [regex]::Escape($oldFont), $newFont
}

Set-Content -Path $OutputFile -Value $content -NoNewline

