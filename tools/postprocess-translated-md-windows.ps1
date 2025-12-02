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
    } elseif ($inMultiline -and $line -match '^\\usepackage\{etoolbox\}') {
        $result += '    ' + $line
    } elseif ($inMultiline -and $line -match '^\\AtBeginEnvironment\{CSLReferences\}') {
        $result += '    ' + $line
    } elseif ($inMultiline -and $line -match '^\\newpage\\section\*\{References\}') {
        $result += '      ' + $line
    } elseif ($inMultiline -and $line -match '^\\setlength\{') {
        $result += '      ' + $line
    } elseif ($inMultiline -and $line -match '^\}$') {
        $result += '    ' + $line
        $inMultiline = $false
    } else {
        $result += $line
    }
}

$content = $result -join "`r`n"
Set-Content -Path $TranslatedMdFile -Value $content -NoNewline

