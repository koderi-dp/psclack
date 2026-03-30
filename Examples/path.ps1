# Demonstrates the path prompt component — run: pwsh .\path.ps1
$modulePath = Join-Path $PSScriptRoot '..\PsClack.psd1'
Import-Module $modulePath -Force

Show-PsClackIntro -Message ' path-demo '

$selected = Read-PsClackPathPrompt `
    -Message 'Select a file or directory' `
    -MaxItems 5 `
    -PassThru

if ($selected.Cancelled) {
    Show-PsClackCancel -Message 'Operation cancelled'
    return
}

$dirResult = Read-PsClackPathPrompt `
    -Message 'Select a directory' `
    -OnlyDirectories `
    -MaxItems 5 `
    -PassThru

if ($dirResult.Cancelled) {
    Show-PsClackCancel -Message 'Operation cancelled'
    return
}

Show-PsClackOutro -Message ('File: {0}  Dir: {1}' -f $selected.Value, $dirResult.Value)
