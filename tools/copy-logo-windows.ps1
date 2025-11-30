# Copy or create symlink for logo file in target directory on Windows

param(
    [Parameter(Mandatory=$true)]
    [string]$SourceLogo,
    
    [Parameter(Mandatory=$true)]
    [string]$TargetDir
)

$ErrorActionPreference = "Continue"

if (-not (Test-Path $SourceLogo -PathType Leaf)) {
    Write-Error "Source logo file not found: $SourceLogo"
    exit 1
}

if (-not (Test-Path $TargetDir -PathType Container)) {
    Write-Error "Target directory not found: $TargetDir"
    exit 1
}

$basename = Split-Path -Leaf $SourceLogo
$targetPath = Join-Path $TargetDir $basename

# Remove existing file/link if it exists
if (Test-Path $targetPath) {
    Remove-Item -Path $targetPath -Force -ErrorAction SilentlyContinue
}

# Try to create symlink first, fallback to copy
$relativePath = Resolve-Path -Relative $SourceLogo
$relativePath = $relativePath -replace '^\.\\', '..\'
$symlinkCreated = $false

try {
    New-Item -ItemType SymbolicLink -Path $targetPath -Target $relativePath -ErrorAction Stop | Out-Null
    $symlinkCreated = $true
} catch {
    # Symlink creation failed, will fallback to copy
}

# Fallback to copy if symlink failed
if (-not $symlinkCreated) {
    Copy-Item -Path $SourceLogo -Destination $targetPath -ErrorAction SilentlyContinue
}

