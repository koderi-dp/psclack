$modulePath = Join-Path $PSScriptRoot '..\PsClack.psd1'
Import-Module $modulePath -Force

Show-PsClackIntro -Message 'PsClack Tasks'

$results = Invoke-PsClackTasks -ContinueTranscript -PassThru -Tasks @(
    [pscustomobject]@{
        Title = 'Install dependencies'
        Task = {
            Start-Sleep -Seconds 1
            'Installed dependencies'
        }
    }
    [pscustomobject]@{
        Title = 'Generate project files'
        Task = {
            Start-Sleep -Seconds 1
            'Generated project files'
        }
    }
    [pscustomobject]@{
        Title = 'Compile assets'
        Task = {
            Start-Sleep -Seconds 1
            'Compiled frontend assets'
        }
    }
    [pscustomobject]@{
        Title = 'Run test suite'
        Task = {
            Start-Sleep -Seconds 1
            'Test suite passed'
        }
    }
    [pscustomobject]@{
        Title = 'Create release bundle'
        Task = {
            Start-Sleep -Seconds 1
            'Created release bundle'
        }
    }
    [pscustomobject]@{
        Title = 'Publish docs'
        Enabled = $false
        Task = {
            Start-Sleep -Milliseconds 200
            'Published docs'
        }
    }
)

$completed = @($results | Where-Object { -not $_.Skipped }).Count
Show-PsClackOutro -Message ("Completed {0} tasks." -f $completed)
