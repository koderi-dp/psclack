$modulePath = Join-Path $PSScriptRoot '..\PsClack.psd1'
Import-Module $modulePath -Force

Show-PsClackIntro -Message 'PsClack Error State'

$name = Read-PsClackTextPrompt `
    -Message 'Enter a deployment name that must be at least 6 characters long' `
    -Placeholder 'sample-app' `
    -Validate {
        param($value)
        if ([string]::IsNullOrWhiteSpace($value)) {
            'A deployment name is required.'
        }
        elseif ($value.Length -lt 6) {
            'Use at least 6 characters.'
        }
    }

$features = Read-PsClackMultiSelectPrompt `
    -Message 'Select at least two features to continue with the generated configuration' `
    -Options @(
        [pscustomobject]@{ Label = 'TypeScript'; Value = 'ts' }
        [pscustomobject]@{ Label = 'ESLint'; Value = 'eslint' }
        [pscustomobject]@{ Label = 'Docker'; Value = 'docker' }
        [pscustomobject]@{ Label = 'Pester'; Value = 'pester' }
    ) `
    -Validate {
        param($values)
        if (@($values).Count -lt 2) {
            'Select at least two features.'
        }
    }

Show-PsClackOutro -Message ("Validated deployment {0} with features: {1}" -f $name, (@($features) -join ', '))
