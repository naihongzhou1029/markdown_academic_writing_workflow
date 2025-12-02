# Translation script for Windows using Gemini API (PowerShell)

param(
    [Parameter(Mandatory=$true)]
    [string]$InputFile,
    
    [Parameter(Mandatory=$true)]
    [string]$OutputFile,
    
    [Parameter(Mandatory=$true)]
    [string]$SourceLang,
    
    [Parameter(Mandatory=$true)]
    [string]$TargetLang,
    
    [Parameter(Mandatory=$true)]
    [string]$Model,
    
    [Parameter(Mandatory=$true)]
    [string]$ApiKeyFile
)

$ErrorActionPreference = "Stop"

# Check if API key file exists, prompt if not
if (-not (Test-Path $ApiKeyFile)) {
    Write-Host "API key file not found: $ApiKeyFile"
    $apiKey = Read-Host "Enter your Gemini API key" -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($apiKey)
    $plainApiKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    $plainApiKey | Out-File -FilePath $ApiKeyFile -Encoding utf8 -NoNewline
    $file = Get-Item $ApiKeyFile
    $file.Attributes = $file.Attributes -bor [System.IO.FileAttributes]::Hidden
    Write-Host "API key saved to $ApiKeyFile"
} else {
    $plainApiKey = Get-Content $ApiKeyFile -Raw
}

# Check for curl
if (-not (Get-Command curl -ErrorAction SilentlyContinue)) {
    Write-Error "Error: curl is required but not installed. Install via: choco install curl or winget install cURL.cURL"
    exit 1
}

# Read input file
if (-not (Test-Path $InputFile)) {
    Write-Error "Error: Input file not found: $InputFile"
    exit 1
}

$inputContent = Get-Content $InputFile -Raw

# Determine file type for prompt customization
$fileExt = [System.IO.Path]::GetExtension($InputFile).TrimStart('.')
if ($fileExt -eq "md") {
    $preserveInstructions = "Preserve all YAML metadata block structure EXACTLY, including all indentation, spacing, and formatting. CRITICAL: Maintain the exact same indentation for multiline YAML blocks (e.g., the |- block). Also preserve citation syntax (e.g., [@citation_key]), cross-reference syntax (e.g., @tbl:label, @fig:label, @eq:label), and Markdown formatting. Translate reference labels like 'Figure' to '圖', 'Table' to '表格', 'Tab.' to '表'."
} elseif ($fileExt -eq "tex") {
    $preserveInstructions = "Preserve all LaTeX commands, structure, and formatting. Only translate text content within commands like \newcommand, but keep all LaTeX syntax intact."
} else {
    $preserveInstructions = "Preserve all formatting and structure."
}

# Construct prompt
if ($fileExt -eq "tex") {
    $prompt = "Translate the following LaTeX file from $SourceLang to $TargetLang. $preserveInstructions Maintain the exact same document structure and formatting. Only translate the natural language text content. IMPORTANT: Return ONLY the LaTeX code, do NOT wrap it in markdown code fences or add any markdown formatting.

Content to translate:
$inputContent"
} else {
    $prompt = "Translate the following content from $SourceLang to $TargetLang. $preserveInstructions Maintain the exact same document structure and formatting. Only translate the natural language text content.

Content to translate:
$inputContent"
}

# Create JSON payload
$jsonPayload = @{
    contents = @(
        @{
            parts = @(
                @{
                    text = $prompt
                }
            )
        }
    )
} | ConvertTo-Json -Depth 10

# Call Gemini API
$apiUrl = "https://generativelanguage.googleapis.com/v1beta/models/${Model}:generateContent?key=$plainApiKey"

try {
    $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Body $jsonPayload -ContentType "application/json"
} catch {
    Write-Error "Error calling Gemini API: $_"
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Error "Response: $responseBody"
    }
    exit 1
}

# Check for API errors
if ($response.error) {
    $errorMsg = $response.error.message
    if (-not $errorMsg) {
        $errorMsg = $response.error | ConvertTo-Json
    }
    Write-Error "Error: Gemini API returned an error: $errorMsg"
    exit 1
}

# Extract translated text
$translatedText = $response.candidates[0].content.parts[0].text

if ([string]::IsNullOrWhiteSpace($translatedText)) {
    Write-Error "Error: No translation returned from API"
    Write-Error "Response: $($response | ConvertTo-Json -Depth 10)"
    exit 1
}

# Remove markdown code fences if present (LLM sometimes wraps code in ```language blocks)
if (($fileExt -eq "tex") -or ($fileExt -eq "md")) {
    # Remove opening code fence (```language or ```)
    if ($translatedText -match '^```[a-zA-Z]*\r?\n') {
        $translatedText = $translatedText -replace '^```[a-zA-Z]*\r?\n', ''
    }
    # Remove closing code fence (```)
    if ($translatedText -match '\r?\n```$') {
        $translatedText = $translatedText -replace '\r?\n```$', ''
    }
    $translatedText = $translatedText.Trim()
}

# Create output directory if needed
$outputDir = Split-Path -Parent $OutputFile
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# Write translated content to output file
$translatedText | Out-File -FilePath $OutputFile -Encoding utf8 -NoNewline

Write-Host "Translation completed: $OutputFile"

