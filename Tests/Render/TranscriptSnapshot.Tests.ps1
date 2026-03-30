BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestBootstrap.ps1')
}

Describe 'PsClack transcript snapshots' {
    It 'matches the plain clack-demo transcript baseline' {
        $theme = Get-Theme -Plain

        $frames = [System.Collections.Generic.List[string]]::new()
        $pendingLeadingGuide = $false

        foreach ($line in (Show-PsClackIntro -Message 'create-my-app' -Plain -PassThru)) {
            $frames.Add([string]$line)
        }

        foreach ($line in (Render-TextPrompt -Theme $theme -State @{
                Message = 'What is your name?'
                Placeholder = 'Anonymous'
                Value = 'typing my name'
                ErrorMessage = $null
                Status = 'Submitted'
                SuppressLeadingGuide = $pendingLeadingGuide
            })) {
            $frames.Add([string]$line)
        }
        $pendingLeadingGuide = $true

        foreach ($line in (Render-PasswordPrompt -Theme $theme -State @{
                Message = 'Enter a password'
                Placeholder = 'Minimum 8 characters'
                Value = 'super-secret'
                ErrorMessage = $null
                ErrorDisplayValue = $null
                Status = 'Submitted'
                Mask = [string]$theme.Symbols.PasswordMask
                ClearOnError = $true
                SuppressLeadingGuide = $pendingLeadingGuide
            })) {
            $frames.Add([string]$line)
        }
        $pendingLeadingGuide = $true

        foreach ($line in (Render-ConfirmPrompt -Theme $theme -State @{
                Message = 'Do you want to continue?'
                CurrentChoice = $true
                Status = 'Submitted'
                Value = $true
                SelectedLabel = 'Yes'
                SuppressLeadingGuide = $pendingLeadingGuide
            })) {
            $frames.Add([string]$line)
        }
        $pendingLeadingGuide = $true

        foreach ($line in (Render-SelectPrompt -Theme $theme -State @{
                Message = 'Pick a project type.'
                Options = @(
                    [pscustomobject]@{ Label = 'TypeScript'; Value = 'ts'; Hint = '' }
                    [pscustomobject]@{ Label = 'JavaScript'; Value = 'js'; Hint = '' }
                    [pscustomobject]@{ Label = 'CoffeeScript'; Value = 'coffee'; Hint = 'oh no' }
                )
                ActiveIndex = 1
                Status = 'Submitted'
                Value = 'js'
                SelectedLabel = 'JavaScript'
                SuppressLeadingGuide = $pendingLeadingGuide
            })) {
            $frames.Add([string]$line)
        }
        $pendingLeadingGuide = $true

        Set-PsClackLeadingGuide -Pending $pendingLeadingGuide
        foreach ($line in (Show-PsClackNote -Title 'Scaffold plan' -Message 'Project: JavaScript. Password accepted. Continue: Yes.' -Plain -PassThru)) {
            $frames.Add([string]$line)
        }

        Set-PsClackLeadingGuide -Pending $false
        foreach ($line in (Show-PsClackBox -Title 'Environment' -Message ('Project type: JavaScript' + [Environment]::NewLine + 'Target runtime: node' + [Environment]::NewLine + 'Package manager: npm') -Rounded -Plain -PassThru)) {
            $frames.Add([string]$line)
        }

        foreach ($line in (Render-Spinner -Theme $theme -Spinner ([pscustomobject]@{
                    Status = 'Success'
                    Frames = @('◒')
                    FrameIndex = 0
                    Message = 'Installing via npm'
                    FinalMessage = 'Installed via npm'
                    ContinueTranscript = $true
                    SuppressLeadingGuide = $false
                }))) {
            $frames.Add([string]$line)
        }

        Set-PsClackLeadingGuide -Pending $false
        foreach ($line in (Show-PsClackOutro -Message "You're all set!" -Plain -PassThru)) {
            $frames.Add([string]$line)
        }

        @($frames) | Should -Be @(
            '┌   create-my-app '
            '│'
            '○  What is your name?'
            '│  typing my name'
            '│'
            '○  Enter a password'
            '│  ▪▪▪▪▪▪▪▪▪▪▪▪'
            '│'
            '○  Do you want to continue?'
            '│  Yes'
            '│'
            '○  Pick a project type.'
            '│  JavaScript'
            '│'
            '○  Scaffold plan ──────────────────────────────────────────╮'
            '│                                                          │'
            '│  Project: JavaScript. Password accepted. Continue: Yes.  │'
            '│                                                          │'
            '├──────────────────────────────────────────────────────────╯'
            '│'
            '│ ╭─Environment────────────────╮'
            '│ │  Project type: JavaScript  │'
            '│ │  Target runtime: node      │'
            '│ │  Package manager: npm      │'
            '│ ╰────────────────────────────╯'
            '│'
            '○  Installed via npm'
            '│'
            '└  You''re all set!'
        )
    }

    It 'matches a wrapped prompt and spinner transcript baseline' {
        Mock Get-TerminalWidth { 24 }

        $theme = Get-Theme -Plain
        $frames = [System.Collections.Generic.List[string]]::new()
        $pendingLeadingGuide = $false

        foreach ($line in (Show-PsClackIntro -Message 'wrapped-demo' -Plain -PassThru)) {
            $frames.Add([string]$line)
        }

        foreach ($line in (Render-TextPrompt -Theme $theme -State @{
                Message = 'What is the internal project name for this generated sample?'
                Placeholder = ''
                Value = 'sample-app'
                ErrorMessage = $null
                Status = 'Submitted'
                SuppressLeadingGuide = $pendingLeadingGuide
            })) {
            $frames.Add([string]$line)
        }
        $pendingLeadingGuide = $true

        foreach ($line in (Render-ConfirmPrompt -Theme $theme -State @{
                Message = 'Do you want to continue with the generated configuration?'
                CurrentChoice = $true
                Status = 'Submitted'
                Value = $true
                SelectedLabel = 'Yes'
                SuppressLeadingGuide = $pendingLeadingGuide
            })) {
            $frames.Add([string]$line)
        }
        $pendingLeadingGuide = $true

        foreach ($line in (Render-Spinner -Theme $theme -Spinner ([pscustomobject]@{
                    Status = 'Success'
                    Frames = @('◒')
                    FrameIndex = 0
                    Message = 'Installing'
                    FinalMessage = 'Installed via npm for a very long package'
                    ContinueTranscript = $true
                    SuppressLeadingGuide = $pendingLeadingGuide
                }))) {
            $frames.Add([string]$line)
        }

        Set-PsClackLeadingGuide -Pending $false
        foreach ($line in (Show-PsClackOutro -Message 'Wrapped transcript complete with additional detail for inspection.' -Plain -PassThru)) {
            $frames.Add([string]$line)
        }

        @($frames) | Should -Be @(
            '┌   wrapped-demo '
            '│'
            '○  What is the internal'
            '│  project name for this'
            '│  generated sample?'
            '│  sample-app'
            '│'
            '○  Do you want to'
            '│  continue with the'
            '│  generated'
            '│  configuration?'
            '│  Yes'
            '│'
            '○  Installed via npm for'
            '│  a very long package'
            '│'
            '└  Wrapped transcript'
            '│  complete with'
            '│  additional detail for'
            '│  inspection.'
        )
    }

    It 'matches a viewported select transcript baseline' {
        Mock Get-TerminalHeight { 9 }

        $theme = Get-Theme -Plain
        $lines = Render-SelectPrompt -Theme $theme -State @{
            Message = 'Choose one'
            Options = @(
                [pscustomobject]@{ Label = 'One'; Value = 1; Hint = '' }
                [pscustomobject]@{ Label = 'Two'; Value = 2; Hint = '' }
                [pscustomobject]@{ Label = 'Three'; Value = 3; Hint = '' }
                [pscustomobject]@{ Label = 'Four'; Value = 4; Hint = '' }
                [pscustomobject]@{ Label = 'Five'; Value = 5; Hint = '' }
                [pscustomobject]@{ Label = 'Six'; Value = 6; Hint = '' }
                [pscustomobject]@{ Label = 'Seven'; Value = 7; Hint = '' }
                [pscustomobject]@{ Label = 'Eight'; Value = 8; Hint = '' }
            )
            ActiveIndex = 5
            Status = 'Active'
            Value = $null
            SelectedLabel = $null
            MaxItems = [int]::MaxValue
        }

        @($lines) | Should -Be @(
            '│'
            '●  Choose one'
            '│  ...'
            '│  ○ Four'
            '│  ○ Five'
            '│  ● Six'
            '│  ○ Seven'
            '│  ○ Eight'
            '└'
        )
    }

    It 'matches a submitted multiselect transcript baseline' {
        $theme = Get-Theme -Plain
        $lines = Render-MultiSelectPrompt -Theme $theme -State @{
            Message = 'Pick features for the sample'
            Options = @(
                [pscustomobject]@{ Label = 'TypeScript'; Value = 'ts'; Selected = $true }
                [pscustomobject]@{ Label = 'ESLint'; Value = 'eslint'; Selected = $true }
                [pscustomobject]@{ Label = 'Docker'; Value = 'docker'; Selected = $false }
            )
            ActiveIndex = 0
            ErrorMessage = $null
            Status = 'Submitted'
            Value = @('ts', 'eslint')
            SelectedLabel = 'TypeScript, ESLint'
            MaxItems = [int]::MaxValue
        }

        @($lines) | Should -Be @(
            '│'
            '○  Pick features for the sample'
            '│  TypeScript, ESLint'
            '│'
        )
    }
}
