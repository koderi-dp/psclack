param(
    [switch]$Fail
)

$modulePath = Join-Path $PSScriptRoot '..\PsClack.psd1'
Import-Module $modulePath -Force

Show-PsClackIntro -Message 'PsClack Task Log'

$log = New-PsClackTaskLog -Title 'npm install' -Limit 10
$log.Message('npm notice cli Installing dependencies')
Start-Sleep -Milliseconds 250
$log.Message('npm info lifecycle Resolving workspace packages')
Start-Sleep -Milliseconds 250
$log.Message('npm http fetch GET 200 https://registry.npmjs.org/picocolors')
Start-Sleep -Milliseconds 250
$log.Message('npm http fetch GET 200 https://registry.npmjs.org/sisteransi')
Start-Sleep -Milliseconds 250
$log.Message('npm info lifecycle Running postinstall hooks')
Start-Sleep -Milliseconds 250

$postInstall = $log.Group('postinstall')
$postInstall.Message('node ./scripts/postinstall.js')
Start-Sleep -Milliseconds 250
$postInstall.Message('Generating local cache')
Start-Sleep -Milliseconds 250
$postInstall.Message('Refreshing shell completions')
Start-Sleep -Milliseconds 250
$postInstall.Success('postinstall complete')

if ($Fail) {
    $log.Message('npm ERR! code ELIFECYCLE')
    Start-Sleep -Milliseconds 250
    $log.Error('npm install failed', $true)
}
else {
    $log.Message('npm info lifecycle Added 52 packages in 1.8s')
    Start-Sleep -Milliseconds 250
    $log.Success('npm install completed')
}

Show-PsClackOutro -Message 'Displayed task log example.'
