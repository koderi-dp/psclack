BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\..\PsClack\PsClack.psd1') -Force
}

Describe 'PsClack autocomplete prompt API' {
    BeforeAll {
        $script:AutocompleteTestOptions = @(
            [pscustomobject]@{ Label = 'TypeScript'; Value = 'ts'; Hint = 'typed' }
            [pscustomobject]@{ Label = 'JavaScript'; Value = 'js' }
            [pscustomobject]@{ Label = 'Ruby'; Value = 'rb'; Disabled = $true }
        )
    }

    It 'submits the focused option after filtering and Enter' {
        $queue = [System.Collections.Generic.Queue[string]]::new()
        $queue.Enqueue('Character:t')
        $queue.Enqueue('Enter')

        $result = Read-PsClackAutocompletePrompt -Message 'Pick language' -Options $script:AutocompleteTestOptions -ReadKeyScript { $queue.Dequeue() }

        $result | Should -Be 'ts'
    }

    It 'submits non-interactive value when it matches an enabled option' {
        $result = Read-PsClackAutocompletePrompt -Message 'Pick language' -Options $script:AutocompleteTestOptions -NonInteractiveValue 'js'

        $result | Should -Be 'js'
    }

    It 'toggles multiselection with Tab and submits multiple values' {
        $queue = [System.Collections.Generic.Queue[string]]::new()
        $queue.Enqueue('Down')
        $queue.Enqueue('Tab')
        $queue.Enqueue('Down')
        $queue.Enqueue('Tab')
        $queue.Enqueue('Enter')

        $result = Read-PsClackAutocompleteMultiSelectPrompt -Message 'Pick languages' -Options $script:AutocompleteTestOptions -ReadKeyScript { $queue.Dequeue() }

        $result | Should -Be @('js', 'ts')
    }

    It 'blocks Required multiselect until at least one option is toggled on' {
        $queue = [System.Collections.Generic.Queue[string]]::new()
        $queue.Enqueue('Enter')
        $queue.Enqueue('Down')
        $queue.Enqueue('Tab')
        $queue.Enqueue('Enter')

        $r = Read-PsClackAutocompleteMultiSelectPrompt -Message 'Pick' -Options $script:AutocompleteTestOptions -Required -ReadKeyScript { $queue.Dequeue() }

        $r | Should -Be @('js')
    }

    It 'applies custom filter script' {
        $queue = [System.Collections.Generic.Queue[string]]::new()
        $queue.Enqueue('Character:x')
        $queue.Enqueue('Enter')

        $result = Read-PsClackAutocompletePrompt -Message 'Pick' -Options $script:AutocompleteTestOptions -ReadKeyScript { $queue.Dequeue() } -Filter {
            param($search, $option)
            return $search -eq 'x' -and $option.Value -eq 'js'
        }

        $result | Should -Be 'js'
    }
}
