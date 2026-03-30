function Invoke-PsClackTasks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Tasks,

        [switch]$Plain,

        [switch]$ContinueTranscript,

        [switch]$PassThru
    )

    $results = [System.Collections.Generic.List[object]]::new()
    $continueTranscriptForNextTask = $ContinueTranscript.IsPresent

    foreach ($task in @($Tasks)) {
        $titleProperty = $task.PSObject.Properties['Title']
        $taskProperty = $task.PSObject.Properties['Task']
        $enabledProperty = $task.PSObject.Properties['Enabled']
        $successMessageProperty = $task.PSObject.Properties['SuccessMessage']
        $errorMessageProperty = $task.PSObject.Properties['ErrorMessage']

        if (-not $titleProperty -or [string]::IsNullOrWhiteSpace([string]$titleProperty.Value)) {
            throw 'Invoke-PsClackTasks requires each task to include a non-empty Title property.'
        }

        if (-not $taskProperty -or $taskProperty.Value -isnot [scriptblock]) {
            throw 'Invoke-PsClackTasks requires each task to include a Task scriptblock property.'
        }

        $title = [string]$titleProperty.Value
        $taskScript = [scriptblock]$taskProperty.Value
        $enabled = if ($enabledProperty) { [bool]$enabledProperty.Value } else { $true }

        if (-not $enabled) {
            $results.Add([pscustomobject]@{
                Title = $title
                Status = 'Skipped'
                Skipped = $true
                Value = $null
                Message = $title
            })
            continue
        }

        $spinner = Start-PsClackSpinner -Message $title -Plain:$Plain -NoAutoSpin -ContinueTranscript:$continueTranscriptForNextTask
        $job = $null

        try {
            $jobStarter = if (Get-Command Start-ThreadJob -ErrorAction SilentlyContinue) { 'Start-ThreadJob' } else { 'Start-Job' }
            $job = & $jobStarter -ScriptBlock $taskScript

            while ($job.State -eq 'Running' -or $job.State -eq 'NotStarted') {
                Start-Sleep -Milliseconds ([int]$spinner.IntervalMs)
                $null = Update-PsClackSpinner -Spinner $spinner
            }

            $taskResult = Receive-Job -Job $job -Wait -AutoRemoveJob -ErrorAction Stop
            $job = $null

            $finalMessage = if ($successMessageProperty -and -not [string]::IsNullOrWhiteSpace([string]$successMessageProperty.Value)) {
                [string]$successMessageProperty.Value
            }
            elseif ($taskResult -is [string] -and -not [string]::IsNullOrWhiteSpace($taskResult)) {
                $taskResult
            }
            else {
                $title
            }

            $null = Stop-PsClackSpinner -Spinner $spinner -Status Success -Message $finalMessage
            $continueTranscriptForNextTask = $true

            $results.Add([pscustomobject]@{
                Title = $title
                Status = 'Success'
                Skipped = $false
                Value = $taskResult
                Message = $finalMessage
            })
        }
        catch {
            $finalMessage = if ($errorMessageProperty -and -not [string]::IsNullOrWhiteSpace([string]$errorMessageProperty.Value)) {
                [string]$errorMessageProperty.Value
            }
            else {
                $_.Exception.Message
            }

            $null = Stop-PsClackSpinner -Spinner $spinner -Status Error -Message $finalMessage
            throw
        }
        finally {
            if ($null -ne $job) {
                Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
            }
        }
    }

    if ($PassThru) {
        return $results.ToArray()
    }
}

function New-PsClackTaskLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,

        [int]$Limit = 0,

        [int]$Spacing = 1,

        [switch]$RetainLog,

        [switch]$Plain,

        [Nullable[bool]]$InteractiveOverride,

        [scriptblock]$WriteFrameScript,

        [switch]$NoRender
    )

    $interactive = if ($PSBoundParameters.ContainsKey('InteractiveOverride')) { [bool]$InteractiveOverride } else { Test-InteractiveConsole }
    $rootBuffer = [pscustomobject]@{
        Header = $null
        Lines = [System.Collections.Generic.List[string]]::new()
        FullLines = [System.Collections.Generic.List[string]]::new()
        Result = $null
    }

    $state = @{
        Title = $Title
        Limit = [Math]::Max(0, $Limit)
        Spacing = [Math]::Max(0, $Spacing)
        RetainLog = $RetainLog.IsPresent
        Plain = $Plain.IsPresent
        Theme = Get-Theme -Plain:$Plain
        Interactive = $interactive
        RenderState = if ($interactive) { New-RenderState } else { $null }
        WriteFrameScript = $WriteFrameScript
        NoRender = $NoRender.IsPresent
        Status = 'Active'
        FinalMessage = $null
        ShowLog = $false
        Buffers = [System.Collections.Generic.List[object]]::new()
        RootBuffer = $rootBuffer
    }
    $state.Buffers.Add($rootBuffer)

    $log = [pscustomobject]@{
        State = $state
    }

    $appendMessage = {
        param(
            [hashtable]$CurrentState,
            [pscustomobject]$Buffer,
            [string]$Message,
            [bool]$Raw = $false
        )

        $segments = @([string]$Message -split "(`r`n|`n|`r)")
        if ($segments.Count -eq 0) {
            $segments = @('')
        }

        for ($index = 0; $index -lt $segments.Count; $index++) {
            $segment = [string]$segments[$index]
            if ($Raw -and $index -eq 0 -and $Buffer.Lines.Count -gt 0) {
                $Buffer.Lines[$Buffer.Lines.Count - 1] = [string]$Buffer.Lines[$Buffer.Lines.Count - 1] + $segment
            }
            else {
                $Buffer.Lines.Add($segment)
            }
        }

        if ($CurrentState.Limit -gt 0) {
            while ($Buffer.Lines.Count -gt $CurrentState.Limit) {
                $removed = [string]$Buffer.Lines[0]
                $Buffer.Lines.RemoveAt(0)
                if ($CurrentState.RetainLog) {
                    $Buffer.FullLines.Add($removed)
                }
            }
        }

        $null = Write-TaskLogState -State $CurrentState
    }

    Add-Member -InputObject $log -MemberType ScriptMethod -Name Message -Value {
        param(
            [string]$Message,
            [bool]$Raw = $false
        )

        $append = $this.PSObject.Properties['AppendMessage'].Value
        & $append $this.State $this.State.RootBuffer $Message $Raw
    }

    Add-Member -InputObject $log -MemberType ScriptMethod -Name Group -Value {
        param([string]$Name)

        $buffer = [pscustomobject]@{
            Header = $Name
            Lines = [System.Collections.Generic.List[string]]::new()
            FullLines = [System.Collections.Generic.List[string]]::new()
            Result = $null
        }
        $this.State.Buffers.Add($buffer)
        $null = Write-TaskLogState -State $this.State

        $group = [pscustomobject]@{
            State = $this.State
            Buffer = $buffer
            AppendMessage = $this.PSObject.Properties['AppendMessage'].Value
        }

        Add-Member -InputObject $group -MemberType ScriptMethod -Name Message -Value {
            param(
                [string]$Message,
                [bool]$Raw = $false
            )

            & $this.AppendMessage $this.State $this.Buffer $Message $Raw
        }

        Add-Member -InputObject $group -MemberType ScriptMethod -Name Success -Value {
            param([string]$Message)

            $this.Buffer.Result = [pscustomobject]@{
                Status = 'Success'
                Message = $Message
            }
            $null = Write-TaskLogState -State $this.State
        }

        Add-Member -InputObject $group -MemberType ScriptMethod -Name Error -Value {
            param([string]$Message)

            $this.Buffer.Result = [pscustomobject]@{
                Status = 'Error'
                Message = $Message
            }
            $null = Write-TaskLogState -State $this.State
        }

        return $group
    }

    Add-Member -InputObject $log -NotePropertyName AppendMessage -NotePropertyValue $appendMessage

    Add-Member -InputObject $log -MemberType ScriptMethod -Name Success -Value {
        param(
            [string]$Message,
            [bool]$ShowLog = $false
        )

        $this.State.Status = 'Success'
        $this.State.FinalMessage = $Message
        $this.State.ShowLog = $ShowLog
        $null = Write-TaskLogState -State $this.State
    }

    Add-Member -InputObject $log -MemberType ScriptMethod -Name Error -Value {
        param(
            [string]$Message,
            [bool]$ShowLog = $true
        )

        $this.State.Status = 'Error'
        $this.State.FinalMessage = $Message
        $this.State.ShowLog = $ShowLog
        $null = Write-TaskLogState -State $this.State
    }

    $null = Write-TaskLogState -State $state
    return $log
}

