[CmdletBinding()]
param(
    [ValidateSet('None', 'Normal', 'Detailed', 'Diagnostic')]
    [string]$Output = 'Detailed'
)

$ErrorActionPreference = 'Stop'

Import-Module Pester -MinimumVersion 5.7.0 -ErrorAction Stop

$testPath = $PSScriptRoot

Invoke-Pester -Path $testPath -Output $Output
