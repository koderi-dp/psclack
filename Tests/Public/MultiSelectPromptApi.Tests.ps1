BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\..\PsClack\PsClack.psd1') -Force
}

Describe 'PsClack multiselect prompt API' {
    It 'returns multiple selected values after toggling and submitting' {
        $queue = [System.Collections.Generic.Queue[string]]::new()
        $queue.Enqueue('Space')
        $queue.Enqueue('Down')
        $queue.Enqueue('Space')
        $queue.Enqueue('Enter')

        $result = Read-PsClackMultiSelectPrompt -Message 'Features' -Options @(
            [pscustomobject]@{ Label = 'TypeScript'; Value = 'ts' }
            [pscustomobject]@{ Label = 'ESLint'; Value = 'eslint' }
        ) -ReadKeyScript { $queue.Dequeue() }

        @($result) | Should -Be @('ts', 'eslint')
    }

    It 'returns non-interactive multiselect values' {
        $result = Read-PsClackMultiSelectPrompt -Message 'Features' -Options @(
            [pscustomobject]@{ Label = 'TypeScript'; Value = 'ts' }
            [pscustomobject]@{ Label = 'ESLint'; Value = 'eslint' }
        ) -NonInteractiveValues @('ts', 'eslint')

        @($result) | Should -Be @('ts', 'eslint')
    }
}
