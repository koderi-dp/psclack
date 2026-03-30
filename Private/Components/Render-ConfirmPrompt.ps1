function Render-ConfirmPrompt {
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
        $selected = if ($State.Value) { 'Yes' } else { 'No' }
        foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $guide) -Text (Format-ThemeText -Theme $Theme -Text $selected -Styles @('Gray')))) {
            $lines.Add($line)
        }
        $lines.Add($guide)
        return $lines.ToArray()
    }

    if ($State.Status -eq 'Cancelled') {
        $selected = if ($State.CurrentChoice) { 'Yes' } else { 'No' }
        foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $guide) -Text (Format-ThemeText -Theme $Theme -Text $selected -Styles @('Gray', 'Strike')))) {
            $lines.Add($line)
        }
        $lines.Add($guide)
        return $lines.ToArray()
    }

    $yesPrefix = if ($State.CurrentChoice) {
        Format-ThemeText -Theme $Theme -Text ([string]$Theme.Symbols.RadioActive) -Styles @('Green')
    }
    else {
        Format-ThemeText -Theme $Theme -Text ([string]$Theme.Symbols.RadioInactive) -Styles @('Gray')
    }

    $noPrefix = if ($State.CurrentChoice) {
        Format-ThemeText -Theme $Theme -Text ([string]$Theme.Symbols.RadioInactive) -Styles @('Gray')
    }
    else {
        Format-ThemeText -Theme $Theme -Text ([string]$Theme.Symbols.RadioActive) -Styles @('Green')
    }

    $yesText = if ($State.CurrentChoice) { 'Yes' } else { Format-ThemeText -Theme $Theme -Text 'Yes' -Styles @('Gray') }
    $noText = if ($State.CurrentChoice) { Format-ThemeText -Theme $Theme -Text 'No' -Styles @('Gray') } else { 'No' }
    $activeText = '{0} {1} / {2} {3}' -f $yesPrefix, $yesText, $noPrefix, $noText
    $continuationPrefix = ('{0}  ' -f $guideActive) + ''.PadRight((Get-VisibleTextWidth -Text ('{0} ' -f (Remove-AnsiEscapeSequences -Text $yesPrefix))))
    foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $guideActive) -ContinuationPrefix $continuationPrefix -Text $activeText)) {
        $lines.Add($line)
    }
    $lines.Add($guideEnd)
    return $lines.ToArray()
}
