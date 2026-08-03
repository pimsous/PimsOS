# ==========================================
# Module : BuildContext
# Projet : PimsOS Builder
# Version : 2.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Etat global du Build
# --------------------------------------------------

function New-BuildState {

    [CmdletBinding()]
    param()

    return [PSCustomObject]@{

        ObjectType = "BuildState"

        Initialized = $false
		
		Status = "NotStarted"

        Recovery = [PSCustomObject]@{

            Completed = $false

            Wim = $null

            Iso = $null

            Registry = $null

        }

        Environment = [PSCustomObject]@{

            Checked = $false

            PowerShell = $false

            Administrator = $false

            Git = $false

            Dism = $false

            Iso = $false

            DiskSpace = $false

        }

        Pipeline = [PSCustomObject]@{

            Started = $false

            Current = $null

            Completed = @()

            Failed = @()

        }

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
		Success = $false
        Completed = $false

    }

}

function New-BuildContext {

    [CmdletBinding()]
    param()

    return [PSCustomObject]@{

        # ==========================================
		# Projet
		# ==========================================

		Project = [PSCustomObject]@{

			Name       = $null
			Version    = $null

			Windows = [PSCustomObject]@{

				Release = $null
				Build   = $null

			}

			Author     = $null
			Company    = $null
			Repository = $null
			BuildDate  = $null
			
			Root       = $null

			Paths = [PSCustomObject]@{

				ISO    = $null
				Logs   = $null
				Output = $null
				Mount  = $null
				Temp   = $null

			}

			Config = $null

			StartTime = Get-Date
			EndTime   = $null
			Duration  = $null

		}

        # ==========================================
        # Build
        # ==========================================

        Build = [PSCustomObject]@{

			Id              = [guid]::NewGuid().Guid


			CreateISO       = $true
			CreateReport    = $true

			DryRun          = $false
			Interactive     = $true

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

        ISO = $null

        WIM = [PSCustomObject]@{

            Type        = $null
            Name        = $null
            FullName    = $null

            SizeGB      = 0

            Images      = @()

            Mount = [PSCustomObject]@{

                Path        = $null
                ReadOnly    = $false

            }

        }

        Image = [PSCustomObject]@{

            Index           = $null

            Name            = $null

            Description     = $null

            Size            = 0

            Modified        = $false

            SelectedBy      = $null

            Interactive     = $false

        }

        # ==========================================
        # Workspace
        # ==========================================

        Workspace = [PSCustomObject]@{

            Root        = $null

            ISO         = $null

            Sources     = $null

            MountISO    = $null

            MountWIM    = $null

            Output      = $null

            Temp        = $null

            Extract     = $null

        }
		

        # ==========================================
        # Registre
        # ==========================================

        Registry = [PSCustomObject]@{

			Mounted = @()

		}
		
	    # ==========================================
        # Contenu
        # ==========================================

        Packages   = @()

        Drivers    = @()

        Tweaks     = @()

        Services   = @()

        Features   = @()


        # ==========================================
        # Rapport
        # ==========================================

        Report = [PSCustomObject]@{

            Environment    = $null

            Phases         = @()

            CurrentPhase   = $null

            Warnings       = @()

            Errors         = @()

            Informations   = @()

        }

        # ==========================================
        # Journal
        # ==========================================

        Logger = [PSCustomObject]@{

            Enabled     = $true

            Path        = $null

            Started     = $false

        }

        # ==========================================
        # Statistiques
        # ==========================================

        Statistics = [PSCustomObject]@{

			ActionsProcessed              = 0

			PackagesProcessed             = 0

			DriversProcessed              = 0

			FeaturesProcessed             = 0

			CapabilitiesProcessed         = 0

			CommandsProcessed             = 0

			FilesProcessed                = 0

			FoldersProcessed              = 0

			EnvironmentVariablesProcessed = 0

			ScheduledTasksProcessed       = 0

			ShortcutsProcessed            = 0

			ServicesProcessed             = 0

			RegistryActionsProcessed      = 0

			TweaksApplied                 = 0

			Errors                        = 0

			Warnings                      = 0

		}

    }

}
function Initialize-BuildContext {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [pscustomobject]$Context

    )

    # ------------------------------------------
    # Informations du projet
    # ------------------------------------------
	
    $Context.Project.Root = Get-ProjectRoot

    $Context.Configuration = Get-Config

	$Context.Project.Config = $Context.Configuration

	$Version = Get-ProjectVersion

	$Context.Project.Name = Get-ObjectProperty `
		-Object $Version `
		-Name "Project" `
		-Default "PimsOS Builder"

	$Context.Project.Version = Get-ObjectProperty `
		-Object $Version `
		-Name "Version" `
		-Default "0.0.0-dev"
		
	$Windows = Get-ObjectProperty `
		-Object $Version `
		-Name "Windows"

	if ($Windows) {

		$Context.Project.Windows.Release = Get-ObjectProperty `
			-Object $Windows `
			-Name "Release"

		$Context.Project.Windows.Build = Get-ObjectProperty `
			-Object $Windows `
			-Name "Build"

	}

	$Context.Project.Author = Get-ObjectProperty `
		-Object $Version `
		-Name "Author"

	$Context.Project.Company = Get-ObjectProperty `
		-Object $Version `
		-Name "Company"

	$Context.Project.Repository = Get-ObjectProperty `
		-Object $Version `
		-Name "Repository"
	
	$Context.Project.BuildDate = Get-ObjectProperty `
		-Object $Version `
		-Name "BuildDate"

	$Context.ConfigurationProfile = Get-ObjectProperty `
		-Object $Context.Configuration `
		-Name "DefaultProfile"

	if ([string]::IsNullOrWhiteSpace($Context.ConfigurationProfile)) {

		$Context.ConfigurationProfile = "Tests\Registry"

	}
    # ------------------------------------------
    # Chemins
    # ------------------------------------------

    foreach ($PathName in @("ISO","Logs","Output","Mount","Temp")) {

        $Context.Project.Paths.$PathName = Get-ProjectPath $PathName

    }

    # Workspace

    $Context.Workspace.Root = $Context.Project.Root

    $Context.Workspace.ISO = $Context.Project.Paths.ISO

    $Context.Workspace.Output = $Context.Project.Paths.Output
	
	$Context.Workspace.Sources = Join-Path `
		$Context.Project.Root `
		"Workspace\Sources"

    $Context.Workspace.Temp = $Context.Project.Paths.Temp

    $Context.Workspace.MountWIM = Join-Path `
        $Context.Project.Paths.Mount `
        "WIM"

    $Context.Workspace.MountISO = Join-Path `
        $Context.Project.Paths.Mount `
        "ISO"

    $Context.Workspace.Extract = Join-Path `
        $Context.Project.Paths.Temp `
        "Extract"

    # ------------------------------------------
    # Logger
    # ------------------------------------------

    $Context.Logger.Path = Join-Path `
        $Context.Project.Paths.Logs `
        ("Build_{0:yyyyMMdd_HHmmss}.log" -f (Get-Date))

    # ------------------------------------------
    # Etat du Build
    # ------------------------------------------
	
	$Context.BuildState.Initialized = $true
    $Context.BuildState.Status = "Initialized"

    return $Context

}
