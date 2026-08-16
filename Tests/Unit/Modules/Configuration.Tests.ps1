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

            }

            Configuration = $null

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

            $script:Configuration

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


        # ==================================================
        # Gestion des erreurs
        # ==================================================

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

}