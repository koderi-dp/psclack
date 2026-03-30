Import-Module (Join-Path $PSScriptRoot '..\PsClack.psd1') -Force

Show-PsClackIntro -Message 'PsClack Password Prompt'

$password = Read-PsClackPasswordPrompt `
    -Message 'Enter a password' `
    -Placeholder 'Minimum 8 characters' `
    -Validate {
        param($value)

        if ([string]::IsNullOrWhiteSpace($value)) {
            return 'Password is required.'
        }

        if ($value.Length -lt 8) {
            return 'Password must be at least 8 characters long.'
        }
    } `
    -ClearOnError `
    -PassThru

if ($password.Status -eq 'Cancelled') {
    Show-PsClackCancel -Message 'Password entry cancelled.'
    return
}

Show-PsClackOutro -Message ('Accepted password with length {0}.' -f $password.Value.Length)
