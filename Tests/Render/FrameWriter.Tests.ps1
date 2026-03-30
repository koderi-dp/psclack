BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestBootstrap.ps1')
}

Describe 'PsClack frame writer' {
    It 'clamps an out-of-range render-state top before redrawing' {
        Resolve-FrameTop -DesiredTop 40 -FrameHeight 2 -BufferHeight 30 | Should -Be 28
    }

    It 'clamps negative frame positions to zero' {
        Resolve-FrameTop -DesiredTop -5 -FrameHeight 3 -BufferHeight 30 | Should -Be 0
    }

    It 'reserves rows instead of overwriting the prompt when the first frame starts at the bottom' {
        $layout = Resolve-InitialFrameLayout -CursorTop 29 -FrameHeight 3 -BufferHeight 30

        $layout.ReserveLines | Should -Be 2
        $layout.Top | Should -Be 27
    }

    It 'does not reserve rows when the initial frame fits below the cursor' {
        $layout = Resolve-InitialFrameLayout -CursorTop 10 -FrameHeight 3 -BufferHeight 30

        $layout.ReserveLines | Should -Be 0
        $layout.Top | Should -Be 10
    }

    It 'keeps the cursor below the frame when it still fits in the buffer' {
        $placement = Resolve-FrameCursorPlacement -Top 10 -FrameHeight 3 -BufferHeight 30

        $placement.CursorTop | Should -Be 13
        $placement.ScrollLines | Should -Be 0
        $placement.AdjustedTop | Should -Be 10
    }

    It 'scrolls and shifts the anchor when the frame ends on the last row' {
        $placement = Resolve-FrameCursorPlacement -Top 28 -FrameHeight 2 -BufferHeight 30

        $placement.CursorTop | Should -Be 29
        $placement.ScrollLines | Should -Be 1
        $placement.AdjustedTop | Should -Be 27
    }

    It 'scrolls enough to preserve a spacer row below a taller frame at the bottom' {
        $layout = Resolve-InitialFrameLayout -CursorTop 29 -FrameHeight 3 -BufferHeight 30
        $placement = Resolve-FrameCursorPlacement -Top $layout.Top -FrameHeight 3 -BufferHeight 30

        $layout.ReserveLines | Should -Be 2
        $layout.Top | Should -Be 27
        $placement.ScrollLines | Should -Be 1
        $placement.AdjustedTop | Should -Be 26
    }

    It 'strips ANSI escape sequences for visible width calculations' {
        $text = "`e[36m○`e[0m  Hello"
        (Remove-AnsiEscapeSequences -Text $text) | Should -Be '○  Hello'
        (Get-VisibleTextWidth -Text $text) | Should -Be 8
    }

    It 'calculates wrapped block height at the current terminal width' {
        $lines = @(
            'short',
            '123456789012'
        )

        (Get-RenderedBlockHeight -Lines $lines -TerminalWidth 10) | Should -Be 3
    }

    It 'initializes render state with previous lines tracking' {
        $state = New-RenderState

        $state.Top | Should -Be -1
        $state.Height | Should -Be 0
        @($state.PreviousLines).Count | Should -Be 0
        $state.TerminalWidth | Should -Be -1
        $state.BufferHeight | Should -Be -1
        $state.LastCursorTop | Should -Be -1
    }

    It 'does not treat the first render as a layout change' {
        $state = New-RenderState

        (Test-FrameLayoutChanged -RenderState $state -TerminalWidth 120 -BufferHeight 30) | Should -BeFalse
    }

    It 'detects terminal width changes as a hard layout reset trigger' {
        $state = [pscustomobject]@{
            Top = 5
            Height = 3
            PreviousLines = @('a', 'b', 'c')
            TerminalWidth = 120
            BufferHeight = 30
        }

        (Test-FrameLayoutChanged -RenderState $state -TerminalWidth 90 -BufferHeight 30) | Should -BeTrue
    }

    It 'detects buffer height changes as a hard layout reset trigger' {
        $state = [pscustomobject]@{
            Top = 5
            Height = 3
            PreviousLines = @('a', 'b', 'c')
            TerminalWidth = 120
            BufferHeight = 30
        }

        (Test-FrameLayoutChanged -RenderState $state -TerminalWidth 120 -BufferHeight 20) | Should -BeTrue
    }

    It 'assigns a unique transcript segment id when the render state id is blank' {
        Reset-PsClackTranscript
        $state = New-RenderState

        Update-PsClackTranscriptDynamicSegment -RenderState $state -Lines @('one') -Top 3

        [string]::IsNullOrWhiteSpace([string]$state.TranscriptSegmentId) | Should -BeFalse

        $context = Get-PsClackTranscriptContext
        $context.Segments.Count | Should -Be 1
        $context.Segments[0].Id | Should -Be $state.TranscriptSegmentId
    }

    It 'offsets transcript anchors when the terminal reflows above the transcript' {
        Reset-PsClackTranscript
        Add-PsClackTranscriptStaticSegment -Lines @('intro') -Top 2

        $state = New-RenderState
        $state.TranscriptSegmentId = 'dynamic-segment'
        Update-PsClackTranscriptDynamicSegment -RenderState $state -Lines @('progress') -Top 5

        Offset-PsClackTranscriptAnchors -Delta 3

        $context = Get-PsClackTranscriptContext
        $context.StartTop | Should -Be 5
        $context.Segments[0].Top | Should -Be 5
        $context.Segments[1].Top | Should -Be 8
    }

    It 'computes transcript rendered height for replay at the current width' {
        Reset-PsClackTranscript
        Add-PsClackTranscriptStaticSegment -Lines @('header') -Top 2
        Add-PsClackTranscriptStaticSegment -Lines @('123456789012') -Top 3

        (Get-PsClackTranscriptRenderedHeight -TerminalWidth 10) | Should -Be 3
    }
}
