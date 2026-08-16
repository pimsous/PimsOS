# ==========================================
# Tests : CapabilityManager
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"

    # --------------------------------------------------
    # Provider DISM par défaut
    # --------------------------------------------------

    function global:Invoke-DismCapability {

        param(
            [psobject]$Context,
            [psobject]$Action
        )

        return $Context

    }

    # --------------------------------------------------
    # Provider de test
    # --------------------------------------------------

    function global:Invoke-TestCapabilityProvider {

        param(
            [psobject]$Context,
            [psobject]$Action
        )

        return $Context

    }

    . "$ProjectRoot\Modules\Managers\CapabilityManager.ps1"

}

Describe "CapabilityManager" {

    BeforeEach {

        Reset-Logger

        Mock Write-Log {}

        Reset-CapabilityProviders

        $script:Context = [pscustomobject]@{

            BuildState = [pscustomobject]@{

                Status = "Idle"

            }

        }

        $script:Action = [pscustomobject]@{

            Provider = "DISM"

            Name = "Microsoft.Windows.Notepad"

        }

        $script:HandlerCalled = $false

    }


    # ==================================================
    # Get-CapabilityProviders
    # ==================================================

    Context "Get-CapabilityProviders" {

        It "Retourne DISM par défaut" {

            $Providers = @(
                Get-CapabilityProviders
            )

            $Providers |
                Should -Contain "DISM"

        }

        It "Retourne les fournisseurs triés" {

            Register-CapabilityProvider `
                -Name "AAA" `
                -Handler "Invoke-TestCapabilityProvider"

            $Providers = @(
                Get-CapabilityProviders
            )

            $Sorted = @(
                $Providers | Sort-Object
            )

            $Providers |
                Should -Be $Sorted

        }

    }


    # ==================================================
    # Invoke-Capability
    # ==================================================

    Context "Invoke-Capability" {

        It "Applique une capability avec le provider DISM" {

            $Result = Invoke-Capability `
                -Context $script:Context `
                -Action $script:Action

            $Result |
                Should -Be $script:Context

        }


        It "Refuse un provider absent" {

            $script:Action.Provider = $null

            {

                Invoke-Capability `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Refuse un nom absent" {

            $script:Action.Name = $null

            {

                Invoke-Capability `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Refuse un provider inconnu" {

            $script:Action.Provider = "Unknown"

            {

                Invoke-Capability `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Refuse un handler introuvable" {

            # On ajoute directement l'entrée dans le registre
            # via Register-CapabilityProvider uniquement avec
            # un handler qui existe réellement au moment de
            # l'enregistrement.

            Register-CapabilityProvider `
                -Name "Broken" `
                -Handler "Invoke-TestCapabilityProvider"

            # Puis on remplace le handler enregistré par un nom
            # inexistant pour tester le contrôle effectué lors
            # de Invoke-Capability.
            $script:CapabilityProviders["Broken"] =
                "Invoke-UnknownCapabilityHandler"

            $script:Action.Provider = "Broken"

            {

                Invoke-Capability `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Appelle le handler du provider" {

            $script:HandlerCalled = $false

            function global:Invoke-TestCapabilityProvider {

                param(
                    [psobject]$Context,
                    [psobject]$Action
                )

                $script:HandlerCalled = $true

                return $Context

            }

            Register-CapabilityProvider `
                -Name "Test" `
                -Handler "Invoke-TestCapabilityProvider"

            $script:Action.Provider = "Test"

            $null = Invoke-Capability `
                -Context $script:Context `
                -Action $script:Action

            $script:HandlerCalled |
                Should -BeTrue

        }

    }


    # ==================================================
    # Register-CapabilityProvider
    # ==================================================

    Context "Register-CapabilityProvider" {

        It "Enregistre un nouveau provider" {

            Register-CapabilityProvider `
                -Name "Test" `
                -Handler "Invoke-TestCapabilityProvider"

            @(
                Get-CapabilityProviders
            ) |
                Should -Contain "Test"

        }


        It "Refuse un handler inexistant" {

            {

                Register-CapabilityProvider `
                    -Name "Broken" `
                    -Handler "Invoke-UnknownCapabilityHandler"

            } |
                Should -Throw

        }

    }


    # ==================================================
    # Reset-CapabilityProviders
    # ==================================================

    Context "Reset-CapabilityProviders" {

        It "Réinitialise les providers par défaut" {

            Register-CapabilityProvider `
                -Name "Test" `
                -Handler "Invoke-TestCapabilityProvider"

            Get-CapabilityProviders |
                Should -Contain "Test"

            Reset-CapabilityProviders

            Get-CapabilityProviders |
                Should -Contain "DISM"

            Get-CapabilityProviders |
                Should -Not -Contain "Test"

        }

    }

}