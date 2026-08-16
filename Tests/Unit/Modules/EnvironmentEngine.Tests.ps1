# ==========================================
# Tests : EnvironmentEngine
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"

    # --------------------------------------------------
    # Dépendance du Manager
    # --------------------------------------------------

    function global:Invoke-Environment {

        param(
            [psobject]$Context,
            [psobject]$Action
        )

        return $Context

    }

    . "$ProjectRoot\Modules\Actions\EnvironmentEngine.ps1"

}

Describe "EnvironmentEngine" {

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

                EnvironmentProcessed = 0

            }

        }

        # ==========================================
        # Action
        # ==========================================

        $script:Action = [pscustomobject]@{

            Id = "Environment.Test"

            Name = "TestVariable"

            Success = $false

            Duration = [timespan]::Zero

            Error = $null

        }

    }


    # ==================================================
    # Invoke-EnvironmentAction
    # ==================================================

    Context "Invoke-EnvironmentAction" {

        It "Applique une variable d'environnement valide" {

            $Result = Invoke-EnvironmentAction `
                -Context $script:Context `
                -Action $script:Action

            $Result |
                Should -Be $script:Context

            $script:Action.Success |
                Should -BeTrue

        }


        It "Passe le BuildState à EnvironmentApplied" {

            $null = Invoke-EnvironmentAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Context.BuildState.Status |
                Should -Be "EnvironmentApplied"

        }


        It "Incrémente EnvironmentProcessed" {

            $null = Invoke-EnvironmentAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Context.Statistics.EnvironmentProcessed |
                Should -Be 1

        }


        It "Positionne Duration" {

            $null = Invoke-EnvironmentAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Action.Duration |
                Should -BeOfType ([TimeSpan])

        }


        It "Réinitialise Error après une réussite" {

            $script:Action.Error = "Ancienne erreur"

            $null = Invoke-EnvironmentAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Action.Error |
                Should -BeNullOrEmpty

        }


        It "Lève une exception si Name est absent" {

            $script:Action.Name = $null

            {

                Invoke-EnvironmentAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Passe le BuildState à EnvironmentFailed en cas d'erreur" {

            function global:Invoke-Environment {

                throw "Erreur de test"

            }

            {

                Invoke-EnvironmentAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

            $script:Context.BuildState.Status |
                Should -Be "EnvironmentFailed"

        }


        It "Positionne Success à False en cas d'erreur" {

            function global:Invoke-Environment {

                throw "Erreur de test"

            }

            {

                Invoke-EnvironmentAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

            $script:Action.Success |
                Should -BeFalse

        }


        It "Conserve le message d'erreur de l'action" {

            function global:Invoke-Environment {

                throw "Erreur environnement"

            }

            {

                Invoke-EnvironmentAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

            $script:Action.Error |
                Should -Be "Erreur environnement"

        }


        It "Enrichit l'exception avec l'identifiant de l'action" {

            function global:Invoke-Environment {

                throw "Erreur environnement"

            }

            {

                Invoke-EnvironmentAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw "*Environment.Test*"

        }

    }

}