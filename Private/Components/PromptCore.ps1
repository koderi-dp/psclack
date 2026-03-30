function New-PromptResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Active', 'Submitted', 'Cancelled')]
        [string]$Status,

        [object]$Value,

        [string]$Label
    )

    return [pscustomobject]@{
        Status = $Status
        Value = $Value
        Label = $Label
        Cancelled = ($Status -eq 'Cancelled')
    }
}

function New-RenderState {
    [CmdletBinding()]
    param()

    return [pscustomobject]@{
        Top = -1
        Height = 0
        PreviousLines = @()
        TerminalWidth = -1
        BufferHeight = -1
        LastCursorTop = -1
        TranscriptSegmentId = $null
    }
}

function Convert-Key {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.ConsoleKeyInfo]$KeyInfo
    )

    switch ($KeyInfo.Key) {
        ([System.ConsoleKey]::UpArrow) { return 'Up' }
        ([System.ConsoleKey]::DownArrow) { return 'Down' }
        ([System.ConsoleKey]::LeftArrow) { return 'Left' }
        ([System.ConsoleKey]::RightArrow) { return 'Right' }
        ([System.ConsoleKey]::Enter) { return 'Enter' }
        ([System.ConsoleKey]::Escape) { return 'Escape' }
        ([System.ConsoleKey]::Spacebar) { return 'Space' }
        ([System.ConsoleKey]::Backspace) { return 'Backspace' }
        ([System.ConsoleKey]::Tab) { return 'Tab' }
        default {
            if (($KeyInfo.Modifiers -band [System.ConsoleModifiers]::Control) -and $KeyInfo.Key -eq [System.ConsoleKey]::C) {
                return 'CtrlC'
            }

            if ($KeyInfo.KeyChar -and -not [char]::IsControl($KeyInfo.KeyChar)) {
                return ('Character:{0}' -f $KeyInfo.KeyChar)
            }

            return $KeyInfo.Key.ToString()
        }
    }
}

function Read-Key {
    [CmdletBinding()]
    param(
        [scriptblock]$ReadKeyScript
    )

    if ($ReadKeyScript) {
        return (& $ReadKeyScript)
    }

    return (Convert-Key -KeyInfo ([Console]::ReadKey($true)))
}

function Invoke-PromptEngine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$State,

        [Parameter(Mandatory = $true)]
        [scriptblock]$Render,

        [Parameter(Mandatory = $true)]
        [scriptblock]$HandleKey,

        [scriptblock]$ReadKeyScript,

        [switch]$NoRender
    )

    $renderState = $null
    if (-not $NoRender) {
        $renderState = New-RenderState
    }

    $cursorVisible = $null
    $prevTreatCtrlC = $null
    if (-not $NoRender) {
        $cursorVisible = Hide-ConsoleCursor
        try {
            $prevTreatCtrlC = [Console]::TreatControlCAsInput
            [Console]::TreatControlCAsInput = $true
        }
        catch { }
    }

    try {
        do {
            if (-not $NoRender) {
                $lines = @(& $Render $State)
                Write-Frame -Lines $lines -RenderState $renderState
            }

            $key = Read-Key -ReadKeyScript $ReadKeyScript
            $State = & $HandleKey $State $key
        }
        while ($State.Status -eq 'Active')

        if (-not $NoRender) {
            $finalLines = @(& $Render $State)
            Write-Frame -Lines $finalLines -RenderState $renderState
        }
    }
    finally {
        if (-not $NoRender) {
            Restore-ConsoleCursor -Visible $cursorVisible
            if ($null -ne $prevTreatCtrlC) {
                try { [Console]::TreatControlCAsInput = $prevTreatCtrlC } catch { }
            }
        }
    }

    return $State
}
