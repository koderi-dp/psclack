function Read-PsClackPathPrompt {
    <#
    .SYNOPSIS
        Prompts the user to enter or select a filesystem path with live autocomplete.

    .DESCRIPTION
        Renders an interactive path input that lists matching filesystem entries as the
        user types. Supports files and directories, with an option to restrict to
        directories only. Returns the selected path string, or a result object when
        -PassThru is specified.

    .PARAMETER Message
        The prompt label shown to the user.

    .PARAMETER InitialValue
        The starting path pre-populated in the input field.

    .PARAMETER Root
        A directory to use as the starting point when InitialValue is not supplied.
        Defaults to the current working directory.

    .PARAMETER OnlyDirectories
        When set, only directories are shown in the completion list.

    .PARAMETER MaxItems
        Maximum number of filesystem entries shown at once. Defaults to 5.

    .PARAMETER Validate
        A script block that receives the submitted path string and returns an error
        message string (or null/empty) to accept.

    .PARAMETER NonInteractiveValue
        Path string to return immediately when running in a non-interactive context.

    .PARAMETER Plain
        Renders without ANSI colour or Unicode symbols.

    .PARAMETER PassThru
        Returns a result object with Status, Value, Label, and Cancelled properties
        instead of the raw path string.

    .PARAMETER ReadKeyScript
        Overrides the default console key-read loop; used by tests.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [string]$InitialValue,

        [string]$Root,

        [switch]$OnlyDirectories,

        [int]$MaxItems = 5,

        [scriptblock]$Validate,

        [string]$NonInteractiveValue,

        [switch]$Plain,

        [switch]$PassThru,

        [scriptblock]$ReadKeyScript
    )

    $startInput = if ($PSBoundParameters.ContainsKey('InitialValue')) {
        $InitialValue
    }
    elseif ($PSBoundParameters.ContainsKey('Root') -and -not [string]::IsNullOrEmpty($Root)) {
        $Root
    }
    else {
        $PWD.Path
    }

    $interactiveConsole = Test-InteractiveConsole
    if (-not $ReadKeyScript -and -not $interactiveConsole) {
        if (-not $PSBoundParameters.ContainsKey('NonInteractiveValue')) {
            throw 'Read-PsClackPathPrompt requires an interactive console, a ReadKeyScript override, or -NonInteractiveValue.'
        }

        $value = $NonInteractiveValue
        $validationMessage = Invoke-Validation -Validate $Validate -Value $value
        if (-not [string]::IsNullOrWhiteSpace($validationMessage)) {
            throw "Read-PsClackPathPrompt -NonInteractiveValue failed validation: $validationMessage"
        }

        $result = New-PromptResult -Status 'Submitted' -Value $value -Label $value
        if ($PassThru) {
            return $result
        }

        return $result.Value
    }

    $theme = Get-Theme -Plain:$Plain
    $blockContext = Get-PsClackTranscriptBlockContext -BlockType Prompt
    $state = @{
        Message             = $Message
        Input               = $startInput
        FilteredOptions     = @()
        ActiveIndex         = 0
        FocusedValue        = $null
        IsNavigating        = $false
        OnlyDirectories     = [bool]$OnlyDirectories
        MaxItems            = $MaxItems
        Validate            = $Validate
        ErrorMessage        = $null
        Status              = 'Active'
        Value               = $null
        SelectedLabel       = $null
        SuppressLeadingGuide = [bool]$blockContext.SuppressLeadingGuide
    }

    Sync-PathOptions -State $state

    $finalState = Invoke-PromptEngine `
        -State $state `
        -Render { param($currentState) Render-PathPrompt -State $currentState -Theme $theme } `
        -HandleKey { param($currentState, $key) Update-PathPromptState -State $currentState -Key $key } `
        -ReadKeyScript $ReadKeyScript `
        -NoRender:(-not $interactiveConsole)

    $result = New-PromptResult -Status $finalState.Status -Value $finalState.Value -Label $finalState.SelectedLabel
    if ($interactiveConsole) {
        Complete-PsClackTranscriptBlock -BlockType Prompt -Status $finalState.Status
    }

    if ($PassThru) {
        return $result
    }

    return $result.Value
}
