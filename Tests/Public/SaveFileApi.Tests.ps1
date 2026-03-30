BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestBootstrap.ps1')
}

Describe 'PsClack file download utility' {
    It 'throws when the destination exists and overwrite is not specified' {
        $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString('N'))
        $targetPath = Join-Path $tempRoot 'download.txt'
        [System.IO.Directory]::CreateDirectory($tempRoot) | Out-Null
        Set-Content -LiteralPath $targetPath -Value 'existing'

        try {
            { Save-PsClackFile -Uri 'https://example.com/file.txt' -Path $targetPath } | Should -Throw 'File already exists:*'
        }
        finally {
            if (Test-Path -LiteralPath $tempRoot) {
                Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
