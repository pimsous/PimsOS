# ==========================================
# Tests : CommandManager
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"

    # --------------------------------------------------
    # Handlers par défaut
    # --------------------------------------------------

    function global:Invoke-NativeCommand {

        param(
            [psobject]$Context,
            [psobject]$Action
        )

        return $Context

    }

    function global:Invoke-PowerShellCommand {

        param(
            [psobject]$Context,
            [psobject]$Action
        )

        return $Context

    }

    function global:Invoke-CmdCommand {

        param(
            [psobject]$Context,
            [psobject]$Action
        )

        return $Context

    }

    # --------------------------------------------------
    # Handler de test
    # --------------------------------------------------

    function global:Invoke-TestCommandProvider {

        param(
            [psobject]$Context,
            [psobject]$Action
        )

        return $Context

    }

    . "$ProjectRoot\Modules\Managers\CommandManager.ps1"

}

Describe "CommandManager" {

    BeforeEach {

        Reset-Logger

        Mock Write-Log {}

        Reset-CommandProviders

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

            Provider  = "Native"

            Command   = "Test-Command"

            Arguments = "--test"

        }

    }


    # ==================================================
    # Get-CommandProviders
    # ==================================================

    Context "Get-CommandProviders" {

        It "Retourne les providers par défaut" {

            $Providers = @(
                Get-CommandProviders
            )

            $Providers |
                Should -Contain "Native"

            $Providers |
                Should -Contain "PowerShell"

            $Providers |
                Should -Contain "CMD"

        }


        It "Retourne les providers dans l'ordre enregistré" {

            $Providers = @(
                Get-CommandProviders
            )

            $Providers[0] |
                Should -Be "Native"

            $Providers[1] |
                Should -Be "PowerShell"

            $Providers[2] |
                Should -Be "CMD"

        }

    }


    # ==================================================
    # Invoke-Command
    # ==================================================

    Context "Invoke-Command" {

        It "Exécute une commande avec le provider Native" {

            $Result = Invoke-Command `
                -Context $script:Context `
                -Action $script:Action

            $Result |
                Should -Be $script:Context

        }


        It "Exécute une commande avec le provider PowerShell" {

            $script:Action.Provider = "PowerShell"

            $Result = Invoke-Command `
                -Context $script:Context `
                -Action $script:Action

            $Result |
                Should -Be $script:Context

        }


        It "Exécute une commande avec le provider CMD" {

            $script:Action.Provider = "CMD"

            $Result = Invoke-Command `
                -Context $script:Context `
                -Action $script:Action

            $Result |
                Should -Be $script:Context

        }


        It "Refuse un provider absent" {

            $script:Action.Provider = $null

            {

                Invoke-Command `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Refuse une commande absente" {

            $script:Action.Command = $null

            {

                Invoke-Command `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Refuse un provider inconnu" {

            $script:Action.Provider = "Unknown"

            {

                Invoke-Command `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Refuse un handler inexistant" {

            Register-CommandProvider `
                -Name "Broken" `
                -Handler "Invoke-UnknownCommandHandler" |
                Out-Null

        } -Skip:$true


        It "Transmet les arguments au handler" {

            $script:ReceivedAction = $null

            function global:Invoke-TestCommandProvider {

                param(
                    [psobject]$Context,
                    [psobject]$Action
                )

                $script:ReceivedAction = $Action

                return $Context

            }

            Register-CommandProvider `
                -Name "Test" `
                -Handler "Invoke-TestCommandProvider"

            $script:Action.Provider = "Test"

            $null = Invoke-Command `
                -Context $script:Context `
                -Action $script:Action

            $script:ReceivedAction.Arguments |
                Should -Be "--test"

        }

    }


    # ==================================================
    # Register-CommandProvider
    # ==================================================

    Context "Register-CommandProvider" {

        It "Enregistre un nouveau provider" {

            Register-CommandProvider `
                -Name "Test" `
                -Handler "Invoke-TestCommandProvider"

            @(
                Get-CommandProviders
            ) |
                Should -Contain "Test"

        }


        It "Refuse un handler inexistant" {

            {

                Register-CommandProvider `
                    -Name "Broken" `
                    -Handler "Invoke-UnknownCommandHandler"

            } |
                Should -Throw

        }

    }


    # ==================================================
    # Reset-CommandProviders
    # ==================================================

    Context "Reset-CommandProviders" {

        It "Réinitialise les providers par défaut" {

            Register-CommandProvider `
                -Name "Test" `
                -Handler "Invoke-TestCommandProvider"

            Get-CommandProviders |
                Should -Contain "Test"

            Reset-CommandProviders

            Get-CommandProviders |
                Should -Contain "Native"

            Get-CommandProviders |
                Should -Contain "PowerShell"

            Get-CommandProviders |
                Should -Contain "CMD"

            Get-CommandProviders |
                Should -Not -Contain "Test"

        }

    }

}