BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestBootstrap.ps1')
}

Describe 'PsClack progress API' {
    It 'creates a progress object with clack-like methods' {
        $progress = New-PsClackProgress -Plain -InteractiveOverride $false -Max 5 -Size 10

        $progress.ProgressMax | Should -Be 5
        $progress.ProgressSize | Should -Be 10
        $progress.Started | Should -BeFalse
    }

    It 'advances progress and tracks the current message' {
        $progress = New-PsClackProgress -Plain -InteractiveOverride $false -Max 5 -Size 10

        $null = $progress.Start('Downloading packages')
        $null = $progress.Advance(2, 'Fetched packages')

        $progress.ProgressValue | Should -Be 2
        $progress.ProgressMessage | Should -Be 'Fetched packages'
    }

    It 'renders a running progress bar through the shared spinner renderer' {
        $progress = New-PsClackProgress -Plain -InteractiveOverride $false -Max 4 -Size 8
        $null = $progress.Start('Preparing scaffold')
        $null = $progress.Advance(2, 'Writing files')

        $lines = Render-Spinner -Spinner $progress -Theme $progress.Theme

        ($lines -join "`n") | Should -Match '━━━━'
        ($lines -join "`n") | Should -Match 'Writing files'
    }

    It 'supports foreground animation ticks between progress updates' {
        $progress = New-PsClackProgress -Plain -InteractiveOverride $false -Max 4 -Size 8
        $null = $progress.Start('Preparing scaffold')
        $initialFrameIndex = $progress.FrameIndex

        $null = $progress.Wait(130)

        $progress.FrameIndex | Should -Not -Be $initialFrameIndex
        $progress.ProgressValue | Should -Be 0
    }

    It 'supports non-blocking animation ticks' {
        $progress = New-PsClackProgress -Plain -InteractiveOverride $false -Max 4 -Size 8
        $null = $progress.Start('Preparing scaffold')
        $initialFrameIndex = $progress.FrameIndex

        $null = $progress.Tick()

        $progress.FrameIndex | Should -Not -Be $initialFrameIndex
        $progress.ProgressValue | Should -Be 0
    }

    It 'stores a minimum bar width for dynamic fitting' {
        $progress = New-PsClackProgress -Plain -InteractiveOverride $false -Max 4 -Size 20 -MinSize 10
        $progress.ProgressMinSize | Should -Be 10
    }
}
