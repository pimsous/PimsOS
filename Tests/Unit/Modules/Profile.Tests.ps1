# ==========================================
# Tests : Profile
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"
    . "$ProjectRoot\Modules\Core\Core.ps1"
    . "$ProjectRoot\Modules\Configuration\Categories.ps1"
    . "$ProjectRoot\Modules\Configuration\Tweak.ps1"
    . "$ProjectRoot\Modules\Configuration\Profile.ps1"

}

Describe "Profile" {

    BeforeEach {

        Reset-Logger

        # Contexte minimal réel
        $script:Context = [pscustomobject]@{

            Project = [pscustomobject]@{

                Root = $ProjectRoot

            }

            BuildState = [pscustomobject]@{

                Image = [pscustomobject]@{

                    TweaksLoaded  = $false
                    ProfileLoaded = $false
                    ProfileMerged = $false

                }

            }

            ConfigurationProfile = $null

            Configuration = $null

        }

    }


    # ==================================================
    # Get-TweakDefinitions
    # ==================================================

    Context "Get-TweakDefinitions" {

        It "Charge les définitions de tweaks" {

            $Tweaks = @(
                Get-TweakDefinitions `
                    -Context $script:Context `
                    -Reload
            )

            $Tweaks |
                Should -Not -BeNullOrEmpty

            $Tweaks.Count |
                Should -BeGreaterThan 0

        }


        It "Marque les tweaks comme chargés dans le BuildState" {

            $null = Get-TweakDefinitions `
                -Context $script:Context `
                -Reload

            $script:Context.BuildState.Image.TweaksLoaded |
                Should -BeTrue

        }


        It "Retourne des objets Tweak" {

            $Tweaks = @(
                Get-TweakDefinitions `
                    -Context $script:Context `
                    -Reload
            )

            foreach ($Tweak in $Tweaks) {

                $Tweak.ObjectType |
                    Should -Be "Tweak"

            }

        }


        It "Charge des identifiants de tweaks uniques" {

            $Tweaks = @(
                Get-TweakDefinitions `
                    -Context $script:Context `
                    -Reload
            )

            $Ids = @(
                $Tweaks.Id
            )

            $Ids.Count |
                Should -Be $Ids.Count

            ($Ids | Sort-Object -Unique).Count |
                Should -Be $Ids.Count

        }


        It "Utilise le cache sans Reload" {

            $First = @(
                Get-TweakDefinitions `
                    -Context $script:Context `
                    -Reload
            )

            $Second = @(
                Get-TweakDefinitions `
                    -Context $script:Context
            )

            $Second.Count |
                Should -Be $First.Count

            for (
                $Index = 0;
                $Index -lt $First.Count;
                $Index++
            ) {

                $Second[$Index].Id |
                    Should -Be $First[$Index].Id

            }

        }


        It "Refuse un dossier Tweaks inexistant" {

            $Context = [pscustomobject]@{

                Project = [pscustomobject]@{

                    Root = (Join-Path $env:TEMP "PimsOS-Profile-Test-DoesNotExist")

                }

                BuildState = [pscustomobject]@{

                    Image = [pscustomobject]@{

                        TweaksLoaded = $false

                    }

                }

            }

            {

                Get-TweakDefinitions `
                    -Context $Context `
                    -Reload

            } |
                Should -Throw

        }

    }


    # ==================================================
    # Get-ProfileList
    # ==================================================

    Context "Get-ProfileList" {

        It "Retourne la liste des profils" {

            $Profiles = @(
                Get-ProfileList `
                    -Context $script:Context
            )

            $Profiles |
                Should -Not -BeNullOrEmpty

        }


        It "Retourne des objets contenant Name FileName et FullName" {

            $Profiles = @(
                Get-ProfileList `
                    -Context $script:Context
            )

            foreach ($Profile in $Profiles) {

                $Profile.Name |
                    Should -Not -BeNullOrEmpty

                $Profile.FileName |
                    Should -Not -BeNullOrEmpty

                $Profile.FullName |
                    Should -Not -BeNullOrEmpty

            }

        }


        It "Retourne les noms de profils sans extension ni point final" {

            $Profiles = @(
                Get-ProfileList `
                    -Context $script:Context
            )

            foreach ($Profile in $Profiles) {

                $Profile.Name |
                    Should -Not -Match '\.json$'

                $Profile.Name |
                    Should -Not -Match '\.$'

            }

        }


        It "Retourne les profils triés par nom" {

            $Profiles = @(
                Get-ProfileList `
                    -Context $script:Context
            )

            $Names = @(
                $Profiles.Name
            )

            $Sorted = @(
                $Names | Sort-Object
            )

            $Names |
                Should -Be $Sorted

        }

        It "Expose les profils imbriqués avec leur chemin relatif" {

            $NestedProfile = Join-Path `
                -Path $ProjectRoot `
                -ChildPath "Profiles\Tests\Registry.json"

            Test-Path $NestedProfile |
                Should -BeTrue

            $Profiles = @(
                Get-ProfileList `
                    -Context $script:Context
            )

            ($Profiles | Where-Object Name -eq "Tests\Registry") |
                Should -Not -BeNullOrEmpty

        }

    }


    # ==================================================
    # Load-Profile
    # ==================================================

    Context "Load-Profile" {

        It "Charge un profil existant" {

            $Profiles = @(
                Get-ProfileList `
                    -Context $script:Context
            )

            $ProfileName = $Profiles[0].Name

            $Profile = Load-Profile `
                -Context $script:Context `
                -Name $ProfileName

            $Profile |
                Should -Not -BeNullOrEmpty

        }


        It "Positionne le profil dans le contexte" {

            $Profiles = @(
                Get-ProfileList `
                    -Context $script:Context
            )

            $ProfileName = $Profiles[0].Name

            $null = Load-Profile `
                -Context $script:Context `
                -Name $ProfileName

            $script:Context.ConfigurationProfile |
                Should -Be $ProfileName

            $script:Context.BuildState.Image.ProfileLoaded |
                Should -BeTrue

        }


        It "Lève une exception pour un profil inconnu" {

            {

                Load-Profile `
                    -Context $script:Context `
                    -Name "Profile_That_Does_Not_Exist"

            } |
                Should -Throw

        }

    }


    # ==================================================
    # New-ConfigurationItem
    # ==================================================

    Context "New-ConfigurationItem" {

        It "Construit un élément de configuration" {

            $Categories = @(
                Get-CategoryDefinitions -Reload
            )

            $Category = $Categories[0]

            $Tweak = [pscustomobject]@{

                Id = "Test.Tweak"

                Name = "Test Tweak"

                Description = "Description"

                CategoryId = $Category.Id

                Enabled = $false

                Default = $false

                Actions = @()

            }

            $Item = New-ConfigurationItem `
                -Tweak $Tweak `
                -Enabled $true

            $Item |
                Should -Not -BeNullOrEmpty

            $Item.Id |
                Should -Be "Test.Tweak"

            $Item.Enabled |
                Should -BeTrue

        }


        It "Ajoute les informations de catégorie" {

            $Categories = @(
                Get-CategoryDefinitions -Reload
            )

            $Category = $Categories[0]

            $Tweak = [pscustomobject]@{

                Id = "Test.Tweak"

                Name = "Test Tweak"

                Description = "Description"

                CategoryId = $Category.Id

                Enabled = $false

                Default = $false

                Actions = @()

            }

            $Item = New-ConfigurationItem `
                -Tweak $Tweak `
                -Enabled $false

            $Item.Category |
				Should -Be $Category.Id

            $Item.PSObject.Properties.Name |
                Should -Contain "CategoryDescription"

            $Item.PSObject.Properties.Name |
                Should -Contain "CategoryColor"

            $Item.PSObject.Properties.Name |
                Should -Contain "CategoryIcon"

            $Item.PSObject.Properties.Name |
                Should -Contain "CategoryOrder"

            $Item.PSObject.Properties.Name |
                Should -Contain "CategoryVisible"

            $Item.PSObject.Properties.Name |
                Should -Contain "CategoryGroups"

        }


        It "Respecte l'état Enabled demandé" {

            $Categories = @(
                Get-CategoryDefinitions -Reload
            )

            $Category = $Categories[0]

            $Tweak = [pscustomobject]@{

                Id = "Test.Tweak"

                Name = "Test Tweak"

                Description = "Description"

                CategoryId = $Category.Id

                Enabled = $false

                Default = $true

                Actions = @()

            }

            $DisabledItem = New-ConfigurationItem `
                -Tweak $Tweak `
                -Enabled $false

            $EnabledItem = New-ConfigurationItem `
                -Tweak $Tweak `
                -Enabled $true

            $DisabledItem.Enabled |
                Should -BeFalse

            $EnabledItem.Enabled |
                Should -BeTrue

        }

    }


    # ==================================================
    # Merge-Profile
    # ==================================================

    Context "Merge-Profile" {

        It "Fusionne les tweaks avec le profil" {

            $Categories = @(
                Get-CategoryDefinitions -Reload
            )

            $Category = $Categories[0]

            $TweakA = [pscustomobject]@{

                Id = "Test.TweakA"

                Name = "Tweak A"

                Description = "A"

                CategoryId = $Category.Id

                Default = $false

                Enabled = $false

                Actions = @()

            }

            $TweakB = [pscustomobject]@{

                Id = "Test.TweakB"

                Name = "Tweak B"

                Description = "B"

                CategoryId = $Category.Id

                Default = $true

                Enabled = $false

                Actions = @()

            }

            $Profile = [pscustomobject]@{

                Tweaks = [pscustomobject]@{

                    "Test.TweakA" = $true

                }

            }

            $Configuration = Merge-Profile `
                -Context $script:Context `
                -Tweaks @(
                    $TweakA
                    $TweakB
                ) `
                -Profile $Profile

            $Configuration |
                Should -Not -BeNullOrEmpty

            $Configuration.Count |
                Should -Be 2

            ($Configuration |
                Where-Object Id -eq "Test.TweakA").Enabled |
                Should -BeTrue

            ($Configuration |
                Where-Object Id -eq "Test.TweakB").Enabled |
                Should -BeTrue

        }


        It "Utilise Default lorsqu'aucune valeur de profil n'existe" {

            $Categories = @(
                Get-CategoryDefinitions -Reload
            )

            $Category = $Categories[0]

            $Tweak = [pscustomobject]@{

                Id = "Test.Tweak"

                Name = "Test Tweak"

                Description = "Description"

                CategoryId = $Category.Id

                Default = $true

                Enabled = $false

                Actions = @()

            }

            $Profile = [pscustomobject]@{}

            $Configuration = Merge-Profile `
                -Context $script:Context `
                -Tweaks @($Tweak) `
                -Profile $Profile

            $Configuration.Count |
                Should -Be 1

            $Configuration[0].Enabled |
                Should -BeTrue

        }


        It "Positionne ProfileMerged à True" {

            $Categories = @(
                Get-CategoryDefinitions -Reload
            )

            $Category = $Categories[0]

            $Tweak = [pscustomobject]@{

                Id = "Test.Tweak"

                Name = "Test Tweak"

                Description = "Description"

                CategoryId = $Category.Id

                Default = $false

                Enabled = $false

                Actions = @()

            }

            $Profile = [pscustomobject]@{}

            $null = Merge-Profile `
                -Context $script:Context `
                -Tweaks @($Tweak) `
                -Profile $Profile

            $script:Context.BuildState.Image.ProfileMerged |
                Should -BeTrue

        }


        It "Stocke la configuration fusionnée dans le contexte" {

            $Categories = @(
                Get-CategoryDefinitions -Reload
            )

            $Category = $Categories[0]

            $Tweak = [pscustomobject]@{

                Id = "Test.Tweak"

                Name = "Test Tweak"

                Description = "Description"

                CategoryId = $Category.Id

                Default = $false

                Enabled = $false

                Actions = @()

            }

            $Profile = [pscustomobject]@{}

            $Configuration = Merge-Profile `
                -Context $script:Context `
                -Tweaks @($Tweak) `
                -Profile $Profile

            $script:Context.Configuration |
                Should -Be $Configuration

        }

        It "Expose une configuration plate contenant Enabled" {

            $Categories = @(
                Get-CategoryDefinitions -Reload
            )

            $Tweak = [pscustomobject]@{
                Id = "Test.Tweak"
                Name = "Test Tweak"
                Description = "Description"
                CategoryId = $Categories[0].Id
                Default = $true
                Enabled = $false
                Actions = @()
            }

            $Configuration = Merge-Profile `
                -Context $script:Context `
                -Tweaks @($Tweak) `
                -Profile ([pscustomobject]@{})

            @($Configuration).Count |
                Should -Be 1

            $Configuration[0].Id |
                Should -Be "Test.Tweak"

            $Configuration[0].Enabled |
                Should -BeTrue

            $script:Context.Configuration[0].Enabled |
                Should -BeTrue

        }

    }

}