BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\PsClack.psd1') -Force
}

Describe 'PsClack box API' {
    It 'returns box lines in passthru mode' {
        $lines = Show-PsClackBox -Title 'Info' -Message 'Hello world' -PassThru -Plain

        @($lines) | Should -Be @(
            '│'
            '│ ┌─Info──────────┐'
            '│ │  Hello world  │'
            '│ └───────────────┘'
        )
    }

    It 'supports an explicit numeric width' {
        $lines = Show-PsClackBox -Title 'Info' -Message 'Hello world' -Width 20 -PassThru -Plain

        @($lines) | Should -Be @(
            '│'
            '│ ┌─Info─────────────┐'
            '│ │  Hello world     │'
            '│ └──────────────────┘'
        )
    }

    It 'accepts a border color option' {
        $lines = Show-PsClackBox -Title 'Info' -Message 'Hello world' -BorderColor Cyan -PassThru

        @($lines).Count | Should -Be 4
    }
}
