# ==========================================
# Tests : ActionRegistry
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Core\ActionRegistry.ps1"

}

Describe "ActionRegistry" {

    BeforeEach {

        # --------------------------------------------------
        # Isolation du logger
        # --------------------------------------------------
        # ActionRegistry peut être testé indépendamment de PimsOS.
        # Le stub est global afin d'être visible depuis la fonction
        # Write-ActionRegistryLog, dont la résolution de commandes se
        # fait dans son propre scope.

        if (Get-Command Write-Log -CommandType Function -ErrorAction SilentlyContinue) {

            Remove-Item Function:\Write-Log -Force -ErrorAction SilentlyContinue

        }

        function global:Write-Log {

            param(
                [object]$Message,
                [object]$Level
            )

        }

        Reset-ActionRegistry

    }

    # ==================================================
    # Get-ActionHandler
    # ==================================================

    Context "Get-ActionHandler" {

        It "Retourne le handler Registry" {

            $Handler = Get-ActionHandler `
                -Type "Registry"

            $Handler |
                Should -Be "Invoke-RegistryAction"

        }

        It "Retourne le handler Service" {

            $Handler = Get-ActionHandler `
                -Type "Service"

            $Handler |
                Should -Be "Invoke-ServiceAction"

        }

        It "Retourne le handler Driver" {

            $Handler = Get-ActionHandler `
                -Type "Driver"

            $Handler |
                Should -Be "Invoke-DriverAction"

        }

        It "Retourne `$null pour un type inconnu" {

            $Handler = Get-ActionHandler `
                -Type "Unknown"

            $Handler |
                Should -BeNullOrEmpty

        }

    }

    # ==================================================
    # Register-ActionHandler
    # ==================================================

    Context "Register-ActionHandler" {

        BeforeEach {

            function Invoke-TestAction {
            }

        }

        It "Ajoute un nouveau handler" {

            Register-ActionHandler `
                -Type "Test" `
                -Handler "Invoke-TestAction"

            $Handler = Get-ActionHandler `
                -Type "Test"

            $Handler |
                Should -Be "Invoke-TestAction"

        }

        It "Refuse un type déjà enregistré" {

            {

                Register-ActionHandler `
                    -Type "Registry" `
                    -Handler "Invoke-TestAction"

            } |
                Should -Throw

        }

        It "Refuse un handler inexistant" {

            {

                Register-ActionHandler `
                    -Type "Test" `
                    -Handler "Invoke-Inconnu"

            } |
                Should -Throw

        }

    }

    # ==================================================
    # Get-RegisteredActionHandlers
    # ==================================================

    Context "Get-RegisteredActionHandlers" {

        It "Retourne une Hashtable" {

            $Registry = Get-RegisteredActionHandlers

            $Registry |
                Should -BeOfType Hashtable

        }

        It "Contient Registry" {

            $Registry = Get-RegisteredActionHandlers

            $Registry.ContainsKey("Registry") |
                Should -BeTrue

        }

        It "Contient Service" {

            $Registry = Get-RegisteredActionHandlers

            $Registry.ContainsKey("Service") |
                Should -BeTrue

        }

        It "Contient Driver" {

            $Registry = Get-RegisteredActionHandlers

            $Registry.ContainsKey("Driver") |
                Should -BeTrue

        }

    }

}