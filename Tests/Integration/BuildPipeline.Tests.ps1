# ==========================================
# Tests : BuildPipeline
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"
    . "$ProjectRoot\Modules\Core\Workflow.ps1"
    . "$ProjectRoot\Modules\Core\Pipeline.ps1"

}

Describe "BuildPipeline" {

    BeforeEach {

        Reset-Logger

        Mock Write-Log {}

        $script:Context = [pscustomobject]@{

            BuildState = [pscustomobject]@{

                Status = "Idle"

                Success   = $false
                Completed = $false

                Pipeline = [pscustomobject]@{

                    Started   = $false
                    Current   = $null
                    Completed = @()
                    Failed    = @()

                }

            }

            Report = [pscustomobject]@{

                Environment = $null

                Phases = @()

                CurrentPhase = [pscustomobject]@{

                    Success = $true
                    Errors  = @()
                    Steps   = @()

                }

                Warnings     = @()
                Errors       = @()
                Informations = @()

            }

        }

    }

    Context "Invoke-BuildStep" {

        It "Ajoute une étape réussie" {

            $Context = Invoke-BuildStep `
                -Context $script:Context `
                -Name "Étape 1" `
                -Action {

                    param($Context)

                    return $Context

                }

            $Context.BuildState.Pipeline.Completed |
                Should -Contain "Étape 1"

        }

        It "Ajoute une étape échouée" {

            {

                Invoke-BuildStep `
                    -Context $script:Context `
                    -Name "Erreur" `
                    -Action {

                        throw "Boom"

                    }

            } | Should -Throw

            $script:Context.BuildState.Pipeline.Failed |
                Should -Contain "Erreur"

        }

        It "Ajoute une ligne dans le rapport" {

            $Context = Invoke-BuildStep `
                -Context $script:Context `
                -Name "Étape 1" `
                -Action {

                    param($Context)

                    return $Context

                }

            $Context.Report.CurrentPhase.Steps.Count |
                Should -Be 1

        }

    }

    Context "Invoke-BuildPipeline" {

        It "Termine le pipeline" {

            $Pipeline = @(

                @{

                    Name = "Étape A"

                    Action = {

                        param($Context)

                        return $Context

                    }

                },

                @{

                    Name = "Étape B"

                    Action = {

                        param($Context)

                        return $Context

                    }

                }

            )

            $Context = Invoke-BuildPipeline `
                -Context $script:Context `
                -Pipeline $Pipeline

            $Context.BuildState.Status |
                Should -Be "PipelineCompleted"

        }

    }

}