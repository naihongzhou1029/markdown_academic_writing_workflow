# Download NTUST logo on Windows using PowerShell

param(
    [Parameter(Mandatory=$true)]
    [string]$LogoFile,
    
    [Parameter(Mandatory=$true)]
    [string]$LogoUrl
)

$ErrorActionPreference = "Stop"

Write-Host "Fetching NTUST logo..."

try {
    Invoke-WebRequest -Uri $LogoUrl -OutFile $LogoFile -UseBasicParsing
    Write-Host "Logo downloaded successfully to $LogoFile"
} catch {
    Write-Host "Failed to download logo: $_" -ForegroundColor Red
    exit 1
}

