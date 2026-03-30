BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\..\PsClack\PsClack.psd1') -Force

    # Scratch directory with a known file tree used across tests
    $script:TestRoot = Join-Path $TestDrive 'file-search-root'
    New-Item -ItemType Directory -Path $script:TestRoot -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $script:TestRoot 'src') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $script:TestRoot 'tests') -Force | Out-Null
    New-Item -ItemType File -Path (Join-Path $script:TestRoot 'src\main.ps1') -Force | Out-Null
    New-Item -ItemType File -Path (Join-Path $script:TestRoot 'src\helper.ps1') -Force | Out-Null
    New-Item -ItemType File -Path (Join-Path $script:TestRoot 'tests\main.Tests.ps1') -Force | Out-Null
    New-Item -ItemType File -Path (Join-Path $script:TestRoot 'README.md') -Force | Out-Null
}

Describe 'PsClack file search prompt API' {
    It 'returns non-interactive value immediately' {
        $result = Read-PsClackFileSearchPrompt -Message 'Find' -Root $script:TestRoot -NonInteractiveValue 'anything'

        $result | Should -Be 'anything'
    }

    It 'returns passthru result in non-interactive mode' {
        $result = Read-PsClackFileSearchPrompt -Message 'Find' -Root $script:TestRoot -NonInteractiveValue 'anything' -PassThru

        $result.Status    | Should -Be 'Submitted'
        $result.Value     | Should -Be 'anything'
        $result.Cancelled | Should -Be $false
    }

    It 'throws when not interactive and no NonInteractiveValue supplied' {
        { Read-PsClackFileSearchPrompt -Message 'Find' -Root $script:TestRoot } |
            Should -Throw '*requires an interactive console*'
    }

    It 'throws when root contains no matching files' {
        { Read-PsClackFileSearchPrompt -Message 'Find' -Root $script:TestRoot -Filter '*.xyz' -ReadKeyScript { 'Escape' } } |
            Should -Throw '*no files found*'
    }

    It 'submits the focused file after typing a partial name and pressing Enter' {
        $queue = [System.Collections.Generic.Queue[string]]::new()
        'm', 'a', 'i', 'n' | ForEach-Object { $queue.Enqueue("Character:$_") }
        $queue.Enqueue('Enter')

        $result = Read-PsClackFileSearchPrompt `
            -Message 'Find' `
            -Root $script:TestRoot `
            -ReadKeyScript { $queue.Dequeue() } `
            -PassThru

        $result.Cancelled | Should -Be $false
        $result.Value     | Should -BeLike '*main*'
    }

    It 'cancels on Escape' {
        $queue = [System.Collections.Generic.Queue[string]]::new()
        $queue.Enqueue('Escape')

        $result = Read-PsClackFileSearchPrompt `
            -Message 'Find' `
            -Root $script:TestRoot `
            -ReadKeyScript { $queue.Dequeue() } `
            -PassThru

        $result.Cancelled | Should -Be $true
    }

    It 'respects the Filter parameter and only indexes matching files' {
        $queue = [System.Collections.Generic.Queue[string]]::new()
        # README.md is excluded by *.ps1 filter — only ps1 files are available
        # typing 'README' should produce no match, Enter falls back to typed input
        'R', 'E', 'A', 'D', 'M', 'E' | ForEach-Object { $queue.Enqueue("Character:$_") }
        $queue.Enqueue('Enter')

        # With *.ps1 filter, README.md is not indexed so the value is the raw typed input
        $result = Read-PsClackFileSearchPrompt `
            -Message 'Find' `
            -Root $script:TestRoot `
            -Filter '*.ps1' `
            -ReadKeyScript { $queue.Dequeue() } `
            -PassThru

        $result.Value | Should -Not -BeLike '*README*'
    }

    It 'caps results at MaxResults' {
        # Create a tree with more files than MaxResults
        $manyRoot = Join-Path $TestDrive 'many'
        New-Item -ItemType Directory -Path $manyRoot -Force | Out-Null
        1..20 | ForEach-Object { New-Item -ItemType File -Path (Join-Path $manyRoot "file$_.txt") -Force | Out-Null }

        $queue = [System.Collections.Generic.Queue[string]]::new()
        $queue.Enqueue('Enter')

        # MaxResults=5 — only 5 options indexed, Enter picks the first focused one
        $result = Read-PsClackFileSearchPrompt `
            -Message 'Find' `
            -Root $manyRoot `
            -MaxResults 5 `
            -ReadKeyScript { $queue.Dequeue() } `
            -PassThru

        $result.Cancelled | Should -Be $false
    }

    It 'multi-token filter matches paths containing all tokens' {
        $queue = [System.Collections.Generic.Queue[string]]::new()
        # 'src main' should match src\main.ps1 — space separates tokens
        's', 'r', 'c', ' ', 'm', 'a', 'i', 'n' | ForEach-Object { $queue.Enqueue("Character:$_") }
        $queue.Enqueue('Enter')

        $result = Read-PsClackFileSearchPrompt `
            -Message 'Find' `
            -Root $script:TestRoot `
            -ReadKeyScript { $queue.Dequeue() } `
            -PassThru

        $result.Value | Should -BeLike '*src*main*'
    }
}
