# Remove temporary files created during build process on Windows

param(
    [Parameter(Mandatory=$true)]
    [string[]]$Files
)

$ErrorActionPreference = "Continue"

foreach ($file in $Files) {
    if (Test-Path $file) {
        Remove-Item -Path $file -Force -Recurse -ErrorAction SilentlyContinue
    }
}

