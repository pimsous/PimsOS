# ==========================================
# Module : BuildContext
# Projet : PimsOS Builder
# Version : 2.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest


# ==================================================
# Etat global du Build
# ==================================================

function New-BuildState {

    [CmdletBinding()]
    param()

    return [PSCustomObject]@{

        ObjectType = "BuildState"

        Initialized = $false

        Status = "NotStarted"


        # ==========================================
        # Recovery
        # ==========================================

        Recovery = [PSCustomObject]@{

            Completed = $false

            Wim = $null

            Iso = $null

            Registry = $null

        }


        # ==========================================
        # Environment
        # ==========================================

        Environment = [PSCustomObject]@{

            Checked = $false

            PowerShell = $false

            Administrator = $false

            Git = $false

            Dism = $false

            Iso = $false

			WindowsADK = $false

            DiskSpace = $false

        }


        # ==========================================
        # Pipeline
        # ==========================================

        Pipeline = [PSCustomObject]@{

            Started = $false

            Current = $null

            Completed = @()

            Failed = @()

        }


        # ==========================================
        # Image
        # ==========================================

        Image = [PSCustomObject]@{

            IsoMounted = $false

            WimMounted = $false

            RegistryLoaded = $false

            CurrentRegistryHive = $null

            ConfigLoaded = $false

            ProfileLoaded = $false

            ProfileMerged = $false

            TweaksLoaded = $false

            TweaksApplied = $false

        }


        # ==========================================
        # Etat final
        # ==========================================

        Success = $false

        Completed = $false

    }
}


# ==================================================
# Création du BuildContext
# ==================================================

function New-BuildContext {

    [CmdletBinding()]
    param()


    # --------------------------------------------------
    # Collections internes
    #
    # Utilisation de List[object] afin de disposer
    # d'objets mutables avec .Add() dans les managers.
    # --------------------------------------------------

    $WimImages = [System.Collections.Generic.List[object]]::new()

    $RegistryMounted = [System.Collections.Generic.List[object]]::new()

    $Packages = [System.Collections.Generic.List[object]]::new()

    $Drivers = [System.Collections.Generic.List[object]]::new()

    $Tweaks = [System.Collections.Generic.List[object]]::new()

    $Services = [System.Collections.Generic.List[object]]::new()

    $Features = [System.Collections.Generic.List[object]]::new()

    $ReportPhases = [System.Collections.Generic.List[object]]::new()

    $ReportWarnings = [System.Collections.Generic.List[object]]::new()

    $ReportErrors = [System.Collections.Generic.List[object]]::new()

    $ReportInformations = [System.Collections.Generic.List[object]]::new()


    # --------------------------------------------------
    # Contexte principal
    # --------------------------------------------------

    return [PSCustomObject]@{


        # ==========================================
        # Projet
        # ==========================================

        Project = [PSCustomObject]@{

            Name = $null

            Version = $null


            Windows = [PSCustomObject]@{

                Release = $null

                Build = $null

            }


            Author = $null

            Company = $null

            Repository = $null

            BuildDate = $null


            Root = $null


            Paths = [PSCustomObject]@{

                ISO = $null

                Logs = $null

                Output = $null

                Mount = $null

                Temp = $null

            }


            Config = $null


            StartTime = Get-Date

            EndTime = $null

            Duration = $null

        }


        # ==========================================
        # Build
        # ==========================================

        Build = [PSCustomObject]@{

            Id = [guid]::NewGuid().Guid

            CreateISO = $true

            CreateReport = $true

            DryRun = $false

            Interactive = $true

        }


        # ==========================================
        # Etat global du Build
        # ==========================================

        BuildState = New-BuildState


        # ==========================================
        # Configuration
        # ==========================================

        Configuration = $null

        ConfigurationProfile = $null


        # ==========================================
        # Image ISO
        # ==========================================

        ISO = [PSCustomObject]@{

		# ------------------------------------------
		# ISO source
		# ------------------------------------------

		Path = $null

		Name = $null

		FullName = $null

		SizeGB = 0

		# ------------------------------------------
		# Montage ISO source
		# ------------------------------------------

		Mounted = $false

		MountPath = $null

		# ------------------------------------------
		# ISO PimsOS générée
		# ------------------------------------------

		OutputPath = $null

		OutputName = $null

		OutputSizeGB = 0

		}


        # ==========================================
        # Image WIM
        # ==========================================

        WIM = [PSCustomObject]@{

            Type = $null

            Name = $null

            FullName = $null

            SizeGB = 0


            # Collection d'images WIM
            Images = $WimImages


            Mount = [PSCustomObject]@{

                Path = $null

                ReadOnly = $false

            }

        }


        # ==========================================
        # Image sélectionnée
        # ==========================================

        Image = [PSCustomObject]@{

            Index = $null

            Name = $null

            Description = $null

            Size = 0

            Modified = $false

            SelectedBy = $null

            Interactive = $false

        }


        # ==========================================
        # Workspace
        # ==========================================

        Workspace = [PSCustomObject]@{

			Root = $null

			Cache = $null

			ISO = $null

			ISOSource = $null

			Sources = $null

			MountISO = $null

			MountTest = $null

			MountWIM = $null

			Temp = $null

			Extract = $null

			Drivers = $null

			Packages = $null

			PackagesChocolatey = $null

			PackagesWinget = $null

			PackagesMicrosoftStore = $null

			Registry = $null

		}


        # ==========================================
        # Registre
        # ==========================================

        Registry = [PSCustomObject]@{

            Mounted = $RegistryMounted

        }


        # ==========================================
        # Contenu
        # ==========================================

        Packages = $Packages

        Drivers = $Drivers

        Tweaks = $Tweaks

        Services = $Services

        Features = $Features


        # ==========================================
        # Rapport
        # ==========================================

        Report = [PSCustomObject]@{

            Environment = $null

            Phases = $ReportPhases

            CurrentPhase = $null

            Warnings = $ReportWarnings

            Errors = $ReportErrors

            Informations = $ReportInformations

        }


        # ==========================================
        # Journal
        # ==========================================

        Logger = [PSCustomObject]@{

            Enabled = $true

            Path = $null

            Started = $false

        }


        # ==========================================
        # Statistiques
        # ==========================================

        Statistics = [PSCustomObject]@{

            ActionsProcessed = 0

            PackagesProcessed = 0

            DriversProcessed = 0

            FeaturesProcessed = 0

            CapabilitiesProcessed = 0

            CommandsProcessed = 0

            FilesProcessed = 0

            FoldersProcessed = 0

            EnvironmentVariablesProcessed = 0

            ScheduledTasksProcessed = 0

            ShortcutsProcessed = 0

            ServicesProcessed = 0

            RegistryActionsProcessed = 0

            TweaksApplied = 0

            Errors = 0

            Warnings = 0

        }

    }
}


# ==================================================
# Initialisation du BuildContext
# ==================================================

function Initialize-BuildContext {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [pscustomobject]$Context

    )


    # ==================================================
    # Informations du projet
    # ==================================================

    $Context.Project.Root = Get-ProjectRoot


    # --------------------------------------------------
    # Configuration
    # --------------------------------------------------

    $Context.Configuration = Get-Config

    $Context.Project.Config = $Context.Configuration


    # --------------------------------------------------
    # Version du projet
    # --------------------------------------------------

    $Version = Get-ProjectVersion


    $Context.Project.Name = Get-ObjectProperty `
        -Object $Version `
        -Name "Project" `
        -Default "PimsOS Builder"


    $Context.Project.Version = Get-ObjectProperty `
        -Object $Version `
        -Name "Version" `
        -Default "0.0.0-dev"


    # --------------------------------------------------
    # Informations Windows
    # --------------------------------------------------

    $Windows = Get-ObjectProperty `
        -Object $Version `
        -Name "Windows"


    if ($Windows) {

        $Context.Project.Windows.Release =
            Get-ObjectProperty `
                -Object $Windows `
                -Name "Release"


        $Context.Project.Windows.Build =
            Get-ObjectProperty `
                -Object $Windows `
                -Name "Build"

    }


    # --------------------------------------------------
    # Informations complémentaires du projet
    # --------------------------------------------------

    $Context.Project.Author =
        Get-ObjectProperty `
            -Object $Version `
            -Name "Author"


    $Context.Project.Company =
        Get-ObjectProperty `
            -Object $Version `
            -Name "Company"


    $Context.Project.Repository =
        Get-ObjectProperty `
            -Object $Version `
            -Name "Repository"


    $Context.Project.BuildDate =
        Get-ObjectProperty `
            -Object $Version `
            -Name "BuildDate"


    # ==================================================
    # Profil de configuration
    # ==================================================

    $Context.ConfigurationProfile =
        Get-ObjectProperty `
            -Object $Context.Configuration `
            -Name "DefaultProfile"


    if ([string]::IsNullOrWhiteSpace(
        $Context.ConfigurationProfile
    )) {

        $Context.ConfigurationProfile =
            "Tests\Registry"

    }


    # ==================================================
    # Chemins du projet
    # ==================================================

    foreach ($PathName in @(
        "ISO",
        "Logs",
        "Output",
        "Mount",
        "Temp"
    )) {

        $Context.Project.Paths.$PathName =
            Get-ProjectPath $PathName

    }


    # ==================================================
	# Workspace
	# ==================================================

	$WorkspaceConfiguration =
		Get-ObjectProperty `
			-Object $Context.Configuration `
			-Name "Workspace"


	if ($null -eq $WorkspaceConfiguration) {

		throw (
			"La configuration PimsOS ne contient pas " +
			"la section 'Workspace'."
		)

	}


	# --------------------------------------------------
	# Initialisation des chemins Workspace
	# --------------------------------------------------

	$WorkspaceProperties = @(
		"Root",
		"Cache",
		"ISO",
		"ISOSource",
		"Sources",
		"MountISO",
		"MountTest",
		"MountWIM",
		"Temp",
		"Extract",
		"Drivers",
		"Packages",
		"PackagesChocolatey",
		"PackagesWinget",
		"PackagesMicrosoftStore",
		"Registry"
	)


	foreach ($WorkspaceProperty in $WorkspaceProperties) {

		$RelativePath =
			Get-ObjectProperty `
				-Object $WorkspaceConfiguration `
				-Name $WorkspaceProperty


		if ([string]::IsNullOrWhiteSpace($RelativePath)) {

			throw (
				"Le chemin Workspace '{0}' est absent " +
				"du fichier Config.json." -f
				$WorkspaceProperty
			)

		}


		$Context.Workspace.$WorkspaceProperty =
			Join-Path `
				$Context.Project.Root `
				$RelativePath

	}

    # ==================================================
    # Logger
    # ==================================================

    $Context.Logger.Path =
        Join-Path `
            $Context.Project.Paths.Logs `
            (
                "Build_{0:yyyyMMdd_HHmmss}.log" -f (Get-Date)
            )


    # ==================================================
    # Etat du Build
    # ==================================================

    $Context.BuildState.Initialized = $true

    $Context.BuildState.Status = "Initialized"


    # ==================================================
    # Retour du contexte
    # ==================================================

    return $Context

}
