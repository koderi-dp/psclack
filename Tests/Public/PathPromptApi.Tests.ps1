BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\..\PsClack\PsClack.psd1') -Force
}

Describe 'PsClack path prompt API' {
    It 'returns non-interactive value immediately' {
        $result = Read-PsClackPathPrompt -Message 'Pick a path' -NonInteractiveValue 'C:\Windows'

        $result | Should -Be 'C:\Windows'
    }

    It 'returns a result object in non-interactive passthru mode' {
        $result = Read-PsClackPathPrompt -Message 'Pick a path' -NonInteractiveValue 'C:\Windows' -PassThru

        $result.Status    | Should -Be 'Submitted'
        $result.Value     | Should -Be 'C:\Windows'
        $result.Cancelled | Should -Be $false
    }

    It 'runs custom validation on non-interactive value' {
        { Read-PsClackPathPrompt -Message 'Pick' -NonInteractiveValue 'bad' -Validate { param($v) if ($v -eq 'bad') { 'Invalid path' } } } |
            Should -Throw '*failed validation*'
    }

    It 'submits typed path on Enter when there are no filesystem matches' {
        $queue = [System.Collections.Generic.Queue[string]]::new()
        'Z', ':', '\', 'n', 'o', 'm', 'a', 't', 'c', 'h' | ForEach-Object { $queue.Enqueue("Character:$_") }
        $queue.Enqueue('Enter')

        $result = Read-PsClackPathPrompt -Message 'Pick a path' -InitialValue '' -ReadKeyScript { $queue.Dequeue() }

        $result | Should -Be 'Z:\nomatch'
    }

    It 'submits the focused filesystem match on Enter when one is highlighted' {
        $queue = [System.Collections.Generic.Queue[string]]::new()
        'C', ':', '\', 'W', 'i', 'n', 'd', 'o', 'w', 's' | ForEach-Object { $queue.Enqueue("Character:$_") }
        $queue.Enqueue('Enter')

        $result = Read-PsClackPathPrompt -Message 'Pick a path' -InitialValue '' -ReadKeyScript { $queue.Dequeue() }

        $result | Should -Be 'C:\Windows'
    }

    It 'cancels on Escape and returns null' {
        $queue = [System.Collections.Generic.Queue[string]]::new()
        $queue.Enqueue('Escape')

        $result = Read-PsClackPathPrompt -Message 'Pick a path' -ReadKeyScript { $queue.Dequeue() }

        $result | Should -BeNullOrEmpty
    }

    It 'cancels on Ctrl+C and returns a cancelled result in passthru mode' {
        $queue = [System.Collections.Generic.Queue[string]]::new()
        $queue.Enqueue('CtrlC')

        $result = Read-PsClackPathPrompt -Message 'Pick a path' -ReadKeyScript { $queue.Dequeue() } -PassThru

        $result.Cancelled | Should -Be $true
        $result.Value     | Should -BeNullOrEmpty
    }

    It 'trims trailing separator from submitted value' {
        $queue = [System.Collections.Generic.Queue[string]]::new()
        'C', ':', '\', 'f', 'o', 'o', '\' | ForEach-Object { $queue.Enqueue("Character:$_") }
        $queue.Enqueue('Enter')

        $result = Read-PsClackPathPrompt -Message 'Pick a path' -InitialValue '' -ReadKeyScript { $queue.Dequeue() }

        $result | Should -Be 'C:\foo'
    }

    It 'backspace removes the last character from the input' {
        $queue = [System.Collections.Generic.Queue[string]]::new()
        'f', 'o', 'o' | ForEach-Object { $queue.Enqueue("Character:$_") }
        $queue.Enqueue('Backspace')
        $queue.Enqueue('Enter')

        $result = Read-PsClackPathPrompt -Message 'Pick a path' -InitialValue '' -ReadKeyScript { $queue.Dequeue() }

        $result | Should -Be 'fo'
    }

    It 'submits a focused match when wildcard pattern is used' {
        $queue = [System.Collections.Generic.Queue[string]]::new()
        # Type C:\Windows\*stem32 to match System32 via wildcard
        'C', ':', '\', 'W', 'i', 'n', 'd', 'o', 'w', 's', '\', '*', 's', 't', 'e', 'm', '3', '2' |
            ForEach-Object { $queue.Enqueue("Character:$_") }
        $queue.Enqueue('Enter')

        $result = Read-PsClackPathPrompt -Message 'Pick a path' -InitialValue '' -ReadKeyScript { $queue.Dequeue() }

        $result | Should -Be 'C:\Windows\System32'
    }

    It 'throws when not interactive and no NonInteractiveValue supplied' {
        { Read-PsClackPathPrompt -Message 'Pick a path' } | Should -Throw '*requires an interactive console*'
    }
}
