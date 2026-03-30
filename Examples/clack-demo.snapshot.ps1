. (Join-Path $PSScriptRoot '..\Tests\TestBootstrap.ps1')

$theme = Get-Theme -Plain

function Show-FrameSnapshot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [string[]]$Lines
    )

    Write-Host ("=== {0} ===" -f $Title)
    foreach ($line in $Lines) {
        Write-Host $line
    }
    Write-Host ''
}

Show-FrameSnapshot -Title 'Intro' -Lines (Show-PsClackIntro -Message 'create-my-app' -Plain -PassThru)

Show-FrameSnapshot -Title 'Text.Active' -Lines (Render-TextPrompt -Theme $theme -State @{
    Message = 'What is your name?'
    Placeholder = 'Anonymous'
    Value = 'typing my name'
    ErrorMessage = $null
    Status = 'Active'
})

Show-FrameSnapshot -Title 'Text.Submitted' -Lines (Render-TextPrompt -Theme $theme -State @{
    Message = 'What is your name?'
    Placeholder = 'Anonymous'
    Value = 'typing my name'
    ErrorMessage = $null
    Status = 'Submitted'
})

Show-FrameSnapshot -Title 'Password.Submitted' -Lines (Render-PasswordPrompt -Theme $theme -State @{
    Message = 'Enter a password'
    Placeholder = 'Minimum 8 characters'
    Value = 'super-secret'
    ErrorMessage = $null
    ErrorDisplayValue = $null
    Status = 'Submitted'
    Mask = [string]$theme.Symbols.PasswordMask
    ClearOnError = $true
})

Show-FrameSnapshot -Title 'Confirm.Active' -Lines (Render-ConfirmPrompt -Theme $theme -State @{
    Message = 'Do you want to continue?'
    CurrentChoice = $true
    Status = 'Active'
    Value = $null
    SelectedLabel = $null
})

Show-FrameSnapshot -Title 'Confirm.Submitted' -Lines (Render-ConfirmPrompt -Theme $theme -State @{
    Message = 'Do you want to continue?'
    CurrentChoice = $true
    Status = 'Submitted'
    Value = $true
    SelectedLabel = 'Yes'
})

Show-FrameSnapshot -Title 'Select.Active' -Lines (Render-SelectPrompt -Theme $theme -State @{
    Message = 'Pick a project type.'
    Options = @(
        [pscustomobject]@{ Label = 'TypeScript'; Value = 'ts'; Hint = '' }
        [pscustomobject]@{ Label = 'JavaScript'; Value = 'js'; Hint = '' }
        [pscustomobject]@{ Label = 'CoffeeScript'; Value = 'coffee'; Hint = 'oh no' }
    )
    ActiveIndex = 0
    Status = 'Active'
    Value = $null
    SelectedLabel = $null
})

Show-FrameSnapshot -Title 'Select.Submitted' -Lines (Render-SelectPrompt -Theme $theme -State @{
    Message = 'Pick a project type.'
    Options = @(
        [pscustomobject]@{ Label = 'TypeScript'; Value = 'ts'; Hint = '' }
        [pscustomobject]@{ Label = 'JavaScript'; Value = 'js'; Hint = '' }
        [pscustomobject]@{ Label = 'CoffeeScript'; Value = 'coffee'; Hint = 'oh no' }
    )
    ActiveIndex = 0
    Status = 'Submitted'
    Value = 'ts'
    SelectedLabel = 'TypeScript'
})

Show-FrameSnapshot -Title 'Note' -Lines (Show-PsClackNote -Title 'Scaffold plan' -Message 'Project: TypeScript. Password accepted. Continue: Yes.' -Plain -PassThru)

Show-FrameSnapshot -Title 'Box' -Lines (Show-PsClackBox -Title 'Environment' -Message ('Project type: TypeScript' + [Environment]::NewLine + 'Target runtime: node' + [Environment]::NewLine + 'Package manager: npm') -Rounded -Plain -PassThru)

Show-FrameSnapshot -Title 'Spinner.Success' -Lines (Render-Spinner -Theme $theme -Spinner ([pscustomobject]@{
    Status = 'Success'
    Frames = @('-')
    FrameIndex = 0
    Message = 'Installing via npm'
    FinalMessage = 'Installed via npm'
}))

Show-FrameSnapshot -Title 'Outro' -Lines (Show-PsClackOutro -Message "You're all set!" -Plain -PassThru)

