function Render-MultiSelectPrompt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$State,

        [Parameter(Mandatory = $true)]
        [hashtable]$Theme
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    $guide = [string]$Theme.Symbols.GuideBar
    $guideActive = [string]$Theme.Symbols.GuideBar
    $guideEnd = [string]$Theme.Symbols.GuideEnd
    $symbol = Get-PromptStateSymbol -Theme $Theme -Status $State.Status
    if (-not $State.SuppressLeadingGuide) {
        $lines.Add($guide)
    }
    foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $symbol) -ContinuationPrefix ('{0}  ' -f $guide) -Text ([string]$State.Message))) {
        $lines.Add($line)
    }

    if ($State.Status -eq 'Submitted') {
        $selectedLabels = @($State.Options | Where-Object Selected | ForEach-Object Label) -join ', '
        foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $guide) -Text (Format-ThemeText -Theme $Theme -Text $selectedLabels -Styles @('Gray')))) {
            $lines.Add($line)
        }
        $lines.Add($guide)
        return $lines.ToArray()
    }

    if ($State.Status -eq 'Cancelled') {
        $selectedLabels = @($State.Options | Where-Object Selected | ForEach-Object Label) -join ', '
        if (-not [string]::IsNullOrWhiteSpace($selectedLabels)) {
            foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $guide) -Text (Format-ThemeText -Theme $Theme -Text $selectedLabels -Styles @('Gray', 'Strike')))) {
                $lines.Add($line)
            }
        }
        $lines.Add($guide)
        return $lines.ToArray()
    }

    $limited = Limit-VisibleOptions -Options $State.Options -ActiveIndex $State.ActiveIndex -MaxItems $State.MaxItems -RowPadding 5
    if ($limited.HasTopOverflow) {
        $lines.Add(('{0}  {1}' -f $guideActive, (Format-ThemeText -Theme $Theme -Text '...' -Styles @('Gray'))))
    }

    foreach ($option in $limited.Items) {
        $index = [Array]::IndexOf([object[]]$State.Options, $option)
        if ($option.Selected) {
            $mark = Format-ThemeText -Theme $Theme -Text ([string]$Theme.Symbols.CheckboxSelected) -Styles @('Green')
        }
        else {
            $mark = Format-ThemeText -Theme $Theme -Text ([string]$Theme.Symbols.CheckboxUnselected) -Styles @('Gray')
        }

        $optionText = if ($index -eq $State.ActiveIndex) {
            [string]$option.Label
        }
        else {
            Format-ThemeText -Theme $Theme -Text ([string]$option.Label) -Styles @('Gray')
        }
        $continuationPrefix = ('{0}  ' -f $guideActive) + ''.PadRight((Get-VisibleTextWidth -Text ('{0} ' -f (Remove-AnsiEscapeSequences -Text $mark))))
        foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $guideActive) -ContinuationPrefix $continuationPrefix -Text ('{0} {1}' -f $mark, $optionText))) {
            $lines.Add($line)
        }
    }

    if ($limited.HasBottomOverflow) {
        $lines.Add(('{0}  {1}' -f $guideActive, (Format-ThemeText -Theme $Theme -Text '...' -Styles @('Gray'))))
    }

    if (-not [string]::IsNullOrWhiteSpace($State.ErrorMessage)) {
        foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $guideEnd) -Text (Format-ThemeText -Theme $Theme -Text $State.ErrorMessage -Styles @('Yellow')))) {
            $lines.Add($line)
        }
    }
    else {
        $lines.Add($guideEnd)
    }

    return $lines.ToArray()
}
