function Render-TaskLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$State
    )

    $theme = $State.Theme
    $guide = Format-ThemeText -Theme $theme -Text ([string]$theme.Symbols.GuideBar) -Styles @('Gray')
    $titleSymbol = Format-ThemeText -Theme $theme -Text ([string]$theme.Symbols.StepSubmit) -Styles @('Green')

    $lines = [System.Collections.Generic.List[string]]::new()

    if ($State.Status -eq 'Active') {
        $lines.Add($guide)
        $lines.Add(('{0}  {1}' -f $titleSymbol, [string]$State.Title))
        for ($i = 0; $i -lt [int]$State.Spacing; $i++) {
            $lines.Add($guide)
        }
    }
    else {
        $statusStyles = switch ($State.Status) {
            'Success' { @('Green') }
            'Error' { @('Yellow') }
            default { @() }
        }
        $statusSymbolText = switch ($State.Status) {
            'Success' { [string]$theme.Symbols.StepSubmit }
            'Error' { [string]$theme.Symbols.StepError }
            default { [string]$theme.Symbols.StepSubmit }
        }
        $statusSymbol = Format-ThemeText -Theme $theme -Text $statusSymbolText -Styles $statusStyles
        $finalMessage = if ([string]::IsNullOrWhiteSpace([string]$State.FinalMessage)) { [string]$State.Title } else { [string]$State.FinalMessage }

        foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $statusSymbol) -ContinuationPrefix ('{0}  ' -f $guide) -Text $finalMessage)) {
            $lines.Add($line)
        }

        if (-not $State.ShowLog) {
            return $lines.ToArray()
        }

        $lines.Add($guide)
    }

    foreach ($buffer in @($State.Buffers)) {
        $bufferLines = if ($State.RetainLog) {
            @($buffer.FullLines) + @($buffer.Lines)
        }
        else {
            @($buffer.Lines)
        }

        if ($buffer.Result) {
            $resultStyles = if ($buffer.Result.Status -eq 'Error') { @('Yellow') } else { @('Green') }
            $resultSymbolText = if ($buffer.Result.Status -eq 'Error') { [string]$theme.Symbols.StepError } else { [string]$theme.Symbols.StepSubmit }
            $resultSymbol = Format-ThemeText -Theme $theme -Text $resultSymbolText -Styles $resultStyles
            foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $resultSymbol) -ContinuationPrefix ('{0}  ' -f $guide) -Text ([string]$buffer.Result.Message))) {
                $lines.Add($line)
            }
            continue
        }

        if (-not [string]::IsNullOrWhiteSpace([string]$buffer.Header)) {
            $lines.Add(('{0}  {1}' -f $guide, [string]$buffer.Header))
        }

        foreach ($bufferLine in $bufferLines) {
            $formattedText = Format-ThemeText -Theme $theme -Text ([string]$bufferLine) -Styles @('Dim')
            foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $guide) -ContinuationPrefix ('{0}  ' -f $guide) -Text $formattedText)) {
                $lines.Add($line)
            }
        }
    }

    return $lines.ToArray()
}
