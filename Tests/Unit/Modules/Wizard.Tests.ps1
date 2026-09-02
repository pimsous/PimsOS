# ==========================================

# Tests : UI Wizard

# Projet : PimsOS Builder

# ==========================================

BeforeAll {


$ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

Import-Module "$ProjectRoot\Modules\PimsOS.psd1" -Force


}

Describe "PimsOS UI Wizard" {


# ==================================================
# Show-PimsOSDriverMenu
# ==================================================

Context "Show-PimsOSDriverMenu" {

    It "Configure None pour le choix 1" {

        InModuleScope PimsOS {

            $TestContext = [pscustomobject]@{

                Project = [pscustomobject]@{
                    Config = [pscustomobject]@{
                        Drivers = $null
                    }
                }

            }

            Mock Read-Host {
                return "1"
            }

            Mock Write-Log {}

            Show-PimsOSDriverMenu `
                -Context $TestContext

            $TestContext.Project.Config.Drivers.Source |
                Should -Be "None"

            $TestContext.Project.Config.Drivers.Path |
                Should -BeNullOrEmpty

        }

    }


    It "Configure CurrentSystem pour le choix 2" {

        InModuleScope PimsOS {

            $TestContext = [pscustomobject]@{

                Project = [pscustomobject]@{
                    Config = [pscustomobject]@{
                        Drivers = $null
                    }
                }

            }

            Mock Read-Host {
                return "2"
            }

            Mock Write-Log {}

            Show-PimsOSDriverMenu `
                -Context $TestContext

            $TestContext.Project.Config.Drivers.Source |
                Should -Be "CurrentSystem"

            $TestContext.Project.Config.Drivers.Path |
                Should -BeNullOrEmpty

        }

    }


    It "Configure le dossier Drivers racine pour le choix 3" {

        InModuleScope PimsOS {

            $TestContext = [pscustomobject]@{

                Project = [pscustomobject]@{
                    Config = [pscustomobject]@{
                        Drivers = $null
                    }
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

            Show-PimsOSDriverMenu `
                -Context $TestContext

            $TestContext.Project.Config.Drivers.Source |
                Should -Be "Folder"

            $TestContext.Project.Config.Drivers.Path |
                Should -Be "C:\Projets\PimsOS\Drivers"

            $TestContext.Project.Config.Drivers.Path |
                Should -Not -Match "\\Workspace\\Drivers"

        }

    }


    It "Active la recherche récursive pour les drivers du dossier projet" {

        InModuleScope PimsOS {

            $TestContext = [pscustomobject]@{

                Project = [pscustomobject]@{
                    Config = [pscustomobject]@{
                        Drivers = $null
                    }
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

            Show-PimsOSDriverMenu `
                -Context $TestContext

            $TestContext.Project.Config.Drivers.Recurse |
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

				Project = [pscustomobject]@{
					Config = [pscustomobject]@{
						Drivers = $ExistingDrivers
					}
				}

			}

            Mock Read-Host {
                return "0"
            }

            Show-PimsOSDriverMenu `
                -Context $TestContext

            $TestContext.Project.Config.Drivers.Source |
                Should -Be "None"

        }

    }

}


# ==================================================
# Show-PimsOSChocolateyPackageMenu
# ==================================================

Context "Show-PimsOSChocolateyPackageMenu" {

    It "Retourne immédiatement avec le choix 0" {

        InModuleScope PimsOS {

            $Root = Join-Path $TestDrive "PimsOS"
            New-Item -ItemType Directory -Path (Join-Path $Root "Config\Packages") -Force | Out-Null
            $Catalog = @{ Provider="Chocolatey"; Version="1.0"; Description="Test"; Packages=@(@{ Id="chocolatey"; Enabled=$true; Category="Chocolatey"; Mode="Offline"; Version=$null }) }
            $Catalog | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $Root "Config\Packages\Chocolatey.json") -Encoding utf8

            $TestContext = [pscustomobject]@{
                Project = [pscustomobject]@{ Root = $Root }
            }

            Mock Read-Host { return "0" }
            Mock Write-Log {}

            Show-PimsOSChocolateyPackageMenu -Context $TestContext

            Test-Path -LiteralPath (Join-Path $Root "Config\Packages\Chocolatey.json") | Should -BeTrue
        }
    }
}


# ==================================================
# Show-PimsOSBuildWizard
# ==================================================

Context "Show-PimsOSBuildWizard" {

    It "Retourne le contexte lorsque le choix 7 est sélectionné" {

        InModuleScope PimsOS {

            $TestContext = [pscustomobject]@{

                ConfigurationProfile = "Tests\Registry"

                Configuration = @()

                Build = [pscustomobject]@{

                    CreateISO    = $true
                    CreateReport = $true
                    DryRun       = $false
                    Interactive  = $true

                }

            }

            Mock Read-Host {
                return "7"
            }

            Mock Write-Log {}

            $Result = Show-PimsOSBuildWizard `
                -Context $TestContext

            $Result |
                Should -Be $TestContext

        }

    }


    It "Lance le menu des drivers lorsque le choix 4 est sélectionné" {

        InModuleScope PimsOS {

            $TestContext = [pscustomobject]@{

                ConfigurationProfile = "Tests\Registry"

                Configuration = @()

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

                    return "4"

                }

                return "7"

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


    It "Lance le menu des options lorsque le choix 3 est sélectionné" {

        InModuleScope PimsOS {

            $TestContext = [pscustomobject]@{

                ConfigurationProfile = "Tests\Registry"

                Configuration = @()

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

                    return "3"

                }

                return "7"

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


    It "Lance le résumé lorsque le choix 6 est sélectionné" {

        InModuleScope PimsOS {

            $TestContext = [pscustomobject]@{

                ConfigurationProfile = "Tests\Registry"

                Configuration = @()

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

                    return "6"

                }

                return "7"

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

                Configuration = @()

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

# ==================================================
# Configuration des profils et personnalisation
# ==================================================

Context "Show-PimsOSProfileMenu" {

    It "Propose la configuration personnalisée sans profil" {
        InModuleScope PimsOS {
            $TestContext = [pscustomobject]@{
				Project = [pscustomobject]@{
					Root = "C:\Projets\PimsOS"
					Config = [pscustomobject]@{
						Drivers = [pscustomobject]@{
							Source = "None"
							Path = $null
							Recurse = $true
							ForceUnsigned = $false
						}
					}
				}

				ConfigurationProfile = ""
				Configuration = @()
				Tweaks = @()

				BuildState = [pscustomobject]@{
					Image = [pscustomobject]@{
						TweaksLoaded = $false
						ProfileLoaded = $false
						ProfileMerged = $false
						ConfigLoaded = $false
					}
				}
			}
            Mock Get-ProjectRoot { "C:\Projets\PimsOS" }
            Mock Test-Path { $true }
            Mock Get-ChildItem { @([pscustomobject]@{ BaseName="Default"; Name="Default.json"; FullName="C:\Projets\PimsOS\Profiles\Default.json" }) }
            Mock Initialize-PimsOSCustomConfiguration {
                $TestContext.ConfigurationProfile = "Custom"
                $TestContext.Configuration = @([pscustomobject]@{ Id="Test.Tweak"; Enabled=$true })
            }
            Mock Read-Host { "P" }
            Mock Write-Log {}
            Show-PimsOSProfileMenu -Context $TestContext
            $TestContext.ConfigurationProfile | Should -Be "Custom"
            @($TestContext.Configuration).Count | Should -Be 1
        }
    }

    It "Charge et applique le profil sélectionné" {
        InModuleScope PimsOS {
            $TestContext = [pscustomobject]@{
				Project = [pscustomobject]@{
					Root = "C:\Projets\PimsOS"
					Config = [pscustomobject]@{
						Drivers = [pscustomobject]@{
							Source = "None"
							Path = $null
							Recurse = $true
							ForceUnsigned = $false
						}
					}
				}

				ConfigurationProfile = ""
				Configuration = @()
				Tweaks = @()

				BuildState = [pscustomobject]@{
					Image = [pscustomobject]@{
						TweaksLoaded = $false
						ProfileLoaded = $false
						ProfileMerged = $false
						ConfigLoaded = $false
					}
				}
			}
            Mock Get-ProjectRoot { "C:\Projets\PimsOS" }
            Mock Test-Path { $true }
            Mock Get-ChildItem { @([pscustomobject]@{ BaseName="Gaming"; Name="Gaming.json"; FullName="C:\Projets\PimsOS\Profiles\Gaming.json" }) }
            Mock Load-Profile { [pscustomobject]@{ Name="Gaming"; Tweaks=[pscustomobject]@{} } }
            Mock Get-TweakDefinitions { @([pscustomobject]@{ Id="Xbox.DisableGameBar"; Default=$false }) }
            Mock Test-TweakDefinitions {}
            Mock Merge-Profile { $TestContext.Configuration=@([pscustomobject]@{ Id="Xbox.DisableGameBar"; Enabled=$true }); return $TestContext.Configuration }
            Mock Read-Host { "1" }
            Mock Write-Log {}
            Show-PimsOSProfileMenu -Context $TestContext
            $TestContext.ConfigurationProfile | Should -Be "Gaming"
            @($TestContext.Configuration).Count | Should -Be 1
            Should -Invoke -CommandName Load-Profile -Times 1 -Exactly
            Should -Invoke -CommandName Load-Profile -ParameterFilter {
                $Name -eq "Gaming"
            } -Times 1 -Exactly
            Should -Invoke -CommandName Merge-Profile -Times 1 -Exactly
        }
    }
}

Context "Initialize-PimsOSCustomConfiguration" {

    It "Initialise les tweaks avec leurs valeurs Default" {
        InModuleScope PimsOS {
            $TestContext = [pscustomobject]@{
				Project = [pscustomobject]@{
					Root = "C:\Projets\PimsOS"
					Config = [pscustomobject]@{
						Drivers = [pscustomobject]@{
							Source = "None"
							Path = $null
							Recurse = $true
							ForceUnsigned = $false
						}
					}
				}

				ConfigurationProfile = "Default"
				Configuration = @()
				Tweaks = @()

				BuildState = [pscustomobject]@{
					Image = [pscustomobject]@{
						TweaksLoaded = $false
						ProfileLoaded = $false
						ProfileMerged = $false
						ConfigLoaded = $false
					}
				}
			}
            Mock Get-TweakDefinitions { @([pscustomobject]@{ Id="Privacy.DisableTelemetry"; Name="Désactiver la télémétrie"; Default=$true; CategoryId="Privacy" }) }
            Mock Test-TweakDefinitions {}
            Mock New-ConfigurationItem { param($Tweak,$Enabled) [pscustomobject]@{ Id=$Tweak.Id; Enabled=$Enabled } }
            Mock Write-Log {}
            Initialize-PimsOSCustomConfiguration -Context $TestContext | Out-Null
            $TestContext.ConfigurationProfile | Should -Be "Custom"
            $TestContext.Configuration[0].Enabled | Should -BeTrue
            $TestContext.BuildState.Image.ProfileLoaded | Should -BeFalse
            $TestContext.BuildState.Image.ConfigLoaded | Should -BeTrue
        }
    }
}



Context "Show-PimsOSTweakMenu - initialisation" {

    It "Reconstruit la configuration lorsqu'elle contient encore la configuration globale" {
        InModuleScope PimsOS {

            $TestContext = [pscustomobject]@{
                ConfigurationProfile = "Default"
                Configuration = [pscustomobject]@{
                    Drivers = [pscustomobject]@{
                        Source = "None"
                    }
                }
                Project = [pscustomobject]@{
                    Config = [pscustomobject]@{
                        Drivers = [pscustomobject]@{
                            Source = "None"
                        }
                    }
                }
            }

            $script:GetConfigurationCalled = $false

            Mock Get-Configuration {
                $script:GetConfigurationCalled = $true
                $Context.Configuration = @(
                    [pscustomobject]@{
                        Id = "T1"
                        Name = "Tweak 1"
                        CategoryId = "Test"
                        Enabled = $true
                        Description = ""
                        Risk = "Safe"
                        Reversible = $true
                        RequiresRestart = $false
                        Impact = ""
                    }
                )
                return $Context
            }

            Mock Read-Host { "0" }
            Mock Write-Log {}

            Show-PimsOSTweakMenu -Context $TestContext

            $script:GetConfigurationCalled |
                Should -BeTrue

            $TestContext.Configuration[0].Id |
                Should -Be "T1"

            $TestContext.Configuration[0].Enabled |
                Should -BeTrue
        }
    }
}

Context "Show-PimsOSTweakMenu - conservation de la configuration" {

    It "Ne reconstruit pas une configuration déjà chargée" {
        InModuleScope PimsOS {

            $script:ReadCount = 0

            $TestContext = [pscustomobject]@{
                ConfigurationProfile = "Default"
                Configuration = @(
                    [pscustomobject]@{
                        Id = "T1"
                        Name = "Tweak 1"
                        CategoryId = "Test"
                        Enabled = $true
                        Description = ""
                        Risk = "Safe"
                        Reversible = $true
                        RequiresRestart = $false
                        Impact = ""
                    }
                )
                Project = [pscustomobject]@{
                    Config = [pscustomobject]@{
                        Drivers = [pscustomobject]@{
                            Source = "Folder"
                            Path = "C:\Drivers"
                            Recurse = $true
                            ForceUnsigned = $false
                        }
                    }
                }
            }

            Mock Read-Host {
                $script:ReadCount++
                return "0"
            }

            Mock Write-Log {}
            Mock Get-Configuration {
                throw "Get-Configuration ne doit pas être rappelé."
            }

            Show-PimsOSTweakMenu -Context $TestContext

            $TestContext.Configuration[0].Enabled |
                Should -BeTrue

            $TestContext.Project.Config.Drivers.Source |
                Should -Be "Folder"
        }
    }

    It "Conserve les drivers dans Project.Config après configuration des tweaks" {
        InModuleScope PimsOS {

            $script:ReadCount = 0

            $TestContext = [pscustomobject]@{
                ConfigurationProfile = "Default"
                Configuration = @(
                    [pscustomobject]@{
                        Id = "T1"
                        Name = "Tweak 1"
                        CategoryId = "Test"
                        Enabled = $true
                        Description = ""
                        Risk = "Safe"
                        Reversible = $true
                        RequiresRestart = $false
                        Impact = ""
                    }
                )
                Project = [pscustomobject]@{
                    Config = [pscustomobject]@{
                        Drivers = [pscustomobject]@{
                            Source = "Folder"
                            Path = "C:\Drivers"
                            Recurse = $true
                            ForceUnsigned = $false
                        }
                    }
                }
            }

            Mock Read-Host {
                $script:ReadCount++
                if ($script:ReadCount -eq 1) {
                    return "1"
                }
                return "0"
            }

            Mock Write-Log {}

            Show-PimsOSTweakMenu -Context $TestContext

            $TestContext.Project.Config.Drivers.Source |
                Should -Be "Folder"
        }
    }
}

Context "Show-PimsOSTweakMenu - sélection multiple" {

    It "Active ou désactive plusieurs tweaks avec une liste" {
		InModuleScope PimsOS {

			$script:Call = 0

			$TestContext = [pscustomobject]@{
				Configuration = @(
					[pscustomobject]@{
						Id="T1"; Name="T1"; CategoryId="Test"
						Enabled=$false; Description=""
						Risk="Safe"; Reversible=$true
						RequiresRestart=$false; Impact=""
					},
					[pscustomobject]@{
						Id="T2"; Name="T2"; CategoryId="Test"
						Enabled=$false; Description=""
						Risk="Safe"; Reversible=$true
						RequiresRestart=$false; Impact=""
					},
					[pscustomobject]@{
						Id="T3"; Name="T3"; CategoryId="Test"
						Enabled=$true; Description=""
						Risk="Safe"; Reversible=$true
						RequiresRestart=$false; Impact=""
					}
				)
			}

			Mock Read-Host {
				$script:Call++

				if ($script:Call -eq 1) {
					return "1,3"
				}

				return "0"
			}

			Mock Write-Log {}

			Show-PimsOSTweakMenu -Context $TestContext

			$TestContext.Configuration[0].Enabled | Should -BeTrue
			$TestContext.Configuration[2].Enabled | Should -BeFalse
		}
	}

    It "Active ou désactive une plage de tweaks" {
		InModuleScope PimsOS {

			$script:Call = 0

			$TestContext = [pscustomobject]@{
				Configuration = @(
					[pscustomobject]@{
						Id="T1"; Name="T1"; CategoryId="Test"
						Enabled=$false; Description=""
						Risk="Safe"; Reversible=$true
						RequiresRestart=$false; Impact=""
					},
					[pscustomobject]@{
						Id="T2"; Name="T2"; CategoryId="Test"
						Enabled=$false; Description=""
						Risk="Safe"; Reversible=$true
						RequiresRestart=$false; Impact=""
					},
					[pscustomobject]@{
						Id="T3"; Name="T3"; CategoryId="Test"
						Enabled=$false; Description=""
						Risk="Safe"; Reversible=$true
						RequiresRestart=$false; Impact=""
					},
					[pscustomobject]@{
						Id="T4"; Name="T4"; CategoryId="Test"
						Enabled=$false; Description=""
						Risk="Safe"; Reversible=$true
						RequiresRestart=$false; Impact=""
					}
				)
			}

			Mock Read-Host {
				$script:Call++

				if ($script:Call -eq 1) {
					return "2-4"
				}

				return "0"
			}

			Mock Write-Log {}

			Show-PimsOSTweakMenu -Context $TestContext

			$TestContext.Configuration[0].Enabled | Should -BeFalse
			$TestContext.Configuration[1].Enabled | Should -BeTrue
			$TestContext.Configuration[2].Enabled | Should -BeTrue
			$TestContext.Configuration[3].Enabled | Should -BeTrue
		}
	}
}

}
