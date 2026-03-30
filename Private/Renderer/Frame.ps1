function Clear-Frame {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$RenderState,

        [int]$WidthOverride
    )

    if ($RenderState.Top -lt 0 -or $RenderState.Height -le 0) {
        return
    }

    Ensure-ConsoleUtf8

    $width = if ($PSBoundParameters.ContainsKey('WidthOverride')) { [int][Math]::Max(1, $WidthOverride) } else { [int](Get-TerminalWidth) }
    $bufferHeight = [Math]::Max(1, [Console]::BufferHeight)
    $RenderState.Top = Resolve-FrameTop -DesiredTop $RenderState.Top -FrameHeight ([Math]::Max(1, $RenderState.Height)) -BufferHeight $bufferHeight
    $blankLine = ''.PadRight($width)

    for ($lineIndex = 0; $lineIndex -lt $RenderState.Height; $lineIndex++) {
        Move-Cursor -Left 0 -Top ($RenderState.Top + $lineIndex)
        [Console]::Write($blankLine)
    }

    Move-Cursor -Left 0 -Top $RenderState.Top
}

function Resolve-FrameCursorPlacement {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$Top,

        [Parameter(Mandatory = $true)]
        [int]$FrameHeight,

        [Parameter(Mandatory = $true)]
        [int]$BufferHeight
    )

    $safeBufferHeight = [Math]::Max(1, $BufferHeight)
    $safeFrameHeight = [Math]::Max(1, $FrameHeight)
    $safeTop = [Math]::Min([Math]::Max(0, $Top), $safeBufferHeight - 1)
    $desiredCursorTop = $safeTop + $safeFrameHeight

    if ($desiredCursorTop -lt $safeBufferHeight) {
        return [pscustomobject]@{
            CursorTop = $desiredCursorTop
            ScrollLines = 0
            AdjustedTop = $safeTop
        }
    }

    $scrollLines = $desiredCursorTop - ($safeBufferHeight - 1)

    return [pscustomobject]@{
        CursorTop = $safeBufferHeight - 1
        ScrollLines = $scrollLines
        AdjustedTop = [Math]::Max(0, $safeTop - $scrollLines)
    }
}

function Resolve-FrameTop {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$DesiredTop,

        [Parameter(Mandatory = $true)]
        [int]$FrameHeight,

        [Parameter(Mandatory = $true)]
        [int]$BufferHeight
    )

    $safeBufferHeight = [Math]::Max(1, $BufferHeight)
    $safeFrameHeight = [Math]::Max(1, $FrameHeight)
    $maxTop = [Math]::Max(0, $safeBufferHeight - $safeFrameHeight)

    return [Math]::Min([Math]::Max(0, $DesiredTop), $maxTop)
}

function Resolve-InitialFrameLayout {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$CursorTop,

        [Parameter(Mandatory = $true)]
        [int]$FrameHeight,

        [Parameter(Mandatory = $true)]
        [int]$BufferHeight
    )

    $safeBufferHeight = [Math]::Max(1, $BufferHeight)
    $safeFrameHeight = [Math]::Max(1, $FrameHeight)
    $safeCursorTop = [Math]::Min([Math]::Max(0, $CursorTop), $safeBufferHeight - 1)

    $reserveLines = [Math]::Max(0, ($safeCursorTop + $safeFrameHeight) - $safeBufferHeight)
    $top = if ($reserveLines -gt 0) {
        [Math]::Max(0, $safeBufferHeight - $safeFrameHeight)
    }
    else {
        $safeCursorTop
    }

    return [pscustomobject]@{
        ReserveLines = $reserveLines
        Top = $top
    }
}

function Test-FrameLayoutChanged {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$RenderState,

        [Parameter(Mandatory = $true)]
        [int]$TerminalWidth,

        [Parameter(Mandatory = $true)]
        [int]$BufferHeight
    )

    $previousWidth = if ($RenderState.PSObject.Properties.Name -contains 'TerminalWidth') { [int]$RenderState.TerminalWidth } else { -1 }
    $previousBufferHeight = if ($RenderState.PSObject.Properties.Name -contains 'BufferHeight') { [int]$RenderState.BufferHeight } else { -1 }

    if ($previousWidth -le 0 -or $previousBufferHeight -le 0) {
        return $false
    }

    return ($previousWidth -ne $TerminalWidth) -or ($previousBufferHeight -ne $BufferHeight)
}

function Write-Frame {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Lines,

        [Parameter(Mandatory = $true)]
        [pscustomobject]$RenderState
    )

    Ensure-ConsoleUtf8

    $width = [int](Get-TerminalWidth)
    $bufferHeight = [Math]::Max(1, [Console]::BufferHeight)
    $currentCursorTop = [Console]::CursorTop
    Write-FrameCaptureLog -RenderState $RenderState -Lines $Lines -Stage 'Before' -CursorTop $currentCursorTop -BufferHeight $bufferHeight
    $layoutChanged = Test-FrameLayoutChanged -RenderState $RenderState -TerminalWidth $width -BufferHeight $bufferHeight
    if ($layoutChanged -and $RenderState.Top -ge 0 -and $RenderState.Height -gt 0) {
        Update-PsClackTranscriptDynamicSegment -RenderState $RenderState -Lines $Lines -Top $RenderState.Top

        $context = Get-PsClackTranscriptContext
        if ($context.Segments.Count -gt 0) {
            $previousWidth = if ($RenderState.TerminalWidth -gt 0) { [int]$RenderState.TerminalWidth } else { $width }
            $previousRenderedHeight = Get-PsClackTranscriptRenderedHeight -TerminalWidth $previousWidth
            $expectedCursorTop = [Math]::Max(0, [int]$context.StartTop + [int]$previousRenderedHeight)
            $cursorDelta = [int]$currentCursorTop - [int]$expectedCursorTop

            if ($cursorDelta -ne 0) {
                Offset-PsClackTranscriptAnchors -Delta $cursorDelta
                $RenderState.Top = [Math]::Max(0, [int]$RenderState.Top + $cursorDelta)
                Update-PsClackTranscriptDynamicSegment -RenderState $RenderState -Lines $Lines -Top $RenderState.Top
            }

            Replay-PsClackTranscript -CurrentRenderState $RenderState
            $RenderState.Height = $Lines.Count
            $RenderState.PreviousLines = @($Lines)
            $RenderState.TerminalWidth = $width
            $RenderState.BufferHeight = $bufferHeight
            $RenderState.LastCursorTop = [Console]::CursorTop
            Write-FrameCaptureLog -RenderState $RenderState -Lines $Lines -Stage 'AfterReplay' -CursorTop ([Console]::CursorTop) -BufferHeight $bufferHeight
            return
        }

        $RenderState.Top = [Math]::Max(0, [int]$currentCursorTop - [Math]::Max(1, $Lines.Count))
        $RenderState.Height = 0
        $RenderState.PreviousLines = @()
        $RenderState.TerminalWidth = $width
        $RenderState.BufferHeight = $bufferHeight
    }

    $previousLines = @($RenderState.PreviousLines)
    $previousHeight = [int][Math]::Max(0, $RenderState.Height)
    $frameHeight = [int][Math]::Max(1, [Math]::Max($Lines.Count, $previousHeight))

    if ($RenderState.Top -lt 0) {
        $initialLayout = Resolve-InitialFrameLayout -CursorTop ([Console]::CursorTop) -FrameHeight $frameHeight -BufferHeight $bufferHeight
        for ($index = 0; $index -lt $initialLayout.ReserveLines; $index++) {
            [Console]::WriteLine('')
        }
        $RenderState.Top = $initialLayout.Top
    }
    else {
        $RenderState.Top = Resolve-FrameTop -DesiredTop $RenderState.Top -FrameHeight $frameHeight -BufferHeight $bufferHeight
    }

    $lineCount = [int][Math]::Max($Lines.Count, $previousHeight)
    for ($lineIndex = 0; $lineIndex -lt $lineCount; $lineIndex++) {
        $newLine = if ($lineIndex -lt $Lines.Count) { [string]$Lines[$lineIndex] } else { '' }
        $previousLine = if ($lineIndex -lt $previousLines.Count) { [string]$previousLines[$lineIndex] } else { '' }

        if ($newLine -eq $previousLine) {
            continue
        }

        Move-Cursor -Left 0 -Top ($RenderState.Top + $lineIndex)
        [Console]::Write($newLine)

        $newWidth = [int](Get-VisibleTextWidth -Text $newLine)
        $previousWidth = [int](Get-VisibleTextWidth -Text $previousLine)
        $targetWidth = [int][Math]::Min($width, [Math]::Max($newWidth, $previousWidth))
        $padWidth = [int]($targetWidth - $newWidth)
        if ($padWidth -gt 0) {
            [Console]::Write(''.PadRight($padWidth))
        }
    }

    $RenderState.Height = $Lines.Count
    $RenderState.PreviousLines = @($Lines)
    $RenderState.TerminalWidth = $width
    $RenderState.BufferHeight = $bufferHeight
    Update-PsClackTranscriptDynamicSegment -RenderState $RenderState -Lines $Lines -Top $RenderState.Top

    $cursorPlacement = Resolve-FrameCursorPlacement -Top $RenderState.Top -FrameHeight ([Math]::Max(1, $RenderState.Height)) -BufferHeight $bufferHeight
    if ($cursorPlacement.ScrollLines -gt 0) {
        Move-Cursor -Left 0 -Top $cursorPlacement.CursorTop
        for ($index = 0; $index -lt $cursorPlacement.ScrollLines; $index++) {
            [Console]::WriteLine('')
        }
        $RenderState.Top = $cursorPlacement.AdjustedTop
        Adjust-PsClackTranscriptForScroll -ScrollLines $cursorPlacement.ScrollLines
        Update-PsClackTranscriptDynamicSegment -RenderState $RenderState -Lines $Lines -Top $RenderState.Top
    }
    else {
        Move-Cursor -Left 0 -Top $cursorPlacement.CursorTop
    }

    $RenderState.LastCursorTop = [Console]::CursorTop
    Write-FrameCaptureLog -RenderState $RenderState -Lines $Lines -Stage 'After' -CursorTop ([Console]::CursorTop) -BufferHeight $bufferHeight
}

function Write-FrameCaptureLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$RenderState,

        [Parameter(Mandatory = $true)]
        [string[]]$Lines,

        [string]$Stage = 'Before',

        [AllowNull()]
        [int]$CursorTop = -1,

        [AllowNull()]
        [int]$BufferHeight = -1
    )

    $capturePath = [string]$env:PSCLACK_CAPTURE_PATH
    if ([string]::IsNullOrWhiteSpace($capturePath)) {
        return
    }

    $entry = [pscustomobject]@{
        Timestamp = [DateTime]::UtcNow.ToString('o')
        Stage = $Stage
        CursorTop = $CursorTop
        BufferHeight = $BufferHeight
        Top = $RenderState.Top
        Height = $RenderState.Height
        PreviousLines = @($RenderState.PreviousLines)
        Lines = @($Lines)
    } | ConvertTo-Json -Depth 6 -Compress

    Add-Content -Path $capturePath -Value $entry
}

function Write-StaticFrame {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Lines,

        [switch]$NoRender
    )

    if ($NoRender) {
        return $Lines
    }

    Ensure-ConsoleUtf8
    $initialTop = [Console]::CursorTop
    Add-PsClackTranscriptStaticSegment -Lines $Lines -Top $initialTop

    foreach ($line in $Lines) {
        [Console]::WriteLine([string]$line)
    }

    $bufferHeight = [Math]::Max(1, [Console]::BufferHeight)
    $placement = Resolve-FrameCursorPlacement -Top $initialTop -FrameHeight ([Math]::Max(1, $Lines.Count)) -BufferHeight $bufferHeight
    if ($placement.ScrollLines -gt 0) {
        Adjust-PsClackTranscriptForScroll -ScrollLines $placement.ScrollLines
    }

    return $Lines
}

function Write-TaskLogState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$State
    )

    $lines = Render-TaskLog -State $State

    if ($State.NoRender) {
        return $lines
    }

    if ($State.Interactive -and $State.RenderState) {
        if ($State.WriteFrameScript) {
            & $State.WriteFrameScript $lines $State.RenderState
        }
        else {
            Write-Frame -Lines $lines -RenderState $State.RenderState
        }
    }
    else {
        $null = Write-StaticFrame -Lines $lines -NoRender:$false
    }

    return $lines
}
