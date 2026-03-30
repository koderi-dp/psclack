function Render-Spinner {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Spinner,

        [Parameter(Mandatory = $true)]
        [hashtable]$Theme
    )

    $guide = Format-ThemeText -Theme $Theme -Text ([string]$Theme.Symbols.GuideBar) -Styles @('Gray')
    $message = if ([string]::IsNullOrWhiteSpace($Spinner.FinalMessage)) { $Spinner.Message } else { $Spinner.FinalMessage }
    $includeGuide = $Spinner.PSObject.Properties.Name -contains 'ContinueTranscript' -and [bool]$Spinner.ContinueTranscript
    if ($includeGuide -and $Spinner.PSObject.Properties.Name -contains 'SuppressLeadingGuide' -and [bool]$Spinner.SuppressLeadingGuide) {
        $includeGuide = $false
    }
    $isProgress = $Spinner.PSObject.Properties.Name -contains 'Mode' -and [string]$Spinner.Mode -eq 'Progress'

    if ($isProgress -and $Spinner.Status -eq 'Running') {
        $progressChar = switch ([string]$Spinner.ProgressStyle) {
            'Light' { '─' }
            'Block' { '█' }
            default { '━' }
        }

        $indicator = Format-ThemeText -Theme $Theme -Text ([string]$Spinner.Frames[$Spinner.FrameIndex]) -Styles @('Magenta')
        $progressValue = [int]$Spinner.ProgressValue
        $progressMax = [int][Math]::Max(1, $Spinner.ProgressMax)
        $configuredProgressSize = [int][Math]::Max(1, $Spinner.ProgressSize)
        $minimumProgressSize = if ($Spinner.PSObject.Properties.Name -contains 'ProgressMinSize') { [int][Math]::Max(4, $Spinner.ProgressMinSize) } else { 12 }
        $progressMessage = [string]$Spinner.ProgressMessage
        $terminalWidth = Get-TerminalWidth
        $prefixWidth = Get-VisibleTextWidth -Text ('{0}  ' -f $indicator)
        $spaceAfterBar = 1
        $messageWidth = Get-VisibleTextWidth -Text $progressMessage
        $availableForContent = [Math]::Max($minimumProgressSize, $terminalWidth - $prefixWidth)
        $progressSize = [int][Math]::Min($configuredProgressSize, [Math]::Max($minimumProgressSize, $availableForContent - $spaceAfterBar - $messageWidth))
        $availableForMessage = [Math]::Max(0, $availableForContent - $progressSize - $spaceAfterBar)
        if ($messageWidth -gt $availableForMessage) {
            $progressMessage = Format-EllipsizedText -Text $progressMessage -MaxWidth $availableForMessage
        }

        $activeCount = [int][Math]::Floor(($progressValue / $progressMax) * $progressSize)
        $inactiveCount = [int][Math]::Max(0, $progressSize - $activeCount)
        $activeBar = if ($activeCount -gt 0) { Format-ThemeText -Theme $Theme -Text ($progressChar * $activeCount) -Styles @('Magenta') } else { '' }
        $inactiveBar = if ($inactiveCount -gt 0) { Format-ThemeText -Theme $Theme -Text ($progressChar * $inactiveCount) -Styles @('Dim') } else { '' }
        $progressText = '{0}{1} {2}' -f $activeBar, $inactiveBar, $progressMessage

        $lines = [System.Collections.Generic.List[string]]::new()
        if ($includeGuide) {
            $lines.Add($guide)
        }
        foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $indicator) -ContinuationPrefix ('{0}  ' -f $guide) -Text $progressText)) {
            $lines.Add($line)
        }
        Write-Output -NoEnumerate ([string[]]$lines.ToArray())
        return
    }

    switch ($Spinner.Status) {
        'Running' {
            $symbol = Format-ThemeText -Theme $Theme -Text ([string]$Spinner.Frames[$Spinner.FrameIndex]) -Styles @('Blue')
            $lines = [System.Collections.Generic.List[string]]::new()
            if ($includeGuide) {
                $lines.Add($guide)
            }
            foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $symbol) -ContinuationPrefix ('{0}  ' -f $guide) -Text ([string]$Spinner.Message))) {
                $lines.Add($line)
            }
            Write-Output -NoEnumerate ([string[]]$lines.ToArray())
            return
        }
        'Success' {
            $symbol = Format-ThemeText -Theme $Theme -Text ([string]$Theme.Symbols.StepSubmit) -Styles @('Green')
            $lines = [System.Collections.Generic.List[string]]::new()
            if ($includeGuide) {
                $lines.Add($guide)
            }
            foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $symbol) -ContinuationPrefix ('{0}  ' -f $guide) -Text ([string]$message))) {
                $lines.Add($line)
            }
            Write-Output -NoEnumerate ([string[]]$lines.ToArray())
            return
        }
        'Cancelled' {
            $symbol = Format-ThemeText -Theme $Theme -Text ([string]$Theme.Symbols.StepCancel) -Styles @('Red')
            $lines = [System.Collections.Generic.List[string]]::new()
            if ($includeGuide) {
                $lines.Add($guide)
            }
            foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $symbol) -ContinuationPrefix ('{0}  ' -f $guide) -Text ([string]$message))) {
                $lines.Add($line)
            }
            Write-Output -NoEnumerate ([string[]]$lines.ToArray())
            return
        }
        'Error' {
            $symbol = Format-ThemeText -Theme $Theme -Text ([string]$Theme.Symbols.StepError) -Styles @('Yellow')
            $lines = [System.Collections.Generic.List[string]]::new()
            if ($includeGuide) {
                $lines.Add($guide)
            }
            foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $symbol) -ContinuationPrefix ('{0}  ' -f $guide) -Text ([string]$message))) {
                $lines.Add($line)
            }
            Write-Output -NoEnumerate ([string[]]$lines.ToArray())
            return
        }
        default {
            $lines = [System.Collections.Generic.List[string]]::new()
            if ($includeGuide) {
                $lines.Add($guide)
            }
            $lines.Add([string]$Spinner.Message)
            Write-Output -NoEnumerate ([string[]]$lines.ToArray())
            return
        }
    }
}
