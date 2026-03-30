BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\..\PsClack\PsClack.psd1') -Force
}

Describe 'PsClack password prompt API' {
    It 'returns typed password after validation passes' {
        $queue = [System.Collections.Generic.Queue[string]]::new()
        $queue.Enqueue('Character:s')
        $queue.Enqueue('Character:e')
        $queue.Enqueue('Character:c')
        $queue.Enqueue('Enter')

        $result = Read-PsClackPasswordPrompt -Message 'Password' -Validate {
            param($value)
            if ($value.Length -lt 3) { 'Too short' }
        } -ReadKeyScript { $queue.Dequeue() }

        $result | Should -Be 'sec'
    }

    It 'returns the non-interactive password value after validation passes' {
        $result = Read-PsClackPasswordPrompt -Message 'Password' -Validate {
            param($value)
            if ($value.Length -lt 3) { 'Too short' }
        } -NonInteractiveValue 'secret'

        $result | Should -Be 'secret'
    }
}
