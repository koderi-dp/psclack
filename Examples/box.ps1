Import-Module (Join-Path $PSScriptRoot '..\PsClack.psd1') -Force

Show-PsClackIntro -Message 'PsClack Box'

Show-PsClackBox `
    -Title 'About box()' `
    -Message 'box() draws a titled frame that wraps to the terminal width. Options include rounded corners, width: "Auto", and content/title alignment.' `
    -Rounded `
    -Width Auto `
    -BorderColor Cyan

Show-PsClackOutro -Message 'Displayed box example.'
