$modulePath = Join-Path $PSScriptRoot '..\PsClack.psd1'
Import-Module $modulePath -Force

$result = Read-PsClackMultiSelectPrompt -Message 'Select features' -Options @(
    [pscustomobject]@{ Label = 'TypeScript'; Value = 'ts' }
    [pscustomobject]@{ Label = 'ESLint'; Value = 'eslint' }
    [pscustomobject]@{ Label = 'Pester'; Value = 'pester' }
    [pscustomobject]@{ Label = 'Docker'; Value = 'docker' }
) -Validate {
    param($values)
    if (@($values).Count -eq 0) {
        'Select at least one feature.'
    }
}

Show-PsClackOutro -Message ("Selected: {0}" -f (@($result) -join ', '))
