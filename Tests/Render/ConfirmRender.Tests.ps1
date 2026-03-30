BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestBootstrap.ps1')
}

Describe 'PsClack confirm rendering' {
    It 'renders yes and no choices on one line with guide lines' {
        $state = @{
            Message = 'Continue?'
            CurrentChoice = $true
            Status = 'Active'
            Value = $null
            SelectedLabel = $null
        }

        $theme = Get-Theme -Plain
        $lines = Render-ConfirmPrompt -State $state -Theme $theme

        $lines[0] | Should -Be $theme.Symbols.GuideBar
        $lines[1] | Should -Be ('{0}  Continue?' -f $theme.Symbols.StepActive)
        $lines[2] | Should -Be ('{0}  {1} Yes / {2} No' -f $theme.Symbols.GuideBar, $theme.Symbols.RadioActive, $theme.Symbols.RadioInactive)
        $lines[3] | Should -Be $theme.Symbols.GuideEnd
    }

    It 'wraps long confirm messages with guide continuation' {
        Mock Get-TerminalWidth { 24 }

        $state = @{
            Message = 'Do you want to continue with a longer prompt?'
            CurrentChoice = $true
            Status = 'Submitted'
            Value = $true
            SelectedLabel = 'Yes'
        }

        $theme = Get-Theme -Plain
        $lines = Render-ConfirmPrompt -State $state -Theme $theme

        $lines | Should -Be @(
            $theme.Symbols.GuideBar
            ('{0}  Do you want to' -f $theme.Symbols.StepSubmit)
            ('{0}  continue with a' -f $theme.Symbols.GuideBar)
            ('{0}  longer prompt?' -f $theme.Symbols.GuideBar)
            ('{0}  Yes' -f $theme.Symbols.GuideBar)
            $theme.Symbols.GuideBar
        )
    }
}
