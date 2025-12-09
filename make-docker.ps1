# Docker wrapper for make - runs make inside dalibo/pandocker container (PowerShell version)
#
# This script uses a derived image with jq and curl pre-installed to avoid
# installing them on every translation run. The container is automatically removed
# after the build completes. All toolchains (pandoc, xelatex, make, etc.)
# are available inside the container.

param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$MakeArgs
)

# Base image name and tag
$BaseImageName = "dalibo/pandocker"
$BaseImageTag = "latest-full"
$BaseImage = "${BaseImageName}:${BaseImageTag}"

# Derived image name (with jq and curl pre-installed)
$DerivedImageName = "pandocker-with-tools"
$DerivedImageTag = "latest"
$DerivedImage = "${DerivedImageName}:${DerivedImageTag}"

# Check if base image exists, pull if needed
$baseImageExists = docker images --format "{{.Repository}}:{{.Tag}}" | Select-String -Pattern "^${BaseImage}$"

if (-not $baseImageExists) {
    Write-Host "Base image ${BaseImage} not found locally. Pulling..."
    docker pull $BaseImage
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to pull ${BaseImage}" -ForegroundColor Red
        Write-Host "Please check your Docker connection and try again." -ForegroundColor Red
        exit 1
    }
}

# Get the current directory
$WorkDir = (Get-Location).Path

# Check if derived image exists, build if needed
$derivedImageExists = docker images --format "{{.Repository}}:{{.Tag}}" | Select-String -Pattern "^${DerivedImage}$"

if (-not $derivedImageExists) {
    Write-Host "Derived image ${DerivedImage} not found. Building from Dockerfile..."
    $dockerfilePath = Join-Path $WorkDir "Dockerfile"
    if (-not (Test-Path $dockerfilePath)) {
        Write-Host "Error: Dockerfile not found in $WorkDir" -ForegroundColor Red
        Write-Host "Please create a Dockerfile that extends ${BaseImage} and installs jq and curl." -ForegroundColor Red
        exit 1
    }
    docker build -t $DerivedImage -f $dockerfilePath $WorkDir
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to build derived image ${DerivedImage}" -ForegroundColor Red
        exit 1
    }
    Write-Host "Derived image built successfully."
}

# Use the derived image
$Image = $DerivedImage

$ApiKeyFile = Join-Path $WorkDir ".api_key"

# Require API key file before running translation targets
if (-not (Test-Path $ApiKeyFile)) {
    # Detect if translation likely requested
    $argsJoined = ($MakeArgs -join " ").ToLowerInvariant()
    if ($argsJoined -match "zh_tw" -or $argsJoined -match "translate") {
        Write-Host "Error: API key file not found: $ApiKeyFile" -ForegroundColor Red
        Write-Host "Create it with your Gemini API key before running translation targets." -ForegroundColor Red
        Write-Host "Example: echo '<your-key>' > $ApiKeyFile" -ForegroundColor Yellow
        exit 1
    }
}

# Run make inside the container
# --rm: automatically remove container after execution
# --entrypoint="": override container entrypoint to run make directly
# -v: mount current directory as /workspace in container
# -w: set working directory in container

# Construct Docker command string to avoid PowerShell array expansion issues with empty strings
$makeTargets = if ($MakeArgs -and $MakeArgs.Count -gt 0) { $MakeArgs -join " " } else { "" }

# Build command string with proper quoting
# Use format string to clearly handle the empty entrypoint value
$dockerCmd = 'docker run --rm --entrypoint="" -v "{0}:/workspace" -w /workspace {1} /usr/bin/make' -f $WorkDir, $Image

if ($makeTargets) {
    $dockerCmd += " $makeTargets"
}

# Execute using Invoke-Expression for proper command string parsing
Invoke-Expression $dockerCmd

