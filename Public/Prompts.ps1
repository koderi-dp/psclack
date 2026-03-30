function Invoke-PsClackPromptGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [scriptblock]$ScriptBlock,

        [switch]$PassThru
    )

    $result = & $ScriptBlock

    if ($PassThru) {
        return [pscustomobject]@{
            Status = 'Submitted'
            Value = $result
            Cancelled = $false
        }
    }

    return $result
}

function Read-PsClackTextPrompt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [string]$Placeholder = '',

        [string]$InitialValue = '',

        [string]$NonInteractiveValue,

        [scriptblock]$Validate,

        [switch]$Plain,

        [switch]$PassThru,

        [scriptblock]$ReadKeyScript
    )

    $interactiveConsole = Test-InteractiveConsole
    if (-not $ReadKeyScript -and -not $interactiveConsole) {
        if (-not $PSBoundParameters.ContainsKey('NonInteractiveValue')) {
            throw 'Read-PsClackTextPrompt requires an interactive console, a ReadKeyScript override, or -NonInteractiveValue.'
        }

        $validationMessage = Invoke-Validation -Validate $Validate -Value $NonInteractiveValue
        if (-not [string]::IsNullOrWhiteSpace($validationMessage)) {
            throw "Read-PsClackTextPrompt -NonInteractiveValue failed validation: $validationMessage"
        }

        $result = New-PromptResult -Status 'Submitted' -Value $NonInteractiveValue -Label $NonInteractiveValue
        if ($PassThru) {
            return $result
        }

        return $result.Value
    }

    $theme = Get-Theme -Plain:$Plain
    $blockContext = Get-PsClackTranscriptBlockContext -BlockType Prompt
    $state = @{
        Message = $Message
        Placeholder = $Placeholder
        Value = [string]$InitialValue
        Validate = $Validate
        ErrorMessage = $null
        Status = 'Active'
        SelectedLabel = $null
        SuppressLeadingGuide = [bool]$blockContext.SuppressLeadingGuide
    }

    $finalState = Invoke-PromptEngine `
        -State $state `
        -Render { param($currentState) Render-TextPrompt -State $currentState -Theme $theme } `
        -HandleKey { param($currentState, $key) Update-TextPromptState -State $currentState -Key $key } `
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

function Read-PsClackPasswordPrompt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [string]$Placeholder = '',

        [string]$InitialValue = '',

        [string]$Mask = '',

        [string]$NonInteractiveValue,

        [scriptblock]$Validate,

        [switch]$ClearOnError,

        [switch]$Plain,

        [switch]$PassThru,

        [scriptblock]$ReadKeyScript
    )

    $interactiveConsole = Test-InteractiveConsole
    if (-not $ReadKeyScript -and -not $interactiveConsole) {
        if (-not $PSBoundParameters.ContainsKey('NonInteractiveValue')) {
            throw 'Read-PsClackPasswordPrompt requires an interactive console, a ReadKeyScript override, or -NonInteractiveValue.'
        }

        $validationMessage = Invoke-Validation -Validate $Validate -Value $NonInteractiveValue
        if (-not [string]::IsNullOrWhiteSpace($validationMessage)) {
            throw "Read-PsClackPasswordPrompt -NonInteractiveValue failed validation: $validationMessage"
        }

        $result = New-PromptResult -Status 'Submitted' -Value $NonInteractiveValue -Label $NonInteractiveValue
        if ($PassThru) {
            return $result
        }

        return $result.Value
    }

    $theme = Get-Theme -Plain:$Plain
    $blockContext = Get-PsClackTranscriptBlockContext -BlockType Prompt
    $state = @{
        Message = $Message
        Placeholder = $Placeholder
        Value = [string]$InitialValue
        Validate = $Validate
        ErrorMessage = $null
        ErrorDisplayValue = $null
        Status = 'Active'
        SelectedLabel = $null
        Mask = if ([string]::IsNullOrEmpty($Mask)) { [string]$theme.Symbols.PasswordMask } else { $Mask }
        ClearOnError = $ClearOnError.IsPresent
        SuppressLeadingGuide = [bool]$blockContext.SuppressLeadingGuide
    }

    $finalState = Invoke-PromptEngine `
        -State $state `
        -Render { param($currentState) Render-PasswordPrompt -State $currentState -Theme $theme } `
        -HandleKey { param($currentState, $key) Update-PasswordPromptState -State $currentState -Key $key } `
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

function Read-PsClackConfirmPrompt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [bool]$InitialValue = $true,

        [Nullable[bool]]$NonInteractiveValue,

        [switch]$Plain,

        [switch]$PassThru,

        [scriptblock]$ReadKeyScript
    )

    $interactiveConsole = Test-InteractiveConsole
    if (-not $ReadKeyScript -and -not $interactiveConsole) {
        if (-not $PSBoundParameters.ContainsKey('NonInteractiveValue')) {
            throw 'Read-PsClackConfirmPrompt requires an interactive console, a ReadKeyScript override, or -NonInteractiveValue.'
        }

        $result = New-PromptResult -Status 'Submitted' -Value ([bool]$NonInteractiveValue) -Label $(if ($NonInteractiveValue) { 'Yes' } else { 'No' })
        if ($PassThru) {
            return $result
        }

        return $result.Value
    }

    $theme = Get-Theme -Plain:$Plain
    $blockContext = Get-PsClackTranscriptBlockContext -BlockType Prompt
    $state = @{
        Message = $Message
        CurrentChoice = [bool]$InitialValue
        Status = 'Active'
        Value = $null
        SelectedLabel = $null
        SuppressLeadingGuide = [bool]$blockContext.SuppressLeadingGuide
    }

    $finalState = Invoke-PromptEngine `
        -State $state `
        -Render { param($currentState) Render-ConfirmPrompt -State $currentState -Theme $theme } `
        -HandleKey { param($currentState, $key) Update-ConfirmPromptState -State $currentState -Key $key } `
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

function Read-PsClackSelectPrompt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $true)]
        [object[]]$Options,

        [object]$InitialValue,

        [object]$NonInteractiveValue,

        [int]$MaxItems = [int]::MaxValue,

        [switch]$Plain,

        [switch]$PassThru,

        [scriptblock]$ReadKeyScript
    )

    $normalizedOptions = @(
        $Options | ForEach-Object {
            $hintProperty = $_.PSObject.Properties['Hint']
            [pscustomobject]@{
                Label = [string]$_.Label
                Value = $_.Value
                Hint = if ($hintProperty) { [string]$hintProperty.Value } else { '' }
            }
        }
    )

    if ($normalizedOptions.Count -eq 0) {
        throw 'Read-PsClackSelectPrompt requires at least one option.'
    }

    $interactiveConsole = Test-InteractiveConsole
    if (-not $ReadKeyScript -and -not $interactiveConsole) {
        if (-not $PSBoundParameters.ContainsKey('NonInteractiveValue')) {
            throw 'Read-PsClackSelectPrompt requires an interactive console, a ReadKeyScript override, or -NonInteractiveValue.'
        }

        $selectedOption = $normalizedOptions | Where-Object { $_.Value -eq $NonInteractiveValue } | Select-Object -First 1
        if (-not $selectedOption) {
            throw 'Read-PsClackSelectPrompt -NonInteractiveValue must match one of the option values.'
        }

        $result = New-PromptResult -Status 'Submitted' -Value $selectedOption.Value -Label $selectedOption.Label
        if ($PassThru) {
            return $result
        }

        return $result.Value
    }

    $activeIndex = 0
    if ($PSBoundParameters.ContainsKey('InitialValue')) {
        for ($i = 0; $i -lt $normalizedOptions.Count; $i++) {
            if ($normalizedOptions[$i].Value -eq $InitialValue) {
                $activeIndex = $i
                break
            }
        }
    }

    $theme = Get-Theme -Plain:$Plain
    $blockContext = Get-PsClackTranscriptBlockContext -BlockType Prompt
    $state = @{
        Message = $Message
        Options = $normalizedOptions
        ActiveIndex = $activeIndex
        Status = 'Active'
        Value = $null
        SelectedLabel = $null
        MaxItems = $MaxItems
        SuppressLeadingGuide = [bool]$blockContext.SuppressLeadingGuide
    }

    $finalState = Invoke-PromptEngine `
        -State $state `
        -Render { param($currentState) Render-SelectPrompt -State $currentState -Theme $theme } `
        -HandleKey { param($currentState, $key) Update-SelectPromptState -State $currentState -Key $key } `
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

function Read-PsClackMultiSelectPrompt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $true)]
        [object[]]$Options,

        [object[]]$InitialValues = @(),

        [object[]]$NonInteractiveValues,

        [int]$MaxItems = [int]::MaxValue,

        [scriptblock]$Validate,

        [switch]$Plain,

        [switch]$PassThru,

        [scriptblock]$ReadKeyScript
    )

    $normalizedOptions = @(
        $Options | ForEach-Object {
            $value = $_.Value
            [pscustomobject]@{
                Label = [string]$_.Label
                Value = $value
                Selected = ($InitialValues -contains $value)
            }
        }
    )

    if ($normalizedOptions.Count -eq 0) {
        throw 'Read-PsClackMultiSelectPrompt requires at least one option.'
    }

    $interactiveConsole = Test-InteractiveConsole
    if (-not $ReadKeyScript -and -not $interactiveConsole) {
        if (-not $PSBoundParameters.ContainsKey('NonInteractiveValues')) {
            throw 'Read-PsClackMultiSelectPrompt requires an interactive console, a ReadKeyScript override, or -NonInteractiveValues.'
        }

        $selectedValues = @($NonInteractiveValues)
        $optionValues = @($normalizedOptions | ForEach-Object Value)
        $missingValues = @($selectedValues | Where-Object { $_ -notin $optionValues })
        if ($missingValues.Count -gt 0) {
            throw 'Read-PsClackMultiSelectPrompt -NonInteractiveValues must all match option values.'
        }

        $validationMessage = Invoke-Validation -Validate $Validate -Value $selectedValues
        if (-not [string]::IsNullOrWhiteSpace($validationMessage)) {
            throw "Read-PsClackMultiSelectPrompt -NonInteractiveValues failed validation: $validationMessage"
        }

        $selectedLabels = @(
            $normalizedOptions |
                Where-Object { $_.Value -in $selectedValues } |
                ForEach-Object Label
        ) -join ', '
        $result = New-PromptResult -Status 'Submitted' -Value $selectedValues -Label $selectedLabels
        if ($PassThru) {
            return $result
        }

        return $result.Value
    }

    $theme = Get-Theme -Plain:$Plain
    $blockContext = Get-PsClackTranscriptBlockContext -BlockType Prompt
    $state = @{
        Message = $Message
        Options = $normalizedOptions
        ActiveIndex = 0
        Validate = $Validate
        ErrorMessage = $null
        Status = 'Active'
        Value = $null
        SelectedLabel = $null
        MaxItems = $MaxItems
        SuppressLeadingGuide = [bool]$blockContext.SuppressLeadingGuide
    }

    $finalState = Invoke-PromptEngine `
        -State $state `
        -Render { param($currentState) Render-MultiSelectPrompt -State $currentState -Theme $theme } `
        -HandleKey { param($currentState, $key) Update-MultiSelectPromptState -State $currentState -Key $key } `
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

