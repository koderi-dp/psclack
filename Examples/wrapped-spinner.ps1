$modulePath = Join-Path $PSScriptRoot '..\PsClack.psd1'
Import-Module $modulePath -Force

Show-PsClackIntro -Message 'PsClack Wrapped Spinner'

$result = Invoke-PsClackWithSpinner `
    -Message 'Installing dependencies and preparing a deliberately long spinner message so wrapping under the guide can be inspected in the terminal transcript' `
    -SuccessMessage 'Finished installing dependencies and preparing the generated sample output for inspection in the terminal transcript' `
    -ScriptBlock {
        Start-Sleep -Milliseconds 1600
        'done'
    } `
    -ContinueTranscript

Show-PsClackOutro -Message ("Wrapped spinner demo complete with result {0} and a deliberately long outro message for alignment review." -f $result)
