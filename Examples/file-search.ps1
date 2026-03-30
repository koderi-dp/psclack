# Demonstrates the file search prompt component
# Usage: pwsh .\file-search.ps1 [-Root <path>] [-Filter <pattern>]
param(
    [string]$Root   = (Join-Path $PSScriptRoot '..'),
    [string]$Filter = '*.ps1'
)

$modulePath = Join-Path $PSScriptRoot '..\PsClack.psd1'
Import-Module $modulePath -Force

Show-PsClackIntro -Message ' file-search-demo '

# Search all PowerShell files under the PsClack root
$file = Read-PsClackFileSearchPrompt `
    -Message ('Search {0} files under {1}' -f $Filter, $Root) `
    -Root $Root `
    -Filter $Filter `
    -MaxItems 10 `
    -PassThru

if ($file.Cancelled) {
    Show-PsClackCancel -Message 'Operation cancelled'
    return
}

Show-PsClackOutro -Message ('Selected: {0}' -f $file.Value)
