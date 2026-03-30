function Format-ThemeText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Theme,

        [Parameter(Mandatory = $true)]
        [string]$Text,

        [AllowNull()]
        [object[]]$Styles = @()
    )

    $styleList = @($Styles | Where-Object { $null -ne $_ -and -not [string]::IsNullOrWhiteSpace([string]$_) })
    if ($Theme.Plain -or $styleList.Count -eq 0) {
        return $Text
    }

    $prefix = [string]::Concat(@($styleList | ForEach-Object { [string]$Theme.Styles[[string]$_] }))
    return '{0}{1}{2}' -f $prefix, $Text, $Theme.Styles.Reset
}

function Get-PromptStateSymbol {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Theme,

        [Parameter(Mandatory = $true)]
        [string]$Status
    )

    switch ($Status) {
        'Submitted' { return (Format-ThemeText -Theme $Theme -Text ([string]$Theme.Symbols.StepSubmit) -Styles @('Green')) }
        'Cancelled' { return (Format-ThemeText -Theme $Theme -Text ([string]$Theme.Symbols.StepCancel) -Styles @('Red')) }
        'Error' { return (Format-ThemeText -Theme $Theme -Text ([string]$Theme.Symbols.StepError) -Styles @('Yellow')) }
        default { return (Format-ThemeText -Theme $Theme -Text ([string]$Theme.Symbols.StepActive) -Styles @('Blue')) }
    }
}

function Get-Theme {
    [CmdletBinding()]
    param(
        [switch]$Plain
    )

    $ansiEnabled = -not $Plain.IsPresent -and (Test-AnsiSupport)

    $styles = if ($ansiEnabled) {
        @{
            Reset = "`e[0m"
            Gray = "`e[90m"
            Dim = "`e[2m"
            Magenta = "`e[35m"
            Blue = "`e[94m"
            Cyan = "`e[36m"
            Green = "`e[32m"
            Red = "`e[31m"
            Yellow = "`e[33m"
            Inverse = "`e[7m"
            Strike = "`e[9m"
        }
    }
    else {
        @{
            Reset = ''
            Gray = ''
            Dim = ''
            Magenta = ''
            Blue = ''
            Cyan = ''
            Green = ''
            Red = ''
            Yellow = ''
            Inverse = ''
            Strike = ''
        }
    }

    return @{
        Plain = (-not $ansiEnabled)
        Symbols = @{
            StepActive = '●'
            StepSubmit = '○'
            StepCancel = '■'
            StepError = '▲'
            GuideStart = '┌'
            GuideBar = '│'
            GuideEnd = '└'
            RadioActive = '●'
            RadioInactive = '○'
            CheckboxSelected = '◼'
            CheckboxUnselected = '◻'
            PasswordMask = '▪'
        }
        Styles = $styles
    }
}

function Invoke-Validation {
    [CmdletBinding()]
    param(
        [scriptblock]$Validate,
        [AllowNull()]
        [object]$Value
    )

    if (-not $Validate) {
        return $null
    }

    return (& $Validate $Value)
}

function Test-AnsiSupport {
    [CmdletBinding()]
    param()

    if ([Console]::IsOutputRedirected) {
        return $false
    }

    if ($env:NO_COLOR) {
        return $false
    }

    $terminal = [string]$env:TERM
    if (-not [string]::IsNullOrWhiteSpace($terminal) -and $terminal -eq 'dumb') {
        return $false
    }

    return $true
}

function Test-InteractiveConsole {
    [CmdletBinding()]
    param()

    try {
        return (-not [Console]::IsInputRedirected) -and (-not [Console]::IsOutputRedirected)
    }
    catch {
        return $false
    }
}
