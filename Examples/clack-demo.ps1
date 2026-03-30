$modulePath = Join-Path $PSScriptRoot '..\PsClack.psd1'
Import-Module $modulePath -Force

function Stop-IfCancelled {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Result
    )

    if ($Result.Cancelled) {
        Show-PsClackCancel -Message 'Operation cancelled'
        return $true
    }

    return $false
}

Show-PsClackIntro -Message 'create-my-app'

$name = Read-PsClackTextPrompt -Message 'What is your name?' -Placeholder 'Anonymous' -PassThru
if (Stop-IfCancelled -Result $name) {
    return
}

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
if (Stop-IfCancelled -Result $password) {
    return
}

$shouldContinue = Read-PsClackConfirmPrompt -Message 'Do you want to continue?' -PassThru
if (Stop-IfCancelled -Result $shouldContinue) {
    return
}

$projectType = Read-PsClackSelectPrompt -Message 'Pick a project type.' -Options @(
    [pscustomobject]@{ Label = 'TypeScript'; Value = 'ts' }
    [pscustomobject]@{ Label = 'JavaScript'; Value = 'js' }
    [pscustomobject]@{ Label = 'CoffeeScript'; Value = 'coffee'; Hint = 'oh no' }
) -PassThru
if (Stop-IfCancelled -Result $projectType) {
    return
}

Show-PsClackNote -Title 'Scaffold plan' -Message ('Project: {0}. Password accepted. Continue: {1}.' -f $projectType.Label, $shouldContinue.Label)
Show-PsClackBox -Title 'Environment' -Message ('Project type: {0}' + [Environment]::NewLine + 'Target runtime: node' + [Environment]::NewLine + 'Package manager: npm') -Rounded
$null = Invoke-PsClackTasks -ContinueTranscript -Tasks @(
    [pscustomobject]@{
        Title = 'Install dependencies'
        Task = {
            Start-Sleep -Milliseconds 600
            'Installed dependencies'
        }
    }
    [pscustomobject]@{
        Title = 'Generate project files'
        Task = {
            Start-Sleep -Milliseconds 600
            'Generated project files'
        }
    }
)

$taskLog = New-PsClackTaskLog -Title 'About taskLog()'
$taskLog.Message('PsClack keeps a live task log that can stay visible on error and clear on success.')
$taskLog.Message('Use it for richer task output than a single spinner line.')
$buildGroup = $taskLog.Group('Build pipeline')
$buildGroup.Message('Restoring packages')
Start-Sleep -Milliseconds 300
$buildGroup.Message('Compiling sources')
Start-Sleep -Milliseconds 300
$buildGroup.Success('Build pipeline ready')
$taskLog.Success('Task log completed')

$progress = New-PsClackProgress -Style Heavy -Max 4 -Size 20 -ContinueTranscript
$progress.Start('Preparing final scaffold')
Start-Sleep -Milliseconds 250
$progress.Advance(1, 'Creating source tree')
Start-Sleep -Milliseconds 250
$progress.Advance(1, 'Writing configuration')
Start-Sleep -Milliseconds 250
$progress.Advance(1, 'Generating package files')
Start-Sleep -Milliseconds 250
$progress.Advance(1, 'Finalizing workspace')
Start-Sleep -Milliseconds 250
$progress.Stop('Scaffold ready')

$null = Invoke-PsClackWithSpinner -Message 'Installing via npm' -SuccessMessage 'Installed via npm' -ContinueTranscript -ScriptBlock {
    Start-Sleep -Seconds 3
}

Show-PsClackOutro -Message "You're all set!"
