param(
    [switch]$Fail
)

$modulePath = Join-Path $PSScriptRoot '..\PsClack.psd1'
Import-Module $modulePath -Force

Show-PsClackIntro -Message 'progress'

$progress = New-PsClackProgress -Style Heavy -Max 100 -Size 36 -ContinueTranscript
$progress.Start('Downloading archive')

foreach ($percent in 10..100 | Where-Object { $_ % 10 -eq 0 }) {
    $progress.Wait(280)

    if ($Fail -and $percent -eq 70) {
        $progress.Error('Connection reset')
        Show-PsClackOutro -Message 'Progress ended in error state.' -Status Error
        return
    }

    $progress.Advance(10, ('Downloading ({0}%)' -f $percent))
}

$progress.Stop('Archive downloaded')

Show-PsClackOutro -Message 'Done.'
