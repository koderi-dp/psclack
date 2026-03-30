BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\..\PsClack\PsClack.psd1') -Force
}

Describe 'PsClack text prompt API' {
    It 'returns typed text after validation passes' {
        $queue = [System.Collections.Generic.Queue[string]]::new()
        $queue.Enqueue('Character:a')
        $queue.Enqueue('Character:b')
        $queue.Enqueue('Enter')

        $result = Read-PsClackTextPrompt -Message 'Name' -Validate {
            param($value)
            if ($value.Length -lt 2) { 'Too short' }
        } -ReadKeyScript { $queue.Dequeue() }

        $result | Should -Be 'ab'
    }

    It 'returns empty text when enter is pressed without typing' {
        $result = Read-PsClackTextPrompt -Message 'Name' -Placeholder 'Anonymous' -ReadKeyScript { 'Enter' }

        $result | Should -Be ''
    }

    It 'returns the non-interactive text value after validation passes' {
        $result = Read-PsClackTextPrompt -Message 'Name' -Validate {
            param($value)
            if ($value.Length -lt 2) { 'Too short' }
        } -NonInteractiveValue 'ab'

        $result | Should -Be 'ab'
    }
}
