function Render-AutocompletePrompt {
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

    $search = [string]$State.Search
    $placeholder = [string]$State.Placeholder
    $showPlaceholder = [string]::IsNullOrEmpty($search) -and -not [string]::IsNullOrEmpty($placeholder)
    $allCount = @($State.AllOptions).Count
    $filtered = @($State.FilteredOptions)
    $filteredCount = $filtered.Count

    if ($State.Status -eq 'Submitted') {
        if ($State.Multiple) {
            $summary = '{0} items selected' -f @([object[]]$State.Value).Count
            foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $guide) -Text (Format-ThemeText -Theme $Theme -Text $summary -Styles @('Gray')))) {
                $lines.Add($line)
            }
        }
        elseif (-not [string]::IsNullOrWhiteSpace($State.SelectedLabel)) {
            foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $guide) -Text (Format-ThemeText -Theme $Theme -Text $State.SelectedLabel -Styles @('Gray')))) {
                $lines.Add($line)
            }
        }

        $lines.Add($guide)
        return $lines.ToArray()
    }

    if ($State.Status -eq 'Cancelled') {
        if (-not [string]::IsNullOrWhiteSpace($search)) {
            foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $guide) -Text (Format-ThemeText -Theme $Theme -Text $search -Styles @('Gray', 'Strike')))) {
                $lines.Add($line)
            }
        }

        $lines.Add($guide)
        return $lines.ToArray()
    }

    $lines.Add($guideActive)

    $cursorBlock = if ($Theme.Plain) { '_' } else { Format-ThemeText -Theme $Theme -Text ' ' -Styles @('Inverse') }
    $searchVisible = if ($showPlaceholder) {
        '{0}{1}' -f (Format-ThemeText -Theme $Theme -Text $placeholder -Styles @('Gray')), $(if ($State.IsNavigating) { '' } else { $cursorBlock })
    }
    elseif ($State.IsNavigating) {
        if ([string]::IsNullOrEmpty($search)) {
            $cursorBlock
        }
        else {
            Format-ThemeText -Theme $Theme -Text $search -Styles @('Gray')
        }
    }
    else {
        if ([string]::IsNullOrEmpty($search)) {
            $cursorBlock
        }
        else {
            '{0}{1}' -f $search, $cursorBlock
        }
    }

    $matchSuffix = ''
    if ($filteredCount -ne $allCount) {
        $word = if ($filteredCount -eq 1) { 'match' } else { 'matches' }
        $matchSuffix = ' ({0} {1})' -f $filteredCount, $word
    }

    $matchStyled = if ([string]::IsNullOrEmpty($matchSuffix)) {
        ''
    }
    else {
        Format-ThemeText -Theme $Theme -Text $matchSuffix -Styles @('Gray')
    }

    $searchLine = '{0}{1}{2}' -f (Format-ThemeText -Theme $Theme -Text 'Search: ' -Styles @('Gray')), $searchVisible, $matchStyled
    foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $guideActive) -ContinuationPrefix ('{0}  ' -f $guideActive) -Text $searchLine)) {
        $lines.Add($line)
    }

    if ($filteredCount -eq 0 -and -not [string]::IsNullOrEmpty($search)) {
        $lines.Add(('{0}  {1}' -f $guideActive, (Format-ThemeText -Theme $Theme -Text 'No matches found' -Styles @('Yellow'))))
    }

    $rowPadding = 10
    $limited = Limit-VisibleOptions -Options $filtered -ActiveIndex $State.ActiveIndex -MaxItems $State.MaxItems -RowPadding $rowPadding
    if ($limited.HasTopOverflow) {
        $lines.Add(('{0}  {1}' -f $guideActive, (Format-ThemeText -Theme $Theme -Text '...' -Styles @('Gray'))))
    }

    # Budget: '│  ' (3) + mark (1) + ' ' (1) = 5 visible prefix chars; reserve 1 extra for safety
    $maxLabelWidth = [Math]::Max(10, (Get-TerminalWidth) - 6)

    foreach ($option in $limited.Items) {
        $index = [Array]::IndexOf([object[]]$filtered, $option)
        $hint = if ([string]::IsNullOrWhiteSpace($option.Hint)) {
            ''
        }
        elseif ($State.FocusedValue -eq $option.Value) {
            ' {0}' -f (Format-ThemeText -Theme $Theme -Text ('({0})' -f $option.Hint) -Styles @('Gray'))
        }
        else {
            ''
        }

        # Truncate from the left so the tail (e.g. filename) stays visible
        $rawLabel = [string]$option.Label
        if ($rawLabel.Length -gt $maxLabelWidth) {
            $rawLabel = '...' + $rawLabel.Substring($rawLabel.Length - ($maxLabelWidth - 3))
        }

        if ($State.Multiple) {
            $isSelected = @([object[]]$State.SelectedValues) -contains $option.Value
            if ($option.Disabled) {
                $mark = Format-ThemeText -Theme $Theme -Text ([string]$Theme.Symbols.CheckboxUnselected) -Styles @('Gray')
                $label = Format-ThemeText -Theme $Theme -Text $rawLabel -Styles @('Gray', 'Strike')
            }
            elseif ($isSelected) {
                $mark = Format-ThemeText -Theme $Theme -Text ([string]$Theme.Symbols.CheckboxSelected) -Styles @('Green')
                $label = if ($index -eq $State.ActiveIndex) { $rawLabel } else { Format-ThemeText -Theme $Theme -Text $rawLabel -Styles @('Gray') }
            }
            else {
                $mark = Format-ThemeText -Theme $Theme -Text ([string]$Theme.Symbols.CheckboxUnselected) -Styles @('Gray')
                $label = if ($index -eq $State.ActiveIndex) { $rawLabel } else { Format-ThemeText -Theme $Theme -Text $rawLabel -Styles @('Gray') }
            }

            $optionText = '{0} {1}{2}' -f $mark, $label, $hint
        }
        else {
            if ($option.Disabled) {
                $prefix = Format-ThemeText -Theme $Theme -Text ([string]$Theme.Symbols.RadioInactive) -Styles @('Gray')
                $label = Format-ThemeText -Theme $Theme -Text $rawLabel -Styles @('Gray', 'Strike')
            }
            elseif ($index -eq $State.ActiveIndex) {
                $prefix = Format-ThemeText -Theme $Theme -Text ([string]$Theme.Symbols.RadioActive) -Styles @('Green')
                $label = $rawLabel
            }
            else {
                $prefix = Format-ThemeText -Theme $Theme -Text ([string]$Theme.Symbols.RadioInactive) -Styles @('Gray')
                $label = Format-ThemeText -Theme $Theme -Text $rawLabel -Styles @('Gray')
            }

            $optionText = '{0} {1}{2}' -f $prefix, $label, $hint
        }

        $markPlain = if ($State.Multiple) {
            if ($option.Disabled) { [string]$Theme.Symbols.CheckboxUnselected } elseif (@([object[]]$State.SelectedValues) -contains $option.Value) { [string]$Theme.Symbols.CheckboxSelected } else { [string]$Theme.Symbols.CheckboxUnselected }
        }
        else {
            if ($option.Disabled) { [string]$Theme.Symbols.RadioInactive } elseif ($index -eq $State.ActiveIndex) { [string]$Theme.Symbols.RadioActive } else { [string]$Theme.Symbols.RadioInactive }
        }

        $continuationPrefix = ('{0}  ' -f $guideActive) + ''.PadRight((Get-VisibleTextWidth -Text ('{0} ' -f (Remove-AnsiEscapeSequences -Text $markPlain))))
        foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $guideActive) -ContinuationPrefix $continuationPrefix -Text $optionText)) {
            $lines.Add($line)
        }
    }

    if ($limited.HasBottomOverflow) {
        $lines.Add(('{0}  {1}' -f $guideActive, (Format-ThemeText -Theme $Theme -Text '...' -Styles @('Gray'))))
    }

    if ($State.Multiple) {
        $instr = if ($State.IsNavigating) {
            '↑/↓ to navigate • Space/Tab: select • Enter: confirm • Type: to search'
        }
        else {
            '↑/↓ to navigate • Tab: select • Enter: confirm • Type: to search'
        }
    }
    else {
        $instr = '↑/↓ to select • Enter: confirm • Type: to search'
    }

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
