# ==========================================
# Tests : FeatureEngine
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"

    # --------------------------------------------------
    # Dépendance du Manager
    # --------------------------------------------------

    function global:Invoke-Feature {

        param(
            [psobject]$Context,
            [psobject]$Action
        )

        return $Context

    }

    . "$ProjectRoot\Modules\Actions\FeatureEngine.ps1"

}

Describe "FeatureEngine" {

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

                FeaturesProcessed = 0

            }

        }

        # ==========================================
        # Action
        # ==========================================

        $script:Action = [pscustomobject]@{

            Id = "Feature.Test"

            Name = "TestFeature"

            Success = $false

            Duration = [timespan]::Zero

            Error = $null

        }

    }


    # ==================================================
    # Invoke-FeatureAction
    # ==================================================

    Context "Invoke-FeatureAction" {

        It "Applique une fonctionnalité valide" {

            $Result = Invoke-FeatureAction `
                -Context $script:Context `
                -Action $script:Action

            $Result |
                Should -Be $script:Context

            $script:Action.Success |
                Should -BeTrue

        }


        It "Passe le BuildState à FeatureApplied" {

            $null = Invoke-FeatureAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Context.BuildState.Status |
                Should -Be "FeatureApplied"

        }


        It "Incrémente FeaturesProcessed" {

            $null = Invoke-FeatureAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Context.Statistics.FeaturesProcessed |
                Should -Be 1

        }


        It "Positionne Duration" {

            $null = Invoke-FeatureAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Action.Duration |
                Should -BeOfType ([TimeSpan])

        }


        It "Réinitialise Error après une réussite" {

            $script:Action.Error = "Ancienne erreur"

            $null = Invoke-FeatureAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Action.Error |
                Should -BeNullOrEmpty

        }


        It "Lève une exception si Name est absent" {

            $script:Action.Name = $null

            {

                Invoke-FeatureAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Passe le BuildState à FeatureFailed en cas d'erreur" {

            function global:Invoke-Feature {

                throw "Erreur de test"

            }

            {

                Invoke-FeatureAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

            $script:Context.BuildState.Status |
                Should -Be "FeatureFailed"

        }


        It "Positionne Success à False en cas d'erreur" {

            function global:Invoke-Feature {

                throw "Erreur de test"

            }

            {

                Invoke-FeatureAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

            $script:Action.Success |
                Should -BeFalse

        }


        It "Conserve le message d'erreur de l'action" {

            function global:Invoke-Feature {

                throw "Erreur fonctionnalité"

            }

            {

                Invoke-FeatureAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

            $script:Action.Error |
                Should -Be "Erreur fonctionnalité"

        }


        It "Enrichit l'exception avec l'identifiant de l'action" {

            function global:Invoke-Feature {

                throw "Erreur fonctionnalité"

            }

            {

                Invoke-FeatureAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw "*Feature.Test*"

        }

    }

}