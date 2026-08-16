# ==========================================
# Tests : DriverManager
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"

    # --------------------------------------------------
    # Providers par défaut
    # --------------------------------------------------

    function global:Invoke-DismDriver {

        param(
            [psobject]$Context,
            [psobject]$Action
        )

        return $Context

    }

    function global:Invoke-PnpDriver {

        param(
            [psobject]$Context,
            [psobject]$Action
        )

        return $Context

    }

    # --------------------------------------------------
    # Provider de test
    # --------------------------------------------------

    function global:Invoke-TestDriverProvider {

        param(
            [psobject]$Context,
            [psobject]$Action
        )

        return $Context

    }

    . "$ProjectRoot\Modules\Managers\DriverManager.ps1"

}

Describe "DriverManager" {

    BeforeEach {

        Reset-Logger

        Mock Write-Log {}

        Reset-DriverProviders

        # ==========================================
        # Contexte
        # ==========================================

        $script:Context = [pscustomobject]@{

            BuildState = [pscustomobject]@{

                Status = "Idle"

            }

        }

        # ==========================================
        # Action
        # ==========================================

        $script:Action = [pscustomobject]@{

            Provider = "DISM"

            Source = "C:\Drivers\Test"

        }

    }


    # ==================================================
    # Get-DriverProviders
    # ==================================================

    Context "Get-DriverProviders" {

        It "Retourne DISM par défaut" {

            $Providers = @(
                Get-DriverProviders
            )

            $Providers |
                Should -Contain "DISM"

        }


        It "Retourne PNP par défaut" {

            $Providers = @(
                Get-DriverProviders
            )

            $Providers |
                Should -Contain "PNP"

        }


        It "Retourne les fournisseurs triés" {

            Register-DriverProvider `
                -Name "AAA" `
                -Handler "Invoke-TestDriverProvider"

            $Providers = @(
                Get-DriverProviders
            )

            $Sorted = @(
                $Providers | Sort-Object
            )

            $Providers |
                Should -Be $Sorted

        }

    }


    # ==================================================
    # Invoke-Driver
    # ==================================================

    Context "Invoke-Driver" {

        It "Applique un pilote avec DISM" {

            $Result = Invoke-Driver `
                -Context $script:Context `
                -Action $script:Action

            $Result |
                Should -Be $script:Context

        }


        It "Applique un pilote avec PNP" {

            $script:Action.Provider = "PNP"

            $Result = Invoke-Driver `
                -Context $script:Context `
                -Action $script:Action

            $Result |
                Should -Be $script:Context

        }


        It "Refuse un provider absent" {

            $script:Action.Provider = $null

            {

                Invoke-Driver `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Refuse une source absente" {

            $script:Action.Source = $null

            {

                Invoke-Driver `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Refuse un provider inconnu" {

            $script:Action.Provider = "Unknown"

            {

                Invoke-Driver `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Transmet l'action au handler" {

            $script:ReceivedAction = $null

            function global:Invoke-TestDriverProvider {

                param(
                    [psobject]$Context,
                    [psobject]$Action
                )

                $script:ReceivedAction = $Action

                return $Context

            }

            Register-DriverProvider `
                -Name "Test" `
                -Handler "Invoke-TestDriverProvider"

            $script:Action.Provider = "Test"

            $null = Invoke-Driver `
                -Context $script:Context `
                -Action $script:Action

            $script:ReceivedAction.Source |
                Should -Be "C:\Drivers\Test"

        }

    }


    # ==================================================
    # Register-DriverProvider
    # ==================================================

    Context "Register-DriverProvider" {

        It "Enregistre un nouveau provider" {

            Register-DriverProvider `
                -Name "Test" `
                -Handler "Invoke-TestDriverProvider"

            @(
                Get-DriverProviders
            ) |
                Should -Contain "Test"

        }


        It "Refuse un handler inexistant" {

            {

                Register-DriverProvider `
                    -Name "Broken" `
                    -Handler "Invoke-UnknownDriverHandler"

            } |
                Should -Throw

        }

    }


    # ==================================================
    # Reset-DriverProviders
    # ==================================================

    Context "Reset-DriverProviders" {

        It "Réinitialise les providers par défaut" {

            Register-DriverProvider `
                -Name "Test" `
                -Handler "Invoke-TestDriverProvider"

            Get-DriverProviders |
                Should -Contain "Test"

            Reset-DriverProviders

            Get-DriverProviders |
                Should -Contain "DISM"

            Get-DriverProviders |
                Should -Contain "PNP"

            Get-DriverProviders |
                Should -Not -Contain "Test"

        }

    }

}