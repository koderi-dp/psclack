function Read-PsClackAutocompletePrompt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $true)]
        [object[]]$Options,

        [object]$InitialValue,

        [string]$InitialUserInput = '',

        [string]$Placeholder = '',

        [object]$NonInteractiveValue,

        [int]$MaxItems = [int]::MaxValue,

        [scriptblock]$Validate,

        [scriptblock]$Filter,

        [switch]$Plain,

        [switch]$PassThru,

        [scriptblock]$ReadKeyScript
    )

    $normalizedOptions = @(
        $Options | ForEach-Object {
            $hintProperty = $_.PSObject.Properties['Hint']
            $disabledProperty = $_.PSObject.Properties['Disabled']
            [pscustomobject]@{
                Label = [string]$_.Label
                Value = $_.Value
                Hint = if ($hintProperty) { [string]$hintProperty.Value } else { '' }
                Disabled = if ($disabledProperty) { [bool]$disabledProperty.Value } else { $false }
            }
        }
    )

    if ($normalizedOptions.Count -eq 0) {
        throw 'Read-PsClackAutocompletePrompt requires at least one option.'
    }

    $interactiveConsole = Test-InteractiveConsole
    if (-not $ReadKeyScript -and -not $interactiveConsole) {
        if (-not $PSBoundParameters.ContainsKey('NonInteractiveValue')) {
            throw 'Read-PsClackAutocompletePrompt requires an interactive console, a ReadKeyScript override, or -NonInteractiveValue.'
        }

        $picked = $normalizedOptions | Where-Object { $_.Value -eq $NonInteractiveValue } | Select-Object -First 1
        if (-not $picked) {
            throw 'Read-PsClackAutocompletePrompt -NonInteractiveValue must match one of the option values.'
        }

        if ($picked.Disabled) {
            throw 'Read-PsClackAutocompletePrompt -NonInteractiveValue must not be a disabled option.'
        }

        $validationMessage = Invoke-Validation -Validate $Validate -Value $NonInteractiveValue
        if (-not [string]::IsNullOrWhiteSpace($validationMessage)) {
            throw "Read-PsClackAutocompletePrompt -NonInteractiveValue failed validation: $validationMessage"
        }

        $result = New-PromptResult -Status 'Submitted' -Value $NonInteractiveValue -Label $picked.Label
        if ($PassThru) {
            return $result
        }

        return $result.Value
    }

    $theme = Get-Theme -Plain:$Plain
    $blockContext = Get-PsClackTranscriptBlockContext -BlockType Prompt
    $state = @{
        Message = $Message
        AllOptions = $normalizedOptions
        Search = [string]$InitialUserInput
        FilteredOptions = @()
        ActiveIndex = 0
        FocusedValue = $null
        SelectedValues = @()
        IsNavigating = $false
        Multiple = $false
        Required = $false
        Placeholder = $Placeholder
        MaxItems = $MaxItems
        Validate = $Validate
        Filter = $Filter
        ErrorMessage = $null
        Status = 'Active'
        Value = $null
        SelectedLabel = $null
        SuppressLeadingGuide = [bool]$blockContext.SuppressLeadingGuide
    }

    Sync-AutocompleteFilteredOptions -State $state
    if ($PSBoundParameters.ContainsKey('InitialValue')) {
        for ($i = 0; $i -lt $state.FilteredOptions.Count; $i++) {
            $o = $state.FilteredOptions[$i]
            if (-not $o.Disabled -and $o.Value -eq $InitialValue) {
                $state.ActiveIndex = (Find-AutocompleteCursor -Cursor $i -Delta 0 -Options $state.FilteredOptions)
                $state.FocusedValue = $o.Value
                $state.SelectedValues = @($o.Value)
                break
            }
        }
    }

    $finalState = Invoke-PromptEngine `
        -State $state `
        -Render { param($currentState) Render-AutocompletePrompt -State $currentState -Theme $theme } `
        -HandleKey { param($currentState, $key) Update-AutocompletePromptState -State $currentState -Key $key } `
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

function Read-PsClackAutocompleteMultiSelectPrompt {
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

        [scriptblock]$Filter,

        [switch]$Required,

        [string]$Placeholder = '',

        [switch]$Plain,

        [switch]$PassThru,

        [scriptblock]$ReadKeyScript
    )

    $normalizedOptions = @(
        $Options | ForEach-Object {
            $hintProperty = $_.PSObject.Properties['Hint']
            $disabledProperty = $_.PSObject.Properties['Disabled']
            [pscustomobject]@{
                Label = [string]$_.Label
                Value = $_.Value
                Hint = if ($hintProperty) { [string]$hintProperty.Value } else { '' }
                Disabled = if ($disabledProperty) { [bool]$disabledProperty.Value } else { $false }
            }
        }
    )

    if ($normalizedOptions.Count -eq 0) {
        throw 'Read-PsClackAutocompleteMultiSelectPrompt requires at least one option.'
    }

    $interactiveConsole = Test-InteractiveConsole
    if (-not $ReadKeyScript -and -not $interactiveConsole) {
        if (-not $PSBoundParameters.ContainsKey('NonInteractiveValues')) {
            throw 'Read-PsClackAutocompleteMultiSelectPrompt requires an interactive console, a ReadKeyScript override, or -NonInteractiveValues.'
        }

        $selectedValues = @($NonInteractiveValues)
        $optionValues = @($normalizedOptions | ForEach-Object Value)
        $missingValues = @($selectedValues | Where-Object { $_ -notin $optionValues })
        if ($missingValues.Count -gt 0) {
            throw 'Read-PsClackAutocompleteMultiSelectPrompt -NonInteractiveValues must all match option values.'
        }

        foreach ($v in $selectedValues) {
            $opt = $normalizedOptions | Where-Object { $_.Value -eq $v } | Select-Object -First 1
            if ($opt.Disabled) {
                throw 'Read-PsClackAutocompleteMultiSelectPrompt -NonInteractiveValues must not include disabled options.'
            }
        }

        if ($Required.IsPresent -and $selectedValues.Count -eq 0) {
            throw 'Read-PsClackAutocompleteMultiSelectPrompt -NonInteractiveValues requires at least one value when -Required is set.'
        }

        $validationMessage = Invoke-Validation -Validate $Validate -Value $selectedValues
        if (-not [string]::IsNullOrWhiteSpace($validationMessage)) {
            throw "Read-PsClackAutocompleteMultiSelectPrompt -NonInteractiveValues failed validation: $validationMessage"
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
        AllOptions = $normalizedOptions
        Search = ''
        FilteredOptions = @()
        ActiveIndex = 0
        FocusedValue = $null
        SelectedValues = @($InitialValues)
        IsNavigating = $false
        Multiple = $true
        Required = $Required.IsPresent
        Placeholder = $Placeholder
        MaxItems = $MaxItems
        Validate = $Validate
        Filter = $Filter
        ErrorMessage = $null
        Status = 'Active'
        Value = $null
        SelectedLabel = $null
        SuppressLeadingGuide = [bool]$blockContext.SuppressLeadingGuide
    }

    Sync-AutocompleteFilteredOptions -State $state

    $finalState = Invoke-PromptEngine `
        -State $state `
        -Render { param($currentState) Render-AutocompletePrompt -State $currentState -Theme $theme } `
        -HandleKey { param($currentState, $key) Update-AutocompletePromptState -State $currentState -Key $key } `
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
