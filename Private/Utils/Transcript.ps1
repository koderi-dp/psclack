function Add-PsClackTranscriptStaticSegment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Lines,

        [Parameter(Mandatory = $true)]
        [int]$Top
    )

    $context = Get-PsClackTranscriptContext
    if ($context.Replaying) {
        return
    }

    if ($context.StartTop -lt 0) {
        $context.StartTop = [Math]::Max(0, $Top)
    }

    $context.Segments.Add([pscustomobject]@{
        Id = [guid]::NewGuid().ToString()
        Top = [Math]::Max(0, $Top)
        Lines = @($Lines)
        Dynamic = $false
    }) | Out-Null
}

function Adjust-PsClackTranscriptForScroll {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$ScrollLines
    )

    if ($ScrollLines -le 0) {
        return
    }

    $context = Get-PsClackTranscriptContext
    if ($context.StartTop -ge 0) {
        $context.StartTop = [Math]::Max(0, [int]$context.StartTop - $ScrollLines)
    }

    foreach ($segment in @($context.Segments)) {
        if ($segment.PSObject.Properties.Name -contains 'Top') {
            $segment.Top = [Math]::Max(0, [int]$segment.Top - $ScrollLines)
        }
    }
}

function Complete-PsClackTranscriptBlock {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Intro', 'Prompt', 'Static', 'Spinner', 'Outro')]
        [string]$BlockType,

        [string]$Status
    )

    $pendingLeadingGuide = $false
    if ($BlockType -eq 'Prompt') {
        $pendingLeadingGuide = $Status -in @('Submitted', 'Cancelled')
    }

    Set-PsClackLeadingGuide -Pending $pendingLeadingGuide
}

function Consume-PsClackLeadingGuide {
    [CmdletBinding()]
    param()

    $context = Get-PsClackTranscriptContext
    $pending = [bool]$context.PendingLeadingGuide
    $context.PendingLeadingGuide = $false
    return $pending
}

function Get-PsClackTranscriptBlockContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Intro', 'Prompt', 'Static', 'Spinner', 'Outro')]
        [string]$BlockType,

        [switch]$ContinueTranscript
    )

    $suppressLeadingGuide = $false
    switch ($BlockType) {
        'Prompt' { $suppressLeadingGuide = Consume-PsClackLeadingGuide }
        'Static' { $suppressLeadingGuide = Consume-PsClackLeadingGuide }
        'Outro' { $suppressLeadingGuide = Consume-PsClackLeadingGuide }
        'Spinner' {
            if ($ContinueTranscript) {
                $suppressLeadingGuide = Consume-PsClackLeadingGuide
            }
        }
    }

    return [pscustomobject]@{
        SuppressLeadingGuide = $suppressLeadingGuide
    }
}

function Get-PsClackTranscriptContext {
    [CmdletBinding()]
    param()

    $contextVariable = Get-Variable -Scope Script -Name PsClackTranscriptContext -ErrorAction SilentlyContinue
    if (-not $contextVariable) {
        $script:PsClackTranscriptContext = @{
            PendingLeadingGuide = $false
            StartTop = -1
            Segments = [System.Collections.Generic.List[object]]::new()
            Replaying = $false
        }
    }

    return $script:PsClackTranscriptContext
}

function Get-PsClackTranscriptRenderedHeight {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$TerminalWidth
    )

    $context = Get-PsClackTranscriptContext
    $totalHeight = 0

    foreach ($segment in @($context.Segments)) {
        $totalHeight += Get-RenderedBlockHeight -Lines @($segment.Lines) -TerminalWidth $TerminalWidth
    }

    return [Math]::Max(0, [int]$totalHeight)
}

function Offset-PsClackTranscriptAnchors {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$Delta
    )

    if ($Delta -eq 0) {
        return
    }

    $context = Get-PsClackTranscriptContext
    if ($context.StartTop -ge 0) {
        $context.StartTop = [Math]::Max(0, [int]$context.StartTop + $Delta)
    }

    foreach ($segment in @($context.Segments)) {
        if ($segment.PSObject.Properties.Name -contains 'Top') {
            $segment.Top = [Math]::Max(0, [int]$segment.Top + $Delta)
        }
    }
}

function Replay-PsClackTranscript {
    [CmdletBinding()]
    param(
        [pscustomobject]$CurrentRenderState
    )

    $context = Get-PsClackTranscriptContext
    if ($context.StartTop -lt 0 -or $context.Segments.Count -eq 0) {
        return
    }

    $context.Replaying = $true
    try {
        Ensure-ConsoleUtf8
        Move-Cursor -Left 0 -Top ([Math]::Max(0, [int]$context.StartTop))
        [Console]::Write("`e[J")

        foreach ($segment in @($context.Segments)) {
            $segmentTop = [Console]::CursorTop
            $segment.Top = $segmentTop

            if ($CurrentRenderState -and ($CurrentRenderState.PSObject.Properties.Name -contains 'TranscriptSegmentId') -and $segment.Id -eq $CurrentRenderState.TranscriptSegmentId) {
                $CurrentRenderState.Top = $segmentTop
            }

            foreach ($line in @($segment.Lines)) {
                [Console]::WriteLine([string]$line)
            }

            $bufferHeight = [Math]::Max(1, [Console]::BufferHeight)
            $placement = Resolve-FrameCursorPlacement -Top $segmentTop -FrameHeight ([Math]::Max(1, @($segment.Lines).Count)) -BufferHeight $bufferHeight
            if ($placement.ScrollLines -gt 0) {
                Adjust-PsClackTranscriptForScroll -ScrollLines $placement.ScrollLines
            }
        }
    }
    finally {
        $context.Replaying = $false
    }
}

function Reset-PsClackTranscript {
    [CmdletBinding()]
    param()

    $context = Get-PsClackTranscriptContext
    $context.PendingLeadingGuide = $false
    $context.StartTop = -1
    $context.Segments = [System.Collections.Generic.List[object]]::new()
    $context.Replaying = $false
}

function Set-PsClackLeadingGuide {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Pending
    )

    $context = Get-PsClackTranscriptContext
    $context.PendingLeadingGuide = $Pending
}

function Update-PsClackTranscriptDynamicSegment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$RenderState,

        [Parameter(Mandatory = $true)]
        [string[]]$Lines,

        [Parameter(Mandatory = $true)]
        [int]$Top
    )

    $context = Get-PsClackTranscriptContext
    if ($context.Replaying) {
        return
    }

    if ($context.StartTop -lt 0) {
        $context.StartTop = [Math]::Max(0, $Top)
    }

    $segmentId = if ($RenderState.PSObject.Properties.Name -contains 'TranscriptSegmentId') {
        [string]$RenderState.TranscriptSegmentId
    }
    else {
        ''
    }

    if ([string]::IsNullOrWhiteSpace($segmentId)) {
        $segmentId = [guid]::NewGuid().ToString()
        if ($RenderState.PSObject.Properties.Name -contains 'TranscriptSegmentId') {
            $RenderState.TranscriptSegmentId = $segmentId
        }
        else {
            Add-Member -InputObject $RenderState -NotePropertyName TranscriptSegmentId -NotePropertyValue $segmentId -Force
        }
    }
    $segment = $context.Segments | Where-Object { $_.Id -eq $segmentId } | Select-Object -First 1
    if (-not $segment) {
        $segment = [pscustomobject]@{
            Id = $segmentId
            Top = [Math]::Max(0, $Top)
            Lines = @($Lines)
            Dynamic = $true
        }
        $context.Segments.Add($segment) | Out-Null
        return
    }

    $segment.Top = [Math]::Max(0, $Top)
    $segment.Lines = @($Lines)
}
