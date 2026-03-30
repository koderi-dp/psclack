BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestBootstrap.ps1')
}

Describe 'PsClack helpers' {
    It 'returns a plain-safe theme' {
        $theme = Get-Theme -Plain

        $theme.Plain | Should -BeTrue
        $theme.Symbols.StepActive | Should -Be '●'
        $theme.Symbols.StepSubmit | Should -Be '○'
        $theme.Symbols.GuideBar | Should -Be '│'
    }

    It 'formats themed text with a scalar style input' {
        $theme = Get-Theme

        { Format-ThemeText -Theme $theme -Text 'Done' -Styles 'Dim' } | Should -Not -Throw
    }

    It 'normalizes arrow keys' {
        $keyInfo = [System.ConsoleKeyInfo]::new([char]0, [System.ConsoleKey]::DownArrow, $false, $false, $false)

        (Convert-Key -KeyInfo $keyInfo) | Should -Be 'Down'
    }
}
