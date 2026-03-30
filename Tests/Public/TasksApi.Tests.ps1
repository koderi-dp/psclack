BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestBootstrap.ps1')
}

Describe 'PsClack task API' {
    It 'runs enabled tasks sequentially and returns result objects in passthru mode' {
        $results = Invoke-PsClackTasks -Plain -PassThru -Tasks @(
            [pscustomobject]@{
                Title = 'Install dependencies'
                Task = { 'Installed dependencies' }
            }
            [pscustomobject]@{
                Title = 'Generate project files'
                Task = { [pscustomobject]@{ Name = 'demo' } }
            }
        )

        $results.Count | Should -Be 2
        $results[0].Status | Should -Be 'Success'
        $results[0].Message | Should -Be 'Installed dependencies'
        $results[1].Status | Should -Be 'Success'
        $results[1].Value.Name | Should -Be 'demo'
        $results[1].Message | Should -Be 'Generate project files'
    }

    It 'marks disabled tasks as skipped' {
        $results = Invoke-PsClackTasks -Plain -PassThru -Tasks @(
            [pscustomobject]@{
                Title = 'Skipped task'
                Enabled = $false
                Task = { 'Should not run' }
            }
        )

        $results.Count | Should -Be 1
        $results[0].Status | Should -Be 'Skipped'
        $results[0].Skipped | Should -BeTrue
    }
}
