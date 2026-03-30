Set-StrictMode -Version Latest

$privateFiles = Get-ChildItem -Path (Join-Path $PSScriptRoot 'Private') -Filter '*.ps1' -File -Recurse | Sort-Object FullName
foreach ($file in $privateFiles) {
    . $file.FullName
}

$publicFiles = Get-ChildItem -Path (Join-Path $PSScriptRoot 'Public') -Filter '*.ps1' -File -Recurse | Sort-Object FullName
foreach ($file in $publicFiles) {
    . $file.FullName
}

$compatibilityAliases = [ordered]@{
    'Invoke-Tasks'             = 'Invoke-PsClackTasks'
    'Invoke-PromptGroup'       = 'Invoke-PsClackPromptGroup'
    'Invoke-WithSpinner'       = 'Invoke-PsClackWithSpinner'
    'New-TaskLog'              = 'New-PsClackTaskLog'
    'New-Progress'             = 'New-PsClackProgress'
    'Read-AutocompleteMultiSelectPrompt' = 'Read-PsClackAutocompleteMultiSelectPrompt'
    'Read-AutocompletePrompt'          = 'Read-PsClackAutocompletePrompt'
    'Read-ConfirmPrompt'       = 'Read-PsClackConfirmPrompt'
    'Read-FileSearchPrompt'    = 'Read-PsClackFileSearchPrompt'
    'Read-PathPrompt'          = 'Read-PsClackPathPrompt'
    'Read-MultiSelectPrompt'   = 'Read-PsClackMultiSelectPrompt'
    'Read-PasswordPrompt'      = 'Read-PsClackPasswordPrompt'
    'Read-SelectPrompt'        = 'Read-PsClackSelectPrompt'
    'Read-TextPrompt'          = 'Read-PsClackTextPrompt'
    'Save-File'                = 'Save-PsClackFile'
    'Show-Cancel'              = 'Show-PsClackCancel'
    'Show-Box'                 = 'Show-PsClackBox'
    'Show-Intro'               = 'Show-PsClackIntro'
    'Show-Note'                = 'Show-PsClackNote'
    'Show-Outro'               = 'Show-PsClackOutro'
    'Start-Spinner'            = 'Start-PsClackSpinner'
    'Stop-Spinner'             = 'Stop-PsClackSpinner'
    'Update-Spinner'           = 'Update-PsClackSpinner'
}
foreach ($aliasName in $compatibilityAliases.Keys) {
    Set-Alias -Name $aliasName -Value $compatibilityAliases[$aliasName] -Scope Script
}

$exportedFunctions = @(
    'Read-PsClackAutocompleteMultiSelectPrompt'
    'Read-PsClackAutocompletePrompt'
    'Invoke-PsClackTasks'
    'Invoke-PsClackWithSpinner'
    'Invoke-PsClackPromptGroup'
    'New-PsClackTaskLog'
    'New-PsClackProgress'
    'Read-PsClackConfirmPrompt'
    'Read-PsClackMultiSelectPrompt'
    'Read-PsClackFileSearchPrompt'
    'Read-PsClackPasswordPrompt'
    'Read-PsClackPathPrompt'
    'Read-PsClackSelectPrompt'
    'Read-PsClackTextPrompt'
    'Save-PsClackFile'
    'Show-PsClackCancel'
    'Show-PsClackBox'
    'Show-PsClackIntro'
    'Show-PsClackNote'
    'Show-PsClackOutro'
    'Start-PsClackSpinner'
    'Stop-PsClackSpinner'
    'Update-PsClackSpinner'
)
if ($exportedFunctions.Count -gt 0) {
    Export-ModuleMember -Function $exportedFunctions
}
