# ==========================================
# Tests : Workflow
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"
    . "$ProjectRoot\Modules\Core\Workflow.ps1"

}

Describe "Workflow" {

    BeforeEach {

        Reset-Logger

        Mock Write-Log {}

        $script:Context = [pscustomobject]@{

            BuildState = [pscustomobject]@{

                Status = "Idle"

            }

            Report = [pscustomobject]@{

                CurrentPhase = $null

                Phases = @()

            }

            Statistics = [pscustomobject]@{

                TweaksApplied     = 0
                PackagesProcessed = 0
                DriversProcessed  = 0
                Errors            = 0
                Warnings          = 0

            }

            Project = [pscustomobject]@{

                Duration = [timespan]::Zero

            }

        }

    }


    # ==================================================
    # Start-BuildPhase
    # ==================================================

    Context "Start-BuildPhase" {

        It "Crée une phase" {

            $Context = Start-BuildPhase `
                -Context $script:Context `
                -Name "Environment"

            $Context.Report.CurrentPhase |
                Should -Not -BeNullOrEmpty

        }

        It "Définit le nom de la phase" {

            $Context = Start-BuildPhase `
                -Context $script:Context `
                -Name "Environment"

            $Context.Report.CurrentPhase.Name |
                Should -Be "Environment"

        }

        It "Ajoute la phase au rapport" {

            $Context = Start-BuildPhase `
                -Context $script:Context `
                -Name "Environment"

            $Context.Report.Phases.Count |
                Should -Be 1

        }

        It "Initialise la phase comme réussie" {

            $Context = Start-BuildPhase `
                -Context $script:Context `
                -Name "Environment"

            $Context.Report.CurrentPhase.Success |
                Should -BeTrue

        }

        It "Initialise Steps comme une collection vide" {

            $Context = Start-BuildPhase `
                -Context $script:Context `
                -Name "Environment"

            $Steps = $Context.Report.CurrentPhase.Steps

            ($null -eq $Steps) |
                Should -BeFalse

            $Steps.Count |
                Should -Be 0

        }

        It "Initialise Errors comme une collection vide" {

            $Context = Start-BuildPhase `
                -Context $script:Context `
                -Name "Environment"

            $Errors = $Context.Report.CurrentPhase.Errors

            ($null -eq $Errors) |
                Should -BeFalse

            $Errors.Count |
                Should -Be 0

        }

        It "Positionne le statut Running-Name" {

            $Context = Start-BuildPhase `
                -Context $script:Context `
                -Name "Environment"

            $Context.BuildState.Status |
                Should -Be "Running-Environment"

        }

        It "Crée une date de début" {

            $Context = Start-BuildPhase `
                -Context $script:Context `
                -Name "Environment"

            $Context.Report.CurrentPhase.StartTime |
                Should -Not -BeNullOrEmpty

        }

    }


    # ==================================================
    # Complete-BuildPhase
    # ==================================================

    Context "Complete-BuildPhase" {

        It "Termine une phase active" {

            $Context = Start-BuildPhase `
                -Context $script:Context `
                -Name "Environment"

            $Context = Complete-BuildPhase `
                -Context $Context

            $Context.Report.CurrentPhase |
                Should -BeNullOrEmpty

        }

        It "Définit EndTime" {

            $Context = Start-BuildPhase `
                -Context $script:Context `
                -Name "Environment"

            $Phase = $Context.Report.CurrentPhase

            $Context = Complete-BuildPhase `
                -Context $Context

            $Phase.EndTime |
                Should -Not -BeNullOrEmpty

        }

        It "Calcule la durée de la phase" {

            $Context = Start-BuildPhase `
                -Context $script:Context `
                -Name "Environment"

            $Phase = $Context.Report.CurrentPhase

            $Context = Complete-BuildPhase `
                -Context $Context

            $Phase.Duration |
                Should -BeOfType ([TimeSpan])

        }

        It "Conserve Success lorsqu'il n'y a pas d'erreur" {

            $Context = Start-BuildPhase `
                -Context $script:Context `
                -Name "Environment"

            $Phase = $Context.Report.CurrentPhase

            $Context = Complete-BuildPhase `
                -Context $Context

            $Phase.Success |
                Should -BeTrue

        }

        It "Passe Success à False lorsqu'une erreur existe" {

            $Context = Start-BuildPhase `
                -Context $script:Context `
                -Name "Environment"

            $Context.Report.CurrentPhase.Errors.Add("Erreur de test")

            $Phase = $Context.Report.CurrentPhase

            Complete-BuildPhase `
                -Context $Context |
                Out-Null

            $Phase.Success |
                Should -BeFalse

        }

        It "Réinitialise le statut à Idle" {

            $Context = Start-BuildPhase `
                -Context $script:Context `
                -Name "Environment"

            $Context = Complete-BuildPhase `
                -Context $Context

            $Context.BuildState.Status |
                Should -Be "Idle"

        }

        It "Retourne le contexte lorsqu'aucune phase active n'existe" {

            $Context = Complete-BuildPhase `
                -Context $script:Context

            $Context |
                Should -Not -BeNullOrEmpty

        }

    }


    # ==================================================
    # Show-BuildSummary
    # ==================================================

    Context "Show-BuildSummary" {

        It "S'exécute sans erreur avec un contexte vide" {

            {

                Show-BuildSummary `
                    -Context $script:Context

            } |
                Should -Not -Throw

        }

        It "S'exécute avec une phase réussie" {

            $Context = Start-BuildPhase `
                -Context $script:Context `
                -Name "Environment"

            Complete-BuildPhase `
                -Context $Context |
                Out-Null

            {

                Show-BuildSummary `
                    -Context $Context

            } |
                Should -Not -Throw

        }

        It "S'exécute avec une phase en erreur" {

            $Context = Start-BuildPhase `
                -Context $script:Context `
                -Name "Environment"

            $Context.Report.CurrentPhase.Errors.Add("Erreur de test")

            Complete-BuildPhase `
                -Context $Context |
                Out-Null

            {

                Show-BuildSummary `
                    -Context $Context

            } |
                Should -Not -Throw

        }

    }

}