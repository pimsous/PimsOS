# ==========================================
# Tests : BuildContext
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    # --------------------------------------------------
    # Chargement des dépendances
    # --------------------------------------------------

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"
    . "$ProjectRoot\Modules\Core\BuildContext.ps1"

}

Describe "BuildContext" {

    # ==================================================
    # New-BuildState
    # ==================================================

    Context "New-BuildState" {

        It "Retourne un objet BuildState" {

            $State = New-BuildState

            $State |
                Should -Not -BeNullOrEmpty
        }

        It "Initialise Initialized à False" {

            (New-BuildState).Initialized |
                Should -BeFalse
        }

        It "Initialise Status à NotStarted" {

            (New-BuildState).Status |
                Should -Be "NotStarted"
        }

        It "Initialise Success à False" {

            (New-BuildState).Success |
                Should -BeFalse
        }

        It "Initialise Completed à False" {

            (New-BuildState).Completed |
                Should -BeFalse
        }

        It "Initialise l'état Environment" {

            $State = New-BuildState

            $State.Environment |
                Should -Not -BeNullOrEmpty

            $State.Environment.Checked |
                Should -BeFalse
        }

        It "Initialise l'état Pipeline" {

            $State = New-BuildState

            $State.Pipeline |
                Should -Not -BeNullOrEmpty

            $State.Pipeline.Started |
                Should -BeFalse
        }

        It "Initialise l'état Image" {

            $State = New-BuildState

            $State.Image |
                Should -Not -BeNullOrEmpty

            $State.Image.IsoMounted |
                Should -BeFalse

            $State.Image.WimMounted |
                Should -BeFalse
        }

        It "Initialise Recovery" {

            $State = New-BuildState

            $State.Recovery |
                Should -Not -BeNullOrEmpty

            $State.Recovery.Completed |
                Should -BeFalse
        }

    }

    # ==================================================
    # New-BuildContext
    # ==================================================

    Context "New-BuildContext" {

        It "Retourne un contexte non null" {

            $Context = New-BuildContext

            $Context |
                Should -Not -BeNullOrEmpty
        }

        It "Crée un identifiant de Build" {

            $Context = New-BuildContext

            $Context.Build.Id |
                Should -Not -BeNullOrEmpty
        }

        It "Crée un GUID valide pour le Build" {

            $Context = New-BuildContext

            $Guid = [guid]::Empty

            [guid]::TryParse(
                $Context.Build.Id,
                [ref]$Guid
            ) |
                Should -BeTrue
        }

        It "Active CreateISO par défaut" {

            (New-BuildContext).Build.CreateISO |
                Should -BeTrue
        }

        It "Active CreateReport par défaut" {

            (New-BuildContext).Build.CreateReport |
                Should -BeTrue
        }

        It "Désactive DryRun par défaut" {

            (New-BuildContext).Build.DryRun |
                Should -BeFalse
        }

        It "Active Interactive par défaut" {

            (New-BuildContext).Build.Interactive |
                Should -BeTrue
        }

        It "Crée la section WIM" {

            $Context = New-BuildContext

            $Context.WIM |
                Should -Not -BeNullOrEmpty

            # Vérifie que la propriété existe réellement.
            $Context.WIM.PSObject.Properties.Name |
                Should -Contain "Images"

            # Vérifie que Images est bien une collection générique.
            $Context.WIM.Images.GetType().IsGenericType |
                Should -BeTrue

            # La collection doit être vide au démarrage.
            $Context.WIM.Images.Count |
                Should -Be 0
        }

        It "Initialise la configuration à null" {

            (New-BuildContext).Configuration |
                Should -BeNullOrEmpty
        }

        It "Initialise le profil de configuration à null" {

            (New-BuildContext).ConfigurationProfile |
                Should -BeNullOrEmpty
        }

        It "Initialise le registre" {

            $Context = New-BuildContext

            $Context.Registry |
                Should -Not -BeNullOrEmpty

            # Vérifie que Mounted existe.
            $Context.Registry.PSObject.Properties.Name |
                Should -Contain "Mounted"

            # Vérifie que Mounted est bien une collection générique.
            $Context.Registry.Mounted.GetType().IsGenericType |
                Should -BeTrue

            # La collection doit être vide au démarrage.
            $Context.Registry.Mounted.Count |
                Should -Be 0
        }

        It "Initialise les collections de contenu" {

            $Context = New-BuildContext

            # Vérifie l'existence des propriétés.
            $Context.PSObject.Properties.Name |
                Should -Contain "Packages"

            $Context.PSObject.Properties.Name |
                Should -Contain "Drivers"

            $Context.PSObject.Properties.Name |
                Should -Contain "Tweaks"

            $Context.PSObject.Properties.Name |
                Should -Contain "Services"

            $Context.PSObject.Properties.Name |
                Should -Contain "Features"

            # Vérifie que chaque propriété est une collection générique.
            $Context.Packages.GetType().IsGenericType |
                Should -BeTrue

            $Context.Drivers.GetType().IsGenericType |
                Should -BeTrue

            $Context.Tweaks.GetType().IsGenericType |
                Should -BeTrue

            $Context.Services.GetType().IsGenericType |
                Should -BeTrue

            $Context.Features.GetType().IsGenericType |
                Should -BeTrue

            # Toutes les collections doivent être vides au démarrage.
            $Context.Packages.Count |
                Should -Be 0

            $Context.Drivers.Count |
                Should -Be 0

            $Context.Tweaks.Count |
                Should -Be 0

            $Context.Services.Count |
                Should -Be 0

            $Context.Features.Count |
                Should -Be 0
        }

        It "Initialise le rapport" {

            $Context = New-BuildContext

            $Context.Report |
                Should -Not -BeNullOrEmpty

            # Vérifie l'existence des collections.
            $Context.Report.PSObject.Properties.Name |
                Should -Contain "Phases"

            $Context.Report.PSObject.Properties.Name |
                Should -Contain "Warnings"

            $Context.Report.PSObject.Properties.Name |
                Should -Contain "Errors"

            # Vérifie que les propriétés sont bien des collections génériques.
            $Context.Report.Phases.GetType().IsGenericType |
                Should -BeTrue

            $Context.Report.Warnings.GetType().IsGenericType |
                Should -BeTrue

            $Context.Report.Errors.GetType().IsGenericType |
                Should -BeTrue

            # Les collections doivent être vides au démarrage.
            $Context.Report.Phases.Count |
                Should -Be 0

            $Context.Report.Warnings.Count |
                Should -Be 0

            $Context.Report.Errors.Count |
                Should -Be 0
        }

        It "Initialise le logger" {

            $Context = New-BuildContext

            $Context.Logger |
                Should -Not -BeNullOrEmpty

            $Context.Logger.Enabled |
                Should -BeTrue

            $Context.Logger.Started |
                Should -BeFalse
        }

        It "Initialise les statistiques" {

            $Context = New-BuildContext

            $Context.Statistics |
                Should -Not -BeNullOrEmpty

            $Context.Statistics.ActionsProcessed |
                Should -Be 0

            $Context.Statistics.PackagesProcessed |
                Should -Be 0

            $Context.Statistics.Errors |
                Should -Be 0

            $Context.Statistics.Warnings |
                Should -Be 0
        }

        It "Crée une date de début" {

            $Context = New-BuildContext

            $Context.Project.StartTime |
                Should -Not -BeNullOrEmpty

            $Context.Project.StartTime |
                Should -BeOfType DateTime
        }

    }

    # ==================================================
    # Initialize-BuildContext
    # ==================================================

    Context "Initialize-BuildContext" {

        BeforeEach {

            # --------------------------------------------------
            # Contexte de test
            # --------------------------------------------------

            $script:Context = New-BuildContext

            # --------------------------------------------------
            # Mocks des dépendances
            # --------------------------------------------------

            function global:Get-ProjectRoot {

                return "C:\Projets\PimsOS"
            }

            function global:Get-Config {

                return [pscustomobject]@{

                    Requirements = [pscustomobject]@{

                        PowerShellMajor = 5

                        MinimumFreeSpaceGB = 0

                    }

                    DefaultProfile = "Tests\Registry"
                }
            }

            function global:Get-ProjectVersion {

                return [pscustomobject]@{

                    Project = "PimsOS Builder"

                    Version = "2.0.0"

                    Windows = [pscustomobject]@{

                        Release = "11 25H2"

                        Build = "26100"

                    }

                    Author = "Pims"

                    Company = "PimsOS"

                    Repository = "PimsOS"

                    BuildDate = "2026-08-16"
                }
            }

            function global:Get-ObjectProperty {

                param(

                    [Parameter(Mandatory)]
                    [object]$Object,

                    [Parameter(Mandatory)]
                    [string]$Name,

                    [object]$Default = $null
                )

                if ($null -eq $Object) {

                    return $Default
                }

                $Property = $Object.PSObject.Properties[$Name]

                if ($null -ne $Property) {

                    return $Property.Value
                }

                return $Default
            }

            function global:Get-ProjectPath {

                param(

                    [Parameter(Mandatory)]
                    [string]$PathName
                )

                return "C:\Projets\PimsOS\$PathName"
            }

        }

        It "Initialise le contexte" {

            $Context = Initialize-BuildContext `
                -Context $script:Context

            $Context |
                Should -Not -BeNullOrEmpty
        }

        It "Définit la racine du projet" {

            $Context = Initialize-BuildContext `
                -Context $script:Context

            $Context.Project.Root |
                Should -Be "C:\Projets\PimsOS"
        }

        It "Charge la configuration" {

            $Context = Initialize-BuildContext `
                -Context $script:Context

            $Context.Configuration |
                Should -Not -BeNullOrEmpty

            $Context.Project.Config |
                Should -Not -BeNullOrEmpty
        }

        It "Définit le nom du projet" {

            $Context = Initialize-BuildContext `
                -Context $script:Context

            $Context.Project.Name |
                Should -Be "PimsOS Builder"
        }

        It "Définit la version du projet" {

            $Context = Initialize-BuildContext `
                -Context $script:Context

            $Context.Project.Version |
                Should -Be "2.0.0"
        }

        It "Définit les informations Windows" {

            $Context = Initialize-BuildContext `
                -Context $script:Context

            $Context.Project.Windows.Release |
                Should -Be "11 25H2"

            $Context.Project.Windows.Build |
                Should -Be "26100"
        }

        It "Définit les informations du projet" {

            $Context = Initialize-BuildContext `
                -Context $script:Context

            $Context.Project.Author |
                Should -Be "Pims"

            $Context.Project.Company |
                Should -Be "PimsOS"

            $Context.Project.Repository |
                Should -Be "PimsOS"

            $Context.Project.BuildDate |
                Should -Be "2026-08-16"
        }

        It "Définit le profil de configuration" {

            $Context = Initialize-BuildContext `
                -Context $script:Context

            $Context.ConfigurationProfile |
                Should -Be "Tests\Registry"
        }

        It "Définit les chemins du projet" {

            $Context = Initialize-BuildContext `
                -Context $script:Context

            $Context.Project.Paths.ISO |
                Should -Be "C:\Projets\PimsOS\ISO"

            $Context.Project.Paths.Logs |
                Should -Be "C:\Projets\PimsOS\Logs"

            $Context.Project.Paths.Output |
                Should -Be "C:\Projets\PimsOS\Output"

            $Context.Project.Paths.Mount |
                Should -Be "C:\Projets\PimsOS\Mount"

            $Context.Project.Paths.Temp |
                Should -Be "C:\Projets\PimsOS\Temp"
        }

        It "Configure le Workspace" {

            $Context = Initialize-BuildContext `
                -Context $script:Context

            $Context.Workspace.Root |
                Should -Be "C:\Projets\PimsOS"

            $Context.Workspace.ISO |
                Should -Be "C:\Projets\PimsOS\ISO"

            $Context.Workspace.Output |
                Should -Be "C:\Projets\PimsOS\Output"

            $Context.Workspace.Sources |
                Should -Be "C:\Projets\PimsOS\Workspace\Sources"

            $Context.Workspace.Temp |
                Should -Be "C:\Projets\PimsOS\Temp"

            $Context.Workspace.MountWIM |
                Should -Be "C:\Projets\PimsOS\Mount\WIM"

            $Context.Workspace.MountISO |
                Should -Be "C:\Projets\PimsOS\Mount\ISO"

            $Context.Workspace.Extract |
                Should -Be "C:\Projets\PimsOS\Temp\Extract"
        }

        It "Configure le chemin du log" {

            $Context = Initialize-BuildContext `
                -Context $script:Context

            $Context.Logger.Path |
                Should -Not -BeNullOrEmpty

            $Context.Logger.Path |
                Should -Match "C:\\Projets\\PimsOS\\Logs\\Build_.*\.log"
        }

        It "Passe l'état à Initialized" {

            $Context = Initialize-BuildContext `
                -Context $script:Context

            $Context.BuildState.Initialized |
                Should -BeTrue

            $Context.BuildState.Status |
                Should -Be "Initialized"
        }

    }

}