function Show-PsClackIntro {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [switch]$Plain,

        [switch]$PassThru
    )

    $theme = Get-Theme -Plain:$Plain
    Reset-PsClackTranscript
    Complete-PsClackTranscriptBlock -BlockType Intro
    $start = Format-ThemeText -Theme $theme -Text ([string]$theme.Symbols.GuideStart) -Styles @('Gray')
    $title = if ($theme.Plain) { ' {0} ' -f $Message } else { Format-ThemeText -Theme $theme -Text (' {0} ' -f $Message) -Styles @('Inverse') }
    $line = '{0}  {1}' -f $start, $title
    if (Test-InteractiveConsole) { [Console]::WriteLine() }
    $rendered = Write-StaticFrame -Lines @($line) -NoRender:(-not (Test-InteractiveConsole))

    if ($PassThru) {
        return $rendered
    }
}

function Show-PsClackOutro {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('Success', 'Info', 'Cancel', 'Error')]
        [string]$Status = 'Success',

        [switch]$Plain,

        [switch]$PassThru
    )

    $theme = Get-Theme -Plain:$Plain
    $blockContext = Get-PsClackTranscriptBlockContext -BlockType Outro
    $suppressLeadingGuide = [bool]$blockContext.SuppressLeadingGuide
    $styles = switch ($Status) {
        'Success' { @() }
        'Info' { @('Dim') }
        'Cancel' { @('Red') }
        'Error' { @('Yellow') }
    }

    $guide = Format-ThemeText -Theme $theme -Text ([string]$theme.Symbols.GuideBar) -Styles @('Gray')
    $end = Format-ThemeText -Theme $theme -Text ([string]$theme.Symbols.GuideEnd) -Styles @('Gray')
    $messageText = Format-ThemeText -Theme $theme -Text $Message -Styles $styles
    $lines = [System.Collections.Generic.List[string]]::new()

    if ($Status -in @('Cancel', 'Error')) {
        foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $end) -ContinuationPrefix ('{0}  ' -f $guide) -Text $messageText)) {
            $lines.Add($line)
        }
    }
    else {
        if (-not $suppressLeadingGuide) {
            $lines.Add($guide)
        }
        foreach ($line in (Format-WrappedLines -Prefix ('{0}  ' -f $end) -ContinuationPrefix ('{0}  ' -f $guide) -Text $messageText)) {
            $lines.Add($line)
        }
    }
    $rendered = Write-StaticFrame -Lines $lines.ToArray() -NoRender:(-not (Test-InteractiveConsole))
    if (Test-InteractiveConsole) { [Console]::WriteLine() }
    Complete-PsClackTranscriptBlock -BlockType Outro -Status $Status

    if ($PassThru) {
        return $rendered
    }
}

function Show-PsClackCancel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [switch]$Plain,

        [switch]$PassThru
    )

    return Show-PsClackOutro -Message $Message -Status Cancel -Plain:$Plain -PassThru:$PassThru
}

function Show-PsClackBox {
    [CmdletBinding()]
    param(
        [AllowEmptyString()]
        [string]$Message = '',

        [string]$Title = '',

        [ValidateSet('Left', 'Center', 'Right')]
        [string]$ContentAlign = 'Left',

        [ValidateSet('Left', 'Center', 'Right')]
        [string]$TitleAlign = 'Left',

        [AllowNull()]
        [object]$Width = 'Auto',

        [int]$TitlePadding = 1,

        [int]$ContentPadding = 2,

        [ValidateSet('Gray', 'Blue', 'Cyan', 'Green', 'Red', 'Yellow')]
        [string]$BorderColor = 'Gray',

        [ValidateSet('Default', 'Gray', 'Blue', 'Cyan', 'Green', 'Red', 'Yellow', 'Dim')]
        [string]$TitleColor = 'Default',

        [ValidateSet('Default', 'Gray', 'Blue', 'Cyan', 'Green', 'Red', 'Yellow', 'Dim')]
        [string]$TextColor = 'Default',

        [switch]$Rounded,

        [switch]$Plain,

        [switch]$PassThru
    )

    $theme = Get-Theme -Plain:$Plain
    $blockContext = Get-PsClackTranscriptBlockContext -BlockType Static
    $suppressLeadingGuide = [bool]$blockContext.SuppressLeadingGuide
    $borderStyles = @($BorderColor)
    $titleStyles = if ($TitleColor -eq 'Default') { @() } else { @($TitleColor) }
    $textStyles = if ($TextColor -eq 'Default') { @() } else { @($TextColor) }
    $guide = Format-ThemeText -Theme $theme -Text ([string]$theme.Symbols.GuideBar) -Styles @('Gray')
    $horizontal = '─'
    $vertical = '│'
    $styledVertical = Format-ThemeText -Theme $theme -Text $vertical -Styles $borderStyles

    if ($Rounded) {
        $topLeft = '╭'
        $topRight = '╮'
        $bottomLeft = '╰'
        $bottomRight = '╯'
    }
    else {
        $topLeft = '┌'
        $topRight = '┐'
        $bottomLeft = '└'
        $bottomRight = '┘'
    }

    $linePrefix = $guide + ' '
    $linePrefixWidth = Get-VisibleTextWidth -Text $linePrefix
    $terminalWidth = Get-TerminalWidth
    $maxBoxWidth = [Math]::Max(3, $terminalWidth - $linePrefixWidth)
    $autoWidthCap = [Math]::Max(24, [Math]::Floor($maxBoxWidth * 0.92))

    $requestedBoxWidth = $maxBoxWidth
    $autoWidthRequested = [string]::Equals([string]$Width, 'Auto', [System.StringComparison]::OrdinalIgnoreCase)
    if ($null -ne $Width -and -not [string]::Equals([string]$Width, 'Auto', [System.StringComparison]::OrdinalIgnoreCase)) {
        if ($Width -is [int] -or $Width -is [long]) {
            $requestedBoxWidth = [int]$Width
        }
        elseif ($Width -is [double] -or $Width -is [single] -or $Width -is [decimal]) {
            $numericWidth = [double]$Width
            if ($numericWidth -gt 0 -and $numericWidth -le 1) {
                $requestedBoxWidth = [Math]::Floor($terminalWidth * $numericWidth) - $linePrefixWidth
            }
            else {
                $requestedBoxWidth = [Math]::Floor($numericWidth)
            }
        }
        else {
            throw "Unsupported -Width value '$Width'. Use 'Auto', an integer column width, or a fractional width between 0 and 1."
        }
    }

    if ($requestedBoxWidth -lt 3) {
        $requestedBoxWidth = 3
    }
    if ($autoWidthRequested) {
        $requestedBoxWidth = $autoWidthCap
    }
    $requestedBoxWidth = [Math]::Min($requestedBoxWidth, $maxBoxWidth)

    $contentWrapWidth = [Math]::Max(1, $requestedBoxWidth - 2 - ($ContentPadding * 2))
    $contentLines = [System.Collections.Generic.List[string]]::new()
    $paragraphs = [regex]::Split([string]$Message, "\r?\n")
    foreach ($paragraph in $paragraphs) {
        $wrappedParagraph = @(Format-WrappedLines -Prefix '' -ContinuationPrefix '' -Text ([string]$paragraph) -Width $contentWrapWidth)
        if ($wrappedParagraph.Count -eq 0) {
            $contentLines.Add('')
            continue
        }

        foreach ($wrappedLine in $wrappedParagraph) {
            $contentLines.Add([string]$wrappedLine)
        }
    }

    if ($contentLines.Count -eq 0) {
        $contentLines.Add('')
    }

    $contentWidth = 0
    foreach ($line in $contentLines) {
        $contentWidth = [Math]::Max($contentWidth, (Get-VisibleTextWidth -Text ([string]$line)))
    }

    $titleWidth = if ([string]::IsNullOrEmpty($Title)) { 0 } else { $Title.Length }
    $autoInnerWidth = [Math]::Max([Math]::Max(($contentWidth + ($ContentPadding * 2)), ($titleWidth + ($TitlePadding * 2))), 1)
    $innerWidth = if ($autoWidthRequested) {
        [Math]::Min($autoInnerWidth, [Math]::Max(1, $autoWidthCap - 2))
    }
    else {
        [Math]::Max(1, $requestedBoxWidth - 2)
    }

    function Get-BoxPadding {
        param(
            [int]$LineLength,
            [int]$Width,
            [int]$Padding,
            [string]$Align
        )

        $leftPadding = $Padding
        if ($Align -eq 'Center') {
            $leftPadding = [Math]::Floor(($Width - $LineLength) / 2)
        }
        elseif ($Align -eq 'Right') {
            $leftPadding = $Width - $LineLength - $Padding
        }

        if ($leftPadding -lt 0) {
            $leftPadding = 0
        }

        $rightPadding = $Width - $leftPadding - $LineLength
        if ($rightPadding -lt 0) {
            $rightPadding = 0
        }

        return @($leftPadding, $rightPadding)
    }

    $styledTopLeft = Format-ThemeText -Theme $theme -Text $topLeft -Styles $borderStyles
    $styledTopRight = Format-ThemeText -Theme $theme -Text $topRight -Styles $borderStyles
    $styledBottomLeft = Format-ThemeText -Theme $theme -Text $bottomLeft -Styles $borderStyles
    $styledBottomRight = Format-ThemeText -Theme $theme -Text $bottomRight -Styles $borderStyles
    $titlePaddingValues = Get-BoxPadding -LineLength $titleWidth -Width $innerWidth -Padding $TitlePadding -Align $TitleAlign
    $styledTitle = Format-ThemeText -Theme $theme -Text ([string]$Title) -Styles $titleStyles
    $topBorder = $styledTopLeft + ([string]::new($horizontal, [int]$titlePaddingValues[0]) | ForEach-Object { Format-ThemeText -Theme $theme -Text $_ -Styles $borderStyles }) + $styledTitle + ([string]::new($horizontal, [int]$titlePaddingValues[1]) | ForEach-Object { Format-ThemeText -Theme $theme -Text $_ -Styles $borderStyles }) + $styledTopRight

    $lines = [System.Collections.Generic.List[string]]::new()
    if (-not $suppressLeadingGuide) {
        $lines.Add($guide)
    }
    $lines.Add($linePrefix + $topBorder)

    foreach ($rawLine in $contentLines) {
        $lineText = [string]$rawLine
        $paddingValues = Get-BoxPadding -LineLength (Get-VisibleTextWidth -Text $lineText) -Width $innerWidth -Padding $ContentPadding -Align $ContentAlign
        $formattedLine = Format-ThemeText -Theme $theme -Text $lineText -Styles $textStyles
        $row = $styledVertical + (' ' * [int]$paddingValues[0]) + $formattedLine + (' ' * [int]$paddingValues[1]) + $styledVertical
        $lines.Add($linePrefix + $row)
    }

    $bottomBorder = $styledBottomLeft + (Format-ThemeText -Theme $theme -Text ([string]::new($horizontal, $innerWidth)) -Styles $borderStyles) + $styledBottomRight
    $lines.Add($linePrefix + $bottomBorder)

    $rendered = Write-StaticFrame -Lines $lines.ToArray() -NoRender:(-not (Test-InteractiveConsole))
    Complete-PsClackTranscriptBlock -BlockType Static

    if ($PassThru) {
        return $rendered
    }
}

function Show-PsClackNote {
    [CmdletBinding()]
    param(
        [AllowEmptyString()]
        [string]$Message = '',

        [string]$Title = '',

        [switch]$Plain,

        [switch]$PassThru
    )

    $theme = Get-Theme -Plain:$Plain
    $blockContext = Get-PsClackTranscriptBlockContext -BlockType Static
    $suppressLeadingGuide = [bool]$blockContext.SuppressLeadingGuide
    $guide = Format-ThemeText -Theme $theme -Text ([string]$theme.Symbols.GuideBar) -Styles @('Gray')
    $step = Format-ThemeText -Theme $theme -Text ([string]$theme.Symbols.StepSubmit) -Styles @('Green')
    $horizontal = '─'
    $topRight = '╮'
    $bottomRight = '╯'
    $connectorLeft = '├'

    $formatText = {
        param([string]$Text)
        Format-ThemeText -Theme $theme -Text $Text -Styles @('Dim')
    }

    $wrappedMessage = Format-WrappedLines -Prefix '' -ContinuationPrefix '' -Text $Message -Width ([Math]::Max(10, (Get-TerminalWidth) - 6))
    $contentLines = [System.Collections.Generic.List[string]]::new()
    $contentLines.Add('')
    foreach ($rawLine in $wrappedMessage) {
        $contentLines.Add((& $formatText ([string]$rawLine)).ToString())
    }
    $contentLines.Add('')

    $contentWidth = 0
    foreach ($line in $contentLines) {
        $contentWidth = [Math]::Max($contentWidth, (Get-VisibleTextWidth -Text ([string]$line)))
    }

    $titleText = [string]$Title
    $titleWidth = if ([string]::IsNullOrEmpty($titleText)) { 0 } else { $titleText.Length }
    $frameWidth = [Math]::Max([Math]::Max($contentWidth, $titleWidth), 1) + 2

    $topFillWidth = [Math]::Max(1, $frameWidth - $titleWidth - 1)
    $topBorderSuffix = Format-ThemeText -Theme $theme -Text ([string]::new($horizontal, $topFillWidth) + $topRight) -Styles @('Gray')
    $topBorder = if ([string]::IsNullOrEmpty($titleText)) {
        [string]$step + '  ' + (Format-ThemeText -Theme $theme -Text ([string]::new($horizontal, $frameWidth + 1) + $topRight) -Styles @('Gray'))
    }
    else {
        [string]$step + '  ' + $titleText + ' ' + $topBorderSuffix
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    if (-not $suppressLeadingGuide) {
        $lines.Add($guide)
    }
    $lines.Add($topBorder)

    foreach ($line in $contentLines) {
        $visibleWidth = Get-VisibleTextWidth -Text ([string]$line)
        $padding = ' ' * [Math]::Max(0, $frameWidth - $visibleWidth)
        $lines.Add(([string]$guide) + '  ' + ([string]$line) + $padding + ([string]$guide))
    }

    $bottomBorder = Format-ThemeText -Theme $theme -Text ($connectorLeft + ([string]::new($horizontal, $frameWidth + 2)) + $bottomRight) -Styles @('Gray')
    $lines.Add([string]$bottomBorder)

    $rendered = Write-StaticFrame -Lines $lines.ToArray() -NoRender:(-not (Test-InteractiveConsole))
    Complete-PsClackTranscriptBlock -BlockType Static

    if ($PassThru) {
        return $rendered
    }
}

