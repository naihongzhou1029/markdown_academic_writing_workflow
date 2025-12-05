# Docker wrapper for make - runs make inside dalibo/pandocker container (PowerShell version)
#
# This script creates an ephemeral container that is automatically removed
# after the build completes. All toolchains (pandoc, xelatex, make, etc.)
# are available inside the container.

param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$MakeArgs
)

# Image name and tag
$ImageName = "dalibo/pandocker"
$ImageTag = "latest-full"
$Image = "${ImageName}:${ImageTag}"

# Check if the image exists locally
$imageExists = docker images --format "{{.Repository}}:{{.Tag}}" | Select-String -Pattern "^${Image}$"

if (-not $imageExists) {
    Write-Host "Checking for alternative ${ImageName} images..."
    $availableImages = docker images --format "{{.Repository}}:{{.Tag}}" | Select-String -Pattern "^${ImageName}:"
    
    if ($availableImages) {
        Write-Host ""
        Write-Host "Warning: Image ${Image} not found locally."
        Write-Host "Available ${ImageName} images:"
        $availableImages | ForEach-Object { Write-Host "  $_" }
        Write-Host ""
        Write-Host "Pulling ${Image}..."
        docker pull $Image
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error: Failed to pull ${Image}" -ForegroundColor Red
            Write-Host "Please check your Docker connection and try again." -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host ""
        Write-Host "Image ${Image} not found locally. Pulling..."
        docker pull $Image
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error: Failed to pull ${Image}" -ForegroundColor Red
            Write-Host "Please check your Docker connection and try again." -ForegroundColor Red
            exit 1
        }
    }
}

# Get the current directory
$WorkDir = (Get-Location).Path

# Run make inside the dalibo/pandocker container
# --rm: automatically remove container after execution
# --entrypoint="": override container entrypoint to run make directly
# -v: mount current directory as /workspace in container
# -w: set working directory in container
# Install curl and jq if missing (required for translation scripts)
$makeArgsStr = if ($MakeArgs.Count -gt 0) { $MakeArgs -join " " } else { "" }
$bashCmd = "apt-get update -qq >/dev/null 2>&1 && (command -v curl >/dev/null 2>&1 || apt-get install -y -qq curl >/dev/null 2>&1) && (command -v jq >/dev/null 2>&1 || apt-get install -y -qq jq >/dev/null 2>&1) && /usr/bin/make $makeArgsStr"

$dockerArgs = @(
    "run",
    "--rm",
    "--entrypoint", "",
    "-v", "${WorkDir}:/workspace",
    "-w", "/workspace",
    $Image,
    "bash", "-c", $bashCmd
)

& docker $dockerArgs

