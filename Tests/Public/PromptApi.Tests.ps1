BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\..\PsClack\PsClack.psd1') -Force
}

Describe 'PsClack public prompts' {
    It 'returns the initial select value when enter is pressed immediately' {
        $result = Read-PsClackSelectPrompt -Message 'Pick one' -Options @(
            [pscustomobject]@{ Label = 'One'; Value = 1; Hint = '' }
            [pscustomobject]@{ Label = 'Two'; Value = 2; Hint = 'second' }
        ) -InitialValue 2 -ReadKeyScript { 'Enter' }

        $result | Should -Be 2
    }

    It 'returns false when confirm moves right then submits' {
        $queue = [System.Collections.Generic.Queue[string]]::new()
        $queue.Enqueue('Right')
        $queue.Enqueue('Enter')

        $result = Read-PsClackConfirmPrompt -Message 'Continue?' -ReadKeyScript { $queue.Dequeue() }

        $result | Should -BeFalse
    }

    It 'returns the explicit non-interactive select value' {
        $result = Read-PsClackSelectPrompt -Message 'Pick one' -Options @(
            [pscustomobject]@{ Label = 'One'; Value = 1; Hint = '' }
            [pscustomobject]@{ Label = 'Two'; Value = 2; Hint = '' }
        ) -NonInteractiveValue 2

        $result | Should -Be 2
    }

    It 'returns the explicit non-interactive confirm value' {
        $result = Read-PsClackConfirmPrompt -Message 'Continue?' -NonInteractiveValue $false

        $result | Should -BeFalse
    }
}
