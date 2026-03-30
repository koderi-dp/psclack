BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestBootstrap.ps1')
}

Describe 'PsClack path rendering' {
    It 'renders the active state with path input and options' {
        $theme = Get-Theme -Plain

        $lines = Render-PathPrompt -Theme $theme -State @{
            Message             = 'Select a file'
            Input               = 'C:\foo'
            FilteredOptions     = @(
                [pscustomobject]@{ Value = 'C:\foobar'; Label = 'foobar'; IsDirectory = $false; Disabled = $false; Hint = '' }
                [pscustomobject]@{ Value = 'C:\foobaz'; Label = 'foobaz\'; IsDirectory = $true; Disabled = $false; Hint = '' }
            )
            ActiveIndex         = 0
            FocusedValue        = 'C:\foobar'
            IsNavigating        = $false
            OnlyDirectories     = $false
            MaxItems            = 5
            ErrorMessage        = $null
            Status              = 'Active'
            SuppressLeadingGuide = $false
        }

        $lines[0] | Should -Be '│'
        $lines[1] | Should -Match 'Select a file'
        $lines | Should -Contain '│  Path: C:\foo_'
        $lines | Should -Contain '│  ● foobar'
        $lines | Should -Contain '│  ○ foobaz\'
    }

    It 'renders the submitted state showing the selected path' {
        $theme = Get-Theme -Plain

        $lines = Render-PathPrompt -Theme $theme -State @{
            Message             = 'Select a file'
            Input               = 'C:\foo\bar.txt'
            FilteredOptions     = @()
            ActiveIndex         = 0
            FocusedValue        = $null
            IsNavigating        = $false
            OnlyDirectories     = $false
            MaxItems            = 5
            ErrorMessage        = $null
            Status              = 'Submitted'
            Value               = 'C:\foo\bar.txt'
            SelectedLabel       = 'C:\foo\bar.txt'
            SuppressLeadingGuide = $false
        }

        $lines | Should -Contain '│  C:\foo\bar.txt'
    }

    It 'renders the cancelled state with strikethrough on the input' {
        $theme = Get-Theme -Plain

        $lines = Render-PathPrompt -Theme $theme -State @{
            Message             = 'Select a file'
            Input               = 'C:\partial'
            FilteredOptions     = @()
            ActiveIndex         = 0
            FocusedValue        = $null
            IsNavigating        = $false
            OnlyDirectories     = $false
            MaxItems            = 5
            ErrorMessage        = $null
            Status              = 'Cancelled'
            Value               = $null
            SelectedLabel       = $null
            SuppressLeadingGuide = $false
        }

        $lines | Should -Contain '│  C:\partial'
    }

    It 'renders a validation error message' {
        $theme = Get-Theme -Plain

        $lines = Render-PathPrompt -Theme $theme -State @{
            Message             = 'Select a file'
            Input               = 'C:\bad'
            FilteredOptions     = @()
            ActiveIndex         = 0
            FocusedValue        = $null
            IsNavigating        = $false
            OnlyDirectories     = $false
            MaxItems            = 5
            ErrorMessage        = 'Path does not exist'
            Status              = 'Active'
            SuppressLeadingGuide = $false
        }

        $lines | Should -Contain '└  Path does not exist'
    }

    It 'does not throw when FilteredOptions is empty' {
        $theme = Get-Theme -Plain

        { Render-PathPrompt -Theme $theme -State @{
            Message             = 'Select a file'
            Input               = 'C:\nonexistent'
            FilteredOptions     = @()
            ActiveIndex         = 0
            FocusedValue        = $null
            IsNavigating        = $false
            OnlyDirectories     = $false
            MaxItems            = 5
            ErrorMessage        = $null
            Status              = 'Active'
            SuppressLeadingGuide = $false
        } } | Should -Not -Throw
    }
}
