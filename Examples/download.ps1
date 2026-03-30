param(
    [string]$Url
)

$modulePath = Join-Path $PSScriptRoot '..\PsClack.psd1'
Import-Module $modulePath -Force

function Format-ByteSize {
    param([double]$Bytes)

    $units = @('B', 'KB', 'MB', 'GB', 'TB')
    $size = [double][Math]::Max(0, $Bytes)
    $unitIndex = 0

    while ($size -ge 1024 -and $unitIndex -lt ($units.Count - 1)) {
        $size /= 1024
        $unitIndex++
    }

    if ($unitIndex -eq 0) {
        return '{0} {1}' -f [int][Math]::Round($size), $units[$unitIndex]
    }

    return '{0:N1} {1}' -f $size, $units[$unitIndex]
}

function Format-TransferRate {
    param([double]$BytesPerSecond)

    return '{0}/s' -f (Format-ByteSize -Bytes $BytesPerSecond)
}

function Get-ExampleTerminalWidth {
    try {
        return [Math]::Max(40, [Console]::BufferWidth)
    }
    catch {
        return 120
    }
}

function Format-MiddleEllipsis {
    param(
        [string]$Text,
        [int]$MaxLength
    )

    $safeText = [string]$Text
    if ($MaxLength -le 0) { return '' }
    if ($safeText.Length -le $MaxLength) { return $safeText }
    if ($MaxLength -le 1) { return '…' }
    if ($MaxLength -le 3) { return ($safeText.Substring(0, 1) + '…') }

    $frontLength = [Math]::Ceiling(($MaxLength - 1) / 2)
    $backLength = [Math]::Floor(($MaxLength - 1) / 2)
    return '{0}…{1}' -f $safeText.Substring(0, $frontLength), $safeText.Substring($safeText.Length - $backLength)
}

function Format-DownloadMessage {
    param([pscustomobject]$State)

    $terminalWidth = Get-ExampleTerminalWidth
    $fileName = if ([string]::IsNullOrWhiteSpace($State.SourceFileName)) { $State.FileName } else { $State.SourceFileName }
    $speed = Format-TransferRate -BytesPerSecond $State.BytesPerSecond
    $percent = '{0:N1}%%' -f $State.Percent
    $sizeText = '{0} / {1}' -f (Format-ByteSize -Bytes $State.BytesDownloaded), (Format-ByteSize -Bytes $State.ContentLength)

    if ($terminalWidth -ge 140) {
        return 'Downloading {0} ({1}, {2}, {3})' -f $fileName, $sizeText, $percent, $speed
    }

    if ($terminalWidth -ge 110) {
        return 'Downloading {0} ({1}, {2})' -f (Format-MiddleEllipsis -Text $fileName -MaxLength 36), $percent, $speed
    }

    if ($terminalWidth -ge 90) {
        return '{0} ({1}, {2})' -f (Format-MiddleEllipsis -Text $fileName -MaxLength 26), $percent, $speed
    }

    return '{0} {1}' -f (Format-MiddleEllipsis -Text $fileName -MaxLength 18), $percent
}

Show-PsClackIntro -Message 'download'

$urlResult = if ([string]::IsNullOrWhiteSpace($Url)) {
    Read-PsClackTextPrompt `
        -Message 'Paste a file URL to download' `
        -Placeholder 'https://example.com/file.zip' `
        -Validate {
            param($value)

            if ([string]::IsNullOrWhiteSpace($value)) {
                return 'Enter a URL.'
            }

            $uri = $null
            if (-not [Uri]::TryCreate($value, [UriKind]::Absolute, [ref]$uri)) {
                return 'Enter a valid absolute URL.'
            }

            if ($uri.Scheme -notin @('http', 'https')) {
                return 'Only http and https URLs are supported.'
            }

            return $null
        } `
        -PassThru
}
else {
    [pscustomobject]@{
        Status = 'Submitted'
        Value = $Url
    }
}

if ($urlResult.Status -eq 'Cancelled') {
    Show-PsClackCancel -Message 'Download cancelled.'
    return
}

$downloadUrl = [string]$urlResult.Value
$uri = [Uri]$downloadUrl
$fileName = [IO.Path]::GetFileName($uri.LocalPath)
if ([string]::IsNullOrWhiteSpace($fileName)) {
    $fileName = 'download.bin'
}

$tempPath = Join-Path ([IO.Path]::GetTempPath()) ("PsClack-{0}-{1}" -f ([guid]::NewGuid().ToString('N')), $fileName)
$progress = $null
$spinner = $null
$completed = $false

try {
    $result = Save-PsClackFile `
        -Uri $uri `
        -Path $tempPath `
        -Overwrite `
        -ChunkSizeBytes 1MB `
        -ProgressIntervalMilliseconds 100 `
        -StartedAction {
            param($state)

            if ($state.ContentLength -gt 0) {
                $script:progress = New-PsClackProgress -Style Heavy -Max 1000 -Size 36 -MinSize 12 -ContinueTranscript
                $script:progress.Start((Format-DownloadMessage -State ([pscustomobject]@{
                    FileName = $state.FileName
                    SourceFileName = $state.SourceFileName
                    BytesDownloaded = 0L
                    ContentLength = $state.ContentLength
                    Percent = 0.0
                    BytesPerSecond = 0.0
                })))
            }
            else {
                $script:spinner = Start-PsClackSpinner -Message ("Downloading {0}" -f $state.SourceFileName) -ContinueTranscript -NoAutoSpin
            }
        } `
        -ProgressChangedAction {
            param($state)

            if ($script:progress) {
                $targetValue = [int][Math]::Min(1000, [Math]::Floor(($state.BytesDownloaded / [double]$state.ContentLength) * 1000))
                $delta = $targetValue - [int]$script:progress.ProgressValue
                $message = Format-DownloadMessage -State $state

                if ($delta -gt 0) {
                    $script:progress.Advance($delta, $message)
                }
                else {
                    $script:progress.Message($message)
                }
            }
            elseif ($script:spinner) {
                Update-PsClackSpinner -Spinner $script:spinner | Out-Null
            }
        } `
        -CompletedAction {
            param($state)

            if ($script:progress) {
                $script:progress.Stop(("Downloaded {0} ({1})" -f $state.SourceFileName, (Format-ByteSize -Bytes $state.BytesDownloaded)))
            }
            elseif ($script:spinner) {
                Stop-PsClackSpinner -Spinner $script:spinner -Status Success -Message ("Downloaded {0} ({1})" -f $state.SourceFileName, (Format-ByteSize -Bytes $state.BytesDownloaded)) | Out-Null
            }
        } `
        -FailedAction {
            param($state)

            if ($script:progress -and $script:progress.Status -eq 'Running') {
                $script:progress.Error($state.Exception.Message)
            }
            elseif ($script:spinner -and $script:spinner.Status -eq 'Running') {
                Stop-PsClackSpinner -Spinner $script:spinner -Status Error -Message $state.Exception.Message | Out-Null
            }
        }

    Show-PsClackNote -Title 'Temporary file' -Message $result.Path
    $completed = $true
}
catch {
    Show-PsClackOutro -Message ("Download failed: {0}" -f $_.Exception.Message) -Status Error
    throw
}
finally {
    if ($tempPath -and (Test-Path -LiteralPath $tempPath)) {
        Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
    }
}

if ($completed) {
    Show-PsClackOutro -Message 'Downloaded file removed from temp storage.'
}
