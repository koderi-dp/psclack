BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestBootstrap.ps1')
}

Describe 'PsClack spinner rendering' {
    It 'renders a running spinner frame' {
        $spinner = [pscustomobject]@{
            Status = 'Running'
            Frames = @('-', '|')
            FrameIndex = 1
            Message = 'Installing'
            FinalMessage = $null
            ContinueTranscript = $true
        }

        $theme = Get-Theme -Plain
        $lines = Render-Spinner -Spinner $spinner -Theme $theme

        $lines[0] | Should -Be $theme.Symbols.GuideBar
        $lines[1] | Should -Be '|  Installing'
    }

    It 'renders success state with final message' {
        $spinner = [pscustomobject]@{
            Status = 'Success'
            Frames = @('-')
            FrameIndex = 0
            Message = 'Installing'
            FinalMessage = 'Installed'
            ContinueTranscript = $true
        }

        $theme = Get-Theme -Plain
        $lines = Render-Spinner -Spinner $spinner -Theme $theme

        $lines[0] | Should -Be $theme.Symbols.GuideBar
        $lines[1] | Should -Be ('{0}  Installed' -f $theme.Symbols.StepSubmit)
    }

    It 'omits the guide spacer for standalone spinner output' {
        $spinner = [pscustomobject]@{
            Status = 'Success'
            Frames = @('-')
            FrameIndex = 0
            Message = 'Installing'
            FinalMessage = 'Installed'
            ContinueTranscript = $false
        }

        $theme = Get-Theme -Plain
        $lines = Render-Spinner -Spinner $spinner -Theme $theme

        $lines | Should -Be @('{0}  Installed' -f $theme.Symbols.StepSubmit)
    }

    It 'wraps long spinner messages under the guide' {
        Mock Get-TerminalWidth { 24 }

        $spinner = [pscustomobject]@{
            Status = 'Success'
            Frames = @('◒')
            FrameIndex = 0
            Message = 'Installing via npm for a very long package'
            FinalMessage = 'Installed via npm for a very long package'
            ContinueTranscript = $true
        }

        $theme = Get-Theme -Plain
        $lines = Render-Spinner -Spinner $spinner -Theme $theme

        $lines | Should -Be @(
            $theme.Symbols.GuideBar
            ('{0}  Installed via npm for' -f $theme.Symbols.StepSubmit)
            ('{0}  a very long package' -f $theme.Symbols.GuideBar)
        )
    }
}
