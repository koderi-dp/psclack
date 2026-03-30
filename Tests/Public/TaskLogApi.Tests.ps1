BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestBootstrap.ps1')
}

Describe 'PsClack task log API' {
    It 'creates a task log and records root messages' {
        $log = New-PsClackTaskLog -Title 'Build pipeline' -Plain -NoRender

        $log.Message('Restoring packages')

        $lines = Render-TaskLog -State $log.State
        $lines | Should -Contain '│  Restoring packages'
    }

    It 'supports grouped success completion and root success' {
        $log = New-PsClackTaskLog -Title 'Build pipeline' -Plain -NoRender

        $group = $log.Group('Compile')
        $group.Message('Bundling assets')
        $group.Success('Compile ready')
        $log.Success('Pipeline finished')

        $lines = Render-TaskLog -State $log.State
        ($lines -join "`n") | Should -Match 'Pipeline finished'
    }

    It 'shows the log on root error by default' {
        $log = New-PsClackTaskLog -Title 'Build pipeline' -Plain -NoRender

        $log.Message('Running tests')
        $log.Error('Tests failed')

        $lines = Render-TaskLog -State $log.State
        $lines[0] | Should -Be '▲  Tests failed'
        $lines | Should -Contain '│'
        $lines | Should -Contain '│  Running tests'
    }
}
