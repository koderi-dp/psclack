$modulePath = Join-Path $PSScriptRoot '..\PsClack.psd1'
Import-Module $modulePath -Force

Show-PsClackIntro -Message 'PsClack Prompt Group'

$result = Invoke-PsClackPromptGroup {
    $name = Read-PsClackTextPrompt -Message 'Service name' -Placeholder 'studio-api'
    $kind = Read-PsClackSelectPrompt -Message 'Service kind' -Options @(
        [pscustomobject]@{ Label = 'api'; Value = 'api' }
        [pscustomobject]@{ Label = 'worker'; Value = 'worker' }
    )
    $ports = Read-PsClackMultiSelectPrompt -Message 'Expose ports' -Options @(
        [pscustomobject]@{ Label = 'HTTP'; Value = 'http' }
        [pscustomobject]@{ Label = 'HTTPS'; Value = 'https' }
        [pscustomobject]@{ Label = 'Metrics'; Value = 'metrics' }
    )

    [pscustomobject]@{
        Name = $name
        Kind = $kind
        Ports = $ports
    }
}

Show-PsClackOutro -Message 'Prompt group completed'
$result
