$modulePath = Join-Path $PSScriptRoot '..\PsClack.psd1'
Import-Module $modulePath -Force

Show-PsClackIntro -Message 'PsClack Wrapped Prompts'

$name = Read-PsClackTextPrompt `
    -Message 'What is the long-form internal project name you want to use for this generated sample application?' `
    -Placeholder 'my-super-long-project-name' `
    -Validate {
        param($value)
        if ([string]::IsNullOrWhiteSpace($value)) {
            'A project name is required.'
        }
    }

$continue = Read-PsClackConfirmPrompt `
    -Message 'Do you want to continue with the generated sample configuration and keep the defaults for the remaining setup steps?' `
    -InitialValue $true

$template = Read-PsClackSelectPrompt `
    -Message 'Choose a project template with a longer description so the option wrapping and continuation alignment are easy to inspect' `
    -Options @(
        [pscustomobject]@{ Label = 'Web application starter kit with frontend assets'; Value = 'web'; Hint = 'recommended for browser projects' }
        [pscustomobject]@{ Label = 'REST API service template with diagnostics'; Value = 'api'; Hint = 'good for backend services' }
        [pscustomobject]@{ Label = 'Background worker with scheduled tasks'; Value = 'worker'; Hint = 'best for automation jobs' }
    ) `
    -InitialValue 'api' `
    -MaxItems 7

Show-PsClackOutro -Message ("Wrapped prompt demo complete for {0} using template {1}." -f $name, $template)
