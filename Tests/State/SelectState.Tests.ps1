BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestBootstrap.ps1')
}

Describe 'PsClack select state' {
    It 'moves active index down' {
        $state = @{
            Options = @(
                [pscustomobject]@{ Label = 'one'; Value = 1 }
                [pscustomobject]@{ Label = 'two'; Value = 2 }
            )
            ActiveIndex = 0
            Status = 'Active'
            Value = $null
            SelectedLabel = $null
        }

        $next = Update-SelectPromptState -State $state -Key 'Down'

        $next.ActiveIndex | Should -Be 1
        $next.Status | Should -Be 'Active'
    }

    It 'submits selected option on enter' {
        $state = @{
            Options = @(
                [pscustomobject]@{ Label = 'one'; Value = 1 }
                [pscustomobject]@{ Label = 'two'; Value = 2 }
            )
            ActiveIndex = 1
            Status = 'Active'
            Value = $null
            SelectedLabel = $null
        }

        $next = Update-SelectPromptState -State $state -Key 'Enter'

        $next.Status | Should -Be 'Submitted'
        $next.Value | Should -Be 2
        $next.SelectedLabel | Should -Be 'two'
    }
}
