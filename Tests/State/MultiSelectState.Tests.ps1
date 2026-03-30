BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestBootstrap.ps1')
}

Describe 'PsClack multiselect state' {
    It 'toggles the active option on space' {
        $state = @{
            Options = @(
                [pscustomobject]@{ Label = 'one'; Value = 1; Selected = $false }
                [pscustomobject]@{ Label = 'two'; Value = 2; Selected = $false }
            )
            ActiveIndex = 1
            Validate = $null
            ErrorMessage = $null
            Status = 'Active'
            Value = $null
            SelectedLabel = $null
        }

        $next = Update-MultiSelectPromptState -State $state -Key 'Space'

        $next.Options[1].Selected | Should -BeTrue
        $next.Status | Should -Be 'Active'
    }

    It 'submits selected values on enter' {
        $state = @{
            Options = @(
                [pscustomobject]@{ Label = 'one'; Value = 1; Selected = $true }
                [pscustomobject]@{ Label = 'two'; Value = 2; Selected = $false }
            )
            ActiveIndex = 0
            Validate = $null
            ErrorMessage = $null
            Status = 'Active'
            Value = $null
            SelectedLabel = $null
        }

        $next = Update-MultiSelectPromptState -State $state -Key 'Enter'

        $next.Status | Should -Be 'Submitted'
        @($next.Value) | Should -Be @(1)
    }
}
