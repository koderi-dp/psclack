$modulePath = Join-Path $PSScriptRoot '..\PsClack.psd1'
Import-Module $modulePath -Force

$options = 1..20 | ForEach-Object {
    [pscustomobject]@{
        Label = 'Project template {0}' -f $_
        Value = 'template-{0}' -f $_
        Hint = if ($_ % 5 -eq 0) { 'recommended' } else { '' }
    }
}

$result = Read-PsClackSelectPrompt `
    -Message 'Choose a project template from a longer list' `
    -Options $options `
    -InitialValue 'template-10' `
    -MaxItems 7

Show-PsClackOutro -Message ("Selected template: {0}" -f $result)
