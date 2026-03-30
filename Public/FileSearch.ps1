function Read-PsClackFileSearchPrompt {
    <#
    .SYNOPSIS
        Prompts the user to search for a file or directory by name within a directory tree.

    .DESCRIPTION
        Scans the given root directory (recursively by default), builds an in-memory index
        of matching filesystem entries, then presents them through the autocomplete prompt
        for interactive fuzzy filtering. Labels are shown as relative paths from Root.

        For large repositories consider passing -Filter (e.g. '*.ps1') or -Depth to limit
        the scan. The caller can wrap this call in Invoke-PsClackWithSpinner when the scan
        time matters to the user experience.

    .PARAMETER Message
        The prompt label shown to the user.

    .PARAMETER Root
        The root directory to scan. Defaults to the current working directory.

    .PARAMETER Filter
        A wildcard pattern applied to file names during the scan (e.g. '*.ps1', '*.txt').
        Defaults to '*' (all files).

    .PARAMETER Depth
        Maximum recursion depth. Omit for unlimited depth.

    .PARAMETER IncludeDirectories
        When set, directories are included in the results alongside files.

    .PARAMETER MaxResults
        Maximum number of entries added to the option list. Defaults to 500.

    .PARAMETER MaxItems
        Viewport height — number of options visible at once. Defaults to 10.

    .PARAMETER Validate
        A script block that receives the submitted path and returns an error message
        string (or null/empty) to accept.

    .PARAMETER NonInteractiveValue
        Path string to return immediately in non-interactive contexts.

    .PARAMETER Plain
        Renders without ANSI colour or Unicode symbols.

    .PARAMETER PassThru
        Returns a result object with Status, Value, Label, and Cancelled properties.

    .PARAMETER ReadKeyScript
        Overrides the default console key-read loop; used by tests.
    #>
    [CmdletBinding()]
    param(
        [string]$Message = 'Search files',

        [string]$Root,

        [string]$Filter = '*',

        [int]$Depth,

        [switch]$IncludeDirectories,

        [int]$MaxResults = 500,

        [int]$MaxItems = 10,

        [scriptblock]$Validate,

        [string]$NonInteractiveValue,

        [switch]$Plain,

        [switch]$PassThru,

        [scriptblock]$ReadKeyScript
    )

    $resolvedRoot = if ($PSBoundParameters.ContainsKey('Root') -and -not [string]::IsNullOrEmpty($Root)) {
        $Root
    }
    else {
        $PWD.Path
    }

    $resolvedRoot = $resolvedRoot.TrimEnd('\', '/')

    $interactiveConsole = Test-InteractiveConsole
    if (-not $ReadKeyScript -and -not $interactiveConsole) {
        if (-not $PSBoundParameters.ContainsKey('NonInteractiveValue')) {
            throw 'Read-PsClackFileSearchPrompt requires an interactive console, a ReadKeyScript override, or -NonInteractiveValue.'
        }

        $validationMessage = Invoke-Validation -Validate $Validate -Value $NonInteractiveValue
        if (-not [string]::IsNullOrWhiteSpace($validationMessage)) {
            throw "Read-PsClackFileSearchPrompt -NonInteractiveValue failed validation: $validationMessage"
        }

        $result = New-PromptResult -Status 'Submitted' -Value $NonInteractiveValue -Label $NonInteractiveValue
        if ($PassThru) { return $result }
        return $result.Value
    }

    # Scan filesystem — spin a manual ticker while a background job does the walk
    $scanSpinner = Start-PsClackSpinner -Message 'Indexing...' -Plain:$Plain -NoAutoSpin -ContinueTranscript

    $depthSet   = $PSBoundParameters.ContainsKey('Depth')
    $depthValue = if ($depthSet) { $Depth } else { $null }
    $inclDirs   = [bool]$IncludeDirectories

    $jobStarter = if (Get-Command Start-ThreadJob -ErrorAction SilentlyContinue) { 'Start-ThreadJob' } else { 'Start-Job' }
    $scanJob = & $jobStarter -ScriptBlock {
        param($root, $filter, $depthSet, $depth, $inclDirs)
        $p = @{ Path = $root; Recurse = $true; Filter = $filter; ErrorAction = 'SilentlyContinue' }
        if ($depthSet) { $p['Depth'] = $depth }
        if ($inclDirs) {
            $p.Remove('Filter')
            @(Get-ChildItem @p | Where-Object { $filter -eq '*' -or $_.Name -like $filter })
        }
        else {
            @(Get-ChildItem @p -File)
        }
    } -ArgumentList $resolvedRoot, $Filter, $depthSet, $depthValue, $inclDirs

    while ($scanJob.State -eq 'Running' -or $scanJob.State -eq 'NotStarted') {
        Start-Sleep -Milliseconds $scanSpinner.IntervalMs
        $null = Update-PsClackSpinner -Spinner $scanSpinner
    }

    $entries = @(Receive-Job -Job $scanJob -Wait -AutoRemoveJob -ErrorAction Stop)

    $null = Stop-PsClackSpinner -Spinner $scanSpinner -Message ('{0} files indexed' -f [Math]::Min($entries.Count, $MaxResults))

    if ($entries.Count -eq 0) {
        throw "Read-PsClackFileSearchPrompt: no files found under '$resolvedRoot' matching '$Filter'."
    }

    $options = @(
        $entries | Select-Object -First $MaxResults | ForEach-Object {
            $relPath = $_.FullName.Substring($resolvedRoot.Length).TrimStart('\', '/')
            [pscustomobject]@{
                Label = $relPath
                Value = $_.FullName
                Hint  = ''
            }
        }
    )

    # Path-aware filter: all space-separated tokens must appear in the relative path
    $pathFilter = {
        param($search, $option)
        if ([string]::IsNullOrEmpty($search)) { return $true }
        $rel = [string]$option.Label
        foreach ($token in $search.ToLowerInvariant().Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)) {
            if (-not $rel.ToLowerInvariant().Contains($token)) { return $false }
        }
        return $true
    }

    $autocompleteParams = @{
        Message    = $Message
        Options    = $options
        MaxItems   = $MaxItems
        Filter     = $pathFilter
        Plain      = $Plain
        PassThru   = $PassThru
    }

    if ($PSBoundParameters.ContainsKey('Validate')) {
        $autocompleteParams['Validate'] = $Validate
    }

    if ($PSBoundParameters.ContainsKey('ReadKeyScript')) {
        $autocompleteParams['ReadKeyScript'] = $ReadKeyScript
    }

    return Read-PsClackAutocompletePrompt @autocompleteParams
}
