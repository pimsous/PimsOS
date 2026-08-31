# ==========================================
# Tests : PostInstall Network
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (
        Resolve-Path "$PSScriptRoot\..\..\..\.."
    ).Path

    . "$ProjectRoot\Modules\PostInstall\Network.ps1"

}

Describe "PostInstall Network" {

    # ==================================================
    # Test-PostInstallNetwork
    # ==================================================

    Context "Test-PostInstallNetwork" {

        It "Retourne True lorsqu'une connexion réseau est disponible" {

            Mock Get-NetConnectionProfile {

                @(
                    [pscustomobject]@{

                        Name             = "Ethernet"
                        IPv4Connectivity = "Internet"
                        IPv6Connectivity = "Internet"

                    }
                )

            }

            $Result = Test-PostInstallNetwork

            $Result |
                Should -BeTrue

        }

        It "Retourne False lorsqu'aucune connexion réseau n'est disponible" {

            Mock Get-NetConnectionProfile {

                @(
                    [pscustomobject]@{

                        Name             = "Ethernet"
                        IPv4Connectivity = "Disconnected"
                        IPv6Connectivity = "Disconnected"

                    }
                )

            }

            Mock Get-NetAdapter {

                @(
                    [pscustomobject]@{

                        Name   = "Ethernet"
                        Status = "Disconnected"

                    }
                )

            }

            $Result = Test-PostInstallNetwork

            $Result |
                Should -BeFalse

        }

        It "Utilise Get-NetAdapter si Get-NetConnectionProfile échoue" {

            Mock Get-NetConnectionProfile {

                throw "Erreur de profil réseau"

            }

            Mock Get-NetAdapter {

                @(
                    [pscustomobject]@{

                        Name   = "Ethernet"
                        Status = "Up"

                    }
                )

            }

            $Result = Test-PostInstallNetwork

            $Result |
                Should -BeTrue

            Should -Invoke `
                -CommandName Get-NetAdapter `
                -Times 1 `
                -Exactly

        }

        It "Retourne False si les deux méthodes de détection échouent" {

            Mock Get-NetConnectionProfile {

                throw "Erreur de profil réseau"

            }

            Mock Get-NetAdapter {

                throw "Erreur adaptateur"

            }

            $Result = Test-PostInstallNetwork

            $Result |
                Should -BeFalse

        }

    }

    # ==================================================
    # Test-PostInstallInternet
    # ==================================================

    Context "Test-PostInstallInternet" {

        It "Retourne True lorsque le réseau et Internet sont disponibles" {

            Mock Test-PostInstallNetwork {

                return $true

            }

            Mock Test-Connection {

                return $true

            }

            $Result = Test-PostInstallInternet

            $Result |
                Should -BeTrue

            Should -Invoke `
                -CommandName Test-Connection `
                -Times 1 `
                -Exactly

        }

        It "Ne teste pas Internet si le réseau est indisponible" {

            Mock Test-PostInstallNetwork {

                return $false

            }

            Mock Test-Connection {

                throw "Le test Internet ne devrait pas être appelé."

            }

            $Result = Test-PostInstallInternet

            $Result |
                Should -BeFalse

            Should -Invoke `
                -CommandName Test-Connection `
                -Times 0 `
                -Exactly

        }

        It "Retourne False si Test-Connection échoue" {

            Mock Test-PostInstallNetwork {

                return $true

            }

            Mock Test-Connection {

                throw "Erreur réseau"

            }

            $Result = Test-PostInstallInternet

            $Result |
                Should -BeFalse

        }

    }

    # ==================================================
    # Wait-PostInstallNetwork
    # ==================================================

    Context "Wait-PostInstallNetwork" {

        It "Retourne immédiatement lorsque le réseau et Internet sont disponibles" {

            Mock Test-PostInstallNetwork {

                return $true

            }

            Mock Test-PostInstallInternet {

                return $true

            }

            Mock Start-Sleep {}

            $Result = Wait-PostInstallNetwork `
                -IntervalSeconds 1 `
                -TimeoutMinutes 1

            $Result |
                Should -BeTrue

            Should -Invoke `
                -CommandName Test-PostInstallNetwork `
                -Times 1 `
                -Exactly

            Should -Invoke `
                -CommandName Test-PostInstallInternet `
                -Times 1 `
                -Exactly

            Should -Invoke `
                -CommandName Start-Sleep `
                -Times 0 `
                -Exactly

        }

        It "Attend lorsque le réseau local est disponible mais Internet est indisponible" {

            $script:InternetChecks = 0

            Mock Test-PostInstallNetwork {

                return $true

            }

            Mock Test-PostInstallInternet {

                $script:InternetChecks++

                if ($script:InternetChecks -lt 3) {

                    return $false

                }

                return $true

            }

            Mock Start-Sleep {}

            $Result = Wait-PostInstallNetwork `
                -IntervalSeconds 1 `
                -TimeoutMinutes 1

            $Result |
                Should -BeTrue

            $script:InternetChecks |
                Should -Be 3

            Should -Invoke `
                -CommandName Start-Sleep `
                -Times 2 `
                -Exactly

        }

        It "Attend lorsque le réseau local est indisponible" {

            $script:NetworkChecks = 0

            Mock Test-PostInstallNetwork {

                $script:NetworkChecks++

                if ($script:NetworkChecks -lt 3) {

                    return $false

                }

                return $true

            }

            Mock Test-PostInstallInternet {

                return $true

            }

            Mock Start-Sleep {}

            $Result = Wait-PostInstallNetwork `
                -IntervalSeconds 1 `
                -TimeoutMinutes 1

            $Result |
                Should -BeTrue

            $script:NetworkChecks |
                Should -Be 3

            Should -Invoke `
                -CommandName Test-PostInstallInternet `
                -Times 1 `
                -Exactly

            Should -Invoke `
                -CommandName Start-Sleep `
                -Times 2 `
                -Exactly

        }

        It "Retourne False lorsque le délai est dépassé sans accès Internet" {

            Mock Test-PostInstallNetwork {

                return $true

            }

            Mock Test-PostInstallInternet {

                return $false

            }

            Mock Start-Sleep {}

            $script:NetworkTestDateCall = 0

            Mock Get-Date {

                $script:NetworkTestDateCall++

                if ($script:NetworkTestDateCall -eq 1) {

                    return [datetime]::Now

                }

                return [datetime]::Now.AddMinutes(1)

            }

            $Result = Wait-PostInstallNetwork `
                -IntervalSeconds 1 `
                -TimeoutMinutes 1

            $Result |
                Should -BeFalse

            $script:NetworkTestDateCall = $null

        }

        It "Ne teste pas Internet si le réseau local est indisponible" {

            Mock Test-PostInstallNetwork {

                return $false

            }

            Mock Test-PostInstallInternet {

                throw "Le test Internet ne devrait pas être appelé."

            }

            Mock Start-Sleep {}

            $script:NetworkTestDateCall = 0

            Mock Get-Date {

                $script:NetworkTestDateCall++

                if ($script:NetworkTestDateCall -eq 1) {

                    return [datetime]::Now

                }

                return [datetime]::Now.AddMinutes(1)

            }

            $Result = Wait-PostInstallNetwork `
                -IntervalSeconds 1 `
                -TimeoutMinutes 1

            $Result |
                Should -BeFalse

            Should -Invoke `
                -CommandName Test-PostInstallInternet `
                -Times 0 `
                -Exactly

            $script:NetworkTestDateCall = $null

        }

        It "Corrige un intervalle inférieur à une seconde" {

            Mock Test-PostInstallNetwork {

                return $true

            }

            Mock Test-PostInstallInternet {

                return $true

            }

            $Result = Wait-PostInstallNetwork `
                -IntervalSeconds 0 `
                -TimeoutMinutes 1

            $Result |
                Should -BeTrue

        }

    }

}