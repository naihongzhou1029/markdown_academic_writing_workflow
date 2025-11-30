# Detect fonts on Windows using PowerShell

$MAIN_FONT = "Times New Roman"

# Get installed fonts from Windows Fonts directory
$fontsPath = "$env:SystemRoot\Fonts"
$allFonts = Get-ChildItem -Path $fontsPath -Filter "*.ttf", "*.otf" | Select-Object -ExpandProperty Name

# Look for Simplified Chinese fonts
$CJK_FONT_SC = $null
$scFonts = @("NotoSansCJKsc-Regular.ttf", "NotoSansSC-Regular.ttf", "simsun.ttc", "simhei.ttf", "msyh.ttc")
foreach ($font in $scFonts) {
    if ($allFonts -contains $font) {
        # Extract font name from filename
        $CJK_FONT_SC = $font -replace '\.(ttf|otf|ttc)$', '' -replace '-Regular$', '' -replace 'CJKsc', 'CJK SC'
        break
    }
}

# If not found, try to find any font with "SC" or "Simplified" in name
if (-not $CJK_FONT_SC) {
    $scMatch = $allFonts | Where-Object { $_ -match "(SC|Simplified|SimSun|SimHei|Microsoft YaHei)" } | Select-Object -First 1
    if ($scMatch) {
        $CJK_FONT_SC = $scMatch -replace '\.(ttf|otf|ttc)$', ''
    }
}

# Fallback
if (-not $CJK_FONT_SC) {
    $CJK_FONT_SC = "Microsoft YaHei"
}

# Look for Traditional Chinese fonts
$CJK_FONT_TC = $null
$tcFonts = @("NotoSansCJKtc-Regular.ttf", "NotoSansTC-Regular.ttf", "mingliu.ttc", "msjh.ttc")
foreach ($font in $tcFonts) {
    if ($allFonts -contains $font) {
        $CJK_FONT_TC = $font -replace '\.(ttf|otf|ttc)$', '' -replace '-Regular$', '' -replace 'CJKtc', 'CJK TC'
        break
    }
}

# If not found, try to find any font with "TC" or "Traditional" in name
if (-not $CJK_FONT_TC) {
    $tcMatch = $allFonts | Where-Object { $_ -match "(TC|Traditional|MingLiU|Microsoft JhengHei)" } | Select-Object -First 1
    if ($tcMatch) {
        $CJK_FONT_TC = $tcMatch -replace '\.(ttf|otf|ttc)$', ''
    }
}

# Fallback
if (-not $CJK_FONT_TC) {
    $CJK_FONT_TC = "Microsoft JhengHei"
}

Write-Output "CJK_FONT_SC=$CJK_FONT_SC"
Write-Output "CJK_FONT_TC=$CJK_FONT_TC"
Write-Output "MAIN_FONT=$MAIN_FONT"

