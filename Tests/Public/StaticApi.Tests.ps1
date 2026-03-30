BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\..\PsClack\PsClack.psd1') -Force
}

Describe 'PsClack static APIs' {
    It 'returns intro lines in passthru mode' {
        $lines = Show-PsClackIntro -Message 'Welcome' -PassThru -Plain

        @($lines) | Should -Be @('┌   Welcome ')
    }

    It 'returns success outro lines in passthru mode' {
        $lines = Show-PsClackOutro -Message 'Done' -Status Success -PassThru -Plain

        @($lines) | Should -Be @('│', '└  Done')
    }

    It 'returns cancel outro lines without the spacer guide' {
        $lines = Show-PsClackOutro -Message 'Operation cancelled' -Status Cancel -PassThru -Plain

        @($lines) | Should -Be @('└  Operation cancelled')
    }

    It 'returns cancel lines through the dedicated cancel helper' {
        $lines = Show-PsClackCancel -Message 'Operation cancelled' -PassThru -Plain

        @($lines) | Should -Be @('└  Operation cancelled')
    }
}
