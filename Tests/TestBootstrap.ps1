$moduleRoot = Join-Path $PSScriptRoot '..'
Get-ChildItem -Path (Join-Path $moduleRoot 'Private') -Filter '*.ps1' -File -Recurse | Sort-Object FullName | ForEach-Object { . $_.FullName }
Get-ChildItem -Path (Join-Path $moduleRoot 'Public') -Filter '*.ps1' -File -Recurse | Sort-Object FullName | ForEach-Object { . $_.FullName }
