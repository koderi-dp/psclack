BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestBootstrap.ps1')
}

Describe 'PsClack select rendering' {
    It 'renders active option with inactive bullets and hints' {
        $state = @{
            Message = 'Choose one'
            Options = @(
                [pscustomobject]@{ Label = 'React'; Value = 'react'; Hint = '' }
                [pscustomobject]@{ Label = 'Vue'; Value = 'vue'; Hint = 'popular' }
            )
            ActiveIndex = 0
            Status = 'Active'
            Value = $null
            SelectedLabel = $null
        }

        $theme = Get-Theme -Plain
        $lines = Render-SelectPrompt -State $state -Theme $theme

        $lines[0] | Should -Be $theme.Symbols.GuideBar
        $lines[1] | Should -Be ('{0}  Choose one' -f $theme.Symbols.StepActive)
        $lines[2] | Should -Be ('{0}  {1} React' -f $theme.Symbols.GuideBar, $theme.Symbols.RadioActive)
        $lines[3] | Should -Be ('{0}  {1} Vue (popular)' -f $theme.Symbols.GuideBar, $theme.Symbols.RadioInactive)
        $lines[4] | Should -Be $theme.Symbols.GuideEnd
    }

    It 'wraps long option labels and hints to terminal width' {
        Mock Get-TerminalWidth { 26 }

        $state = @{
            Message = 'Choose one'
            Options = @(
                [pscustomobject]@{ Label = 'Very long option name'; Value = 'one'; Hint = 'with extra hint' }
            )
            ActiveIndex = 0
            Status = 'Active'
            Value = $null
            SelectedLabel = $null
        }

        $theme = Get-Theme -Plain
        $lines = Render-SelectPrompt -State $state -Theme $theme

        $lines | Should -Be @(
            $theme.Symbols.GuideBar
            ('{0}  Choose one' -f $theme.Symbols.StepActive)
            ('{0}  {1} Very long option name' -f $theme.Symbols.GuideBar, $theme.Symbols.RadioActive)
            ('{0}    (with extra hint)' -f $theme.Symbols.GuideBar)
            $theme.Symbols.GuideEnd
        )
    }

    It 'limits the visible option window and shows overflow markers' {
        Mock Get-TerminalHeight { 9 }

        $state = @{
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

        $theme = Get-Theme -Plain
        $lines = Render-SelectPrompt -State $state -Theme $theme

        $lines | Should -Be @(
            $theme.Symbols.GuideBar
            ('{0}  Choose one' -f $theme.Symbols.StepActive)
            ('{0}  ...' -f $theme.Symbols.GuideBar)
            ('{0}  {1} Four' -f $theme.Symbols.GuideBar, $theme.Symbols.RadioInactive)
            ('{0}  {1} Five' -f $theme.Symbols.GuideBar, $theme.Symbols.RadioInactive)
            ('{0}  {1} Six' -f $theme.Symbols.GuideBar, $theme.Symbols.RadioActive)
            ('{0}  {1} Seven' -f $theme.Symbols.GuideBar, $theme.Symbols.RadioInactive)
            ('{0}  {1} Eight' -f $theme.Symbols.GuideBar, $theme.Symbols.RadioInactive)
            $theme.Symbols.GuideEnd
        )
    }
}
