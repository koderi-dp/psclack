$modulePath = Join-Path $PSScriptRoot '..\PsClack.psd1'
Import-Module $modulePath -Force

Show-PsClackIntro -Message 'PsClack Non-Interactive Example' -PassThru | Out-Null

$result = Invoke-PsClackPromptGroup {
    $name = Read-PsClackTextPrompt -Message 'Project name' -NonInteractiveValue 'demo-app'
    $template = Read-PsClackSelectPrompt -Message 'Template' -Options @(
        [pscustomobject]@{ Label = 'web'; Value = 'web' }
        [pscustomobject]@{ Label = 'api'; Value = 'api' }
    ) -NonInteractiveValue 'api'
    $features = Read-PsClackMultiSelectPrompt -Message 'Features' -Options @(
        [pscustomobject]@{ Label = 'TypeScript'; Value = 'ts' }
        [pscustomobject]@{ Label = 'Pester'; Value = 'pester' }
    ) -NonInteractiveValues @('ts', 'pester')
    $install = Read-PsClackConfirmPrompt -Message 'Install?' -NonInteractiveValue $true

    [pscustomobject]@{
        Name = $name
        Template = $template
        Features = $features
        Install = $install
    }
}

Show-PsClackOutro -Message 'Headless configuration resolved' -PassThru | Out-Null
$result
