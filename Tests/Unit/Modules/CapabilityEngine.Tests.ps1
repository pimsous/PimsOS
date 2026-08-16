# ==========================================
# Tests : CapabilityEngine
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"

    # --------------------------------------------------
    # Fonction dépendante du Manager
    # --------------------------------------------------

    function global:Invoke-Capability {

        param(
            [psobject]$Context,
            [psobject]$Action
        )

        return $Context

    }

    . "$ProjectRoot\Modules\Actions\CapabilityEngine.ps1"

}

Describe "CapabilityEngine" {

    BeforeEach {

        Reset-Logger

        Mock Write-Log {}

        # ==========================================
        # Contexte de test
        # ==========================================

        $script:Context = [pscustomobject]@{

            BuildState = [pscustomobject]@{

                Status = "Idle"

            }

            Statistics = [pscustomobject]@{

                CapabilitiesProcessed = 0

            }

        }

        # ==========================================
        # Action de test
        # ==========================================

        $script:Action = [pscustomobject]@{

            Id = "Capability.Test"

            Name = "TestCapability"

            Success = $false

            Duration = [timespan]::Zero

            Error = $null

        }

    }

    # ==================================================
    # Invoke-CapabilityAction
    # ==================================================

    Context "Invoke-CapabilityAction" {

        It "Applique une capability valide" {

            $Result = Invoke-CapabilityAction `
                -Context $script:Context `
                -Action $script:Action

            $Result |
                Should -Be $script:Context

            $script:Action.Success |
                Should -BeTrue

        }


        It "Passe le BuildState à ApplyingCapability puis CapabilityApplied" {

            $null = Invoke-CapabilityAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Context.BuildState.Status |
                Should -Be "CapabilityApplied"

        }


        It "Incrémente CapabilitiesProcessed" {

            $null = Invoke-CapabilityAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Context.Statistics.CapabilitiesProcessed |
                Should -Be 1

        }


        It "Positionne Duration" {

            $null = Invoke-CapabilityAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Action.Duration |
                Should -BeOfType ([TimeSpan])

        }


        It "Réinitialise Error après une réussite" {

            $script:Action.Error = "Ancienne erreur"

            $null = Invoke-CapabilityAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Action.Error |
                Should -BeNullOrEmpty

        }


        It "Lève une exception si Name est absent" {

            $script:Action.Name = $null

            {

                Invoke-CapabilityAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Passe le BuildState à CapabilityFailed en cas d'erreur" {

            function global:Invoke-Capability {

                throw "Erreur de test"

            }

            {

                Invoke-CapabilityAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

            $script:Context.BuildState.Status |
                Should -Be "CapabilityFailed"

        }


        It "Positionne Success à False en cas d'erreur" {

            function global:Invoke-Capability {

                throw "Erreur de test"

            }

            {

                Invoke-CapabilityAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

            $script:Action.Success |
                Should -BeFalse

        }


        It "Conserve le message d'erreur de l'action" {

            function global:Invoke-Capability {

                throw "Erreur capability"

            }

            {

                Invoke-CapabilityAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

            $script:Action.Error |
                Should -Be "Erreur capability"

        }


        It "Arrête le traitement avec une exception enrichie" {

            function global:Invoke-Capability {

                throw "Erreur capability"

            }

            {

                Invoke-CapabilityAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw "*Capability.Test*"

        }

    }

}