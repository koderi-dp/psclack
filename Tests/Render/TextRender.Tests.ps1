BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestBootstrap.ps1')
}

Describe 'PsClack text rendering' {
    It 'renders clack-like guide lines for active text input' {
        $state = @{
            Message = 'Project name'
            Placeholder = 'my-app'
            Value = ''
            ErrorMessage = $null
            Status = 'Active'
        }

        $theme = Get-Theme -Plain
        $lines = Render-TextPrompt -State $state -Theme $theme

        $lines[0] | Should -Be $theme.Symbols.GuideBar
        $lines[1] | Should -Be ('{0}  Project name' -f $theme.Symbols.StepActive)
        $lines[2] | Should -Be ('{0}  my-app_' -f $theme.Symbols.GuideBar)
        $lines[3] | Should -Be $theme.Symbols.GuideEnd
    }

    It 'wraps long messages and values to terminal width' {
        Mock Get-TerminalWidth { 20 }

        $state = @{
            Message = 'A very long prompt message'
            Placeholder = ''
            Value = 'wrapped value text'
            ErrorMessage = $null
            Status = 'Submitted'
        }

        $theme = Get-Theme -Plain
        $lines = Render-TextPrompt -State $state -Theme $theme

        $lines | Should -Be @(
            $theme.Symbols.GuideBar
            ('{0}  A very long' -f $theme.Symbols.StepSubmit)
            ('{0}  prompt message' -f $theme.Symbols.GuideBar)
            ('{0}  wrapped value' -f $theme.Symbols.GuideBar)
            ('{0}  text' -f $theme.Symbols.GuideBar)
            $theme.Symbols.GuideBar
        )
    }

    It 'renders a single-word submitted value without scalar wrap errors' {
        $state = @{
            Message = 'What is your name?'
            Placeholder = ''
            Value = 'dsa'
            ErrorMessage = $null
            Status = 'Submitted'
        }

        $theme = Get-Theme -Plain
        $lines = Render-TextPrompt -State $state -Theme $theme

        $lines | Should -Be @(
            $theme.Symbols.GuideBar
            ('{0}  What is your name?' -f $theme.Symbols.StepSubmit)
            ('{0}  dsa' -f $theme.Symbols.GuideBar)
            $theme.Symbols.GuideBar
        )
    }
}
