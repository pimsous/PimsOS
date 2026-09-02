# ==========================================
# Tests : BuildPipeline
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..").Path

    # --------------------------------------------------
    # Infrastructure
    # --------------------------------------------------

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"

    # --------------------------------------------------
    # Core
    # --------------------------------------------------

	    . "$ProjectRoot\Modules\Core\Core.ps1"
    . "$ProjectRoot\Modules\Core\Workflow.ps1"

    # --------------------------------------------------
    # Configuration
    # --------------------------------------------------

    . "$ProjectRoot\Modules\Configuration\Configuration.ps1"

    # --------------------------------------------------
    # Image / DISM
    # --------------------------------------------------

    . "$ProjectRoot\Modules\Image\Dism.ps1"

    # --------------------------------------------------
    # Registry
    # --------------------------------------------------

    . "$ProjectRoot\Modules\Windows\Registry.ps1"

    # --------------------------------------------------
    # Actions
    # --------------------------------------------------

    . "$ProjectRoot\Modules\Actions\DriverEngine.ps1"
	. "$ProjectRoot\Modules\PostInstall\FirstBoot.ps1"
	. "$ProjectRoot\Modules\PostInstall\Unattend.ps1"
	. "$ProjectRoot\Modules\PostInstall\Installer.ps1"

    # --------------------------------------------------
    # Pipeline
    # --------------------------------------------------

    . "$ProjectRoot\Modules\Core\Pipeline.ps1"

}

Describe "BuildPipeline" {

    BeforeEach {

        Reset-Logger

        Mock Write-Log {}

        # ==========================================
        # Contexte minimal
        # ==========================================

        $script:Context = [pscustomobject]@{

            Project = [pscustomobject]@{

				Root = "C:\Projets\PimsOS"

                Config = [pscustomobject]@{

                    Drivers = [pscustomobject]@{

                        Source        = "None"
                        Path          = $null
                        Recurse       = $true
                        ForceUnsigned = $false

                    }

                }

            }

            Workspace = [pscustomobject]@{

                Cache = Join-Path $TestDrive "Cache"
                PackagesChocolatey = Join-Path $TestDrive "Cache\Chocolatey"

            }

            Drivers = [System.Collections.Generic.List[object]]::new()

            Configuration = @()

            Registry = [pscustomobject]@{

                Mounted = @()

            }

            BuildState = [pscustomobject]@{

                Status = "Idle"

                Success   = $false
                Completed = $false

                Image = [pscustomobject]@{

                    MountPath = $null
                    Mounted = $false
                    WimMounted = $false
                    IsoMounted = $false
                    RegistryLoaded = $false
                    CurrentRegistryHive = $null
                    Index = $null

                }

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

        # ==========================================
        # Mocks Drivers
        # ==========================================

        Mock Get-DriverConfiguration {

            return [PSCustomObject]@{

                Source        = "None"
                Path          = $null
                Recurse       = $true
                ForceUnsigned = $false

            }

        }

        Mock Invoke-DriverAction {

            param(
                [psobject]$Context,
                [psobject]$Action
            )

            return $Context

        }

    }

    # ==================================================
    # Invoke-BuildStep
    # ==================================================

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

            } |
                Should -Throw

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

    # ==================================================
    # Invoke-BuildPipeline
    # ==================================================

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

    # ==================================================
	# Get-BuildPipeline
	# ==================================================

	Context "Get-BuildPipeline" {

        It "Contient les étapes principales du pipeline" {

            $Pipeline = @(Get-BuildPipeline)
            $Ids = @($Pipeline | ForEach-Object { $_.Id })

            foreach ($RequiredId in @(
                "MountIso",
                "CopyIsoContent",
                "DetectWim",
                "CopyWim",
                "ReadWimImages",
                "SelectImage",
                "MountWim",
                "ApplyDrivers",
                "PreparePostInstall",
                "LoadConfiguration",
                "MountConfigurationRegistryHives",
                "ApplyConfiguration",
                "DismountConfigurationRegistryHives",
                "ValidatePostInstallDeployment",
                "DismountWim",
                "SyncWimToIsoSource",
                "DismountIso",
                "NewPimsOSIso"
            )) {

                $Ids | Should -Contain $RequiredId

            }

            $Ids | Should -Not -Contain "DismountSoftwareHive"

        }

        It "Place l'application des drivers après le montage du WIM" {

            $Pipeline = @(Get-BuildPipeline)
            $Ids = @($Pipeline | ForEach-Object { $_.Id })

            $MountIndex = [Array]::IndexOf($Ids, "MountWim")
            $DriverIndex = [Array]::IndexOf($Ids, "ApplyDrivers")

            $MountIndex | Should -BeGreaterOrEqual 0
            $DriverIndex | Should -BeGreaterOrEqual 0
            $DriverIndex | Should -BeGreaterThan $MountIndex

        }

        It "Place la préparation du PostInstall après les drivers" {

            $Pipeline = @(Get-BuildPipeline)
            $Ids = @($Pipeline | ForEach-Object { $_.Id })

            $DriverIndex = [Array]::IndexOf($Ids, "ApplyDrivers")
            $PostInstallIndex = [Array]::IndexOf($Ids, "PreparePostInstall")

            $DriverIndex | Should -BeGreaterOrEqual 0
            $PostInstallIndex | Should -BeGreaterOrEqual 0
            $PostInstallIndex | Should -BeGreaterThan $DriverIndex

        }

		It "Place la préparation du PostInstall après les drivers et avant le montage des ruches de configuration" {

			$Pipeline = @(Get-BuildPipeline)

			$Names = @(
				$Pipeline |
					ForEach-Object {
						$_.Name
					}
			)

			$DriverIndex = [Array]::IndexOf(
				$Names,
				"Application des drivers"
			)

			$PostInstallIndex = [Array]::IndexOf(
				$Names,
				"Préparation du PostInstall"
			)

			$HiveIndex = [Array]::IndexOf(
				$Names,
				"Montage des ruches de registre"
			)

			$DriverIndex |
				Should -BeGreaterOrEqual 0

			$PostInstallIndex |
				Should -BeGreaterOrEqual 0

			$HiveIndex |
				Should -BeGreaterOrEqual 0

			$PostInstallIndex |
				Should -BeGreaterThan $DriverIndex

			$PostInstallIndex |
				Should -BeLessThan $HiveIndex

		}
        It "Place SyncWimToIsoSource entre DismountWim et DismountIso" {

            $Pipeline = @(Get-BuildPipeline)

			$Ids = @(
				$Pipeline | ForEach-Object { $_.Id }
			)

            $IndexDismountWim =
                [Array]::IndexOf(
                    $Ids,
                    "DismountWim"
                )

            $IndexSync =
                [Array]::IndexOf(
                    $Ids,
                    "SyncWimToIsoSource"
                )

            $IndexDismountIso =
                [Array]::IndexOf(
                    $Ids,
                    "DismountIso"
                )

            $IndexDismountWim |
                Should -BeGreaterOrEqual 0

            $IndexSync |
                Should -BeGreaterOrEqual 0

            $IndexDismountIso |
                Should -BeGreaterOrEqual 0

            $IndexSync |
                Should -BeGreaterThan $IndexDismountWim

            $IndexSync |
                Should -BeLessThan $IndexDismountIso
        }


        It "Place NewPimsOSIso après SyncWimToIsoSource et DismountIso" {

            $Pipeline = @(Get-BuildPipeline)

			$Ids = @(
				$Pipeline | ForEach-Object { $_.Id }
			)

            $IndexSync =
                [Array]::IndexOf(
                    $Ids,
                    "SyncWimToIsoSource"
                )

            $IndexDismountIso =
                [Array]::IndexOf(
                    $Ids,
                    "DismountIso"
                )

            $IndexNewIso =
                [Array]::IndexOf(
                    $Ids,
                    "NewPimsOSIso"
                )

            $IndexSync |
                Should -BeGreaterOrEqual 0

            $IndexDismountIso |
                Should -BeGreaterOrEqual 0

            $IndexNewIso |
                Should -BeGreaterOrEqual 0

            $IndexNewIso |
                Should -BeGreaterThan $IndexSync

            $IndexNewIso |
                Should -BeGreaterThan $IndexDismountIso
        }


        It "Place les étapes finales du pipeline dans le bon ordre" {

            $Pipeline = @(Get-BuildPipeline)

			$Ids = @(
				$Pipeline | ForEach-Object { $_.Id }
			)

            $ExpectedOrder = @(
                "DismountWim"
                "SyncWimToIsoSource"
                "DismountIso"
                "NewPimsOSIso"
            )

            $ActualOrder = @(
                $ExpectedOrder |
                    ForEach-Object {
                        [PSCustomObject]@{
                            Id = $_
                            Index = [Array]::IndexOf(
                                $Ids,
                                $_
                            )
                        }
                    }
            )

            foreach ($Item in $ActualOrder) {

                $Item.Index |
                    Should -BeGreaterOrEqual 0

            }

            $ActualOrder[0].Index |
                Should -BeLessThan $ActualOrder[1].Index

            $ActualOrder[1].Index |
                Should -BeLessThan $ActualOrder[2].Index

            $ActualOrder[2].Index |
                Should -BeLessThan $ActualOrder[3].Index
        }

		It "Synchronise le WIM de travail vers la source ISO et vérifie le SHA256" {

            $Pipeline = @(Get-BuildPipeline)

            $Step = $Pipeline |
                Where-Object {
                    $_.Id -eq "SyncWimToIsoSource"
                }

            $Step |
                Should -Not -BeNullOrEmpty

            $TestRoot = Join-Path `
                -Path $TestDrive `
                -ChildPath "SyncWim"

            $Sources = Join-Path `
                -Path $TestRoot `
                -ChildPath "Sources"

            $IsoSources = Join-Path `
                -Path $TestRoot `
                -ChildPath "ISOSource\sources"

            New-Item `
                -ItemType Directory `
                -Path $Sources `
                -Force |
                Out-Null

            New-Item `
                -ItemType Directory `
                -Path $IsoSources `
                -Force |
                Out-Null

            $WimName = "install.wim"

            $SourceWim = Join-Path `
                -Path $Sources `
                -ChildPath $WimName

            $IsoWim = Join-Path `
                -Path $IsoSources `
                -ChildPath $WimName

            [System.IO.File]::WriteAllText(
                $SourceWim,
                "PimsOS Sync Test"
            )

            Mock Get-ProjectRoot {
                return $TestRoot
            }

            Mock Get-Config {

                return [PSCustomObject]@{
                    Workspace = [PSCustomObject]@{
                        Sources = "Sources"
                        ISOSource = "ISOSource"
                    }
                }

            }

            Mock Write-Log {
            }

            $Context = [PSCustomObject]@{
                WIM = [PSCustomObject]@{
                    Name = $WimName
                }
            }

            $Result = & $Step.Action $Context

            Test-Path `
                -LiteralPath $IsoWim `
                -PathType Leaf |
                Should -BeTrue

            $SourceHash = (
                Get-FileHash `
                    -LiteralPath $SourceWim `
                    -Algorithm SHA256
            ).Hash

            $IsoHash = (
                Get-FileHash `
                    -LiteralPath $IsoWim `
                    -Algorithm SHA256
            ).Hash

            $IsoHash |
                Should -Be $SourceHash

            $Result |
                Should -Not -BeNullOrEmpty
        }
	}

    # ==================================================
    # Apply-Drivers
    # ==================================================
 {

        It "Ne fait rien lorsque la source est None" {

            $Result = Apply-Drivers `
                -Context $script:Context

            $Result |
                Should -Be $script:Context

            Should -Invoke `
                -CommandName Invoke-DriverAction `
                -Times 0 `
                -Exactly

        }

        It "Applique les drivers depuis un dossier" {

            $DriverPath = Join-Path `
                $TestDrive `
                "Drivers"

            New-Item `
                -ItemType Directory `
                -Path $DriverPath `
                -Force |
                Out-Null

            Mock Get-DriverConfiguration {

                return [PSCustomObject]@{

                    Source        = "Folder"
                    Path          = $DriverPath
                    Recurse       = $true
                    ForceUnsigned = $false

                }

            }

            Mock Invoke-DriverAction {

                param(
                    [psobject]$Context,
                    [psobject]$Action
                )

                return $Context

            }

            $Result = Apply-Drivers `
                -Context $script:Context

            $Result |
                Should -Be $script:Context

            Should -Invoke `
                -CommandName Invoke-DriverAction `
                -Times 1 `
                -Exactly

        }

        It "Construit une action Driver DISM pour un dossier" {

            $DriverPath = Join-Path `
                $TestDrive `
                "Drivers"

            New-Item `
                -ItemType Directory `
                -Path $DriverPath `
                -Force |
                Out-Null

            Mock Get-DriverConfiguration {

                return [PSCustomObject]@{

                    Source        = "Folder"
                    Path          = $DriverPath
                    Recurse       = $true
                    ForceUnsigned = $false

                }

            }

            Mock Invoke-DriverAction {

                param(
                    [psobject]$Context,
                    [psobject]$Action
                )

                $script:ReceivedDriverAction = $Action

                return $Context

            }

            $script:ReceivedDriverAction = $null

            $null = Apply-Drivers `
                -Context $script:Context

            $script:ReceivedDriverAction |
                Should -Not -BeNullOrEmpty

            $script:ReceivedDriverAction.Id |
                Should -Be "Drivers.Folder"

            $script:ReceivedDriverAction.Type |
                Should -Be "Driver"

            $script:ReceivedDriverAction.Name |
                Should -Be "Drivers"

            $script:ReceivedDriverAction.Provider |
                Should -Be "DISM"

            $script:ReceivedDriverAction.Source |
                Should -Be $DriverPath

            $script:ReceivedDriverAction.Recurse |
                Should -BeTrue

            $script:ReceivedDriverAction.ForceUnsigned |
                Should -BeFalse

            $script:ReceivedDriverAction.Enabled |
                Should -BeTrue

            $script:ReceivedDriverAction.ContinueOnError |
                Should -BeFalse

        }

        It "Enregistre l'action Driver dans le contexte" {

            $DriverPath = Join-Path `
                $TestDrive `
                "Drivers"

            New-Item `
                -ItemType Directory `
                -Path $DriverPath `
                -Force |
                Out-Null

            Mock Get-DriverConfiguration {

                return [PSCustomObject]@{

                    Source        = "Folder"
                    Path          = $DriverPath
                    Recurse       = $true
                    ForceUnsigned = $false

                }

            }

            Mock Invoke-DriverAction {

                param(
                    [psobject]$Context,
                    [psobject]$Action
                )

                return $Context

            }

            $null = Apply-Drivers `
                -Context $script:Context

            $script:Context.Drivers.Count |
                Should -Be 1

            $script:Context.Drivers[0].Id |
                Should -Be "Drivers.Folder"

        }

        It "Transmet Recurse et ForceUnsigned à l'action" {

            $DriverPath = Join-Path `
                $TestDrive `
                "Drivers"

            New-Item `
                -ItemType Directory `
                -Path $DriverPath `
                -Force |
                Out-Null

            Mock Get-DriverConfiguration {

                return [PSCustomObject]@{

                    Source        = "Folder"
                    Path          = $DriverPath
                    Recurse       = $false
                    ForceUnsigned = $true

                }

            }

            Mock Invoke-DriverAction {

                param(
                    [psobject]$Context,
                    [psobject]$Action
                )

                $script:ReceivedDriverAction = $Action

                return $Context

            }

            $script:ReceivedDriverAction = $null

            $null = Apply-Drivers `
                -Context $script:Context

            $script:ReceivedDriverAction.Recurse |
                Should -BeFalse

            $script:ReceivedDriverAction.ForceUnsigned |
                Should -BeTrue

        }

         It "Exporte les drivers du système actuel" {

            $WorkspaceDrivers = Join-Path `
                $TestDrive `
                "Workspace\Drivers"

            $ExpectedDestination = Join-Path `
                $WorkspaceDrivers `
                "CurrentSystem"

            Mock Get-DriverConfiguration {

                return [PSCustomObject]@{

                    Source        = "CurrentSystem"
                    Path          = $null
                    Recurse       = $true
                    ForceUnsigned = $false

                }

            }

            Mock Get-Config {

                return [PSCustomObject]@{

                    Workspace = [PSCustomObject]@{

                        Drivers = "Workspace\Drivers"

                    }

                }

            }

            Mock Get-ProjectRoot {

                return $TestDrive

            }

            Mock Export-DismCurrentSystemDrivers {}

            Mock Invoke-DriverAction {

                param(
                    [psobject]$Context,
                    [psobject]$Action
                )

                return $Context

            }

            $Result = Apply-Drivers `
                -Context $script:Context

            $Result |
                Should -Be $script:Context

            Should -Invoke `
                -CommandName Export-DismCurrentSystemDrivers `
                -Times 1 `
                -Exactly `
                -ParameterFilter {

                    $DestinationPath -eq $ExpectedDestination

                }

        }

        It "Construit une action Driver DISM pour CurrentSystem" {

            $WorkspaceDrivers = Join-Path `
                $TestDrive `
                "Workspace\Drivers"

            $ExpectedSource = Join-Path `
                $WorkspaceDrivers `
                "CurrentSystem"

            Mock Get-DriverConfiguration {

                return [PSCustomObject]@{

                    Source        = "CurrentSystem"
                    Path          = $null
                    Recurse       = $false
                    ForceUnsigned = $true

                }

            }

            Mock Get-Config {

                return [PSCustomObject]@{

                    Workspace = [PSCustomObject]@{

                        Drivers = "Workspace\Drivers"

                    }

                }

            }

            Mock Get-ProjectRoot {

                return $TestDrive

            }

            Mock Export-DismCurrentSystemDrivers {}

            Mock Invoke-DriverAction {

                param(
                    [psobject]$Context,
                    [psobject]$Action
                )

                $script:ReceivedDriverAction = $Action

                return $Context

            }

            $script:ReceivedDriverAction = $null

            $null = Apply-Drivers `
                -Context $script:Context

            $script:ReceivedDriverAction |
                Should -Not -BeNullOrEmpty

            $script:ReceivedDriverAction.Id |
                Should -Be "Drivers.CurrentSystem"

            $script:ReceivedDriverAction.Type |
                Should -Be "Driver"

            $script:ReceivedDriverAction.Name |
                Should -Be "CurrentSystemDrivers"

            $script:ReceivedDriverAction.Provider |
                Should -Be "DISM"

            $script:ReceivedDriverAction.Source |
                Should -Be $ExpectedSource

            $script:ReceivedDriverAction.Recurse |
                Should -BeFalse

            $script:ReceivedDriverAction.ForceUnsigned |
                Should -BeTrue
			
			$script:Context.Drivers.Count |
                Should -Be 1

            $script:Context.Drivers[0].Id |
                Should -Be "Drivers.CurrentSystem"

            Should -Invoke `
                -CommandName Invoke-DriverAction `
                -Times 1 `
                -Exactly `
                -ParameterFilter {
                    $Action.Id -eq "Drivers.CurrentSystem" -and
                    $Action.Provider -eq "DISM" -and
                    $Action.Source -eq $ExpectedSource
                }
        }

    }
	# ==================================================
    # Prepare-PostInstall
    # ==================================================

    Context "Prepare-PostInstall" {

        It "Prépare le runtime PostInstall dans le WIM" {

            $script:Context.BuildState.Image = [pscustomobject]@{

                MountPath = Join-Path `
                    $TestDrive `
                    "Mount"

            }

            Mock Get-PostInstallRuntimePath {

                return (
                    Join-Path `
                        $TestDrive `
                        "Runtime"
                )

            }

            Mock Install-PimsOSPostInstallRuntime {

                return [pscustomobject]@{

                    DestinationPath =
                        "C:\ProgramData\PimsOS\PostInstall"

                }

            }

            Mock Install-PimsOSFirstBoot {

                return [pscustomobject]@{

                    UnattendPath =
                        "C:\Windows\Panther\unattend.xml"

                }

            }

            $Result =
                Prepare-PostInstall `
                    -Context $script:Context

            $Result |
                Should -Be $script:Context

            Should -Invoke `
                -CommandName Install-PimsOSPostInstallRuntime `
                -Times 1 `
                -Exactly

            Should -Invoke `
                -CommandName Install-PimsOSFirstBoot `
                -Times 1 `
                -Exactly

        }

        It "Utilise le runtime PostInstall du projet" {

            $script:Context.BuildState.Image = [pscustomobject]@{

                MountPath = Join-Path `
                    $TestDrive `
                    "Mount"

            }

            Mock Get-PostInstallRuntimePath {

                return (
                    Join-Path `
                        $TestDrive `
                        "Runtime"
                )

            }

            Mock Install-PimsOSPostInstallRuntime {

                param(
                    [string]$MountPath,
                    [string]$SourcePath
                )

                $script:ReceivedSourcePath =
                    $SourcePath

                return [pscustomobject]@{

                    DestinationPath =
                        "C:\ProgramData\PimsOS\PostInstall"

                }

            }

            Mock Install-PimsOSFirstBoot {

                return [pscustomobject]@{

                    UnattendPath =
                        "C:\Windows\Panther\unattend.xml"

                }

            }

            $script:ReceivedSourcePath = $null

            Prepare-PostInstall `
                -Context $script:Context |
                Out-Null

            $script:ReceivedSourcePath |
                Should -Be (
                    Join-Path `
                        $TestDrive `
                        "Runtime"
                )

        }

        It "Utilise le Bootstrap installé dans ProgramData" {

            $script:Context.BuildState.Image = [pscustomobject]@{

                MountPath = Join-Path `
                    $TestDrive `
                    "Mount"

            }

            Mock Get-PostInstallRuntimePath {

                return (
                    Join-Path `
                        $TestDrive `
                        "Runtime"
                )

            }

            Mock Install-PimsOSPostInstallRuntime {

                return [pscustomobject]@{

                    DestinationPath =
                        "C:\ProgramData\PimsOS\PostInstall"

                }

            }

            Mock Install-PimsOSFirstBoot {

                param(
                    [string]$MountPath,
                    [string]$BootstrapPath
                )

                $script:ReceivedBootstrapPath =
                    $BootstrapPath

                return [pscustomobject]@{

                    UnattendPath =
                        "C:\Windows\Panther\unattend.xml"

                }

            }

            $script:ReceivedBootstrapPath = $null

            Prepare-PostInstall `
                -Context $script:Context |
                Out-Null

            $script:ReceivedBootstrapPath |
                Should -Be (
                    "C:\ProgramData\PimsOS\PostInstall\Bootstrap.ps1"
                )

        }

        It "Crée le runtime et unattend.xml dans le WIM" {

            $script:Context.BuildState.Image =
                [pscustomobject]@{
                    MountPath = $TestDrive
                }

            Mock Get-PostInstallRuntimePath {
                return (Join-Path $TestDrive "Runtime")
            }

            $RuntimePath = Join-Path $TestDrive "Runtime"

            New-Item `
                -ItemType Directory `
                -Path $RuntimePath `
                -Force |
                Out-Null

            foreach ($FileName in @(
                "Bootstrap.ps1"
                "Logger.ps1"
                "Network.ps1"
                "UI.ps1"
                "DriverCheck.ps1"
                "PostInstall.ps1"
                "State.ps1"
            )) {

                New-Item `
                    -ItemType File `
                    -Path (
                        Join-Path `
                            $RuntimePath `
                            $FileName
                    ) `
                    -Force |
                    Out-Null

            }

            Mock Install-PimsOSPostInstallRuntime {

                return [pscustomobject]@{
                    Installed = $true
                }

            }

            Mock Install-PimsOSFirstBoot {

                param(
                    [string]$MountPath,
                    [string]$BootstrapPath
                )

                $UnattendPath = Join-Path `
                    $MountPath `
                    "Windows\Panther\unattend.xml"

                New-Item `
                    -ItemType Directory `
                    -Path (
                        Split-Path $UnattendPath -Parent
                    ) `
                    -Force |
                    Out-Null

                New-Item `
                    -ItemType File `
                    -Path $UnattendPath `
                    -Force |
                    Out-Null

                return [pscustomobject]@{
                    UnattendPath = $UnattendPath
                }

            }

            $Result = Prepare-PostInstall `
                -Context $script:Context

            $RuntimePathInImage = Join-Path `
                $TestDrive `
                "ProgramData\PimsOS\PostInstall"

            $UnattendPathInImage = Join-Path `
                $TestDrive `
                "Windows\Panther\unattend.xml"

            Should -Invoke `
                -CommandName Install-PimsOSPostInstallRuntime `
                -Times 1 `
                -Exactly

            Should -Invoke `
                -CommandName Install-PimsOSFirstBoot `
                -Times 1 `
                -Exactly

            Test-Path `
                -LiteralPath $UnattendPathInImage `
                -PathType Leaf |
                Should -BeTrue

        }
        It "Refuse un contexte sans montage WIM" {

            $script:Context.BuildState.Image = [pscustomobject]@{

                MountPath = $null

            }

            {

                Prepare-PostInstall `
                    -Context $script:Context

            } |
                Should -Throw "*chemin de montage WIM est absent*"

        }

    }
}
