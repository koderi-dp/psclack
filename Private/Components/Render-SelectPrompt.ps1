function Render-SelectPrompt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$State,

        [Parameter(Mandatory = $true)]
        [hashtable]$Theme
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    $guide = Format-ThemeText -Theme $Theme -Text ([string]$Theme.Symbols.GuideBar) -Styles @('Gray')
    $guideActive = Format-ThemeText -Theme $Theme -Text ([string]$Theme.Symbols.GuideBar) -Styles @('Blue')
    $guideEnd = Format-ThemeText -Theme $Theme -Text ([string]$Theme.Symbols.GuideEnd) -Styles @('Blue')
    $symbol = Get-PromptStateSymbol -Theme $Theme -Status $State.Status
    if (-not $State.SuppressLeadingGuide) {
        $lines.Add($guide)
    }
    foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $symbol) -ContinuationPrefix ('{0}  ' -f $guide) -Text ([string]$State.Message))) {
        $lines.Add($line)
    }

    if ($State.Status -eq 'Submitted') {
        foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $guide) -Text (Format-ThemeText -Theme $Theme -Text $State.SelectedLabel -Styles @('Gray')))) {
            $lines.Add($line)
        }
        $lines.Add($guide)
        return $lines.ToArray()
    }

    if ($State.Status -eq 'Cancelled') {
        $cancelledLabel = [string]$State.Options[$State.ActiveIndex].Label
        foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $guide) -Text (Format-ThemeText -Theme $Theme -Text $cancelledLabel -Styles @('Gray', 'Strike')))) {
            $lines.Add($line)
        }
        $lines.Add($guide)
        return $lines.ToArray()
    }

    $limited = Limit-VisibleOptions -Options $State.Options -ActiveIndex $State.ActiveIndex -MaxItems $State.MaxItems -RowPadding 4
    if ($limited.HasTopOverflow) {
        $lines.Add(('{0}  {1}' -f $guideActive, (Format-ThemeText -Theme $Theme -Text '...' -Styles @('Gray'))))
    }

    foreach ($option in $limited.Items) {
        $index = [Array]::IndexOf([object[]]$State.Options, $option)
        $hint = if ([string]::IsNullOrWhiteSpace($option.Hint)) { '' } else { ' {0}' -f (Format-ThemeText -Theme $Theme -Text ('({0})' -f $option.Hint) -Styles @('Gray')) }
        if ($index -eq $State.ActiveIndex) {
            $prefix = Format-ThemeText -Theme $Theme -Text ([string]$Theme.Symbols.RadioActive) -Styles @('Green')
            $label = [string]$option.Label
        }
        else {
            $prefix = Format-ThemeText -Theme $Theme -Text ([string]$Theme.Symbols.RadioInactive) -Styles @('Gray')
            $label = Format-ThemeText -Theme $Theme -Text ([string]$option.Label) -Styles @('Gray')
        }
        $optionText = '{0} {1}{2}' -f $prefix, $label, $hint
        $continuationPrefix = ('{0}  ' -f $guideActive) + ''.PadRight((Get-VisibleTextWidth -Text ('{0} ' -f (Remove-AnsiEscapeSequences -Text $prefix))))
        foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $guideActive) -ContinuationPrefix $continuationPrefix -Text $optionText)) {
            $lines.Add($line)
        }
    }

    if ($limited.HasBottomOverflow) {
        $lines.Add(('{0}  {1}' -f $guideActive, (Format-ThemeText -Theme $Theme -Text '...' -Styles @('Gray'))))
    }

    $lines.Add($guideEnd)
    return $lines.ToArray()
}
