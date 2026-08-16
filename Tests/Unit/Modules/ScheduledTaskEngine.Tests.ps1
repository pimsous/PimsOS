# ==========================================
# Tests : ScheduledTaskEngine
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"

    # --------------------------------------------------
    # Dépendance du Manager
    # --------------------------------------------------

    function global:Invoke-ScheduledTask {

        param(
            [psobject]$Context,
            [psobject]$Action
        )

        return $Context

    }

    . "$ProjectRoot\Modules\Actions\ScheduledTaskEngine.ps1"

}

Describe "ScheduledTaskEngine" {

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

                ScheduledTasksProcessed = 0

            }

        }

        # ==========================================
        # Action
        # ==========================================

        $script:Action = [pscustomobject]@{

            Id = "ScheduledTask.Test"

            Name = "TestScheduledTask"

            Success = $false

            Duration = [timespan]::Zero

            Error = $null

        }

    }


    # ==================================================
    # Invoke-ScheduledTaskAction
    # ==================================================

    Context "Invoke-ScheduledTaskAction" {

        It "Applique une tâche planifiée valide" {

            $Result = Invoke-ScheduledTaskAction `
                -Context $script:Context `
                -Action $script:Action

            $Result |
                Should -Be $script:Context

            $script:Action.Success |
                Should -BeTrue

        }


        It "Passe le BuildState à ScheduledTaskApplied" {

            $null = Invoke-ScheduledTaskAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Context.BuildState.Status |
                Should -Be "ScheduledTaskApplied"

        }


        It "Incrémente ScheduledTasksProcessed" {

            $null = Invoke-ScheduledTaskAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Context.Statistics.ScheduledTasksProcessed |
                Should -Be 1

        }


        It "Positionne Duration" {

            $null = Invoke-ScheduledTaskAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Action.Duration |
                Should -BeOfType ([TimeSpan])

        }


        It "Réinitialise Error après une réussite" {

            $script:Action.Error = "Ancienne erreur"

            $null = Invoke-ScheduledTaskAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Action.Error |
                Should -BeNullOrEmpty

        }


        It "Lève une exception si Name est absent" {

            $script:Action.Name = $null

            {

                Invoke-ScheduledTaskAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Passe le BuildState à ScheduledTaskFailed en cas d'erreur" {

            function global:Invoke-ScheduledTask {

                throw "Erreur de test"

            }

            {

                Invoke-ScheduledTaskAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

            $script:Context.BuildState.Status |
                Should -Be "ScheduledTaskFailed"

        }


        It "Positionne Success à False en cas d'erreur" {

            function global:Invoke-ScheduledTask {

                throw "Erreur de test"

            }

            {

                Invoke-ScheduledTaskAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

            $script:Action.Success |
                Should -BeFalse

        }


        It "Conserve le message d'erreur de l'action" {

            function global:Invoke-ScheduledTask {

                throw "Erreur tâche planifiée"

            }

            {

                Invoke-ScheduledTaskAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

            $script:Action.Error |
                Should -Be "Erreur tâche planifiée"

        }


        It "Enrichit l'exception avec l'identifiant de l'action" {

            function global:Invoke-ScheduledTask {

                throw "Erreur tâche planifiée"

            }

            {

                Invoke-ScheduledTaskAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw "*ScheduledTask.Test*"

        }

    }

}