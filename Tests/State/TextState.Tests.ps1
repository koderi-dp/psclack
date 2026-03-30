BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestBootstrap.ps1')
}

Describe 'PsClack text state' {
    It 'appends characters to the value' {
        $state = @{
            Value = 'ab'
            Validate = $null
            ErrorMessage = $null
            Status = 'Active'
            SelectedLabel = $null
        }

        $next = Update-TextPromptState -State $state -Key 'Character:c'

        $next.Value | Should -Be 'abc'
        $next.Status | Should -Be 'Active'
    }

    It 'stores validation errors on enter' {
        $state = @{
            Value = ''
            Validate = { param($value) if ([string]::IsNullOrWhiteSpace($value)) { 'Required' } }
            ErrorMessage = $null
            Status = 'Active'
            SelectedLabel = $null
        }

        $next = Update-TextPromptState -State $state -Key 'Enter'

        $next.Status | Should -Be 'Active'
        $next.ErrorMessage | Should -Be 'Required'
    }
}
