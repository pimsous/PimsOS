# ==========================================
# Tests : PostInstall
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..\..").Path

    # --------------------------------------------------
    # Chargement explicite des dépendances
    # --------------------------------------------------

    . "$ProjectRoot\Modules\PostInstall\State.ps1"
    . "$ProjectRoot\Modules\PostInstall\Network.ps1"
    . "$ProjectRoot\Modules\PostInstall\PostInstall.ps1"

}

Describe "PostInstall" {

    BeforeEach {

        # --------------------------------------------------
        # Etat de test
        # --------------------------------------------------

        $script:StatePath = Join-Path `
            $TestDrive `
            "PostInstall\state.json"

        $script:State = New-PostInstallState `
            -StatePath $script:StatePath

    }

    # ==================================================
    # Initialize-PostInstall
    # ==================================================

    Context "Initialize-PostInstall" {

        It "Crée un nouvel état lorsque le fichier est absent" {

            $Result = Initialize-PostInstall `
                -StatePath $script:StatePath

            $Result |
                Should -Not -BeNullOrEmpty

            $Result.Status |
                Should -Be "Pending"

            $Result.StatePath |
                Should -Be $script:StatePath

            Test-Path `
                -LiteralPath $script:StatePath `
                -PathType Leaf |
                Should -BeTrue

        }

        It "Recharge un état existant" {

            $script:State.Status = "Running"
            $script:State.CurrentPhase = "Local"

            Save-PostInstallState `
                -State $script:State |
                Out-Null

            $Result = Initialize-PostInstall `
                -StatePath $script:StatePath

            $Result.Status |
                Should -Be "Running"

            $Result.CurrentPhase |
                Should -Be "Local"

        }

    }

    # ==================================================
    # Invoke-PostInstall
    # ==================================================

    Context "Invoke-PostInstall" {

        It "Termine le PostInstall sans attente réseau" {

            Mock Save-PostInstallState {

                param(
                    [psobject]$State,
                    [string]$StatePath
                )

                return $State

            }

            $Result = Invoke-PostInstall `
                -State $script:State

            $Result.Status |
                Should -Be "Completed"

            $Result.Completed |
                Should -BeTrue

            $Result.Failed |
                Should -BeFalse

            $Result.WaitingForNetwork |
                Should -BeFalse

        }

        It "Exécute la phase locale" {

            Mock Save-PostInstallState {

                param(
                    [psobject]$State,
                    [string]$StatePath
                )

                return $State

            }

            $Result = Invoke-PostInstall `
                -State $script:State

            $Result.CompletedTasks |
                Should -Contain "Local"

        }

        It "Détecte un réseau déjà disponible" {

            Mock Save-PostInstallState {

                param(
                    [psobject]$State,
                    [string]$StatePath
                )

                return $State

            }

            Mock Test-PostInstallNetwork {

                return $true

            }

            $Result = Invoke-PostInstall `
                -State $script:State `
                -WaitForNetwork

            $Result.NetworkAvailable |
                Should -BeTrue

            $Result.Status |
                Should -Be "Completed"

            Should -Invoke `
                -CommandName Test-PostInstallNetwork `
                -Times 1 `
                -Exactly

        }

		It "Utilise l'interface UI pour détecter le réseau" {

            Mock Save-PostInstallState {

                param(
                    [psobject]$State,
                    [string]$StatePath
                )

                return $State

            }

            function Show-PostInstallNetworkStatus {
                return $true
            }

            $Result = Invoke-PostInstall `
                -State $script:State `
                -WaitForNetwork

            $Result.NetworkAvailable |
                Should -BeTrue

            $Result.Status |
                Should -Be "Completed"

            Remove-Item `
                -Path Function:\Show-PostInstallNetworkStatus `
                -Force `
                -ErrorAction SilentlyContinue

        }

        It "Utilise l'attente UI lorsque le réseau est indisponible" {

            Mock Save-PostInstallState {

                param(
                    [psobject]$State,
                    [string]$StatePath
                )

                return $State

            }

            function Show-PostInstallNetworkStatus {
                return $false
            }

            function Wait-PostInstallNetworkUI {

                param(
                    [int]$IntervalSeconds,
                    [int]$TimeoutMinutes
                )

                return $true

            }

            $Result = Invoke-PostInstall `
                -State $script:State `
                -WaitForNetwork

            $Result.NetworkAvailable |
                Should -BeTrue

            $Result.Status |
                Should -Be "Completed"

            Remove-Item `
                -Path Function:\Show-PostInstallNetworkStatus `
                -Force `
                -ErrorAction SilentlyContinue

            Remove-Item `
                -Path Function:\Wait-PostInstallNetworkUI `
                -Force `
                -ErrorAction SilentlyContinue

        }

        It "Passe en WaitingForNetwork lorsque le réseau est absent" {

            Mock Save-PostInstallState {

                param(
                    [psobject]$State,
                    [string]$StatePath
                )

                return $State

            }

            Mock Test-PostInstallNetwork {

                return $false

            }

            Mock Wait-PostInstallNetwork {

                return $true

            }

            $Result = Invoke-PostInstall `
                -State $script:State `
                -WaitForNetwork

            $Result.NetworkAvailable |
                Should -BeTrue

            $Result.Status |
                Should -Be "Completed"

            Should -Invoke `
                -CommandName Wait-PostInstallNetwork `
                -Times 1 `
                -Exactly

        }

        It "Respecte le timeout réseau" {

            Mock Save-PostInstallState {

                param(
                    [psobject]$State,
                    [string]$StatePath
                )

                return $State

            }

            Mock Test-PostInstallNetwork {

                return $false

            }

            Mock Wait-PostInstallNetwork {

                param(
                    [int]$IntervalSeconds,
                    [int]$TimeoutMinutes
                )

                $TimeoutMinutes |
                    Should -Be 15

                return $false

            }

            {

                Invoke-PostInstall `
                    -State $script:State `
                    -WaitForNetwork `
                    -NetworkTimeoutMinutes 15

            } |
                Should -Throw "*délai d'attente réseau*"

        }

        It "Passe par WaitingForNetwork avant la reprise" {

            $script:Statuses = @()

            Mock Save-PostInstallState {

                param(
                    [psobject]$State,
                    [string]$StatePath
                )

                $script:Statuses += $State.Status

                return $State

            }

            Mock Test-PostInstallNetwork {

                return $false

            }

            Mock Wait-PostInstallNetwork {

                return $true

            }

            $Result = Invoke-PostInstall `
                -State $script:State `
                -WaitForNetwork

            $script:Statuses |
                Should -Contain "WaitingForNetwork"

            $script:Statuses |
                Should -Contain "Running"

            $Result.Status |
                Should -Be "Completed"

        }

        It "Ajoute la phase réseau aux tâches terminées" {

            Mock Save-PostInstallState {

                param(
                    [psobject]$State,
                    [string]$StatePath
                )

                return $State

            }

            Mock Test-PostInstallNetwork {

                return $true

            }

            $Result = Invoke-PostInstall `
                -State $script:State `
                -WaitForNetwork

            $Result.CompletedTasks |
                Should -Contain "Local"

            $Result.CompletedTasks |
                Should -Contain "Network"

        }

        It "Passe à Failed lorsqu'une erreur survient" {

            Mock Save-PostInstallState {

                param(
                    [psobject]$State,
                    [string]$StatePath
                )

                return $State

            }

            Mock Set-PostInstallStatus {

                param(
                    [psobject]$State,
                    [string]$Status
                )

                $State.Status = $Status
                $State.Started = $true
                $State.Failed = ($Status -eq "Failed")
                $State.Completed = ($Status -eq "Completed")
                $State.WaitingForNetwork = ($Status -eq "WaitingForNetwork")

                return $State

            }

            Mock Test-PostInstallNetwork {

                throw "Erreur réseau de test"

            }

            {

                Invoke-PostInstall `
                    -State $script:State `
                    -WaitForNetwork

            } |
                Should -Throw "*Erreur réseau de test*"

            $script:State.Failed |
                Should -BeTrue

            $script:State.Status |
                Should -Be "Failed"

            $script:State.Errors |
                Should -Contain "Erreur réseau de test"

        }

    }

}

