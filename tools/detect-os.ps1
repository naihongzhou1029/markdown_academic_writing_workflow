# Detect operating system for Windows (PowerShell)

if ($IsWindows -or $env:OS -like "*Windows*") {
    Write-Output "Windows_NT"
} else {
    Write-Output "Unknown"
}

