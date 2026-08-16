# ==========================================
# Tests : CommandEngine
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"

    # --------------------------------------------------
    # Fonction dépendante du Manager
    # --------------------------------------------------

    function global:Invoke-Command {

        param(
            [psobject]$Context,
            [psobject]$Action
        )

        return $Context

    }

    . "$ProjectRoot\Modules\Actions\CommandEngine.ps1"

}

Describe "CommandEngine" {

    BeforeEach {

        Reset-Logger

        Mock Write-Log {}

        # ==========================================
        # Contexte
        # ==========================================

        $script:Context = [pscustomobject]@{

            BuildState = [pscustomobject]@{

                Status = "Idle"

            }

            Statistics = [pscustomobject]@{

                CommandsProcessed = 0

            }

        }

        # ==========================================
        # Action
        # ==========================================

        $script:Action = [pscustomobject]@{

            Id = "Command.Test"

            Command = "Test-Command"

            Success = $false

            Duration = [timespan]::Zero

            Error = $null

        }

    }


    # ==================================================
    # Invoke-CommandAction
    # ==================================================

    Context "Invoke-CommandAction" {

        It "Exécute une commande valide" {

            $Result = Invoke-CommandAction `
                -Context $script:Context `
                -Action $script:Action

            $Result |
                Should -Be $script:Context

            $script:Action.Success |
                Should -BeTrue

        }


        It "Passe le BuildState à CommandApplied" {

            $null = Invoke-CommandAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Context.BuildState.Status |
                Should -Be "CommandApplied"

        }


        It "Incrémente CommandsProcessed" {

            $null = Invoke-CommandAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Context.Statistics.CommandsProcessed |
                Should -Be 1

        }


        It "Positionne Duration" {

            $null = Invoke-CommandAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Action.Duration |
                Should -BeOfType ([TimeSpan])

        }


        It "Réinitialise Error après une réussite" {

            $script:Action.Error = "Ancienne erreur"

            $null = Invoke-CommandAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Action.Error |
                Should -BeNullOrEmpty

        }


        It "Lève une exception si la commande est absente" {

            $script:Action.Command = $null

            {

                Invoke-CommandAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Passe le BuildState à CommandFailed en cas d'erreur" {

            function global:Invoke-Command {

                throw "Erreur de test"

            }

            {

                Invoke-CommandAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

            $script:Context.BuildState.Status |
                Should -Be "CommandFailed"

        }


        It "Positionne Success à False en cas d'erreur" {

            function global:Invoke-Command {

                throw "Erreur de test"

            }

            {

                Invoke-CommandAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

            $script:Action.Success |
                Should -BeFalse

        }


        It "Conserve le message d'erreur de l'action" {

            function global:Invoke-Command {

                throw "Erreur commande"

            }

            {

                Invoke-CommandAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

            $script:Action.Error |
                Should -Be "Erreur commande"

        }


        It "Enrichit l'exception avec l'identifiant de la commande" {

            function global:Invoke-Command {

                throw "Erreur commande"

            }

            {

                Invoke-CommandAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw "*Command.Test*"

        }

    }

}