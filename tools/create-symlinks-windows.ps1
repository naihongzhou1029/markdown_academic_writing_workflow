# Create symbolic links for dependencies in target directory on Windows

param(
    [Parameter(Mandatory=$true)]
    [string]$TargetDir,
    
    [Parameter(Mandatory=$true)]
    [string[]]$Files
)

$ErrorActionPreference = "Continue"

if (-not (Test-Path $TargetDir -PathType Container)) {
    Write-Error "Target directory not found: $TargetDir"
    exit 1
}

foreach ($file in $Files) {
    if (-not (Test-Path $file -PathType Leaf)) {
        Write-Warning "Source file not found: $file, skipping..."
        continue
    }
    
    $basename = Split-Path -Leaf $file
    $targetPath = Join-Path $TargetDir $basename
    
    # Remove existing file/link if it exists
    if (Test-Path $targetPath) {
        Remove-Item -Path $targetPath -Force -ErrorAction SilentlyContinue
    }
    
    # Create symlink (relative path)
    $relativePath = Resolve-Path -Relative $file
    $relativePath = $relativePath -replace '^\.\\', '..\'
    New-Item -ItemType SymbolicLink -Path $targetPath -Target $relativePath -ErrorAction SilentlyContinue | Out-Null
    
    # Fallback to copy if symlink fails
    if (-not (Test-Path $targetPath)) {
        Copy-Item -Path $file -Destination $targetPath -ErrorAction SilentlyContinue
    }
}

