# ==========================================
# Tests : API publique PimsOS
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..").Path

    Import-Module "$ProjectRoot\Modules\PimsOS.psd1" -Force

}

Describe "API publique PimsOS" {

    Context "Initialize-PimsOS" {

        It "Est exposée comme seule API publique" {

            $PublicCommands = @(
                (Get-Command -Module PimsOS).Name
            )

            $PublicCommands |
                Should -Contain "Initialize-PimsOS"

            $PublicCommands |
                Should -Not -Contain "New-BuildContext"

            $PublicCommands |
                Should -Not -Contain "Initialize-BuildContext"

            $PublicCommands |
                Should -Not -Contain "Show-PimsOSBuildWizard"

            $PublicCommands |
                Should -Not -Contain "Show-PimsOSDriverMenu"
        }

    }
	
	Context "Initialize-PimsOS - intégration du Wizard" {

        It "Transmet la configuration des drivers du Wizard au pipeline" {

            InModuleScope PimsOS {

                # ------------------------------------------
                # Configuration initiale
                # ------------------------------------------

                Mock Show-PimsOSBuildWizard {

                    param(
                        [psobject]$Context
                    )

                    $Context.Configuration.Drivers =
                        [pscustomobject]@{

                            Source        = "Folder"
                            Path          = "C:\Projets\PimsOS\Drivers"
                            Recurse       = $true
                            ForceUnsigned = $false

                        }

                    return $Context
                }

                # ------------------------------------------
                # Empêcher les opérations réelles du Build
                # ------------------------------------------

                Mock Repair-BuildEnvironment {

                    param(
                        [psobject]$Context
                    )

                    return $Context
                }

                Mock Test-PimsOSWindowsADK {

                    return [pscustomobject]@{
                        Installed    = $true
                        OsCdImgPath  = $null
                    }
                }

                Mock Invoke-EnvironmentChecks {

                    param(
                        [psobject]$Context
                    )

                    $Context.Report.Environment = [pscustomobject]@{
                        Success = $true
                    }

                    return $Context
                }

                Mock Invoke-BuildPipeline {

                    param(
                        [psobject]$Context
                    )

                    return $Context
                }

                Mock Complete-Build {

                    param(
                        [psobject]$Context,
                        [int]$ExitCode
                    )

                    return $Context
                }

                Mock Start-Logger {}

                Mock Write-Log {}

                # ------------------------------------------
                # Exécution
                # ------------------------------------------

                $Context = Initialize-PimsOS

                # ------------------------------------------
                # Vérifications
                # ------------------------------------------

                $Context |
                    Should -Not -BeNullOrEmpty

                $Context.Configuration.Drivers |
                    Should -Not -BeNullOrEmpty

                $Context.Configuration.Drivers.Source |
                    Should -Be "Folder"

                $Context.Configuration.Drivers.Path |
                    Should -Be "C:\Projets\PimsOS\Drivers"

                $Context.Configuration.Drivers.Recurse |
                    Should -BeTrue

                Should -Invoke `
                    -CommandName Show-PimsOSBuildWizard `
                    -Times 1 `
                    -Exactly

                Should -Invoke `
                    -CommandName Invoke-BuildPipeline `
                    -Times 1 `
                    -Exactly
            }
        }
    }
	
	Context "Initialize-PimsOS - intégration Profil et Options" {

        It "Transmet le profil et les options du Wizard au pipeline" {

            InModuleScope PimsOS {

                # ------------------------------------------
                # Simulation du Wizard
                # ------------------------------------------

                Mock Show-PimsOSBuildWizard {

                    param(
                        [psobject]$Context
                    )

                    $Context.ConfigurationProfile =
                        "Tests\Registry"

                    $Context.Build.CreateISO =
                        $false

                    $Context.Build.CreateReport =
                        $false

                    $Context.Build.DryRun =
                        $true

                    return $Context
                }

                # ------------------------------------------
                # Empêcher les opérations réelles
                # ------------------------------------------

                Mock Repair-BuildEnvironment {

                    param(
                        [psobject]$Context
                    )

                    return $Context
                }

                Mock Test-PimsOSWindowsADK {

                    return [pscustomobject]@{
                        Installed   = $true
                        OsCdImgPath = $null
                    }
                }

                Mock Invoke-EnvironmentChecks {

                    param(
                        [psobject]$Context
                    )

                    $Context.Report.Environment =
                        [pscustomobject]@{
                            Success = $true
                        }

                    return $Context
                }

                Mock Invoke-BuildPipeline {

                    param(
                        [psobject]$Context
                    )

                    $script:PipelineContext = $Context

                    return $Context
                }

                Mock Complete-Build {

                    param(
                        [psobject]$Context,
                        [int]$ExitCode
                    )

                    return $Context
                }

                Mock Start-Logger {}

                Mock Write-Log {}

                # ------------------------------------------
                # Exécution
                # ------------------------------------------

                $script:PipelineContext = $null

                $Context = Initialize-PimsOS

                # ------------------------------------------
                # Vérification du contexte final
                # ------------------------------------------

                $Context |
                    Should -Not -BeNullOrEmpty

                $Context.ConfigurationProfile |
                    Should -Be "Tests\Registry"

                $Context.Build.CreateISO |
                    Should -BeFalse

                $Context.Build.CreateReport |
                    Should -BeFalse

                $Context.Build.DryRun |
                    Should -BeTrue

                # ------------------------------------------
                # Vérification du contexte transmis
                # ------------------------------------------

                $script:PipelineContext |
                    Should -Not -BeNullOrEmpty

                $script:PipelineContext.ConfigurationProfile |
                    Should -Be "Tests\Registry"

                $script:PipelineContext.Build.CreateISO |
                    Should -BeFalse

                $script:PipelineContext.Build.CreateReport |
                    Should -BeFalse

                $script:PipelineContext.Build.DryRun |
                    Should -BeTrue

                # ------------------------------------------
                # Vérification des appels
                # ------------------------------------------

                Should -Invoke `
                    -CommandName Show-PimsOSBuildWizard `
                    -Times 1 `
                    -Exactly

                Should -Invoke `
                    -CommandName Invoke-BuildPipeline `
                    -Times 1 `
                    -Exactly
            }
        }
    }
}