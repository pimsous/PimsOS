# ==========================================
# Tests : PostInstall DriverCheck
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"
    . "$ProjectRoot\Modules\PostInstall\DriverCheck.ps1"

}

Describe "PostInstall DriverCheck" {

    BeforeEach {

        Reset-Logger

        Mock Write-Log {}

    }

    Context "Test-PostInstallDrivers" {

        It "Retourne un résultat positif lorsque tous les périphériques sont OK" {

            Mock Get-PnpDevice {

                @(
                    [pscustomobject]@{
                        FriendlyName = "Carte réseau"
                        Status       = "OK"
                    }

                    [pscustomobject]@{
                        FriendlyName = "Contrôleur audio"
                        Status       = "OK"
                    }
                )

            }

            $Result = Test-PostInstallDrivers

            $Result.Available |
                Should -BeTrue

            $Result.Success |
                Should -BeTrue

            $Result.ProblemCount |
                Should -Be 0

        }

        It "Détecte les périphériques avec un problème" {

            Mock Get-PnpDevice {

                @(
                    [pscustomobject]@{
                        FriendlyName = "Carte réseau"
                        Status       = "OK"
                    }

                    [pscustomobject]@{
                        FriendlyName = "Périphérique inconnu"
                        Status       = "Error"
                    }
                )

            }

            $Result = Test-PostInstallDrivers

            $Result.Available |
                Should -BeTrue

            $Result.Success |
                Should -BeFalse

            $Result.ProblemCount |
                Should -Be 1

            $Result.ProblemDevices[0].FriendlyName |
                Should -Be "Périphérique inconnu"

        }

        It "Ne bloque pas le PostInstall lorsqu'un pilote pose problème" {

            Mock Get-PnpDevice {

                @(
                    [pscustomobject]@{
                        FriendlyName = "Périphérique inconnu"
                        Status       = "Error"
                    }
                )

            }

            {

                $Result = Test-PostInstallDrivers

            } |
                Should -Not -Throw

        }

        It "Retourne Available False si Get-PnpDevice échoue" {

            Mock Get-PnpDevice {

                throw "Erreur PnP de test"

            }

            $Result = Test-PostInstallDrivers

            $Result.Available |
                Should -BeFalse

            $Result.Success |
                Should -BeFalse

        }

        It "Retourne une collection vide lorsqu'aucun problème n'est détecté" {

            Mock Get-PnpDevice {

                @(
                    [pscustomobject]@{
                        FriendlyName = "Périphérique OK"
                        Status       = "OK"
                    }
                )

            }

            $Result = Test-PostInstallDrivers

            @($Result.ProblemDevices).Count |
                Should -Be 0

        }

    }

}