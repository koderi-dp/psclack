BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\..\PsClack\PsClack.psd1') -Force
}

Describe 'PsClack prompt groups' {
    It 'returns grouped results from nested prompts' {
        $selectKeys = [System.Collections.Generic.Queue[string]]::new()
        $selectKeys.Enqueue('Down')
        $selectKeys.Enqueue('Enter')

        $confirmKeys = [System.Collections.Generic.Queue[string]]::new()
        $confirmKeys.Enqueue('Enter')

        $textKeys = [System.Collections.Generic.Queue[string]]::new()
        $textKeys.Enqueue('Character:a')
        $textKeys.Enqueue('Character:p')
        $textKeys.Enqueue('Character:p')
        $textKeys.Enqueue('Enter')

        $result = Invoke-PsClackPromptGroup {
            $name = Read-PsClackTextPrompt -Message 'Name' -ReadKeyScript { $textKeys.Dequeue() }
            $kind = Read-PsClackSelectPrompt -Message 'Kind' -Options @(
                [pscustomobject]@{ Label = 'web'; Value = 'web' }
                [pscustomobject]@{ Label = 'api'; Value = 'api' }
            ) -ReadKeyScript { $selectKeys.Dequeue() }
            $confirm = Read-PsClackConfirmPrompt -Message 'Continue?' -ReadKeyScript { $confirmKeys.Dequeue() }

            [pscustomobject]@{
                Name = $name
                Kind = $kind
                Continue = $confirm
            }
        }

        $result.Name | Should -Be 'app'
        $result.Kind | Should -Be 'api'
        $result.Continue | Should -BeTrue
    }
}
