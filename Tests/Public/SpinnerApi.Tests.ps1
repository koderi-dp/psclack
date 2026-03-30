BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\..\PsClack\PsClack.psd1') -Force
}

Describe 'PsClack spinner API' {
    It 'creates a headless spinner and stops it successfully' {
        $spinner = Start-PsClackSpinner -Message 'Installing'
        $stopped = Stop-PsClackSpinner -Spinner $spinner -Status Success -Message 'Installed'

        $stopped.Status | Should -Be 'Success'
        $stopped.FinalMessage | Should -Be 'Installed'
        $stopped.Timer | Should -BeNullOrEmpty
    }

    It 'uses clack-like default frames and interval for ansi mode' {
        $spinner = Start-PsClackSpinner -Message 'Installing' -InteractiveOverride $false

        $spinner.Frames | Should -Be @('◒', '◐', '◓', '◑')
        $spinner.IntervalMs | Should -Be 80
    }

    It 'uses fallback frames and interval in plain mode' {
        $spinner = Start-PsClackSpinner -Message 'Installing' -InteractiveOverride $false -Plain

        $spinner.Frames | Should -Be @('•', 'o', 'O', '0')
        $spinner.IntervalMs | Should -Be 120
    }

    It 'updates a spinner frame explicitly without auto-spin' {
        $writes = [System.Collections.Generic.List[object]]::new()

        $spinner = Start-PsClackSpinner -Message 'Installing' -InteractiveOverride $true -NoAutoSpin `
            -HideCursorScript { $true } `
            -WriteFrameScript {
                param($lines, $renderState)
                $writes.Add(@($lines)) | Out-Null
            }

        $spinner.Timer | Should -BeNullOrEmpty
        $spinner.AutoSpin | Should -BeFalse
        $spinner.FrameIndex | Should -Be 0

        $updated = Update-PsClackSpinner -Spinner $spinner -WriteFrameScript {
            param($lines, $renderState)
            $writes.Add(@($lines)) | Out-Null
        }

        $updated.FrameIndex | Should -Be 1
        $writes.Count | Should -Be 2
    }

    It 'covers interactive registration and cleanup through test seams' {
        $writes = [System.Collections.Generic.List[object]]::new()
        $unregistered = [System.Collections.Generic.List[string]]::new()
        $removedJobs = [System.Collections.Generic.List[int]]::new()
        $restoredVisibility = [System.Collections.Generic.List[object]]::new()
        $captured = [pscustomobject]@{
            Timer = $null
            SourceIdentifier = $null
            Spinner = $null
        }

        $timer = [pscustomobject]@{ AutoReset = $false; Started = $false; Stopped = $false; Disposed = $false }
        $timer | Add-Member -MemberType ScriptMethod -Name Start -Value { $this.Started = $true }
        $timer | Add-Member -MemberType ScriptMethod -Name Stop -Value { $this.Stopped = $true }
        $timer | Add-Member -MemberType ScriptMethod -Name Dispose -Value { $this.Disposed = $true }

        $spinner = Start-PsClackSpinner -Message 'Installing' -InteractiveOverride $true `
            -HideCursorScript { $true } `
            -CreateTimerScript { param($intervalMs) $timer } `
            -RegisterEventScript {
                param($timerArg, $sourceIdentifierArg, $spinnerArg)
                $captured.Timer = $timerArg
                $captured.SourceIdentifier = $sourceIdentifierArg
                $captured.Spinner = $spinnerArg
                return [pscustomobject]@{ Id = 42 }
            } `
            -WriteFrameScript {
                param($lines, $renderState)
                $writes.Add(@($lines)) | Out-Null
            }

        $spinner.SubscriptionId | Should -Be $captured.SourceIdentifier
        $spinner.EventJobId | Should -Be 42
        $spinner.CursorVisible | Should -BeTrue
        $spinner.AutoSpin | Should -BeTrue
        $timer.Started | Should -BeTrue
        $writes.Count | Should -Be 1

        $stopped = Stop-PsClackSpinner -Spinner $spinner -Status Success -Message 'Installed' `
            -UnregisterEventScript { param($id) $unregistered.Add($id) | Out-Null } `
            -RemoveJobScript { param($id) $removedJobs.Add($id) | Out-Null } `
            -RestoreCursorScript { param($Visible) $restoredVisibility.Add($Visible) | Out-Null } `
            -WriteFrameScript {
                param($lines, $renderState)
                $writes.Add(@($lines)) | Out-Null
            }

        $unregistered[0] | Should -Be $captured.SourceIdentifier
        $removedJobs[0] | Should -Be 42
        $timer.Stopped | Should -BeTrue
        $timer.Disposed | Should -BeTrue
        $stopped.SubscriptionId | Should -BeNullOrEmpty
        $stopped.EventJobId | Should -BeNullOrEmpty
        $writes.Count | Should -Be 2
        $restoredVisibility | Should -Be @($true)
    }
}



