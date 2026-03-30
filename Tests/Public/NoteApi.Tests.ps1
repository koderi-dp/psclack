BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\PsClack.psd1') -Force
}

Describe 'PsClack note API' {
    It 'returns note lines in passthru mode' {
        $lines = Show-PsClackNote -Title 'Info' -Message 'Hello world' -PassThru -Plain

        @($lines) | Should -Be @(
            '│'
            '○  Info ────────╮'
            '│               │'
            '│  Hello world  │'
            '│               │'
            '├───────────────╯'
        )
    }
}
