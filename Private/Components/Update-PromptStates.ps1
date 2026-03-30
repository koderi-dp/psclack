function Update-ConfirmPromptState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$State,

        [Parameter(Mandatory = $true)]
        [string]$Key
    )

    switch ($Key) {
        'Left' { $State.CurrentChoice = $true }
        'Right' { $State.CurrentChoice = $false }
        'Up' { $State.CurrentChoice = $true }
        'Down' { $State.CurrentChoice = $false }
        'Character:y' { $State.CurrentChoice = $true }
        'Character:Y' { $State.CurrentChoice = $true }
        'Character:n' { $State.CurrentChoice = $false }
        'Character:N' { $State.CurrentChoice = $false }
        'Enter' {
            $State.Status = 'Submitted'
            $State.Value = [bool]$State.CurrentChoice
            $State.SelectedLabel = if ($State.CurrentChoice) { 'Yes' } else { 'No' }
        }
        'Escape' {
            $State.Status = 'Cancelled'
            $State.Value = $null
            $State.SelectedLabel = $null
        }
        'CtrlC' {
            $State.Status = 'Cancelled'
            $State.Value = $null
            $State.SelectedLabel = $null
        }
    }

    return $State
}

function Update-MultiSelectPromptState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$State,

        [Parameter(Mandatory = $true)]
        [string]$Key
    )

    switch ($Key) {
        'Up' {
            if ($State.ActiveIndex -gt 0) {
                $State.ActiveIndex--
            }
            $State.ErrorMessage = $null
        }
        'Down' {
            if ($State.ActiveIndex -lt ($State.Options.Count - 1)) {
                $State.ActiveIndex++
            }
            $State.ErrorMessage = $null
        }
        'Space' {
            $current = $State.Options[$State.ActiveIndex]
            $current.Selected = -not $current.Selected
            $State.ErrorMessage = $null
        }
        'Enter' {
            $selectedValues = @($State.Options | Where-Object Selected | ForEach-Object Value)
            $validationMessage = Invoke-Validation -Validate $State.Validate -Value $selectedValues
            if ([string]::IsNullOrWhiteSpace($validationMessage)) {
                $State.Status = 'Submitted'
                $State.Value = $selectedValues
                $State.SelectedLabel = @($State.Options | Where-Object Selected | ForEach-Object Label) -join ', '
                $State.ErrorMessage = $null
            }
            else {
                $State.ErrorMessage = [string]$validationMessage
            }
        }
        'Escape' {
            $State.Status = 'Cancelled'
            $State.Value = $null
            $State.SelectedLabel = $null
            $State.ErrorMessage = $null
        }
        'CtrlC' {
            $State.Status = 'Cancelled'
            $State.Value = $null
            $State.SelectedLabel = $null
            $State.ErrorMessage = $null
        }
    }

    return $State
}

function Update-PasswordPromptState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$State,

        [Parameter(Mandatory = $true)]
        [string]$Key
    )

    switch -Regex ($Key) {
        '^Character:(.+)$' {
            $State.Value = '{0}{1}' -f $State.Value, $Matches[1]
            $State.ErrorMessage = $null
            $State.ErrorDisplayValue = $null
            break
        }
        '^Backspace$' {
            if (-not [string]::IsNullOrEmpty($State.Value)) {
                $State.Value = $State.Value.Substring(0, $State.Value.Length - 1)
            }
            $State.ErrorMessage = $null
            $State.ErrorDisplayValue = $null
            break
        }
        '^Enter$' {
            $validationMessage = Invoke-Validation -Validate $State.Validate -Value $State.Value
            if ([string]::IsNullOrWhiteSpace($validationMessage)) {
                $State.Status = 'Submitted'
                $State.SelectedLabel = $State.Value
                $State.ErrorMessage = $null
                $State.ErrorDisplayValue = $null
            }
            else {
                $mask = if ([string]::IsNullOrEmpty([string]$State.Mask)) { '*' } else { [string]$State.Mask }
                $State.ErrorMessage = [string]$validationMessage
                $State.ErrorDisplayValue = if ([string]::IsNullOrEmpty([string]$State.Value)) { '' } else { $mask * ([string]$State.Value).Length }
                if ($State.ClearOnError) {
                    $State.Value = ''
                }
            }
            break
        }
        '^(Escape|CtrlC)$' {
            $State.Status = 'Cancelled'
            $State.SelectedLabel = $null
            $State.ErrorMessage = $null
            $State.ErrorDisplayValue = $null
            break
        }
    }

    return $State
}

function Update-SelectPromptState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$State,

        [Parameter(Mandatory = $true)]
        [string]$Key
    )

    switch ($Key) {
        'Up' {
            if ($State.ActiveIndex -gt 0) {
                $State.ActiveIndex--
            }
        }
        'Down' {
            if ($State.ActiveIndex -lt ($State.Options.Count - 1)) {
                $State.ActiveIndex++
            }
        }
        'Enter' {
            $selectedOption = $State.Options[$State.ActiveIndex]
            $State.Status = 'Submitted'
            $State.Value = $selectedOption.Value
            $State.SelectedLabel = $selectedOption.Label
        }
        'Escape' {
            $State.Status = 'Cancelled'
            $State.Value = $null
            $State.SelectedLabel = $null
        }
        'CtrlC' {
            $State.Status = 'Cancelled'
            $State.Value = $null
            $State.SelectedLabel = $null
        }
    }

    return $State
}

function Update-TextPromptState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$State,

        [Parameter(Mandatory = $true)]
        [string]$Key
    )

    switch -Regex ($Key) {
        '^Character:(.+)$' {
            $State.Value = '{0}{1}' -f $State.Value, $Matches[1]
            $State.ErrorMessage = $null
            break
        }
        '^Backspace$' {
            if (-not [string]::IsNullOrEmpty($State.Value)) {
                $State.Value = $State.Value.Substring(0, $State.Value.Length - 1)
            }
            $State.ErrorMessage = $null
            break
        }
        '^Enter$' {
            $validationMessage = Invoke-Validation -Validate $State.Validate -Value $State.Value
            if ([string]::IsNullOrWhiteSpace($validationMessage)) {
                $State.Status = 'Submitted'
                $State.SelectedLabel = $State.Value
                $State.ErrorMessage = $null
            }
            else {
                $State.ErrorMessage = [string]$validationMessage
            }
            break
        }
        '^(Escape|CtrlC)$' {
            $State.Status = 'Cancelled'
            $State.SelectedLabel = $null
            $State.ErrorMessage = $null
            break
        }
    }

    return $State
}
function Test-AutocompleteDefaultFilter {
    [CmdletBinding()]
    param(
        [AllowEmptyString()]
        [string]$SearchText,

        [Parameter(Mandatory = $true)]
        [object]$Option
    )

    if ([string]::IsNullOrEmpty($SearchText)) {
        return $true
    }

    $term = $SearchText.ToLowerInvariant()
    $label = ([string]$Option.Label).ToLowerInvariant()
    $hint = ([string]$Option.Hint).ToLowerInvariant()
    $valueStr = ([string]$Option.Value).ToLowerInvariant()
    return $label.Contains($term) -or $hint.Contains($term) -or $valueStr.Contains($term)
}

function Find-AutocompleteCursor {
    [CmdletBinding()]
    param(
        [int]$Cursor,

        [int]$Delta,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$Options
    )

    $opts = @($Options)
    if ($opts.Count -eq 0) {
        return 0
    }

    $hasEnabled = $false
    foreach ($o in $opts) {
        if (-not $o.Disabled) {
            $hasEnabled = $true
            break
        }
    }

    if (-not $hasEnabled) {
        return $Cursor
    }

    $newCursor = $Cursor + $Delta
    $maxCursor = [Math]::Max($opts.Count - 1, 0)
    $clamped = if ($newCursor -lt 0) {
        $maxCursor
    }
    elseif ($newCursor -gt $maxCursor) {
        0
    }
    else {
        $newCursor
    }

    $opt = $opts[$clamped]
    if ($opt.Disabled) {
        $nextDelta = if ($Delta -lt 0) { -1 } else { 1 }
        return (Find-AutocompleteCursor -Cursor $clamped -Delta $nextDelta -Options $opts)
    }

    return $clamped
}

function Test-AutocompletePlaceholderSelectable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$State
    )

    $ph = [string]$State.Placeholder
    if ([string]::IsNullOrWhiteSpace($ph)) {
        return $false
    }

    foreach ($opt in $State.AllOptions) {
        if ($opt.Disabled) {
            continue
        }

        $match = if ($State.Filter) {
            & $State.Filter $ph $opt
        }
        else {
            Test-AutocompleteDefaultFilter -SearchText $ph -Option $opt
        }

        if ($match) {
            return $true
        }
    }

    return $false
}

function Sync-AutocompleteFilteredOptions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$State
    )

    $search = [string]$State.Search
    $filtered = [System.Collections.Generic.List[object]]::new()
    foreach ($opt in $State.AllOptions) {
        $pass = if ([string]::IsNullOrEmpty($search)) {
            $true
        }
        elseif ($State.Filter) {
            & $State.Filter $search $opt
        }
        else {
            Test-AutocompleteDefaultFilter -SearchText $search -Option $opt
        }

        if ($pass) {
            $filtered.Add($opt) | Out-Null
        }
    }

    $State.FilteredOptions = @($filtered)
    if ($State.FilteredOptions.Count -eq 0) {
        $State.ActiveIndex = 0
        $State.FocusedValue = $null
        if (-not $State.Multiple) {
            $State.SelectedValues = @()
        }

        return
    }
    $priorFocus = $State.FocusedValue
    $idx = -1
    if ($null -ne $priorFocus) {
        for ($i = 0; $i -lt $State.FilteredOptions.Count; $i++) {
            if ($State.FilteredOptions[$i].Value -eq $priorFocus) {
                $idx = $i
                break
            }
        }
    }

    if ($idx -lt 0) {
        $idx = 0
    }

    $State.ActiveIndex = (Find-AutocompleteCursor -Cursor $idx -Delta 0 -Options $State.FilteredOptions)
    $focusedOpt = if ($State.FilteredOptions.Count -gt 0) { $State.FilteredOptions[$State.ActiveIndex] } else { $null }

    if ($focusedOpt -and -not $focusedOpt.Disabled) {
        $State.FocusedValue = $focusedOpt.Value
        if (-not $State.Multiple) {
            $State.SelectedValues = @($focusedOpt.Value)
        }
    }
    else {
        $State.FocusedValue = $null
        if (-not $State.Multiple) {
            $State.SelectedValues = @()
        }
    }
}

function Update-AutocompletePromptState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$State,

        [Parameter(Mandatory = $true)]
        [string]$Key
    )

    switch -Regex ($Key) {
        '^(Escape|CtrlC)$' {
            $State.Status = 'Cancelled'
            $State.Value = $null
            $State.SelectedLabel = $null
            $State.ErrorMessage = $null
            break
        }
        '^Up$' {
            if ($State.FilteredOptions.Count -eq 0) {
                break
            }

            $State.ActiveIndex = (Find-AutocompleteCursor -Cursor $State.ActiveIndex -Delta -1 -Options $State.FilteredOptions)
            $opt = $State.FilteredOptions[$State.ActiveIndex]
            if ($opt -and -not $opt.Disabled) {
                $State.FocusedValue = $opt.Value
                if (-not $State.Multiple) {
                    $State.SelectedValues = @($opt.Value)
                }
            }

            $State.IsNavigating = $true
            $State.ErrorMessage = $null
            break
        }
        '^Down$' {
            if ($State.FilteredOptions.Count -eq 0) {
                break
            }

            $State.ActiveIndex = (Find-AutocompleteCursor -Cursor $State.ActiveIndex -Delta 1 -Options $State.FilteredOptions)
            $opt = $State.FilteredOptions[$State.ActiveIndex]
            if ($opt -and -not $opt.Disabled) {
                $State.FocusedValue = $opt.Value
                if (-not $State.Multiple) {
                    $State.SelectedValues = @($opt.Value)
                }
            }

            $State.IsNavigating = $true
            $State.ErrorMessage = $null
            break
        }
        '^Enter$' {
            if ($State.Multiple) {
                $selected = @([object[]]$State.SelectedValues)
                if ($State.Required -and $selected.Count -eq 0) {
                    $State.ErrorMessage = 'Please select at least one item'
                    break
                }

                $validationMessage = Invoke-Validation -Validate $State.Validate -Value $selected
                if ([string]::IsNullOrWhiteSpace($validationMessage)) {
                    $State.Status = 'Submitted'
                    $State.Value = $selected
                    $labels = @(
                        foreach ($v in $selected) {
                            ($State.AllOptions | Where-Object { $_.Value -eq $v } | Select-Object -First 1).Label
                        }
                    ) -join ', '
                    $State.SelectedLabel = $labels
                    $State.ErrorMessage = $null
                }
                else {
                    $State.ErrorMessage = [string]$validationMessage
                }
            }
            else {
                $selectedValue = if ($State.SelectedValues.Count -gt 0) { $State.SelectedValues[0] } else { $null }
                $validationMessage = Invoke-Validation -Validate $State.Validate -Value $selectedValue
                if ([string]::IsNullOrWhiteSpace($validationMessage)) {
                    $State.Status = 'Submitted'
                    $State.Value = $selectedValue
                    $picked = $State.AllOptions | Where-Object { $_.Value -eq $selectedValue } | Select-Object -First 1
                    $State.SelectedLabel = if ($picked) { [string]$picked.Label } else { '' }
                    $State.ErrorMessage = $null
                }
                else {
                    $State.ErrorMessage = [string]$validationMessage
                }
            }

            break
        }
        '^Tab$' {
            $search = [string]$State.Search
            $isEmpty = [string]::IsNullOrEmpty($search)
            if ($isEmpty -and (Test-AutocompletePlaceholderSelectable -State $State)) {
                $State.Search = [string]$State.Placeholder
                $State.IsNavigating = $false
                Sync-AutocompleteFilteredOptions -State $State
                $State.ErrorMessage = $null
                break
            }

            if ($State.Multiple -and $null -ne $State.FocusedValue) {
                $fv = $State.FocusedValue
                $list = [System.Collections.Generic.List[object]]::new(@([object[]]$State.SelectedValues))
                if ($list.Contains($fv)) {
                    $null = $list.Remove($fv)
                }
                else {
                    $list.Add($fv) | Out-Null
                }

                $State.SelectedValues = @($list)
            }
            elseif (-not $State.Multiple) {
                if ($null -ne $State.FocusedValue) {
                    $State.SelectedValues = @($State.FocusedValue)
                }

                $State.IsNavigating = $false
            }

            break
        }
        '^Space$' {
            if (-not $State.Multiple -or -not $State.IsNavigating) {
                break
            }

            if ($null -eq $State.FocusedValue) {
                break
            }

            $fv = $State.FocusedValue
            $list = [System.Collections.Generic.List[object]]::new(@([object[]]$State.SelectedValues))
            if ($list.Contains($fv)) {
                $null = $list.Remove($fv)
            }
            else {
                $list.Add($fv) | Out-Null
            }

            $State.SelectedValues = @($list)
            $State.ErrorMessage = $null
            break
        }
        '^Backspace$' {
            if (-not [string]::IsNullOrEmpty($State.Search)) {
                $State.Search = $State.Search.Substring(0, $State.Search.Length - 1)
            }

            if ($State.Multiple) {
                $State.IsNavigating = $false
            }

            Sync-AutocompleteFilteredOptions -State $State
            $State.ErrorMessage = $null
            break
        }
        '^Character:(.+)$' {
            $State.Search = '{0}{1}' -f $State.Search, $Matches[1]
            if ($State.Multiple) {
                $State.IsNavigating = $false
            }

            Sync-AutocompleteFilteredOptions -State $State
            $State.ErrorMessage = $null
            break
        }
    }

    return $State
}

function Sync-PathOptions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$State
    )

    $inputPath = [string]$State.Input

    if ([string]::IsNullOrEmpty($inputPath)) {
        $State.FilteredOptions = @()
        $State.ActiveIndex = 0
        $State.FocusedValue = $null
        return
    }

    try {
        $searchDir = $null

        # Detect wildcard in the leaf segment (last path component)
        $leaf = Split-Path -Path $inputPath -Leaf -ErrorAction SilentlyContinue
        $isWildcard = $leaf -match '[*?]'

        if ($isWildcard) {
            # Wildcard mode: searchDir is the parent, filter items by Name -like pattern
            $parent = Split-Path -Path $inputPath -Parent -ErrorAction SilentlyContinue
            if ($parent -and (Test-Path -LiteralPath $parent -PathType Container)) {
                $searchDir = $parent
            }
        }
        elseif (Test-Path -LiteralPath $inputPath -PathType Container) {
            $endsWithSep = $inputPath.EndsWith('\') -or $inputPath.EndsWith('/')
            if ($endsWithSep -or $State.OnlyDirectories) {
                $searchDir = $inputPath
                # Auto-append separator so the next typed character filters inside
                # this directory rather than backing up to its siblings
                if (-not $endsWithSep) {
                    $State.Input = $inputPath + '\'
                }
            }
            else {
                $parent = Split-Path -Path $inputPath -Parent
                $searchDir = if ($parent) { $parent } else { $inputPath }
            }
        }
        else {
            $parent = Split-Path -Path $inputPath -Parent -ErrorAction SilentlyContinue
            if ($parent -and (Test-Path -LiteralPath $parent -PathType Container)) {
                $searchDir = $parent
            }
        }

        if (-not $searchDir) {
            $State.FilteredOptions = @()
            $State.ActiveIndex = 0
            $State.FocusedValue = $null
            return
        }

        $items = @(Get-ChildItem -LiteralPath $searchDir -Force -ErrorAction SilentlyContinue)

        if ($State.OnlyDirectories) {
            $items = @($items | Where-Object { $_.PSIsContainer })
        }

        $filtered = @(
            $items |
                Where-Object {
                    if ($isWildcard) {
                        $_.Name -like $leaf
                    }
                    else {
                        $prefix = $inputPath.TrimEnd('\', '/')
                        $_.FullName.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)
                    }
                } |
                ForEach-Object {
                    [pscustomobject]@{
                        Value       = $_.FullName
                        Label       = if ($_.PSIsContainer) { $_.Name + '\' } else { $_.Name }
                        IsDirectory = $_.PSIsContainer
                        Disabled    = $false
                        Hint        = ''
                    }
                }
        )

        $State.FilteredOptions = $filtered

        if ($filtered.Count -eq 0) {
            $State.ActiveIndex = 0
            $State.FocusedValue = $null
            return
        }

        $priorFocus = $State.FocusedValue
        $idx = 0
        if ($null -ne $priorFocus) {
            for ($i = 0; $i -lt $filtered.Count; $i++) {
                if ($filtered[$i].Value -eq $priorFocus) {
                    $idx = $i
                    break
                }
            }
        }

        $State.ActiveIndex = [Math]::Min($idx, $filtered.Count - 1)
        $State.FocusedValue = $filtered[$State.ActiveIndex].Value
    }
    catch {
        $State.FilteredOptions = @()
        $State.ActiveIndex = 0
        $State.FocusedValue = $null
    }
}

function Update-PathPromptState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$State,

        [Parameter(Mandatory = $true)]
        [string]$Key
    )

    switch -Regex ($Key) {
        '^(Escape|CtrlC)$' {
            $State.Status = 'Cancelled'
            $State.Value = $null
            $State.SelectedLabel = $null
            $State.ErrorMessage = $null
            break
        }
        '^Up$' {
            $opts = @($State.FilteredOptions)
            if ($opts.Count -gt 0) {
                $State.ActiveIndex = (Find-AutocompleteCursor -Cursor $State.ActiveIndex -Delta -1 -Options $opts)
                $opt = $opts[$State.ActiveIndex]
                if ($opt) { $State.FocusedValue = $opt.Value }
            }

            $State.IsNavigating = $true
            $State.ErrorMessage = $null
            break
        }
        '^Down$' {
            $opts = @($State.FilteredOptions)
            if ($opts.Count -gt 0) {
                $State.ActiveIndex = (Find-AutocompleteCursor -Cursor $State.ActiveIndex -Delta 1 -Options $opts)
                $opt = $opts[$State.ActiveIndex]
                if ($opt) { $State.FocusedValue = $opt.Value }
            }

            $State.IsNavigating = $true
            $State.ErrorMessage = $null
            break
        }
        '^Tab$' {
            if ($null -ne $State.FocusedValue) {
                $focused = $State.FocusedValue
                $isDir = $false
                foreach ($o in $State.FilteredOptions) {
                    if ($o.Value -eq $focused) {
                        $isDir = [bool]$o.IsDirectory
                        break
                    }
                }

                $State.Input = if ($isDir) { $focused + '\' } else { $focused }
                $State.IsNavigating = $false
                Sync-PathOptions -State $State
                $State.ErrorMessage = $null
            }

            break
        }
        '^Enter$' {
            $value = if ($null -ne $State.FocusedValue) {
                [string]$State.FocusedValue
            }
            else {
                [string]$State.Input
            }

            $value = $value.TrimEnd('\', '/')

            if ([string]::IsNullOrWhiteSpace($value)) {
                $State.ErrorMessage = 'Please enter a path'
                break
            }

            $validationMessage = Invoke-Validation -Validate $State.Validate -Value $value
            if ([string]::IsNullOrWhiteSpace($validationMessage)) {
                $State.Status = 'Submitted'
                $State.Value = $value
                $State.SelectedLabel = $value
                $State.ErrorMessage = $null
            }
            else {
                $State.ErrorMessage = [string]$validationMessage
            }

            break
        }
        '^Backspace$' {
            $inp = [string]$State.Input
            if (-not [string]::IsNullOrEmpty($inp)) {
                if ($inp.EndsWith('\') -or $inp.EndsWith('/')) {
                    # Jump up one directory level so further typing stays in the parent
                    $trimmed = $inp.TrimEnd('\', '/')
                    $parent = Split-Path -Path $trimmed -Parent -ErrorAction SilentlyContinue
                    $State.Input = if ($parent) { $parent + '\' } else { $trimmed }
                }
                else {
                    $State.Input = $inp.Substring(0, $inp.Length - 1)
                }
            }

            $State.IsNavigating = $false
            Sync-PathOptions -State $State
            $State.ErrorMessage = $null
            break
        }
        '^Character:(.+)$' {
            $State.Input = '{0}{1}' -f $State.Input, $Matches[1]
            $State.IsNavigating = $false
            Sync-PathOptions -State $State
            $State.ErrorMessage = $null
            break
        }
    }

    return $State
}
