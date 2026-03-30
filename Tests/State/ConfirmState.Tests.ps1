BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestBootstrap.ps1')
}

Describe 'PsClack confirm state' {
    It 'switches to no on down' {
        $state = @{
            CurrentChoice = $true
            Status = 'Active'
            Value = $null
            SelectedLabel = $null
        }

        $next = Update-ConfirmPromptState -State $state -Key 'Down'

        $next.CurrentChoice | Should -BeFalse
    }

    It 'submits yes on enter' {
        $state = @{
            CurrentChoice = $true
            Status = 'Active'
            Value = $null
            SelectedLabel = $null
        }

        $next = Update-ConfirmPromptState -State $state -Key 'Enter'

        $next.Status | Should -Be 'Submitted'
        $next.Value | Should -BeTrue
        $next.SelectedLabel | Should -Be 'Yes'
    }
}
