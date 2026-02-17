# Development Operations Center (PowerShell)
# Mirrors devops.sh for Windows. Handles Docker orchestration and invokes devops.sh
# inside the pandocker-with-tools container.

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$TargetArgs
)

$ErrorActionPreference = "Stop"

$BaseImageName = "dalibo/pandocker"
$BaseImageTag = "latest-full"
$BaseImage = "${BaseImageName}:${BaseImageTag}"

$DerivedImageName = "pandocker-with-tools"
$DerivedImageTag = "latest"
$DerivedImage = "${DerivedImageName}:${DerivedImageTag}"

$WorkDir = (Get-Location).Path
$Target = if ($TargetArgs.Count -gt 0) { $TargetArgs[0] } else { "printed" }

function Write-Info { param([string]$Msg) Write-Host "[INFO] $Msg" -ForegroundColor Green }
function Write-Warn { param([string]$Msg) Write-Host "[WARN] $Msg" -ForegroundColor Yellow }
function Write-Err { param([string]$Msg) Write-Host "[ERROR] $Msg" -ForegroundColor Red }

function Test-Docker {
    try {
        docker --version | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Ensure-BaseImage {
    $images = docker images --format "{{.Repository}}:{{.Tag}}" 2>$null
    $found = $images | Where-Object { $_ -eq $BaseImage }
    if (-not $found) {
        Write-Info "Base image ${BaseImage} not found locally. Pulling..."
        docker pull --platform linux/amd64 $BaseImage
        if ($LASTEXITCODE -ne 0) {
            Write-Err "Failed to pull ${BaseImage}"
            Write-Err "Please check your Docker connection and try again."
            exit 1
        }
    }
}

function Ensure-DerivedImage {
    $images = docker images --format "{{.Repository}}:{{.Tag}}" 2>$null
    $m = $images | Where-Object { $_ -eq $DerivedImage }
    if (-not $m) {
        Write-Info "Derived image ${DerivedImage} not found. Building from Dockerfile..."
        $dockerfilePath = Join-Path $WorkDir "Dockerfile"
        if (-not (Test-Path $dockerfilePath)) {
            Write-Err "Dockerfile not found in $WorkDir"
            Write-Err "Please create a Dockerfile that extends ${BaseImage} and installs jq and curl."
            exit 1
        }
        docker build --platform linux/amd64 -t $DerivedImage -f $dockerfilePath $WorkDir
        if ($LASTEXITCODE -ne 0) {
            Write-Err "Failed to build derived image ${DerivedImage}"
            exit 1
        }
        Write-Info "Derived image built successfully."
    }
}

if (-not (Test-Docker)) {
    Write-Err "Docker is not installed or not in PATH"
    exit 1
}

Ensure-BaseImage
Ensure-DerivedImage

$cmd = "./devops.sh $Target"

$dockerArgs = @(
    "run",
    "--rm",
    "--entrypoint", "",
    "-v", "${WorkDir}:/workspace",
    "-w", "/workspace",
    $DerivedImage,
    "bash", "-c", $cmd
)

& docker $dockerArgs
exit $LASTEXITCODE
