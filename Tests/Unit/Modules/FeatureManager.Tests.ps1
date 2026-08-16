# ==========================================
# Tests : FeatureManager
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"

    # --------------------------------------------------
    # Provider DISM par défaut
    # --------------------------------------------------

    function global:Invoke-DismFeature {

        param(
            [psobject]$Context,
            [psobject]$Action
        )

        return $Context

    }

    # --------------------------------------------------
    # Provider de test
    # --------------------------------------------------

    function global:Invoke-TestFeatureProvider {

        param(
            [psobject]$Context,
            [psobject]$Action
        )

        return $Context

    }

    . "$ProjectRoot\Modules\Managers\FeatureManager.ps1"

}

Describe "FeatureManager" {

    BeforeEach {

        Reset-Logger

        Mock Write-Log {}

        Reset-FeatureProviders

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

            Name = "Microsoft-Windows-Feature"

        }

    }


    # ==================================================
    # Get-FeatureProviders
    # ==================================================

    Context "Get-FeatureProviders" {

        It "Retourne DISM par défaut" {

            $Providers = @(
                Get-FeatureProviders
            )

            $Providers |
                Should -Contain "DISM"

        }


        It "Retourne les fournisseurs triés" {

            Register-FeatureProvider `
                -Name "AAA" `
                -Handler "Invoke-TestFeatureProvider"

            $Providers = @(
                Get-FeatureProviders
            )

            $Sorted = @(
                $Providers | Sort-Object
            )

            $Providers |
                Should -Be $Sorted

        }

    }


    # ==================================================
    # Invoke-Feature
    # ==================================================

    Context "Invoke-Feature" {

        It "Applique une fonctionnalité avec DISM" {

            $Result = Invoke-Feature `
                -Context $script:Context `
                -Action $script:Action

            $Result |
                Should -Be $script:Context

        }


        It "Refuse un provider absent" {

            $script:Action.Provider = $null

            {

                Invoke-Feature `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Refuse un nom absent" {

            $script:Action.Name = $null

            {

                Invoke-Feature `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Refuse un provider inconnu" {

            $script:Action.Provider = "Unknown"

            {

                Invoke-Feature `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Appelle le handler du provider" {

            $script:ReceivedAction = $null

            function global:Invoke-TestFeatureProvider {

                param(
                    [psobject]$Context,
                    [psobject]$Action
                )

                $script:ReceivedAction = $Action

                return $Context

            }

            Register-FeatureProvider `
                -Name "Test" `
                -Handler "Invoke-TestFeatureProvider"

            $script:Action.Provider = "Test"

            $null = Invoke-Feature `
                -Context $script:Context `
                -Action $script:Action

            $script:ReceivedAction.Name |
                Should -Be "Microsoft-Windows-Feature"

        }

    }


    # ==================================================
    # Register-FeatureProvider
    # ==================================================

    Context "Register-FeatureProvider" {

        It "Enregistre un nouveau provider" {

            Register-FeatureProvider `
                -Name "Test" `
                -Handler "Invoke-TestFeatureProvider"

            @(
                Get-FeatureProviders
            ) |
                Should -Contain "Test"

        }


        It "Refuse un handler inexistant" {

            {

                Register-FeatureProvider `
                    -Name "Broken" `
                    -Handler "Invoke-UnknownFeatureHandler"

            } |
                Should -Throw

        }

    }


    # ==================================================
    # Reset-FeatureProviders
    # ==================================================

    Context "Reset-FeatureProviders" {

        It "Réinitialise les providers par défaut" {

            Register-FeatureProvider `
                -Name "Test" `
                -Handler "Invoke-TestFeatureProvider"

            Get-FeatureProviders |
                Should -Contain "Test"

            Reset-FeatureProviders

            Get-FeatureProviders |
                Should -Contain "DISM"

            Get-FeatureProviders |
                Should -Not -Contain "Test"

        }

    }

}