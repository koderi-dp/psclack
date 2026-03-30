BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\..\PsClack\PsClack.psd1') -Force
}

Describe 'PsClack Invoke-PsClackWithSpinner' {
    It 'returns the script result and stops with success' {
        $result = Invoke-PsClackWithSpinner -Message 'Installing' -SuccessMessage 'Installed' -ScriptBlock {
            Start-Sleep -Milliseconds 60
            return 'done'
        } -IntervalMs 20

        $result | Should -Be 'done'
    }

    It 'rethrows errors from the task script' {
        { Invoke-PsClackWithSpinner -Message 'Installing' -ErrorMessage 'Failed' -ScriptBlock {
                throw 'boom'
            } -IntervalMs 20 } | Should -Throw
    }
}
