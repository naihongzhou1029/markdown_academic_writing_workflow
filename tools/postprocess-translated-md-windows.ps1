# Post-process translated markdown file on Windows

param(
    [Parameter(Mandatory=$true)]
    [string]$TranslatedMdFile,
    
    [Parameter(Mandatory=$true)]
    [string]$CjkFont
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $TranslatedMdFile)) {
    Write-Error "Translated markdown file not found: $TranslatedMdFile"
    exit 1
}

$content = Get-Content -Path $TranslatedMdFile -Raw

# Apply font replacements
$content = $content -replace 'CJKmainfont: "PingFang SC"', "CJKmainfont: `"$CjkFont`""
$content = $content -replace 'setCJKmainfont\{PingFang SC\}', "setCJKmainfont{$CjkFont}"

# Apply label translations
$content = $content -replace '"Figure"', '"圖"'
$content = $content -replace '"Figures"', '"圖"'
$content = $content -replace '"Tab\."', '"表"'

# Apply indentation fixes for LaTeX code blocks
$lines = $content -split "`r?`n"
$inMultiline = $false
$result = @()

for ($i = 0; $i -lt $lines.Length; $i++) {
    $line = $lines[$i]
    
    if ($line -match '^- \|$') {
        $inMultiline = $true
        $result += $line
    } elseif ($inMultiline -and $line.Trim() -match '^[a-zA-Z].*:$') {
        # End of block: next top-level YAML key
        $inMultiline = $false
        $result += $line
    } elseif ($inMultiline) {
        # Inside block: fix indentation
        if ($line -match '^    ') {
            # Already properly indented
            $result += $line
        } elseif ($line -match '^\\' -and -not ($line -match '^\s')) {
            # LaTeX command that needs indentation (starts with backslash, no leading spaces)
            $result += '    ' + $line
        } elseif (-not $line.Trim()) {
            # Empty line - preserve as is
            $result += $line
        } else {
            # Other content in block - indent if not already indented
            if ($line -match '^\s') {
                $result += $line
            } else {
                $result += '    ' + $line
            }
        }
    } else {
        $result += $line
    }
}

$content = $result -join "`r`n"
Set-Content -Path $TranslatedMdFile -Value $content -NoNewline

