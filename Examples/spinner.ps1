$modulePath = Join-Path $PSScriptRoot '..\PsClack.psd1'
Import-Module $modulePath -Force

$result = Invoke-PsClackWithSpinner -Message 'Simulating work' -SuccessMessage 'Work complete' -ScriptBlock {
    Start-Sleep -Milliseconds 800
    return 'done'
}

$result | Out-Null
