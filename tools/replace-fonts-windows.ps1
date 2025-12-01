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

# Use UTF-8 explicitly to keep Pandoc-compatible encoding across platforms.
$content = Get-Content -Path $InputFile -Raw -Encoding UTF8

# Apply all replacements
for ($i = 0; $i -lt $Replacements.Count; $i += 2) {
    $oldFont = $Replacements[$i]
    $newFont = $Replacements[$i + 1]
    $content = $content -replace [regex]::Escape($oldFont), $newFont
}

Set-Content -Path $OutputFile -Value $content -NoNewline -Encoding UTF8

# Reset ACLs on the generated file to avoid restrictive inherited permissions (e.g. NULL SID denies).
try {
    icacls $OutputFile /reset | Out-Null
} catch {
    # Non-fatal: continue even if ACL reset fails.
}

