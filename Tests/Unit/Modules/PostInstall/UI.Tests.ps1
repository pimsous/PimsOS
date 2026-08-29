# ==========================================
# Tests : PostInstall UI
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ModuleRoot = Join-Path `
        -Path $PSScriptRoot `
        -ChildPath "..\..\..\..\Modules\PostInstall"

    $NetworkScript = Join-Path `
        -Path $ModuleRoot `
        -ChildPath "Network.ps1"

    $UIScript = Join-Path `
        -Path $ModuleRoot `
        -ChildPath "UI.ps1"

    if (-not (Test-Path $NetworkScript)) {

        throw (
            "Network.ps1 introuvable : {0}" -f
            $NetworkScript
        )

    }

    if (-not (Test-Path $UIScript)) {

        throw (
            "UI.ps1 introuvable : {0}" -f
            $UIScript
        )

    }

    . $NetworkScript
    . $UIScript
}

Describe "PostInstall UI" {

    Context "Show-PostInstallNetworkStatus" {

        It "Retourne True lorsque le réseau et Internet sont disponibles" {

            Mock Test-PostInstallNetwork {
                return $true
            }

            Mock Test-PostInstallInternet {
                return $true
            }

            $Result = Show-PostInstallNetworkStatus

            $Result |
                Should -BeTrue
        }


        It "Retourne False lorsque le réseau est indisponible" {

            Mock Test-PostInstallNetwork {
                return $false
            }

            $Result = Show-PostInstallNetworkStatus

            $Result |
                Should -BeFalse
        }


        It "Retourne False lorsque le réseau existe mais Internet est indisponible" {

            Mock Test-PostInstallNetwork {
                return $true
            }

            Mock Test-PostInstallInternet {
                return $false
            }

            $Result = Show-PostInstallNetworkStatus

            $Result |
                Should -BeFalse
        }

    }


    Context "Show-PostInstallNetworkHelp" {

        It "S'exécute sans erreur" {

            {
                Show-PostInstallNetworkHelp
            } |
                Should -Not -Throw
        }

    }


    Context "Wait-PostInstallNetworkUI" {

        It "Retourne immédiatement lorsque le réseau est disponible" {

            Mock Show-PostInstallNetworkStatus {
                return $true
            }

            $Result = Wait-PostInstallNetworkUI `
                -IntervalSeconds 1

            $Result |
                Should -BeTrue
        }

    }

}