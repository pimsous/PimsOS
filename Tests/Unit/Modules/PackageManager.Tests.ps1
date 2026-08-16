# ==========================================
# Tests : PackageManager
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"

    # --------------------------------------------------
    # Providers par défaut simulés
    # --------------------------------------------------

    function global:Invoke-ChocolateyPackage {

        param(
            [psobject]$Context,
            [psobject]$Action
        )

        return $Context

    }

    function global:Invoke-WingetPackage {

        param(
            [psobject]$Context,
            [psobject]$Action
        )

        return $Context

    }

    # --------------------------------------------------
    # Provider de test
    # --------------------------------------------------

    function global:Invoke-TestPackageProvider {

        param(
            [psobject]$Context,
            [psobject]$Action
        )

        return $Context

    }

    . "$ProjectRoot\Modules\Managers\PackageManager.ps1"

}

Describe "PackageManager" {

    BeforeEach {

        Reset-Logger

        Mock Write-Log {}

        Reset-PackageProviders

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

            Provider = "Chocolatey"

            Name = "7zip"

        }

    }


    # ==================================================
    # Get-PackageProviders
    # ==================================================

    Context "Get-PackageProviders" {

        It "Retourne Chocolatey par défaut" {

            $Providers = @(
                Get-PackageProviders
            )

            $Providers |
                Should -Contain "Chocolatey"

        }


        It "Retourne Winget par défaut" {

            $Providers = @(
                Get-PackageProviders
            )

            $Providers |
                Should -Contain "Winget"

        }


        It "Retourne les fournisseurs triés" {

            Register-PackageProvider `
                -Name "AAA" `
                -Handler "Invoke-TestPackageProvider"

            $Providers = @(
                Get-PackageProviders
            )

            $Sorted = @(
                $Providers | Sort-Object
            )

            $Providers |
                Should -Be $Sorted

        }

    }


    # ==================================================
    # Invoke-Package
    # ==================================================

    Context "Invoke-Package" {

        It "Applique un package avec Chocolatey" {

            $Result = Invoke-Package `
                -Context $script:Context `
                -Action $script:Action

            $Result |
                Should -Be $script:Context

        }


        It "Applique un package avec Winget" {

            $script:Action.Provider = "Winget"

            $Result = Invoke-Package `
                -Context $script:Context `
                -Action $script:Action

            $Result |
                Should -Be $script:Context

        }


        It "Refuse un provider absent" {

            $script:Action.Provider = $null

            {

                Invoke-Package `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Refuse un nom absent" {

            $script:Action.Name = $null

            {

                Invoke-Package `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Refuse un provider inconnu" {

            $script:Action.Provider = "Unknown"

            {

                Invoke-Package `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Appelle le handler du provider" {

            $script:ReceivedAction = $null

            function global:Invoke-TestPackageProvider {

                param(
                    [psobject]$Context,
                    [psobject]$Action
                )

                $script:ReceivedAction = $Action

                return $Context

            }

            Register-PackageProvider `
                -Name "Test" `
                -Handler "Invoke-TestPackageProvider"

            $script:Action.Provider = "Test"

            $null = Invoke-Package `
                -Context $script:Context `
                -Action $script:Action

            $script:ReceivedAction.Name |
                Should -Be "7zip"

        }

    }


    # ==================================================
    # Register-PackageProvider
    # ==================================================

    Context "Register-PackageProvider" {

        It "Enregistre un nouveau provider" {

            Register-PackageProvider `
                -Name "Test" `
                -Handler "Invoke-TestPackageProvider"

            @(
                Get-PackageProviders
            ) |
                Should -Contain "Test"

        }


        It "Refuse un handler inexistant" {

            {

                Register-PackageProvider `
                    -Name "Broken" `
                    -Handler "Invoke-UnknownPackageHandler"

            } |
                Should -Throw

        }

    }


    # ==================================================
    # Reset-PackageProviders
    # ==================================================

    Context "Reset-PackageProviders" {

        It "Réinitialise les providers par défaut" {

            Register-PackageProvider `
                -Name "Test" `
                -Handler "Invoke-TestPackageProvider"

            Get-PackageProviders |
                Should -Contain "Test"

            Reset-PackageProviders

            Get-PackageProviders |
                Should -Contain "Chocolatey"

            Get-PackageProviders |
                Should -Contain "Winget"

            Get-PackageProviders |
                Should -Not -Contain "Test"

        }

    }

}