@{
    RootModule = 'PsClack.psm1'
    ModuleVersion = '0.1.0'
    GUID = '2cf46836-8cf1-4860-960e-2e0a275d4fd1'
    Author = 'koderi-dp'
    CompanyName = 'koderi'
    Copyright = '(c) koderi-dp'
    Description = 'Clack-inspired terminal prompts and UI components for PowerShell 7+.'
    PowerShellVersion = '7.0'
    PrivateData = @{
        PSData = @{
            Tags = @('PowerShell', 'terminal', 'cli', 'prompt', 'ui', 'clack')
            LicenseUri = 'https://github.com/koderi-dp/psclack/blob/main/LICENSE'
            ProjectUri = 'https://github.com/koderi-dp/psclack'
            IconUri = 'https://raw.githubusercontent.com/koderi-dp/psclack/main/icon.svg'
            ReleaseNotes = 'Initial public gallery release.'
        }
    }
    FunctionsToExport = @(
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
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
}
