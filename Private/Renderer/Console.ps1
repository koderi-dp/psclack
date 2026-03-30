function Ensure-ConsoleUtf8 {
    [CmdletBinding()]
    param()

    try {
        $utf8 = [System.Text.UTF8Encoding]::new($false)
        if ([Console]::OutputEncoding.WebName -ne $utf8.WebName) {
            [Console]::OutputEncoding = $utf8
        }
    }
    catch {
    }
}

function Get-TerminalHeight {
    [CmdletBinding()]
    param()

    try {
        if ([Console]::WindowHeight -gt 0) {
            return [int][Console]::WindowHeight
        }

        return [int][Math]::Max(1, [Console]::BufferHeight)
    }
    catch {
        return 20
    }
}

function Get-TerminalWidth {
    [CmdletBinding()]
    param()

    try {
        return [Math]::Max(1, [Console]::BufferWidth)
    }
    catch {
        return 120
    }
}

function Hide-ConsoleCursor {
    [CmdletBinding()]
    param()

    try {
        $wasVisible = [bool][Console]::CursorVisible
        [Console]::CursorVisible = $false
        return $wasVisible
    }
    catch {
        return $null
    }
}

function Move-Cursor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$Left,

        [Parameter(Mandatory = $true)]
        [int]$Top
    )

    $safeWidth = [Math]::Max(1, [Console]::BufferWidth)
    $safeHeight = [Math]::Max(1, [Console]::BufferHeight)
    $safeLeft = [Math]::Min([Math]::Max(0, $Left), $safeWidth - 1)
    $safeTop = [Math]::Min([Math]::Max(0, $Top), $safeHeight - 1)

    [Console]::SetCursorPosition($safeLeft, $safeTop)
}

function Restore-ConsoleCursor {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object]$Visible
    )

    if ($null -eq $Visible) {
        return
    }

    try {
        [Console]::CursorVisible = [bool]$Visible
    }
    catch {
    }
}
