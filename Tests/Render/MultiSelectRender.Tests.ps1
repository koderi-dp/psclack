BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestBootstrap.ps1')
}

Describe 'PsClack multiselect rendering' {
    It 'renders selected and unselected markers with guide lines' {
        $state = @{
            Message = 'Pick features'
            Options = @(
                [pscustomobject]@{ Label = 'TypeScript'; Value = 'ts'; Selected = $true }
                [pscustomobject]@{ Label = 'ESLint'; Value = 'eslint'; Selected = $false }
            )
            ActiveIndex = 0
            ErrorMessage = $null
            Status = 'Active'
            Value = $null
            SelectedLabel = $null
        }

        $theme = Get-Theme -Plain
        $lines = Render-MultiSelectPrompt -State $state -Theme $theme

        $lines[0] | Should -Be $theme.Symbols.GuideBar
        $lines[1] | Should -Be ('{0}  Pick features' -f $theme.Symbols.StepActive)
        $lines[2] | Should -Be ('{0}  {1} TypeScript' -f $theme.Symbols.GuideBar, $theme.Symbols.CheckboxSelected)
        $lines[3] | Should -Be ('{0}  {1} ESLint' -f $theme.Symbols.GuideBar, $theme.Symbols.CheckboxUnselected)
        $lines[4] | Should -Be $theme.Symbols.GuideEnd
    }

    It 'limits multiselect options and shows clipped overflow markers' {
        Mock Get-TerminalHeight { 10 }

        $state = @{
            Message = 'Pick features'
            Options = @(
                [pscustomobject]@{ Label = 'One'; Value = 1; Selected = $false }
                [pscustomobject]@{ Label = 'Two'; Value = 2; Selected = $false }
                [pscustomobject]@{ Label = 'Three'; Value = 3; Selected = $false }
                [pscustomobject]@{ Label = 'Four'; Value = 4; Selected = $true }
                [pscustomobject]@{ Label = 'Five'; Value = 5; Selected = $false }
                [pscustomobject]@{ Label = 'Six'; Value = 6; Selected = $false }
                [pscustomobject]@{ Label = 'Seven'; Value = 7; Selected = $false }
            )
            ActiveIndex = 4
            ErrorMessage = $null
            Status = 'Active'
            Value = $null
            SelectedLabel = $null
            MaxItems = [int]::MaxValue
        }

        $theme = Get-Theme -Plain
        $lines = Render-MultiSelectPrompt -State $state -Theme $theme

        $lines | Should -Be @(
            $theme.Symbols.GuideBar
            ('{0}  Pick features' -f $theme.Symbols.StepActive)
            ('{0}  ...' -f $theme.Symbols.GuideBar)
            ('{0}  {1} Three' -f $theme.Symbols.GuideBar, $theme.Symbols.CheckboxUnselected)
            ('{0}  {1} Four' -f $theme.Symbols.GuideBar, $theme.Symbols.CheckboxSelected)
            ('{0}  {1} Five' -f $theme.Symbols.GuideBar, $theme.Symbols.CheckboxUnselected)
            ('{0}  {1} Six' -f $theme.Symbols.GuideBar, $theme.Symbols.CheckboxUnselected)
            ('{0}  {1} Seven' -f $theme.Symbols.GuideBar, $theme.Symbols.CheckboxUnselected)
            $theme.Symbols.GuideEnd
        )
    }
}
