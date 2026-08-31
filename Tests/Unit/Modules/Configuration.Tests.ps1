# ==========================================
# Tests : Configuration
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"
    . "$ProjectRoot\Modules\Core\Core.ps1"
    . "$ProjectRoot\Modules\Infrastructure\Validation.ps1"
    . "$ProjectRoot\Modules\Configuration\Categories.ps1"
    . "$ProjectRoot\Modules\Configuration\Tweak.ps1"
    . "$ProjectRoot\Modules\Configuration\Profile.ps1"
    . "$ProjectRoot\Modules\Configuration\Configuration.ps1"

}

Describe "Configuration" {

    BeforeEach {

        Reset-Logger

        Mock Write-Log {}

        # ==========================================
        # Contexte
        # ==========================================

        $script:Context = [pscustomobject]@{

            Project = [pscustomobject]@{

                Root = $ProjectRoot

                Config = [pscustomobject]@{

                    Drivers = [pscustomobject]@{

                        Source        = "None"
                        Path          = $null
                        Recurse       = $true
                        ForceUnsigned = $false

                    }

                }

            }

            Configuration = $null

			Tweaks = @()

			ConfigurationProfile = $null

            BuildState = [pscustomobject]@{

                Image = [pscustomobject]@{

                    TweaksLoaded  = $false
                    ProfileLoaded = $false
                    ProfileMerged = $false
                    ConfigLoaded  = $false

                }

            }

        }

        # ==========================================
        # Données de test
        # ==========================================

        $script:Tweak = [pscustomobject]@{

            Id          = "Test.Tweak"
            Name        = "Test Tweak"
            Description = "Tweak de test"
            Enabled     = $false

        }

        $script:ProfileObject = [pscustomobject]@{

            Name = "Default"

            Tweaks = [pscustomobject]@{

                "Test.Tweak" = $true

            }

        }

        $script:Configuration = @(
            [pscustomobject]@{

                Id      = "Test.Tweak"
                Name    = "Test Tweak"
                Enabled = $true

            }
        )

        # ==========================================
        # Mocks
        # ==========================================

        Mock Get-TweakDefinitions {

            @(
                $script:Tweak
            )

        }

        Mock Test-TweakDefinitions {

            $null

        }

        Mock Load-Profile {

            $script:ProfileObject

        }

        Mock Merge-Profile {

			$Context.Configuration = @(
				$script:Configuration
			)

			return $Context.Configuration

		}

    }

    # ==================================================
    # Get-Configuration
    # ==================================================

    Context "Get-Configuration" {

        It "Construit une configuration complète" {

            Get-Configuration `
                -Context $script:Context `
                -Profile "Default" |
                Out-Null

            ($null -ne $script:Context.Configuration) |
                Should -BeTrue

            @($script:Context.Configuration).Count |
                Should -Be 1

        }

        It "Retourne le contexte fourni" {

            $Result = Get-Configuration `
                -Context $script:Context `
                -Profile "Default"

            $Result |
                Should -BeOfType ([pscustomobject])

            $Result.Project.Root |
                Should -Be $ProjectRoot

        }

        It "Stocke une configuration de tweaks plate avec Enabled" {

            Get-Configuration `
                -Context $script:Context `
                -Profile "Default" |
                Out-Null

            $Configuration = @(
                $script:Context.Configuration
            )

            $Configuration.Count |
                Should -Be 1

            $Configuration[0].PSObject.Properties.Name |
                Should -Contain "Id"

            $Configuration[0].PSObject.Properties.Name |
                Should -Contain "Enabled"

            $Configuration[0].Id |
                Should -Be "Test.Tweak"

            $Configuration[0].Enabled |
                Should -BeTrue

        }

        It "Conserve la configuration globale dans Project.Config" {

            Get-Configuration `
                -Context $script:Context `
                -Profile "Default" |
                Out-Null

            $script:Context.Project.Config.Drivers |
                Should -Not -BeNullOrEmpty

            $script:Context.Project.Config.Drivers.Source |
                Should -Be "None"

        }

        It "Charge les définitions de tweaks" {

            Get-Configuration `
                -Context $script:Context `
                -Profile "Default" |
                Out-Null

            Should -Invoke `
                -CommandName Get-TweakDefinitions `
                -Times 1 `
                -Exactly

        }

        It "Valide les définitions de tweaks" {

            Get-Configuration `
                -Context $script:Context `
                -Profile "Default" |
                Out-Null

            Should -Invoke `
                -CommandName Test-TweakDefinitions `
                -Times 1 `
                -Exactly

        }

        It "Charge le profil demandé" {

            Get-Configuration `
                -Context $script:Context `
                -Profile "Default" |
                Out-Null

            Should -Invoke `
                -CommandName Load-Profile `
                -Times 1 `
                -Exactly `
                -ParameterFilter {

                    $Name -eq "Default"

                }

        }

        It "Fusionne les tweaks avec le profil" {

            Get-Configuration `
                -Context $script:Context `
                -Profile "Default" |
                Out-Null

            Should -Invoke `
                -CommandName Merge-Profile `
                -Times 1 `
                -Exactly

        }

        It "Marque les tweaks comme chargés" {

            Get-Configuration `
                -Context $script:Context `
                -Profile "Default" |
                Out-Null

            $script:Context.BuildState.Image.TweaksLoaded |
                Should -BeTrue

        }

        It "Marque le profil comme chargé" {

            Get-Configuration `
                -Context $script:Context `
                -Profile "Default" |
                Out-Null

            $script:Context.BuildState.Image.ProfileLoaded |
                Should -BeTrue

        }

        It "Marque le profil comme fusionné" {

            Get-Configuration `
                -Context $script:Context `
                -Profile "Default" |
                Out-Null

            $script:Context.BuildState.Image.ProfileMerged |
                Should -BeTrue

        }

        It "Marque la configuration comme chargée" {

            Get-Configuration `
                -Context $script:Context `
                -Profile "Default" |
                Out-Null

            $script:Context.BuildState.Image.ConfigLoaded |
                Should -BeTrue

        }

        It "Conserve une configuration personnalisée sans charger un profil JSON" {

            $CustomConfiguration = @(
                [pscustomobject]@{
                    Id = "Test.Tweak"
                    Name = "Test Tweak"
                    Enabled = $false
                }
            )

            $script:Context.ConfigurationProfile = "Custom"
            $script:Context.Configuration = $CustomConfiguration

            Mock Load-Profile {
                throw "Load-Profile ne doit pas être appelé pour Custom."
            }

            Mock Get-TweakDefinitions {
                throw "Get-TweakDefinitions ne doit pas être appelé pour Custom."
            }

            $Result = Get-Configuration `
                -Context $script:Context `
                -Profile "Custom"

            @($Result.Configuration).Count |
                Should -Be 1

            $Result.Configuration[0].Id |
                Should -Be "Test.Tweak"

            $Result.Configuration[0].Enabled |
                Should -BeFalse

            $Result.ConfigurationProfile |
                Should -Be "Custom"

            Should -Invoke `
                -CommandName Load-Profile `
                -Times 0 `
                -Exactly

            Should -Invoke `
                -CommandName Get-TweakDefinitions `
                -Times 0 `
                -Exactly

        }


        It "Refuse une configuration personnalisée sans Enabled" {

            $script:Context.ConfigurationProfile = "Custom"

            $script:Context.Configuration = @(
                [pscustomobject]@{
                    Id = "Test.Tweak"
                    Name = "Test Tweak"
                }
            )

            {
                Get-Configuration `
                    -Context $script:Context `
                    -Profile "Custom"

            } |
                Should -Throw

        }


        It "Lève une exception si aucun tweak n'est chargé" {

            Mock Get-TweakDefinitions {

                @()

            }

            {

                Get-Configuration `
                    -Context $script:Context `
                    -Profile "Default"

            } |
                Should -Throw

        }

        It "Lève une exception si le profil est null" {

            Mock Load-Profile {

                $null

            }

            {

                Get-Configuration `
                    -Context $script:Context `
                    -Profile "Default"

            } |
                Should -Throw

        }

        It "Lève une exception si la fusion retourne null" {

            Mock Merge-Profile {

                $null

            }

            {

                Get-Configuration `
                    -Context $script:Context `
                    -Profile "Default"

            } |
                Should -Throw

        }

    }

    # ==================================================
    # Get-DriverConfiguration
    # ==================================================

    Context "Get-DriverConfiguration" {

        It "Retourne les valeurs par défaut configurées" {

            $Result = Get-DriverConfiguration `
                -Context $script:Context

            $Result.Source |
                Should -Be "None"

            $Result.Path |
                Should -BeNullOrEmpty

            $Result.Recurse |
                Should -BeTrue

            $Result.ForceUnsigned |
                Should -BeFalse

        }

        It "Retourne la configuration Folder" {

            $DriversPath = Join-Path `
                $TestDrive `
                "Drivers"

            New-Item `
                -ItemType Directory `
                -Path $DriversPath `
                -Force |
                Out-Null

            $script:Context.Project.Config.Drivers = [pscustomobject]@{

                Source        = "Folder"
                Path          = $DriversPath
                Recurse       = $true
                ForceUnsigned = $false

            }

            $Result = Get-DriverConfiguration `
                -Context $script:Context

            $Result.Source |
                Should -Be "Folder"

            $Result.Path |
                Should -Be (
                    Resolve-Path `
                        -LiteralPath $DriversPath
                ).Path

            $Result.Recurse |
                Should -BeTrue

            $Result.ForceUnsigned |
                Should -BeFalse

        }

        It "Accepte CurrentSystem sans chemin" {

            $script:Context.Project.Config.Drivers = [pscustomobject]@{

                Source        = "CurrentSystem"
                Path          = $null
                Recurse       = $true
                ForceUnsigned = $false

            }

            $Result = Get-DriverConfiguration `
                -Context $script:Context

            $Result.Source |
                Should -Be "CurrentSystem"

            $Result.Path |
                Should -BeNullOrEmpty

        }

        It "Accepte Source None sans chemin" {

            $script:Context.Project.Config.Drivers = [pscustomobject]@{

                Source        = "None"
                Path          = $null
                Recurse       = $true
                ForceUnsigned = $false

            }

            $Result = Get-DriverConfiguration `
                -Context $script:Context

            $Result.Source |
                Should -Be "None"

            $Result.Path |
                Should -BeNullOrEmpty

        }

        It "Refuse une source inconnue" {

            $script:Context.Project.Config.Drivers = [pscustomobject]@{

                Source        = "Unknown"
                Path          = $null
                Recurse       = $true
                ForceUnsigned = $false

            }

            {

                Get-DriverConfiguration `
                    -Context $script:Context

            } |
                Should -Throw "*n'est pas prise en charge*"

        }

        It "Refuse Folder sans chemin" {

            $script:Context.Project.Config.Drivers = [pscustomobject]@{

                Source        = "Folder"
                Path          = $null
                Recurse       = $true
                ForceUnsigned = $false

            }

            {

                Get-DriverConfiguration `
                    -Context $script:Context

            } |
                Should -Throw "*chemin des drivers est obligatoire*"

        }

        It "Refuse Folder avec un dossier inexistant" {

            $script:Context.Project.Config.Drivers = [pscustomobject]@{

                Source        = "Folder"
                Path          = "Drivers\Missing"
                Recurse       = $true
                ForceUnsigned = $false

            }

            {

                Get-DriverConfiguration `
                    -Context $script:Context

            } |
                Should -Throw "*dossier de drivers est introuvable*"

        }

        It "Utilise les valeurs par défaut si Drivers est absent" {

            $script:Context.Project.Config |
                Add-Member `
                    -MemberType NoteProperty `
                    -Name Temporary `
                    -Value $true

            $script:Context.Project.Config.PSObject.Properties.Remove("Drivers")

            $Result = Get-DriverConfiguration `
                -Context $script:Context

            $Result.Source |
                Should -Be "None"

            $Result.Path |
                Should -BeNullOrEmpty

            $Result.Recurse |
                Should -BeTrue

            $Result.ForceUnsigned |
                Should -BeFalse

        }

    }

}