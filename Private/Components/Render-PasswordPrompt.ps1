function Render-PasswordPrompt {
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
    $mask = if ([string]::IsNullOrEmpty([string]$State.Mask)) { [string]$Theme.Symbols.PasswordMask } else { [string]$State.Mask }

    if (-not $State.SuppressLeadingGuide) {
        $lines.Add($guide)
    }
    foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $symbol) -ContinuationPrefix ('{0}  ' -f $guide) -Text ([string]$State.Message))) {
        $lines.Add($line)
    }

    $maskedValue = if ([string]::IsNullOrEmpty([string]$State.Value)) {
        ''
    }
    else {
        $mask * ([string]$State.Value).Length
    }

    $cursorBlock = if ($Theme.Plain) { '_' } else { Format-ThemeText -Theme $Theme -Text ' ' -Styles @('Inverse') }

    if ($State.Status -eq 'Cancelled') {
        if (-not [string]::IsNullOrEmpty($maskedValue)) {
            foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $guide) -Text (Format-ThemeText -Theme $Theme -Text $maskedValue -Styles @('Gray', 'Strike')))) {
                $lines.Add($line)
            }
        }
        $lines.Add($guide)
        return $lines.ToArray()
    }

    if ($State.Status -eq 'Submitted') {
        if (-not [string]::IsNullOrEmpty($maskedValue)) {
            foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $guide) -Text (Format-ThemeText -Theme $Theme -Text $maskedValue -Styles @('Gray')))) {
                $lines.Add($line)
            }
        }
        $lines.Add($guide)
        return $lines.ToArray()
    }

    $displayValue = if (-not [string]::IsNullOrEmpty([string]$State.ErrorDisplayValue)) {
        [string]$State.ErrorDisplayValue
    }
    elseif (-not [string]::IsNullOrEmpty($maskedValue)) {
        $maskedValue
    }
    elseif (-not [string]::IsNullOrEmpty([string]$State.Placeholder)) {
        Format-ThemeText -Theme $Theme -Text ([string]$State.Placeholder) -Styles @('Gray')
    }
    else {
        ''
    }

    $activeValue = '{0}{1}' -f $displayValue, $cursorBlock
    foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $guideActive) -Text $activeValue)) {
        $lines.Add($line)
    }

    if (-not [string]::IsNullOrWhiteSpace($State.ErrorMessage)) {
        $errorText = Format-ThemeText -Theme $Theme -Text ([string]$State.ErrorMessage) -Styles @('Yellow')
        foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $guideEnd) -Text $errorText)) {
            $lines.Add($line)
        }
    }
    else {
        $lines.Add($guideEnd)
    }

    return $lines.ToArray()
}
