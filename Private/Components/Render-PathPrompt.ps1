function Render-PathPrompt {
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
    $symbol = Get-PromptStateSymbol -Theme $Theme -Status $(if ($State.ErrorMessage) { 'Error' } else { $State.Status })

    if (-not $State.SuppressLeadingGuide) {
        $lines.Add($guide)
    }

    foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $symbol) -ContinuationPrefix ('{0}  ' -f $guide) -Text ([string]$State.Message))) {
        $lines.Add($line)
    }

    $inputPath = [string]$State.Input
    $filtered = @($State.FilteredOptions)

    if ($State.Status -eq 'Submitted') {
        $displayValue = if (-not [string]::IsNullOrWhiteSpace($State.SelectedLabel)) { $State.SelectedLabel } else { $inputPath }
        foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $guide) -Text (Format-ThemeText -Theme $Theme -Text $displayValue -Styles @('Gray')))) {
            $lines.Add($line)
        }

        $lines.Add($guide)
        return $lines.ToArray()
    }

    if ($State.Status -eq 'Cancelled') {
        if (-not [string]::IsNullOrWhiteSpace($inputPath)) {
            foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $guide) -Text (Format-ThemeText -Theme $Theme -Text $inputPath -Styles @('Gray', 'Strike')))) {
                $lines.Add($line)
            }
        }

        $lines.Add($guide)
        return $lines.ToArray()
    }

    $lines.Add($guideActive)

    $cursorBlock = if ($Theme.Plain) { '_' } else { Format-ThemeText -Theme $Theme -Text ' ' -Styles @('Inverse') }
    $pathVisible = if ([string]::IsNullOrEmpty($inputPath)) {
        $cursorBlock
    }
    elseif ($State.IsNavigating) {
        Format-ThemeText -Theme $Theme -Text $inputPath -Styles @('Gray')
    }
    else {
        '{0}{1}' -f $inputPath, $cursorBlock
    }

    $pathLine = '{0}{1}' -f (Format-ThemeText -Theme $Theme -Text 'Path: ' -Styles @('Gray')), $pathVisible
    foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $guideActive) -ContinuationPrefix ('{0}  ' -f $guideActive) -Text $pathLine)) {
        $lines.Add($line)
    }

    $rowPadding = 8
    $limited = Limit-VisibleOptions -Options $filtered -ActiveIndex $State.ActiveIndex -MaxItems $State.MaxItems -RowPadding $rowPadding
    if ($limited.HasTopOverflow) {
        $lines.Add(('{0}  {1}' -f $guideActive, (Format-ThemeText -Theme $Theme -Text '...' -Styles @('Gray'))))
    }

    foreach ($option in $limited.Items) {
        $index = [Array]::IndexOf([object[]]$filtered, $option)
        $isActive = $index -eq $State.ActiveIndex

        $prefix = if ($isActive) {
            Format-ThemeText -Theme $Theme -Text ([string]$Theme.Symbols.RadioActive) -Styles @('Green')
        }
        else {
            Format-ThemeText -Theme $Theme -Text ([string]$Theme.Symbols.RadioInactive) -Styles @('Gray')
        }

        $labelText = [string]$option.Label
        $label = if ($isActive) { $labelText } else { Format-ThemeText -Theme $Theme -Text $labelText -Styles @('Gray') }
        $optionText = '{0} {1}' -f $prefix, $label

        $markPlain = if ($isActive) { [string]$Theme.Symbols.RadioActive } else { [string]$Theme.Symbols.RadioInactive }
        $continuationPrefix = ('{0}  ' -f $guideActive) + ''.PadRight((Get-VisibleTextWidth -Text ('{0} ' -f (Remove-AnsiEscapeSequences -Text $markPlain))))
        foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $guideActive) -ContinuationPrefix $continuationPrefix -Text $optionText)) {
            $lines.Add($line)
        }
    }

    if ($limited.HasBottomOverflow) {
        $lines.Add(('{0}  {1}' -f $guideActive, (Format-ThemeText -Theme $Theme -Text '...' -Styles @('Gray'))))
    }

    if ($filtered.Count -eq 0 -and -not [string]::IsNullOrEmpty($inputPath)) {
        $lines.Add(('{0}  {1}' -f $guideActive, (Format-ThemeText -Theme $Theme -Text 'No matches' -Styles @('Yellow'))))
    }

    $instr = '↑/↓ to select • Tab: accept • Enter: confirm • Type path'
    $lines.Add(('{0}  {1}' -f $guideActive, (Format-ThemeText -Theme $Theme -Text $instr -Styles @('Gray'))))

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
