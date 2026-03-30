function Format-EllipsizedText {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Text = '',

        [int]$MaxWidth = 0
    )

    $safeText = [string]$Text
    if ($MaxWidth -le 0) {
        return ''
    }

    if ((Get-VisibleTextWidth -Text $safeText) -le $MaxWidth) {
        return $safeText
    }

    if ($MaxWidth -eq 1) {
        return '…'
    }

    return '{0}…' -f $safeText.Substring(0, [Math]::Max(0, $MaxWidth - 1))
}

function Format-WrappedLines {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Prefix,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Text,

        [Parameter()]
        [AllowEmptyString()]
        [string]$ContinuationPrefix = $Prefix,

        [Parameter()]
        [int]$Width = (Get-TerminalWidth)
    )

    $availableWidth = [Math]::Max(1, $Width - (Get-VisibleTextWidth -Text $Prefix))
    $words = @([regex]::Split([string]$Text, '\s+') | Where-Object { $_ -ne '' })

    if ($words.Count -eq 0) {
        return @($Prefix)
    }

    $wrapped = [System.Collections.Generic.List[string]]::new()
    $current = ''

    foreach ($word in $words) {
        $remaining = [string]$word

        while ((Get-VisibleTextWidth -Text $remaining) -gt $availableWidth) {
            if (-not [string]::IsNullOrEmpty($current)) {
                $wrapped.Add($current)
                $current = ''
            }

            $chunk = ''
            foreach ($char in $remaining.ToCharArray()) {
                $candidate = '{0}{1}' -f $chunk, $char
                if ((Get-VisibleTextWidth -Text $candidate) -gt $availableWidth) {
                    break
                }
                $chunk = $candidate
            }

            if ([string]::IsNullOrEmpty($chunk)) {
                $chunk = $remaining.Substring(0, 1)
            }

            $wrapped.Add($chunk)
            $remaining = $remaining.Substring($chunk.Length)
        }

        $candidate = if ([string]::IsNullOrEmpty($current)) { $remaining } else { '{0} {1}' -f $current, $remaining }
        if ((Get-VisibleTextWidth -Text $candidate) -le $availableWidth) {
            $current = $candidate
        }
        else {
            $wrapped.Add($current)
            $current = $remaining
        }
    }

    if (-not [string]::IsNullOrEmpty($current)) {
        $wrapped.Add($current)
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    for ($index = 0; $index -lt $wrapped.Count; $index++) {
        $linePrefix = if ($index -eq 0) { $Prefix } else { $ContinuationPrefix }
        $lines.Add(([string]$linePrefix) + ([string]$wrapped[$index]))
    }

    return $lines.ToArray()
}

function Get-RenderedBlockHeight {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Lines,

        [Parameter(Mandatory = $true)]
        [int]$TerminalWidth
    )

    $safeWidth = [Math]::Max(1, [int]$TerminalWidth)
    $totalHeight = 0

    foreach ($line in @($Lines)) {
        $visibleWidth = [int](Get-VisibleTextWidth -Text ([string]$line))
        $wrappedHeight = if ($visibleWidth -le 0) { 1 } else { [int][Math]::Ceiling($visibleWidth / [double]$safeWidth) }
        $totalHeight += [Math]::Max(1, $wrappedHeight)
    }

    return [Math]::Max(1, $totalHeight)
}

function Get-VisibleTextWidth {
    [CmdletBinding()]
    param(
        [AllowEmptyString()]
        [AllowNull()]
        [string]$Text = ''
    )

    $visibleText = [string](Remove-AnsiEscapeSequences -Text $Text)
    return [int]$visibleText.Length
}

function Limit-VisibleOptions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$Options,

        [Parameter(Mandatory = $true)]
        [int]$ActiveIndex,

        [int]$MaxItems = [int]::MaxValue,

        [int]$RowPadding = 4
    )

    $count = @($Options).Count
    if ($count -eq 0) {
        return [pscustomobject]@{
            Items = @()
            HasTopOverflow = $false
            HasBottomOverflow = $false
        }
    }

    $outputMaxItems = [Math]::Max(0, (Get-TerminalHeight) - $RowPadding)
    $computedMaxItems = [Math]::Max([Math]::Min($MaxItems, $outputMaxItems), 5)

    if ($count -le $computedMaxItems) {
        return [pscustomobject]@{
            Items = @($Options)
            HasTopOverflow = $false
            HasBottomOverflow = $false
        }
    }

    $windowStart = 0
    if ($ActiveIndex -ge ($computedMaxItems - 3)) {
        $windowStart = [Math]::Max([Math]::Min($ActiveIndex - $computedMaxItems + 3, $count - $computedMaxItems), 0)
    }

    $windowEnd = [Math]::Min($windowStart + $computedMaxItems, $count)

    return [pscustomobject]@{
        Items = @($Options[$windowStart..($windowEnd - 1)])
        HasTopOverflow = ($windowStart -gt 0)
        HasBottomOverflow = ($windowEnd -lt $count)
    }
}

function Remove-AnsiEscapeSequences {
    [CmdletBinding()]
    param(
        [AllowEmptyString()]
        [AllowNull()]
        [string]$Text = ''
    )

    if ($null -eq $Text) {
        return ''
    }

    return [string]([regex]::Replace($Text, "`e\[[0-9;]*[A-Za-z]", ''))
}
