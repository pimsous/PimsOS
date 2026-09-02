# ==========================================
# Tests : PostInstall Finalize
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..\..").Path

    . "$ProjectRoot\Modules\PostInstall\Finalize.ps1"

}

Describe "PostInstall Finalize" {

    BeforeEach {

        $script:State = [PSCustomObject]@{
            Status = "Completed"
            Completed = $true
            Failed = $false
            CurrentPhase = $null
            CompletedTasks = @(
                "Initialize",
                "Network",
                "DriverCheck",
                "Chocolatey",
                "Applications",
                "MicrosoftStore",
                "Configuration",
                "Cleanup"
            )
            Verification = [PSCustomObject]@{
                Verified = $false
                VerifiedAt = $null
                MissingTasks = @()
            }
            Cleanup = [PSCustomObject]@{
                Status = "Pending"
                Scheduled = $false
                ScheduledAt = $null
                RemovedItems = @()
                PreservedItems = @()
                Errors = @()
            }
        }

        $script:RuntimePath = Join-Path $TestDrive "PostInstall"
        New-Item -ItemType Directory -Path $script:RuntimePath -Force | Out-Null

        foreach ($FileName in @(
            "Bootstrap.ps1",
            "Finalize.ps1",
            "Logger.ps1",
            "Network.ps1",
            "UI.ps1",
            "DriverCheck.ps1",
            "Chocolatey.ps1",
            "PostInstall.ps1",
            "State.ps1"
        )) {
            New-Item -ItemType File -Path (Join-Path $script:RuntimePath $FileName) -Force | Out-Null
        }

        $script:UnattendPath = Join-Path $TestDrive "unattend.xml"
        New-Item -ItemType File -Path $script:UnattendPath -Force | Out-Null

    }

    Context "Test-PimsOSPostInstallCompletion" {

        It "Valide un état PostInstall complet" {

            $Result = Test-PimsOSPostInstallCompletion -State $script:State

            $Result.Success | Should -BeTrue
            $Result.MissingTasks | Should -HaveCount 0

        }

        It "Détecte une tâche obligatoire manquante" {

            $script:State.CompletedTasks = @(
                "Initialize",
                "Network"
            )

            $Result = Test-PimsOSPostInstallCompletion -State $script:State

            $Result.Success | Should -BeFalse
            $Result.MissingTasks | Should -Contain "DriverCheck"
            $Result.MissingTasks | Should -Contain "Cleanup"

        }

        It "Refuse un état non terminé" {

            $script:State.Status = "Running"

            $Result = Test-PimsOSPostInstallCompletion -State $script:State

            $Result.Success | Should -BeFalse

        }

    }

    Context "Invoke-PimsOSPostInstallCleanup" {

        It "Programme le nettoyage dans un processus séparé" {

            Mock Start-Process {
                return [PSCustomObject]@{ Id = 1234 }
            }

            $Result = Invoke-PimsOSPostInstallCleanup `
                -RuntimePath $script:RuntimePath `
                -UnattendPath $script:UnattendPath `
                -DelaySeconds 5

            $Result.Scheduled | Should -BeTrue
            $Result.ProcessId | Should -Be 1234
            $Result.DelaySeconds | Should -Be 5
            $Result.RemovedItems | Should -Contain (Join-Path $script:RuntimePath "Bootstrap.ps1")
            $Result.RemovedItems | Should -Contain $script:UnattendPath
            $Result.PreservedItems | Should -Contain (Join-Path $script:RuntimePath "state.json")
            $Result.PreservedItems | Should -Contain (Join-Path $script:RuntimePath "PostInstall.log")
            $Result.PreservedItems | Should -Contain (Join-Path $script:RuntimePath "Chocolatey")

            Should -Invoke Start-Process -Times 1 -Exactly

        }

        It "Refuse un délai nul" {

            {
                Invoke-PimsOSPostInstallCleanup `
                    -RuntimePath $script:RuntimePath `
                    -DelaySeconds 0
            } | Should -Throw "*délai de nettoyage*"

        }

    }

    Context "Complete-PimsOSPostInstall" {

        It "Vérifie puis programme le nettoyage" {

            Mock Start-Process {
                return [PSCustomObject]@{ Id = 5678 }
            }

            $Result = Complete-PimsOSPostInstall `
                -State $script:State `
                -RuntimePath $script:RuntimePath `
                -UnattendPath $script:UnattendPath `
                -DelaySeconds 5

            $Result.Verification.Success | Should -BeTrue
            $Result.State.Verification.Verified | Should -BeTrue
            $Result.State.Cleanup.Status | Should -Be "Scheduled"
            $Result.State.Cleanup.Scheduled | Should -BeTrue
            $Result.Cleanup.ProcessId | Should -Be 5678

        }

        It "Ne programme pas le nettoyage si la vérification échoue" {

            $script:State.Failed = $true

            Mock Start-Process {
                throw "Start-Process ne doit pas être appelé."
            }

            {
                Complete-PimsOSPostInstall `
                    -State $script:State `
                    -RuntimePath $script:RuntimePath
            } | Should -Throw "*Vérification finale du PostInstall échouée*"

            Should -Invoke Start-Process -Times 0 -Exactly

        }

    }

}
