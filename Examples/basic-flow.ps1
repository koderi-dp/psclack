$modulePath = Join-Path $PSScriptRoot '..\PsClack.psd1'
Import-Module $modulePath -Force

Show-PsClackIntro -Message 'PsClack Basic Flow'

$name = Read-PsClackTextPrompt -Message 'Project name' -Placeholder 'my-app' -Validate {
    param($value)
    if ([string]::IsNullOrWhiteSpace($value)) {
        'Project name is required.'
    }
}

$template = Read-PsClackSelectPrompt -Message 'Template' -Options @(
    [pscustomobject]@{ Label = 'web'; Value = 'web' }
    [pscustomobject]@{ Label = 'api'; Value = 'api' }
    [pscustomobject]@{ Label = 'worker'; Value = 'worker' }
)

$install = Read-PsClackConfirmPrompt -Message 'Install dependencies?' -InitialValue $true

$result = [pscustomobject]@{
    Name = $name
    Template = $template
    Install = $install
}

Show-PsClackOutro -Message ("Created config for {0} ({1})" -f $result.Name, $result.Template)
$result
