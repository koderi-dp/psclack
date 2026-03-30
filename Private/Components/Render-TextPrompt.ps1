function Render-TextPrompt {
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

    $submittedValue = [string]$State.Value
    $placeholder = [string]$State.Placeholder
    $cursorBlock = if ($Theme.Plain) { '_' } else { Format-ThemeText -Theme $Theme -Text ' ' -Styles @('Inverse') }

    if ($State.Status -eq 'Cancelled') {
        if (-not [string]::IsNullOrWhiteSpace($submittedValue)) {
            foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $guide) -Text (Format-ThemeText -Theme $Theme -Text $submittedValue -Styles @('Gray', 'Strike')))) {
                $lines.Add($line)
            }
        }
        $lines.Add($guide)
        return $lines.ToArray()
    }

    if ($State.Status -eq 'Submitted') {
        if (-not [string]::IsNullOrWhiteSpace($submittedValue)) {
            foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $guide) -Text (Format-ThemeText -Theme $Theme -Text $submittedValue -Styles @('Gray')))) {
                $lines.Add($line)
            }
        }
        $lines.Add($guide)
        return $lines.ToArray()
    }

    if ([string]::IsNullOrEmpty($submittedValue)) {
        $activeValue = if ([string]::IsNullOrEmpty($placeholder)) { $cursorBlock } else { '{0}{1}' -f (Format-ThemeText -Theme $Theme -Text $placeholder -Styles @('Gray')), $cursorBlock }
    }
    else {
        $activeValue = '{0}{1}' -f $submittedValue, $cursorBlock
    }

    foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $guideActive) -Text $activeValue)) {
        $lines.Add($line)
    }
    if (-not [string]::IsNullOrWhiteSpace($State.ErrorMessage)) {
        $errorText = Format-ThemeText -Theme $Theme -Text $State.ErrorMessage -Styles @('Yellow')
        foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $guideEnd) -Text $errorText)) {
            $lines.Add($line)
        }
    }
    else {
        $lines.Add($guideEnd)
    }

    return $lines.ToArray()
}
