param(
    [string]$ApiKey,
    [switch]$WhatIf,
    [switch]$Bundle,
    [switch]$KeepStaging
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$moduleManifestPath = Join-Path $PSScriptRoot 'PsClack.psd1'
$moduleEntryPath = Join-Path $PSScriptRoot 'PsClack.psm1'
$stageRoot = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
$stageModulePath = Join-Path $stageRoot 'PsClack'

if (-not (Test-Path -LiteralPath $moduleManifestPath)) {
    throw "Module manifest not found: $moduleManifestPath"
}

if (-not (Test-Path -LiteralPath $moduleEntryPath)) {
    throw "Module entry point not found: $moduleEntryPath"
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

Write-Host 'Preparing staged publish layout...' -ForegroundColor Cyan
New-Item -ItemType Directory -Path $stageModulePath -Force | Out-Null

$pathsToCopy = @('PsClack.psd1', 'LICENSE', 'README.md')
if ($Bundle) {
    $pathsToCopy += 'icon.svg'
}
else {
    $pathsToCopy += @('PsClack.psm1', 'Public', 'Private')
}

foreach ($relativePath in $pathsToCopy) {
    $sourcePath = Join-Path $PSScriptRoot $relativePath
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "Required publish path not found: $sourcePath"
    }

    Copy-Item -LiteralPath $sourcePath -Destination $stageModulePath -Recurse -Force
}

if ($Bundle) {
    Write-Host 'Bundling module sources into a single publish-time PSM1...' -ForegroundColor Cyan

    $privateFiles = Get-ChildItem -Path (Join-Path $PSScriptRoot 'Private') -Filter '*.ps1' -File -Recurse | Sort-Object FullName
    $publicFiles = Get-ChildItem -Path (Join-Path $PSScriptRoot 'Public') -Filter '*.ps1' -File -Recurse | Sort-Object FullName
    $moduleSource = Get-Content -LiteralPath $moduleEntryPath -Raw

    $bundleParts = [System.Collections.Generic.List[string]]::new()
    $bundleParts.Add("Set-StrictMode -Version Latest")

    foreach ($file in $privateFiles) {
        $bundleParts.Add("")
        $bundleParts.Add("# Source: Private/$($file.FullName.Substring((Join-Path $PSScriptRoot 'Private').Length + 1).Replace('\', '/'))")
        $bundleParts.Add((Get-Content -LiteralPath $file.FullName -Raw).TrimEnd())
    }

    foreach ($file in $publicFiles) {
        $bundleParts.Add("")
        $bundleParts.Add("# Source: Public/$($file.FullName.Substring((Join-Path $PSScriptRoot 'Public').Length + 1).Replace('\', '/'))")
        $bundleParts.Add((Get-Content -LiteralPath $file.FullName -Raw).TrimEnd())
    }

    $aliasStart = $moduleSource.IndexOf('$compatibilityAliases')
    if ($aliasStart -lt 0) {
        throw 'Could not locate compatibility alias block in PsClack.psm1.'
    }

    $bundleParts.Add("")
    $bundleParts.Add($moduleSource.Substring($aliasStart).Trim())

    $bundledModulePath = Join-Path $stageModulePath 'PsClack.psm1'
    Set-Content -LiteralPath $bundledModulePath -Value ($bundleParts -join [Environment]::NewLine) -Encoding UTF8
}

Write-Host ("Staging path: {0}" -f $stageModulePath) -ForegroundColor DarkGray

$publishParams = @{
    Path = $stageModulePath
    NuGetApiKey = $resolvedApiKey
    Verbose = $true
}

if ($WhatIf) {
    $publishParams.WhatIf = $true
}

try {
    Write-Host 'Publishing module...' -ForegroundColor Cyan
    Publish-Module @publishParams
}
finally {
    if ((-not $KeepStaging) -and (Test-Path -LiteralPath $stageRoot)) {
        Remove-Item -LiteralPath $stageRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
