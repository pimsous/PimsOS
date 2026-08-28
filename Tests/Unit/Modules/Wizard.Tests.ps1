# ==========================================
# Tests : UI Wizard
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    Import-Module "$ProjectRoot\Modules\PimsOS.psd1" -Force

}

Describe "PimsOS UI Wizard" {

    Context "Show-PimsOSDriverMenu" {

        It "Configure None pour le choix 1" {

            InModuleScope PimsOS {

                $TestContext = [pscustomobject]@{
                    Configuration = [pscustomobject]@{
                        Drivers = $null
                    }
                }

                Mock Read-Host {
                    return "1"
                }

                Mock Write-Log {}

                Show-PimsOSDriverMenu -Context $TestContext

                $TestContext.Configuration.Drivers.Source |
                    Should -Be "None"

                $TestContext.Configuration.Drivers.Path |
                    Should -BeNullOrEmpty
            }
        }


        It "Configure CurrentSystem pour le choix 2" {

            InModuleScope PimsOS {

                $TestContext = [pscustomobject]@{
                    Configuration = [pscustomobject]@{
                        Drivers = $null
                    }
                }

                Mock Read-Host {
                    return "2"
                }

                Mock Write-Log {}

                Show-PimsOSDriverMenu -Context $TestContext

                $TestContext.Configuration.Drivers.Source |
                    Should -Be "CurrentSystem"

                $TestContext.Configuration.Drivers.Path |
                    Should -BeNullOrEmpty
            }
        }


        It "Configure le dossier Drivers racine pour le choix 3" {

            InModuleScope PimsOS {

                $TestContext = [pscustomobject]@{
                    Configuration = [pscustomobject]@{
                        Drivers = $null
                    }
                }

                Mock Read-Host {
                    return "3"
                }

                Mock Write-Log {}

                Mock Get-ProjectRoot {
                    return "C:\Projets\PimsOS"
                }

                Mock Test-Path {
                    return $true
                }

                Show-PimsOSDriverMenu -Context $TestContext

                $TestContext.Configuration.Drivers.Source |
                    Should -Be "Folder"

                $TestContext.Configuration.Drivers.Path |
                    Should -Be "C:\Projets\PimsOS\Drivers"

                $TestContext.Configuration.Drivers.Path |
                    Should -Not -Match "\\Workspace\\Drivers"
            }
        }


        It "Active la recherche récursive pour les drivers du dossier projet" {

            InModuleScope PimsOS {

                $TestContext = [pscustomobject]@{
                    Configuration = [pscustomobject]@{
                        Drivers = $null
                    }
                }

                Mock Read-Host {
                    return "3"
                }

                Mock Write-Log {}

                Mock Get-ProjectRoot {
                    return "C:\Projets\PimsOS"
                }

                Mock Test-Path {
                    return $true
                }

                Show-PimsOSDriverMenu -Context $TestContext

                $TestContext.Configuration.Drivers.Recurse |
                    Should -BeTrue
            }
        }


        It "Ne modifie pas la configuration avec le choix 0" {

            InModuleScope PimsOS {

                $ExistingDrivers = [pscustomobject]@{
                    Source        = "None"
                    Path          = $null
                    Recurse       = $true
                    ForceUnsigned = $false
                }

                $TestContext = [pscustomobject]@{
                    Configuration = [pscustomobject]@{
                        Drivers = $ExistingDrivers
                    }
                }

                Mock Read-Host {
                    return "0"
                }

                Show-PimsOSDriverMenu -Context $TestContext

                $TestContext.Configuration.Drivers.Source |
                    Should -Be "None"
            }
        }

    }
	
	Context "Show-PimsOSBuildWizard" {

        It "Retourne le contexte lorsque le choix 5 est sélectionné" {

            InModuleScope PimsOS {

                $TestContext = [pscustomobject]@{

                    ConfigurationProfile = "Tests\Registry"

                    Build = [pscustomobject]@{
                        CreateISO    = $true
                        CreateReport = $true
                        DryRun       = $false
                        Interactive  = $true
                    }

                }

                Mock Read-Host {
                    return "5"
                }

                Mock Write-Log {}

                $Result = Show-PimsOSBuildWizard `
                    -Context $TestContext

                $Result |
                    Should -Be $TestContext

            }

        }


        It "Lance le menu drivers lorsque le choix 3 est sélectionné" {

            InModuleScope PimsOS {

                $TestContext = [pscustomobject]@{

                    ConfigurationProfile = "Tests\Registry"

                    Build = [pscustomobject]@{
                        CreateISO    = $true
                        CreateReport = $true
                        DryRun       = $false
                        Interactive  = $true
                    }

                }

                $script:DriverMenuCalled = $false

                Mock Read-Host {

                    if (-not $script:DriverMenuCalled) {
                        return "3"
                    }

                    return "5"
                }

                Mock Show-PimsOSDriverMenu {

                    $script:DriverMenuCalled = $true

                }

                Mock Write-Log {}

                $Result = Show-PimsOSBuildWizard `
                    -Context $TestContext

                $script:DriverMenuCalled |
                    Should -BeTrue

                $Result |
                    Should -Be $TestContext

            }

        }


        It "Lance le menu des options lorsque le choix 2 est sélectionné" {

            InModuleScope PimsOS {

                $TestContext = [pscustomobject]@{

                    ConfigurationProfile = "Tests\Registry"

                    Build = [pscustomobject]@{
                        CreateISO    = $true
                        CreateReport = $true
                        DryRun       = $false
                        Interactive  = $true
                    }

                }

                $script:OptionsMenuCalled = $false

                Mock Read-Host {

                    if (-not $script:OptionsMenuCalled) {
                        return "2"
                    }

                    return "5"
                }

                Mock Show-PimsOSBuildOptions {

                    $script:OptionsMenuCalled = $true

                }

                Mock Write-Log {}

                $Result = Show-PimsOSBuildWizard `
                    -Context $TestContext

                $script:OptionsMenuCalled |
                    Should -BeTrue

                $Result |
                    Should -Be $TestContext

            }

        }


        It "Lance le résumé lorsque le choix 4 est sélectionné" {

            InModuleScope PimsOS {

                $TestContext = [pscustomobject]@{

                    ConfigurationProfile = "Tests\Registry"

                    Build = [pscustomobject]@{
                        CreateISO    = $true
                        CreateReport = $true
                        DryRun       = $false
                        Interactive  = $true
                    }

                }

                $script:SummaryCalled = $false

                Mock Read-Host {

                    if (-not $script:SummaryCalled) {
                        return "4"
                    }

                    return "5"
                }

                Mock Show-PimsOSBuildSummary {

                    $script:SummaryCalled = $true

                }

                Mock Write-Log {}

                $Result = Show-PimsOSBuildWizard `
                    -Context $TestContext

                $script:SummaryCalled |
                    Should -BeTrue

                $Result |
                    Should -Be $TestContext

            }

        }


        It "Lève une erreur lorsque le build est annulé" {

            InModuleScope PimsOS {

                $TestContext = [pscustomobject]@{

                    ConfigurationProfile = "Tests\Registry"

                    Build = [pscustomobject]@{
                        CreateISO    = $true
                        CreateReport = $true
                        DryRun       = $false
                        Interactive  = $true
                    }

                }

                Mock Read-Host {
                    return "0"
                }

                {

                    Show-PimsOSBuildWizard `
                        -Context $TestContext

                } |
                    Should -Throw "*Build annulé*"

            }

        }

    }

}
