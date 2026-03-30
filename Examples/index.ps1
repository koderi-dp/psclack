param(
    [string]$Example,
    [switch]$List
)

$modulePath = Join-Path $PSScriptRoot '..\PsClack.psd1'
Import-Module $modulePath -Force

$exampleMap = [ordered]@{
    'basic-flow' = [pscustomobject]@{
        File = 'basic-flow.ps1'
        Description = 'Intro, text, select, confirm, and outro.'
    }
    'clack-demo' = [pscustomobject]@{
        File = 'clack-demo.ps1'
        Description = 'PowerShell port of the create-my-app demo using all current PsClack components.'
    }
    'password' = [pscustomobject]@{
        File = 'password.ps1'
        Description = 'Masked password input with validation and cancel handling.'
    }
    'note' = [pscustomobject]@{
        File = 'note.ps1'
        Description = 'Static informational note block.'
    }
    'box' = [pscustomobject]@{
        File = 'box.ps1'
        Description = 'Standalone boxed text display.'
    }
    'tasks' = [pscustomobject]@{
        File = 'tasks.ps1'
        Description = 'Sequential task execution with spinner-wrapped progress.'
    }
    'task-log' = [pscustomobject]@{
        File = 'task-log.ps1'
        Description = 'Buffered task log with groups and success/error completion.'
    }
    'progress' = [pscustomobject]@{
        File = 'progress.ps1'
        Description = 'Progress bar display built on the shared spinner renderer.'
    }
    'download' = [pscustomobject]@{
        File = 'download.ps1'
        Description = 'Paste a URL, stream the file with progress, then remove the temp file.'
    }
    'prompt-group' = [pscustomobject]@{
        File = 'prompt-group.ps1'
        Description = 'Grouped prompt flow returning a single object.'
    }
    'multi-select' = [pscustomobject]@{
        File = 'multi-select.ps1'
        Description = 'Multi-select prompt with validation.'
    }
    'multiselect-viewport' = [pscustomobject]@{
        File = 'multiselect-viewport.ps1'
        Description = 'Long multi-select list with viewporting and clipped overflow.'
    }
    'error-state' = [pscustomobject]@{
        File = 'error-state.ps1'
        Description = 'Validation errors for text and multiselect prompts.'
    }
    'select-viewport' = [pscustomobject]@{
        File = 'select-viewport.ps1'
        Description = 'Long select list with viewporting and overflow markers.'
    }
    'wrapped-prompts' = [pscustomobject]@{
        File = 'wrapped-prompts.ps1'
        Description = 'Long prompt text and wrapped option alignment.'
    }
    'wrapped-spinner' = [pscustomobject]@{
        File = 'wrapped-spinner.ps1'
        Description = 'Long spinner and outro messages with wrapped transcript lines.'
    }
    'spinner' = [pscustomobject]@{
        File = 'spinner.ps1'
        Description = 'Spinner lifecycle around simulated work.'
    }
    'non-interactive' = [pscustomobject]@{
        File = 'non-interactive.ps1'
        Description = 'Headless fallback values for automation and tests.'
    }
}

if ($List) {
    $exampleMap.GetEnumerator() | ForEach-Object {
        [pscustomobject]@{
            Name = $_.Key
            File = $_.Value.File
            Description = $_.Value.Description
        }
    }
    return
}

$selectedName = $Example
if ([string]::IsNullOrWhiteSpace($selectedName)) {
    Show-PsClackIntro -Message 'PsClack Examples'

    $selectedName = Read-PsClackSelectPrompt -Message 'Choose an example' -Options @(
        $exampleMap.GetEnumerator() | ForEach-Object {
            [pscustomobject]@{
                Label = '{0} - {1}' -f $_.Key, $_.Value.Description
                Value = $_.Key
            }
        }
    )
}

if (-not $exampleMap.Contains($selectedName)) {
    throw "Unknown example '$selectedName'. Use -List to see available examples."
}

$selected = $exampleMap[$selectedName]
$scriptPath = Join-Path $PSScriptRoot $selected.File

$shouldRun = $true
if (-not $PSBoundParameters.ContainsKey('Example')) {
    $shouldRun = Read-PsClackConfirmPrompt -Message ("Run {0}?" -f $selectedName) -InitialValue $true
}

if (-not $shouldRun) {
    Show-PsClackCancel -Message 'Example run cancelled.'
    return
}

$spinner = $null
if ($selectedName -ne 'spinner') {
    $spinner = Start-PsClackSpinner -Message ("Launching {0}" -f $selectedName)
}

try {
    if ($spinner) {
        $null = Stop-PsClackSpinner -Spinner $spinner -Status Success -Message ("Starting {0}" -f $selectedName)
    }

    & $scriptPath
    Show-PsClackOutro -Message ("Completed example: {0}" -f $selectedName)
}
catch {
    if ($spinner) {
        $null = Stop-PsClackSpinner -Spinner $spinner -Status Error -Message ("Failed to launch {0}" -f $selectedName)
    }

    Show-PsClackOutro -Message ("Example failed: {0}" -f $_.Exception.Message) -Status Error
    throw
}
