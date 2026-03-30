# PsClack Examples

These examples are standalone PowerShell scripts for the `PsClack` module.

Run from the repo root with PowerShell 7+.

## Available examples

- `basic-flow.ps1`: intro, text, select, confirm, outro
- `clack-demo.ps1`: PowerShell port of the create-my-app demo using all current PsClack components
- `clack-demo.snapshot.ps1`: prints renderer snapshots without live cursor redraw
- `password.ps1`: masked password input with validation and cancel handling
- `note.ps1`: static informational note block
- `box.ps1`: standalone boxed text display
- `tasks.ps1`: sequential task execution with spinner-wrapped progress
- `task-log.ps1`: buffered task log with grouped output, bounded log history, and `--fail` error mode
- `progress.ps1`: progress bar display with `-Fail` support for the error end state
- `download.ps1`: prompts for a file URL, streams it with progress, and removes the temp file afterward
- `prompt-group.ps1`: grouped prompt flow returning a single object
- `multi-select.ps1`: multiselect prompt usage
- `multiselect-viewport.ps1`: long multiselect list with viewporting and clipped overflow
- `error-state.ps1`: validation errors for text and multiselect prompts
- `select-viewport.ps1`: long select list with viewporting and overflow markers
- `wrapped-prompts.ps1`: long prompt text and wrapped option alignment
- `wrapped-spinner.ps1`: long spinner and outro messages with wrapped transcript lines
- `spinner.ps1`: foreground-owned spinner task example
- `non-interactive.ps1`: explicit headless fallback values for automation and tests
- `index.ps1`: PsClack-driven example launcher

## Example usage

```powershell
pwsh .\ocd\components\PsClack\Examples\index.ps1
pwsh .\ocd\components\PsClack\Examples\index.ps1 -List
pwsh .\ocd\components\PsClack\Examples\index.ps1 -Example clack-demo
pwsh .\ocd\components\PsClack\Examples\password.ps1
pwsh .\ocd\components\PsClack\Examples\note.ps1
pwsh .\ocd\components\PsClack\Examples\box.ps1
pwsh .\ocd\components\PsClack\Examples\tasks.ps1
pwsh .\ocd\components\PsClack\Examples\task-log.ps1
pwsh .\ocd\components\PsClack\Examples\task-log.ps1 -Fail
pwsh .\ocd\components\PsClack\Examples\progress.ps1
pwsh .\ocd\components\PsClack\Examples\progress.ps1 -Fail
pwsh .\ocd\components\PsClack\Examples\download.ps1
pwsh .\ocd\components\PsClack\Examples\select-viewport.ps1
pwsh .\ocd\components\PsClack\Examples\multiselect-viewport.ps1
pwsh .\ocd\components\PsClack\Examples\error-state.ps1
pwsh .\ocd\components\PsClack\Examples\wrapped-prompts.ps1
pwsh .\ocd\components\PsClack\Examples\wrapped-spinner.ps1
pwsh .\ocd\components\PsClack\Examples\clack-demo.ps1
pwsh .\ocd\components\PsClack\Examples\clack-demo.snapshot.ps1
```

## Spinner note

`Invoke-PsClackWithSpinner` is the preferred foreground-owned spinner API used by the examples.
`Start-PsClackSpinner -NoAutoSpin` with `Update-PsClackSpinner` remains available when you want manual control.

## Debug capture

To capture the live interactive frames written by `Write-Frame`, set `PSCLACK_CAPTURE_PATH` before running an example:

```powershell
$env:PSCLACK_CAPTURE_PATH = "$PWD\\psclack-capture.jsonl"
pwsh .\ocd\components\PsClack\Examples\clack-demo.ps1
Remove-Item Env:PSCLACK_CAPTURE_PATH
```

Each line in the capture file is one JSON frame record.
