# ==========================================
# Tests : EnvironmentChecks
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..").Path

    . "$ProjectRoot\Modules\Core\Core.ps1"
    . "$ProjectRoot\Modules\Core\Report.ps1"
    . "$ProjectRoot\Modules\Core\Workflow.ps1"
    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"
    . "$ProjectRoot\Modules\Infrastructure\Prerequisites.ps1"
    . "$ProjectRoot\Modules\Infrastructure\Check.ps1"
    . "$ProjectRoot\Modules\Image\Iso.ps1"

}

Describe "EnvironmentChecks" {

    BeforeEach {

        Reset-Core
        Reset-Logger

        $Config = Get-Config

        $script:Context = [pscustomobject]@{

            Project = [pscustomobject]@{

                Root = Get-ProjectRoot
                Config = $Config

            }

            Report = [pscustomobject]@{

                Environment = $null
                Informations = @()
                Warnings = @()
                Errors = @()

            }

            BuildState = [pscustomobject]@{

                Status = ""

                Environment = [pscustomobject]@{

                    Checked       = $false
					PowerShell    = $false
					Administrator = $false
					Git           = $false
					Dism          = $false
					Iso           = $false
					WindowsADK    = $false
					DiskSpace     = $false

                }

            }

        }

        Mock Write-Log {}

        Mock Start-BuildPhase {
            param($Context)
            return $Context
        }

        Mock Complete-BuildPhase {
            param($Context)
            return $Context
        }

    }

    It "Marque l'environnement comme vérifié" {

        $Result = Invoke-EnvironmentChecks `
            -Context $script:Context

        $Result.BuildState.Environment.Checked |
            Should -BeTrue

    }

    It "Crée le rapport d'environnement" {

        $Result = Invoke-EnvironmentChecks `
            -Context $script:Context

        $Result.Report.Environment |
            Should -Not -BeNullOrEmpty

    }

    It "Positionne le statut à EnvironmentChecked" {

        $Result = Invoke-EnvironmentChecks `
            -Context $script:Context

        $Result.BuildState.Status |
            Should -Be "EnvironmentChecked"

    }

    It "Retourne un contexte valide" {

        $Result = Invoke-EnvironmentChecks `
            -Context $script:Context

        $Result |
            Should -Not -BeNullOrEmpty

    }

}