BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestBootstrap.ps1')
}

Describe 'PsClack password rendering' {
    It 'renders masked active password input' {
        $state = @{
            Message = 'Password'
            Placeholder = ''
            Value = 'abc'
            ErrorMessage = $null
            ErrorDisplayValue = $null
            Status = 'Active'
            Mask = '*'
            ClearOnError = $false
        }

        $theme = Get-Theme -Plain
        $lines = Render-PasswordPrompt -State $state -Theme $theme

        $lines | Should -Be @(
            $theme.Symbols.GuideBar
            ('{0}  Password' -f $theme.Symbols.StepActive)
            ('{0}  ***_' -f $theme.Symbols.GuideBar)
            $theme.Symbols.GuideEnd
        )
    }

    It 'renders a masked submitted password value' {
        $state = @{
            Message = 'Password'
            Placeholder = ''
            Value = 'secret'
            ErrorMessage = $null
            ErrorDisplayValue = $null
            Status = 'Submitted'
            Mask = '*'
            ClearOnError = $false
        }

        $theme = Get-Theme -Plain
        $lines = Render-PasswordPrompt -State $state -Theme $theme

        $lines | Should -Be @(
            $theme.Symbols.GuideBar
            ('{0}  Password' -f $theme.Symbols.StepSubmit)
            ('{0}  ******' -f $theme.Symbols.GuideBar)
            $theme.Symbols.GuideBar
        )
    }

    It 'shows validation error text and clears the active value when requested' {
        $state = @{
            Message = 'Password'
            Placeholder = ''
            Value = ''
            ErrorMessage = 'Too short'
            ErrorDisplayValue = '***'
            Status = 'Active'
            Mask = '*'
            ClearOnError = $true
        }

        $theme = Get-Theme -Plain
        $lines = Render-PasswordPrompt -State $state -Theme $theme

        $lines | Should -Be @(
            $theme.Symbols.GuideBar
            ('{0}  Password' -f $theme.Symbols.StepActive)
            ('{0}  ***_' -f $theme.Symbols.GuideBar)
            ('{0}  Too short' -f $theme.Symbols.GuideEnd)
        )
    }
}
