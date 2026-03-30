param(
    [string]$ApiKey,
    [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$moduleManifestPath = Join-Path $PSScriptRoot 'PsClack.psd1'

if (-not (Test-Path -LiteralPath $moduleManifestPath)) {
    throw "Module manifest not found: $moduleManifestPath"
}

$resolvedApiKey = $ApiKey
if ([string]::IsNullOrWhiteSpace($resolvedApiKey)) {
    $resolvedApiKey = $env:PSGALLERY_API_KEY
}

if ([string]::IsNullOrWhiteSpace($resolvedApiKey)) {
    throw 'No API key provided. Pass -ApiKey or set PSGALLERY_API_KEY.'
}

Write-Host 'Validating module manifest...' -ForegroundColor Cyan
Test-ModuleManifest -Path $moduleManifestPath | Out-Null

$publishParams = @{
    Path = $PSScriptRoot
    NuGetApiKey = $resolvedApiKey
    Verbose = $true
}

if ($WhatIf) {
    $publishParams.WhatIf = $true
}

Write-Host 'Publishing module...' -ForegroundColor Cyan
Publish-Module @publishParams
