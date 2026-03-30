$modulePath = Join-Path $PSScriptRoot '..\PsClack.psd1'
Import-Module $modulePath -Force

$options = 1..18 | ForEach-Object {
    [pscustomobject]@{
        Label = 'Feature pack {0}' -f $_
        Value = 'feature-{0}' -f $_
    }
}

$result = Read-PsClackMultiSelectPrompt `
    -Message 'Select feature packs from a longer list to inspect the multiselect viewport behavior' `
    -Options $options `
    -InitialValues @('feature-4', 'feature-9') `
    -MaxItems 7 `
    -Validate {
        param($values)
        if (@($values).Count -eq 0) {
            'Select at least one feature pack.'
        }
    }

Show-PsClackOutro -Message ("Selected feature packs: {0}" -f (@($result) -join ', '))
