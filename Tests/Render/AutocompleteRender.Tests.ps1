BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestBootstrap.ps1')
}

Describe 'PsClack autocomplete rendering' {
    It 'renders search row and first option for active single-select' {
        $state = @{
            Message = 'Pick one'
            AllOptions = @(
                [pscustomobject]@{ Label = 'A'; Value = 'a'; Hint = ''; Disabled = $false }
                [pscustomobject]@{ Label = 'B'; Value = 'b'; Hint = ''; Disabled = $false }
            )
            Search = ''
            FilteredOptions = @(
                [pscustomobject]@{ Label = 'A'; Value = 'a'; Hint = ''; Disabled = $false }
                [pscustomobject]@{ Label = 'B'; Value = 'b'; Hint = ''; Disabled = $false }
            )
            ActiveIndex = 0
            FocusedValue = 'a'
            SelectedValues = @('a')
            IsNavigating = $false
            Multiple = $false
            Placeholder = ''
            MaxItems = [int]::MaxValue
            ErrorMessage = $null
            Status = 'Active'
            Required = $false
            SuppressLeadingGuide = $false
        }

        $theme = Get-Theme -Plain
        $lines = Render-AutocompletePrompt -State $state -Theme $theme

        $lines[0] | Should -Be $theme.Symbols.GuideBar
        $lines[1] | Should -BeLike ('{0}*Pick one' -f $theme.Symbols.StepActive)
        $lines[2] | Should -Be $theme.Symbols.GuideBar
        $lines[3] | Should -BeLike ('{0}*Search:*' -f $theme.Symbols.GuideBar)
        $lines[4] | Should -Match 'A'
    }

    It 'renders no-matches state without throwing when FilteredOptions is empty' {
        $state = @{
            Message = 'Pick one'
            AllOptions = @(
                [pscustomobject]@{ Label = 'A'; Value = 'a'; Hint = ''; Disabled = $false }
            )
            Search = 'zzz'
            FilteredOptions = @()
            ActiveIndex = 0
            FocusedValue = $null
            SelectedValues = @()
            IsNavigating = $false
            Multiple = $false
            Placeholder = ''
            MaxItems = [int]::MaxValue
            ErrorMessage = $null
            Status = 'Active'
            Required = $false
            SuppressLeadingGuide = $false
        }

        $theme = Get-Theme -Plain
        { Render-AutocompletePrompt -State $state -Theme $theme } | Should -Not -Throw
        $lines = Render-AutocompletePrompt -State $state -Theme $theme
        $joined = $lines -join "`n"
        $joined | Should -Match 'No matches found'
    }

    It 'renders multiselect with empty search while IsNavigating without throwing' {
        $state = @{
            Message = 'Pick stacks'
            AllOptions = @(
                [pscustomobject]@{ Label = 'Frontend'; Value = 'fe'; Hint = ''; Disabled = $false }
                [pscustomobject]@{ Label = 'Backend'; Value = 'be'; Hint = ''; Disabled = $false }
            )
            Search = ''
            FilteredOptions = @(
                [pscustomobject]@{ Label = 'Frontend'; Value = 'fe'; Hint = ''; Disabled = $false }
                [pscustomobject]@{ Label = 'Backend'; Value = 'be'; Hint = ''; Disabled = $false }
            )
            ActiveIndex = 0
            FocusedValue = 'fe'
            SelectedValues = @('fe')
            IsNavigating = $true
            Multiple = $true
            Placeholder = ''
            MaxItems = [int]::MaxValue
            ErrorMessage = $null
            Status = 'Active'
            Required = $false
            SuppressLeadingGuide = $false
        }

        $theme = Get-Theme -Plain
        { Render-AutocompletePrompt -State $state -Theme $theme } | Should -Not -Throw
    }
}
