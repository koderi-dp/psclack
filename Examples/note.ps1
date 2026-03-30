Import-Module (Join-Path $PSScriptRoot '..\PsClack.psd1') -Force

Show-PsClackIntro -Message 'PsClack Note'

Show-PsClackNote `
    -Title 'Next steps' `
    -Message 'Choose a template, install dependencies, and then open the generated project in your editor to continue setup.'

Show-PsClackOutro -Message 'Displayed note example.'
