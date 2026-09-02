# ==========================================
# Module : PimsOS
# Projet : PimsOS Builder
# Version : 3.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# ==========================================
# Chargement des composants internes
# ==========================================

# --------------------------------------------------
# Infrastructure
# --------------------------------------------------

. "$PSScriptRoot\Infrastructure\Security.ps1"
. "$PSScriptRoot\Infrastructure\Logger.ps1"
. "$PSScriptRoot\Infrastructure\Recovery.ps1"
. "$PSScriptRoot\Infrastructure\Prerequisites.ps1"
. "$PSScriptRoot\Infrastructure\Check.ps1"
. "$PSScriptRoot\Infrastructure\Validation.ps1"
. "$PSScriptRoot\Infrastructure\Service.ps1"

# --------------------------------------------------
# Core
# --------------------------------------------------

. "$PSScriptRoot\Core\Core.ps1"
. "$PSScriptRoot\Core\BuildContext.ps1"
. "$PSScriptRoot\Core\ActionRegistry.ps1"
. "$PSScriptRoot\Core\Workflow.ps1"
. "$PSScriptRoot\Core\Pipeline.ps1"
. "$PSScriptRoot\Core\Complete-Build.ps1"
. "$PSScriptRoot\Core\Report.ps1"
. "$PSScriptRoot\Core\Engine.ps1"

# --------------------------------------------------
# Configuration
# --------------------------------------------------

. "$PSScriptRoot\Configuration\Categories.ps1"
. "$PSScriptRoot\Configuration\Tweak.ps1"
. "$PSScriptRoot\Configuration\TweakCatalog.ps1"
. "$PSScriptRoot\Configuration\Profile.ps1"
. "$PSScriptRoot\Configuration\Configuration.ps1"

# --------------------------------------------------
# Managers
# --------------------------------------------------

. "$PSScriptRoot\Managers\PackageManager.ps1"
. "$PSScriptRoot\Managers\DriverManager.ps1"
. "$PSScriptRoot\Managers\FeatureManager.ps1"
. "$PSScriptRoot\Managers\CapabilityManager.ps1"
. "$PSScriptRoot\Managers\CommandManager.ps1"
. "$PSScriptRoot\Managers\FileManager.ps1"
. "$PSScriptRoot\Managers\FolderManager.ps1"
. "$PSScriptRoot\Managers\EnvironmentManager.ps1"
. "$PSScriptRoot\Managers\ScheduledTaskManager.ps1"
. "$PSScriptRoot\Managers\ShortcutManager.ps1"

# --------------------------------------------------
# Package Providers
# --------------------------------------------------

. "$PSScriptRoot\Package\Chocolatey.ps1"
. "$PSScriptRoot\Package\ChocolateyCache.ps1"
. "$PSScriptRoot\Package\ChocolateyCatalog.ps1"
. "$PSScriptRoot\Package\Winget.ps1"

# --------------------------------------------------
# Windows
# --------------------------------------------------

. "$PSScriptRoot\Windows\Registry.ps1"

# --------------------------------------------------
# Image
# --------------------------------------------------

. "$PSScriptRoot\Image\Iso.ps1"
. "$PSScriptRoot\Image\Dism.ps1"
. "$PSScriptRoot\Image\Wim.ps1"

# ==========================================
# PostInstall
# ==========================================

. "$PSScriptRoot\PostInstall\State.ps1"
. "$PSScriptRoot\PostInstall\Network.ps1"
. "$PSScriptRoot\PostInstall\PostInstall.ps1"
. "$PSScriptRoot\PostInstall\Finalize.ps1"
. "$PSScriptRoot\PostInstall\FirstBoot.ps1"
. "$PSScriptRoot\PostInstall\Unattend.ps1"
. "$PSScriptRoot\PostInstall\Installer.ps1"

# ==========================================
# UI
# ==========================================

. "$PSScriptRoot\UI\Wizard.ps1"

# --------------------------------------------------
# Actions
# --------------------------------------------------

. "$PSScriptRoot\Actions\ActionEngine.ps1"
. "$PSScriptRoot\Actions\RegistryEngine.ps1"
. "$PSScriptRoot\Actions\ServiceEngine.ps1"
. "$PSScriptRoot\Actions\PackageEngine.ps1"
. "$PSScriptRoot\Actions\DriverEngine.ps1"
. "$PSScriptRoot\Actions\FeatureEngine.ps1"
. "$PSScriptRoot\Actions\CapabilityEngine.ps1"
. "$PSScriptRoot\Actions\CommandEngine.ps1"
. "$PSScriptRoot\Actions\FileEngine.ps1"
. "$PSScriptRoot\Actions\FolderEngine.ps1"
. "$PSScriptRoot\Actions\EnvironmentEngine.ps1"
. "$PSScriptRoot\Actions\ScheduledTaskEngine.ps1"
. "$PSScriptRoot\Actions\ShortcutEngine.ps1"


# ==========================================
# Initialisation de PimsOS
# ==========================================

function Initialize-PimsOS {

    [CmdletBinding()]
    param()

    $ExitCode = 0
    $Context = $null

    try {

        # ------------------------------------------
        # BuildContext
        # ------------------------------------------

        Write-Verbose "Création du BuildContext..."

        $Context = New-BuildContext

        $Context = Initialize-BuildContext `
            -Context $Context


        # ------------------------------------------
        # Logger
        # ------------------------------------------

        Start-Logger `
            -Path $Context.Logger.Path

        Write-Log "Initialisation de PimsOS..."

        Write-Log (
            "Version : {0}" -f
            $Context.Project.Version
        )

        Write-Log (
            "Build ID : {0}" -f
            $Context.Build.Id
        )

        Write-Log (
            "Projet : {0}" -f
            $Context.Project.Root
        )

        Write-Log (
            "Profil : {0}" -f
            $Context.ConfigurationProfile
        )

		# ------------------------------------------
		# Assistant de configuration
		# ------------------------------------------

		if ($Context.Build.Interactive) {

			Write-Verbose "Lancement de l'assistant de configuration..."

			Write-Log "Lancement de l'assistant de configuration..." INFO

			$Context = Show-PimsOSBuildWizard `
				-Context $Context
		}

        # ------------------------------------------
        # Recovery
        # ------------------------------------------

        Write-Verbose "Préparation de l'environnement..."

        $Context = Repair-BuildEnvironment `
            -Context $Context

        # ------------------------------------------
        # Windows ADK
        # ------------------------------------------

        $AdkRequired = $false

        if (
            $null -ne $Context.Project.Config -and
            $null -ne $Context.Project.Config.Requirements -and
            $null -ne $Context.Project.Config.Requirements.WindowsADK
        ) {

            $AdkConfiguration =
                $Context.Project.Config.Requirements.WindowsADK

            if (
                $AdkConfiguration.PSObject.Properties.Name `
                    -contains "Required"
            ) {

                $AdkRequired =
                    [bool]$AdkConfiguration.Required

            }

        }


        if ($AdkRequired) {

            Write-Verbose "Vérification de Windows ADK..."

            $AdkStatus = Test-PimsOSWindowsADK

            if (-not $AdkStatus.Installed) {

                Write-Log (
                    "Windows ADK requis mais absent. " +
                    "Préparation de l'installation..."
                )

                $Context.BuildState.Environment.WindowsADK = $false

                Install-PimsOSWindowsADK `
					-Configuration $Context.Project.Config `
					-DestinationPath (
						Join-Path `
							$Context.Workspace.Temp `
							"ADK"
					)

                Write-Log (
                    "Windows ADK installé : {0}" -f
                    (Get-PimsOSOsCdImgPath)
                ) SUCCESS

            }
            else {

                Write-Log (
                    "Windows ADK déjà disponible : {0}" -f
                    $AdkStatus.OsCdImgPath
                ) SUCCESS

            }

        }


        # ------------------------------------------
        # Vérifications
        # ------------------------------------------

        Write-Verbose "Vérification de l'environnement..."

        $Context = Invoke-EnvironmentChecks `
            -Context $Context

        if (-not $Context.Report.Environment.Success) {

            throw "Les prérequis ne sont pas satisfaits."

        }

        # ------------------------------------------
        # Pipeline
        # ------------------------------------------

        $Context = Invoke-BuildPipeline `
            -Context $Context

        # ------------------------------------------
        # Etat final
        # ------------------------------------------

        $Context.BuildState.Status = "Completed"

        Write-Log (
            "Etat final : {0}" -f
            $Context.BuildState.Status
        )

        Write-Log "Initialisation de PimsOS terminée." SUCCESS

    }
    catch {

        $ExitCode = 1

        if ($Context) {

            $Context.BuildState.Status = "Failed"

        }

        throw

    }
    finally {

        if ($Context) {

            $Context = Complete-Build `
                -Context $Context `
                -ExitCode $ExitCode

        }

    }

    return $Context

}

Export-ModuleMember `
    -Function @(
        "Initialize-PimsOS"
    )
