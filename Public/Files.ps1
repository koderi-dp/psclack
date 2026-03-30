function Save-PsClackFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Uri]$Uri,

        [string]$Path,

        [int]$TimeoutSeconds = 1800,

        [switch]$Overwrite,

        [int]$ChunkSizeBytes = 1MB,

        [int]$ProgressIntervalMilliseconds = 100,

        [scriptblock]$StartedAction,

        [scriptblock]$ProgressChangedAction,

        [scriptblock]$CompletedAction,

        [scriptblock]$FailedAction
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        $fileName = [System.IO.Path]::GetFileName($Uri.LocalPath)
        if ([string]::IsNullOrWhiteSpace($fileName)) {
            $fileName = 'download.bin'
        }

        $Path = Join-Path ([System.IO.Path]::GetTempPath()) ("PsClack-{0}-{1}" -f ([guid]::NewGuid().ToString('N')), $fileName)
    }

    $resolvedPath = if ([System.IO.Path]::IsPathRooted($Path)) {
        $Path
    }
    else {
        Join-Path (Get-Location) $Path
    }

    $directoryPath = [System.IO.Path]::GetDirectoryName($resolvedPath)
    if (-not [string]::IsNullOrWhiteSpace($directoryPath) -and -not (Test-Path -LiteralPath $directoryPath)) {
        [System.IO.Directory]::CreateDirectory($directoryPath) | Out-Null
    }

    if ((Test-Path -LiteralPath $resolvedPath) -and -not $Overwrite) {
        throw "File already exists: $resolvedPath"
    }

    $request = $null
    $response = $null
    $responseStream = $null
    $fileStream = $null
    $bytesDownloaded = 0L
    $contentLength = 0L
    $contentType = ''
    $fileName = [System.IO.Path]::GetFileName($resolvedPath)
    $sourceFileName = [System.IO.Path]::GetFileName($Uri.LocalPath)
    if ([string]::IsNullOrWhiteSpace($sourceFileName)) {
        $sourceFileName = $fileName
    }
    $startedAt = [DateTime]::UtcNow

    function New-DownloadState {
        param(
            [long]$BytesDownloaded,
            [long]$ContentLength,
            [string]$ContentType,
            [long]$ChunkBytes = 0,
            [double]$ElapsedSeconds = 0,
            [switch]$Completed
        )

        $percent = if ($ContentLength -gt 0) {
            [Math]::Min(100.0, ($BytesDownloaded / [double]$ContentLength) * 100.0)
        }
        else {
            $null
        }

        [pscustomobject]@{
            Uri = $Uri.AbsoluteUri
            Path = $resolvedPath
            FileName = $fileName
            SourceFileName = $sourceFileName
            BytesDownloaded = [int64]$BytesDownloaded
            ContentLength = [int64]$ContentLength
            ContentType = [string]$ContentType
            ChunkBytes = [int64]$ChunkBytes
            Percent = $percent
            ElapsedSeconds = $ElapsedSeconds
            BytesPerSecond = if ($ElapsedSeconds -gt 0) { $BytesDownloaded / $ElapsedSeconds } else { 0.0 }
            Completed = [bool]$Completed
        }
    }

    try {
        $request = [System.Net.HttpWebRequest]::Create($Uri)
        $request.Method = 'GET'
        $request.Timeout = [int][TimeSpan]::FromSeconds([Math]::Max(1, $TimeoutSeconds)).TotalMilliseconds
        $request.ReadWriteTimeout = [int][TimeSpan]::FromSeconds([Math]::Max(1, $TimeoutSeconds)).TotalMilliseconds

        $response = [System.Net.HttpWebResponse]$request.GetResponse()
        $responseStream = $response.GetResponseStream()
        $contentLength = [int64][Math]::Max(0, $response.ContentLength)
        $contentType = [string]$response.ContentType

        $fileMode = if ($Overwrite) { [System.IO.FileMode]::Create } else { [System.IO.FileMode]::CreateNew }
        $fileStream = [System.IO.File]::Open($resolvedPath, $fileMode, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)

        if ($StartedAction) {
            & $StartedAction (New-DownloadState -BytesDownloaded 0 -ContentLength $contentLength -ContentType $contentType -ElapsedSeconds 0)
        }

        $buffer = [byte[]]::new([Math]::Max(4096, $ChunkSizeBytes))
        $lastProgressTick = [Environment]::TickCount64
        while (($bytesRead = $responseStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $fileStream.Write($buffer, 0, $bytesRead)
            $bytesDownloaded += $bytesRead
            $elapsedSeconds = [Math]::Max(0.001, ([DateTime]::UtcNow - $startedAt).TotalSeconds)

            if ($ProgressChangedAction) {
                $currentTick = [Environment]::TickCount64
                $elapsed = [Math]::Max(0, $currentTick - $lastProgressTick)
                if ($elapsed -ge [Math]::Max(0, $ProgressIntervalMilliseconds)) {
                    & $ProgressChangedAction (New-DownloadState -BytesDownloaded $bytesDownloaded -ContentLength $contentLength -ContentType $contentType -ChunkBytes $bytesRead -ElapsedSeconds $elapsedSeconds)
                    $lastProgressTick = $currentTick
                }
            }
        }

        $result = New-DownloadState -BytesDownloaded $bytesDownloaded -ContentLength $contentLength -ContentType $contentType -ElapsedSeconds ([Math]::Max(0.001, ([DateTime]::UtcNow - $startedAt).TotalSeconds)) -Completed
        if ($CompletedAction) {
            & $CompletedAction $result
        }

        return $result
    }
    catch {
        if ($FailedAction) {
            & $FailedAction ([pscustomobject]@{
                Uri = $Uri.AbsoluteUri
                Path = $resolvedPath
                FileName = $fileName
                SourceFileName = $sourceFileName
                BytesDownloaded = [int64]$bytesDownloaded
                ContentLength = [int64]$contentLength
                ContentType = [string]$contentType
                ElapsedSeconds = [Math]::Max(0.001, ([DateTime]::UtcNow - $startedAt).TotalSeconds)
                BytesPerSecond = if (([DateTime]::UtcNow - $startedAt).TotalSeconds -gt 0) { $bytesDownloaded / ([DateTime]::UtcNow - $startedAt).TotalSeconds } else { 0.0 }
                Exception = $_.Exception
            })
        }

        if (Test-Path -LiteralPath $resolvedPath) {
            Remove-Item -LiteralPath $resolvedPath -Force -ErrorAction SilentlyContinue
        }

        throw
    }
    finally {
        if ($responseStream) { $responseStream.Dispose() }
        if ($response) { $response.Dispose() }
        if ($fileStream) { $fileStream.Dispose() }
    }
}

