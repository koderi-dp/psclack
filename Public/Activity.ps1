function Start-PsClackSpinner {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Message,

        [string[]]$Frames,

        [int]$IntervalMs,

        [switch]$Plain,

        [Nullable[bool]]$InteractiveOverride,

        [switch]$NoAutoSpin,

        [switch]$ContinueTranscript,

        [scriptblock]$CreateTimerScript,

        [scriptblock]$RegisterEventScript,

        [scriptblock]$WriteFrameScript,

        [scriptblock]$HideCursorScript
    )

    $interactiveConsole = if ($PSBoundParameters.ContainsKey('InteractiveOverride')) { [bool]$InteractiveOverride } else { Test-InteractiveConsole }
    $blockContext = Get-PsClackTranscriptBlockContext -BlockType Spinner -ContinueTranscript:$ContinueTranscript
    $theme = Get-Theme -Plain:$Plain

    if (-not $PSBoundParameters.ContainsKey('Frames')) {
        $Frames = if ($Plain.IsPresent) {
            @('•', 'o', 'O', '0')
        }
        else {
            @('◒', '◐', '◓', '◑')
        }
    }

    if (-not $PSBoundParameters.ContainsKey('IntervalMs')) {
        $IntervalMs = if ($Plain.IsPresent) { 120 } else { 80 }
    }

    $spinner = [pscustomobject]@{
        Message = $Message
        Frames = @($Frames)
        FrameIndex = 0
        IntervalMs = $IntervalMs
        Status = 'Running'
        FinalMessage = $null
        Interactive = $interactiveConsole
        RenderState = if ($interactiveConsole) { New-RenderState } else { $null }
        Theme = $theme
        Timer = $null
        SubscriptionId = $null
        EventJobId = $null
        CursorVisible = $null
        AutoSpin = (-not $NoAutoSpin)
        ContinueTranscript = $ContinueTranscript.IsPresent
        SuppressLeadingGuide = [bool]$blockContext.SuppressLeadingGuide
    }

    if ($interactiveConsole) {
        $spinner.CursorVisible = if ($HideCursorScript) { & $HideCursorScript } else { Hide-ConsoleCursor }

        if ($WriteFrameScript) {
            & $WriteFrameScript (Render-Spinner -Spinner $spinner -Theme $theme) $spinner.RenderState
        }
        else {
            Write-Frame -Lines (Render-Spinner -Spinner $spinner -Theme $theme) -RenderState $spinner.RenderState
        }

        if (-not $NoAutoSpin) {
            $timer = if ($CreateTimerScript) {
                & $CreateTimerScript $IntervalMs
            }
            else {
                [System.Timers.Timer]::new($IntervalMs)
            }
            $timer.AutoReset = $true
            $sourceIdentifier = [guid]::NewGuid().ToString()

            $subscriber = if ($RegisterEventScript) {
                & $RegisterEventScript $timer $sourceIdentifier $spinner
            }
            else {
                Register-ObjectEvent -InputObject $timer -EventName Elapsed -SourceIdentifier $sourceIdentifier -MessageData $spinner -Action {
                    $current = $event.MessageData
                    if ($current.Status -ne 'Running') {
                        return
                    }

                    try {
                        Ensure-ConsoleUtf8
                        $current.FrameIndex = ($current.FrameIndex + 1) % $current.Frames.Count
                        $line = [string]::Format('{0} {1}', $current.Frames[$current.FrameIndex], $current.Message)

                        $top = $current.RenderState.Top
                        if ($top -lt 0) {
                            $top = [Console]::CursorTop
                            $current.RenderState.Top = $top
                        }

                        $lineTop = $top + 1
                        $width = [Math]::Max(1, [Console]::BufferWidth)
                        if ($line.Length -gt $width) {
                            $line = $line.Substring(0, $width)
                        }
                        else {
                            $line = $line.PadRight($width)
                        }

                        [Console]::SetCursorPosition(0, $lineTop)
                        [Console]::Write($line)
                        $current.RenderState.Height = 2
                    }
                    catch {
                    }
                }
            }

            $spinner.Timer = $timer
            $spinner.SubscriptionId = $sourceIdentifier
            $spinner.EventJobId = $subscriber.Id
            $timer.Start()
        }
    }

    return $spinner
}

function Update-PsClackSpinner {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Spinner,

        [scriptblock]$WriteFrameScript
    )

    if ($Spinner.Status -ne 'Running') {
        return $Spinner
    }

    $Spinner.FrameIndex = ($Spinner.FrameIndex + 1) % $Spinner.Frames.Count

    if ($Spinner.Interactive -and $Spinner.RenderState) {
        if ($WriteFrameScript) {
            & $WriteFrameScript (Render-Spinner -Spinner $Spinner -Theme $Spinner.Theme) $Spinner.RenderState
        }
        else {
            Write-Frame -Lines (Render-Spinner -Spinner $Spinner -Theme $Spinner.Theme) -RenderState $Spinner.RenderState
        }
    }

    return $Spinner
}

function Stop-PsClackSpinner {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Spinner,

        [ValidateSet('Success', 'Cancelled', 'Error')]
        [string]$Status = 'Success',

        [string]$Message,

        [scriptblock]$UnregisterEventScript,

        [scriptblock]$RemoveJobScript,

        [scriptblock]$WriteFrameScript,

        [scriptblock]$RestoreCursorScript
    )

    $Spinner.Status = $Status
    if ($PSBoundParameters.ContainsKey('Message')) {
        $Spinner.FinalMessage = $Message
    }

    if ($Spinner.Timer) {
        $Spinner.Timer.Stop()
    }

    if ($Spinner.SubscriptionId) {
        if ($UnregisterEventScript) {
            & $UnregisterEventScript $Spinner.SubscriptionId
        }
        else {
            Unregister-Event -SourceIdentifier $Spinner.SubscriptionId -ErrorAction SilentlyContinue
        }
        $Spinner.SubscriptionId = $null
    }

    if ($Spinner.EventJobId) {
        if ($RemoveJobScript) {
            & $RemoveJobScript $Spinner.EventJobId
        }
        else {
            Remove-Job -Id $Spinner.EventJobId -Force -ErrorAction SilentlyContinue
        }
        $Spinner.EventJobId = $null
    }

    if ($Spinner.Timer) {
        $Spinner.Timer.Dispose()
        $Spinner.Timer = $null
    }

    try {
        if ($Spinner.Interactive -and $Spinner.RenderState) {
            if ($WriteFrameScript) {
                & $WriteFrameScript (Render-Spinner -Spinner $Spinner -Theme $Spinner.Theme) $Spinner.RenderState
            }
            else {
                Write-Frame -Lines (Render-Spinner -Spinner $Spinner -Theme $Spinner.Theme) -RenderState $Spinner.RenderState
            }
        }
    }
    finally {
        if ($Spinner.PSObject.Properties.Name -contains 'CursorVisible') {
            if ($RestoreCursorScript) {
                & $RestoreCursorScript $Spinner.CursorVisible
            }
            else {
                Restore-ConsoleCursor -Visible $Spinner.CursorVisible
            }
        }
    }

    return $Spinner
}

function Invoke-PsClackWithSpinner {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Nullable[int]]$IntervalMs,

        [string[]]$Frames,

        [string]$SuccessMessage,

        [string]$CancelMessage = 'Operation cancelled',

        [string]$ErrorMessage,

        [switch]$Plain,

        [switch]$ContinueTranscript
    )

    $spinnerParams = @{
        Message = $Message
        Plain = $Plain
        NoAutoSpin = $true
        ContinueTranscript = $ContinueTranscript
    }

    if ($PSBoundParameters.ContainsKey('IntervalMs')) {
        $spinnerParams.IntervalMs = [int]$IntervalMs
    }

    if ($PSBoundParameters.ContainsKey('Frames')) {
        $spinnerParams.Frames = $Frames
    }

    $spinner = Start-PsClackSpinner @spinnerParams
    $job = $null

    try {
        $jobStarter = if (Get-Command Start-ThreadJob -ErrorAction SilentlyContinue) { 'Start-ThreadJob' } else { 'Start-Job' }
        $job = & $jobStarter -ScriptBlock $ScriptBlock

        $sleepMs = if ($PSBoundParameters.ContainsKey('IntervalMs')) { [int]$IntervalMs } else { [int]$spinner.IntervalMs }
        while ($job.State -eq 'Running' -or $job.State -eq 'NotStarted') {
            Start-Sleep -Milliseconds $sleepMs
            $null = Update-PsClackSpinner -Spinner $spinner
        }

        $result = Receive-Job -Job $job -Wait -AutoRemoveJob -ErrorAction Stop
        $job = $null
        $finalMessage = if ($PSBoundParameters.ContainsKey('SuccessMessage')) { $SuccessMessage } else { $Message }
        $null = Stop-PsClackSpinner -Spinner $spinner -Status Success -Message $finalMessage
        return $result
    }
    catch [System.OperationCanceledException] {
        $null = Stop-PsClackSpinner -Spinner $spinner -Status Cancelled -Message $CancelMessage
        throw
    }
    catch {
        $finalMessage = if ($PSBoundParameters.ContainsKey('ErrorMessage')) { $ErrorMessage } else { $_.Exception.Message }
        $null = Stop-PsClackSpinner -Spinner $spinner -Status Error -Message $finalMessage
        throw
    }
    finally {
        if ($null -ne $job) {
            Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
        }
    }
}

function New-PsClackProgress {
    [CmdletBinding()]
    param(
        [ValidateSet('Light', 'Heavy', 'Block')]
        [string]$Style = 'Heavy',

        [int]$Max = 100,

        [int]$Size = 40,

        [int]$MinSize = 12,

        [switch]$Plain,

        [Nullable[bool]]$InteractiveOverride,

        [switch]$ContinueTranscript
    )

    $safeMax = [Math]::Max(1, $Max)
    $safeSize = [Math]::Max(1, $Size)
    $interactiveConsole = if ($PSBoundParameters.ContainsKey('InteractiveOverride')) { [bool]$InteractiveOverride } else { Test-InteractiveConsole }

    $progress = Start-PsClackSpinner -Message '' -Plain:$Plain -InteractiveOverride:$interactiveConsole -NoAutoSpin -ContinueTranscript:$ContinueTranscript
    Add-Member -InputObject $progress -NotePropertyName Mode -NotePropertyValue 'Progress' -Force
    Add-Member -InputObject $progress -NotePropertyName ProgressStyle -NotePropertyValue $Style -Force
    Add-Member -InputObject $progress -NotePropertyName ProgressMax -NotePropertyValue $safeMax -Force
    Add-Member -InputObject $progress -NotePropertyName ProgressSize -NotePropertyValue $safeSize -Force
    Add-Member -InputObject $progress -NotePropertyName ProgressMinSize -NotePropertyValue ([Math]::Max(4, $MinSize)) -Force
    Add-Member -InputObject $progress -NotePropertyName ProgressValue -NotePropertyValue 0 -Force
    Add-Member -InputObject $progress -NotePropertyName ProgressMessage -NotePropertyValue '' -Force
    Add-Member -InputObject $progress -NotePropertyName Started -NotePropertyValue $false -Force

    Add-Member -InputObject $progress -MemberType ScriptMethod -Name Start -Value {
        param([string]$Message = '')

        $this.ProgressMessage = [string]$Message
        $this.Started = $true

        if ($this.Interactive -and $this.RenderState) {
            Write-Frame -Lines (Render-Spinner -Spinner $this -Theme $this.Theme) -RenderState $this.RenderState
        }
    }

    Add-Member -InputObject $progress -MemberType ScriptMethod -Name Advance -Value {
        param(
            [int]$Step = 1,
            [string]$Message
        )

        $this.ProgressValue = [Math]::Min([int]$this.ProgressMax, [int]$this.ProgressValue + $Step)
        $this.FrameIndex = ($this.FrameIndex + 1) % $this.Frames.Count
        if ($PSBoundParameters.ContainsKey('Message')) {
            $this.ProgressMessage = [string]$Message
        }

        if ($this.Interactive -and $this.RenderState) {
            Write-Frame -Lines (Render-Spinner -Spinner $this -Theme $this.Theme) -RenderState $this.RenderState
        }
    }

    Add-Member -InputObject $progress -MemberType ScriptMethod -Name Message -Value {
        param([string]$Message)

        $this.FrameIndex = ($this.FrameIndex + 1) % $this.Frames.Count
        $this.ProgressMessage = [string]$Message

        if ($this.Interactive -and $this.RenderState) {
            Write-Frame -Lines (Render-Spinner -Spinner $this -Theme $this.Theme) -RenderState $this.RenderState
        }
    } -Force

    Add-Member -InputObject $progress -MemberType ScriptMethod -Name Tick -Value {
        $this.FrameIndex = ($this.FrameIndex + 1) % $this.Frames.Count

        if ($this.Interactive -and $this.RenderState) {
            Write-Frame -Lines (Render-Spinner -Spinner $this -Theme $this.Theme) -RenderState $this.RenderState
        }
    }

    Add-Member -InputObject $progress -MemberType ScriptMethod -Name Wait -Value {
        param([int]$Milliseconds)

        $remaining = [Math]::Max(0, [int]$Milliseconds)
        $tickMs = [Math]::Max(50, [int]$this.IntervalMs)

        while ($remaining -gt 0 -and $this.Status -eq 'Running') {
            $currentTick = [Math]::Min($tickMs, $remaining)
            Start-Sleep -Milliseconds $currentTick
            $remaining -= $currentTick

            $this.FrameIndex = ($this.FrameIndex + 1) % $this.Frames.Count
            if ($this.Interactive -and $this.RenderState) {
                Write-Frame -Lines (Render-Spinner -Spinner $this -Theme $this.Theme) -RenderState $this.RenderState
            }
        }
    }

    Add-Member -InputObject $progress -MemberType ScriptMethod -Name Stop -Value {
        param([string]$Message)

        if ($PSBoundParameters.ContainsKey('Message')) {
            $this.FinalMessage = [string]$Message
        }

        Stop-PsClackSpinner -Spinner $this -Status Success -Message $(if ($PSBoundParameters.ContainsKey('Message')) { $Message } else { $this.ProgressMessage }) | Out-Null
    }

    Add-Member -InputObject $progress -MemberType ScriptMethod -Name Cancel -Value {
        param([string]$Message = 'Operation cancelled')

        Stop-PsClackSpinner -Spinner $this -Status Cancelled -Message $Message | Out-Null
    }

    Add-Member -InputObject $progress -MemberType ScriptMethod -Name Error -Value {
        param([string]$Message)

        $final = if ($PSBoundParameters.ContainsKey('Message')) { $Message } else { $this.ProgressMessage }
        Stop-PsClackSpinner -Spinner $this -Status Error -Message $final | Out-Null
    }

    return $progress
}

