# ==========================================
# Module : PostInstall
# Projet : PimsOS Builder
# Version : 1.2.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Initialise le PostInstall
# --------------------------------------------------

function Initialize-PostInstall {

    [CmdletBinding()]
    param(

        [Parameter()]
        [string]$StatePath =
            "C:\ProgramData\PimsOS\PostInstall\state.json"

    )

    $State = Get-PostInstallState `
        -StatePath $StatePath

    if (
        $State.PSObject.Properties.Name -notcontains "StatePath"
    ) {

        $State |
            Add-Member `
                -MemberType NoteProperty `
                -Name StatePath `
                -Value $StatePath

    }

    $State.StatePath = $StatePath

    return Save-PostInstallState `
        -State $State `
        -StatePath $StatePath

}

# --------------------------------------------------
# Vérifie si une phase est déjà terminée
# --------------------------------------------------

function Test-PostInstallTaskCompleted {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$State,

        [Parameter(Mandatory)]
        [string]$TaskName

    )

    if (
        $State.PSObject.Properties.Name -notcontains
        "CompletedTasks"
    ) {

        return $false

    }

    if ($null -eq $State.CompletedTasks) {

        return $false

    }

    return (
        $State.CompletedTasks -contains $TaskName
    )

}

# --------------------------------------------------
# Marque une phase comme terminée
# --------------------------------------------------

function Complete-PostInstallTask {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$State,

        [Parameter(Mandatory)]
        [string]$TaskName

    )

    if (
        $State.PSObject.Properties.Name -notcontains
        "CompletedTasks"
    ) {

        $State |
            Add-Member `
                -MemberType NoteProperty `
                -Name CompletedTasks `
                -Value @()

    }

    if ($null -eq $State.CompletedTasks) {

        $State.CompletedTasks = @()

    }

    if (
        $State.CompletedTasks -notcontains $TaskName
    ) {

        $State.CompletedTasks += $TaskName

    }

    return $State

}

# --------------------------------------------------
# Définit la phase courante
# --------------------------------------------------

function Set-PostInstallPhase {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$State,

        [Parameter(Mandatory)]
        [string]$Phase

    )

    $State.CurrentPhase = $Phase

    return Save-PostInstallState `
        -State $State

}

# --------------------------------------------------
# Exécute le PostInstall
# --------------------------------------------------

function Invoke-PostInstall {

    [CmdletBinding()]
    param(

        [Parameter()]
        [psobject]$State,

        [Parameter()]
        [switch]$WaitForNetwork,

        [Parameter()]
        [int]$NetworkTimeoutMinutes = 0

    )

    if ($null -eq $State) {

        $State = Initialize-PostInstall

    }

    # --------------------------------------------------
    # Protection contre une seconde exécution complète
    # --------------------------------------------------

    if (
        $null -ne $State.Status -and
        $State.Status -eq "Completed"
    ) {

        Write-Log `
            "PostInstall déjà terminé. Aucune nouvelle exécution." `
            INFO

        return $State

    }

    try {

        # ==================================================
        # INITIALIZE
        # ==================================================

        if (-not (Test-PostInstallTaskCompleted `
            -State $State `
            -TaskName "Initialize")) {

            Set-PostInstallPhase `
                -State $State `
                -Phase "Initialize" |
                Out-Null

            $State = Set-PostInstallStatus `
                -State $State `
                -Status "Running"

            $State = Save-PostInstallState `
                -State $State

            Write-Log `
                "Initialisation du PostInstall." `
                INFO

            $State = Complete-PostInstallTask `
                -State $State `
                -TaskName "Initialize"

            $State = Save-PostInstallState `
                -State $State

        }

        # ==================================================
        # NETWORK
        # ==================================================

        if (-not (Test-PostInstallTaskCompleted `
            -State $State `
            -TaskName "Network")) {

            Set-PostInstallPhase `
                -State $State `
                -Phase "Network" |
                Out-Null

            Write-Log `
                "Vérification de la connexion réseau." `
                INFO

            $NetworkAvailable = $false

            if (Get-Command Test-PostInstallInternet `
                -ErrorAction SilentlyContinue) {

                $NetworkAvailable =
                    Test-PostInstallInternet

            }
            elseif (Get-Command Test-PostInstallNetwork `
                -ErrorAction SilentlyContinue) {

                $NetworkAvailable =
                    Test-PostInstallNetwork

            }
            else {

                throw `
                    "Aucune fonction de vérification réseau disponible."

            }

            if (-not $NetworkAvailable) {

                $State = Set-PostInstallStatus `
                    -State $State `
                    -Status "WaitingForNetwork"

                $State.CurrentPhase = "Network"

                $State = Save-PostInstallState `
                    -State $State

                Write-Log `
                    "Connexion Internet indisponible. Attente du réseau." `
                    WARNING

                if (-not $WaitForNetwork) {

                    throw (
                        "Une connexion Internet est requise pour poursuivre le PostInstall."
                    )

                }

                if (Get-Command Wait-PostInstallNetwork `
                    -ErrorAction SilentlyContinue) {

                    $NetworkAvailable =
                        Wait-PostInstallNetwork `
                            -TimeoutMinutes $NetworkTimeoutMinutes

                }
                else {

                    throw `
                        "La fonction Wait-PostInstallNetwork est indisponible."

                }

                if (-not $NetworkAvailable) {

                    throw (
                        "Le délai d'attente réseau a été dépassé."
                    )

                }

            }

            $State.NetworkAvailable = $true

            $State = Set-PostInstallStatus `
                -State $State `
                -Status "Running"

            $State.CurrentPhase = "Network"

            $State = Complete-PostInstallTask `
                -State $State `
                -TaskName "Network"

            $State = Save-PostInstallState `
                -State $State

            Write-Log `
                "Connexion Internet disponible." `
                SUCCESS

        }
        else {

            Write-Log `
                "Phase Network déjà terminée. Reprise du PostInstall." `
                INFO

        }

        # ==================================================
		# DRIVER CHECK
		# ==================================================

		if (-not (Test-PostInstallTaskCompleted `
			-State $State `
			-TaskName "DriverCheck")) {

			Set-PostInstallPhase `
				-State $State `
				-Phase "DriverCheck" |
				Out-Null

			Write-Log `
				"Vérification des périphériques et pilotes." `
				INFO

			# --------------------------------------------------
			# Vérification des drivers
			# --------------------------------------------------

			if (Get-Command Test-PostInstallDrivers `
				-ErrorAction SilentlyContinue) {

				$DriverCheckResult =
					Test-PostInstallDrivers

			}
			else {

				throw `
					"La fonction Test-PostInstallDrivers est indisponible."

			}

			# --------------------------------------------------
			# Analyse du résultat
			# --------------------------------------------------

			if ($DriverCheckResult.Success) {

				Write-Log `
					"Tous les périphériques détectés disposent d'un pilote fonctionnel." `
					SUCCESS

			}
			elseif ($DriverCheckResult.Available) {

				Write-Log (
					"{0} périphérique(s) présente(nt) un problème de pilote." -f
					$DriverCheckResult.ProblemCount
				) WARNING

				# --------------------------------------------------
				# Important :
				# Un problème de pilote ne bloque pas le PostInstall.
				# Aucune installation runtime n'est effectuée ici.
				# --------------------------------------------------

				Write-Log `
					"Aucune installation runtime de pilote n'est configurée. Poursuite du PostInstall." `
					WARNING

			}
			else {

				Write-Log `
					"La vérification des pilotes n'a pas pu être effectuée. Poursuite du PostInstall." `
					WARNING

			}

			# --------------------------------------------------
			# Phase terminée
			# --------------------------------------------------

			$State = Complete-PostInstallTask `
				-State $State `
				-TaskName "DriverCheck"

			$State = Save-PostInstallState `
				-State $State

			Write-Log `
				"Vérification des pilotes terminée." `
				SUCCESS

		}

        else {

            Write-Log `
                "Phase Drivers déjà terminée. Reprise du PostInstall." `
                INFO

        }

        # ==================================================
        # CHOCOLATEY
        # ==================================================

        if (-not (Test-PostInstallTaskCompleted `
            -State $State `
            -TaskName "Chocolatey")) {

            Set-PostInstallPhase `
                -State $State `
                -Phase "Chocolatey" |
                Out-Null

            Write-Log `
                "Phase Chocolatey." `
                INFO

            # --------------------------------------------------
            # L'installation de Chocolatey et l'utilisation
            # du cache local seront ajoutées ici.
            # --------------------------------------------------

            $State = Complete-PostInstallTask `
                -State $State `
                -TaskName "Chocolatey"

            $State = Save-PostInstallState `
                -State $State

            Write-Log `
                "Phase Chocolatey terminée." `
                SUCCESS

        }
        else {

            Write-Log `
                "Phase Chocolatey déjà terminée. Reprise du PostInstall." `
                INFO

        }

        # ==================================================
        # APPLICATIONS
        # ==================================================

        if (-not (Test-PostInstallTaskCompleted `
            -State $State `
            -TaskName "Applications")) {

            Set-PostInstallPhase `
                -State $State `
                -Phase "Applications" |
                Out-Null

            Write-Log `
                "Phase Applications." `
                INFO

            # --------------------------------------------------
            # Les installations d'applications seront ajoutées
            # ici.
            # --------------------------------------------------

            $State = Complete-PostInstallTask `
                -State $State `
                -TaskName "Applications"

            $State = Save-PostInstallState `
                -State $State

            Write-Log `
                "Phase Applications terminée." `
                SUCCESS

        }
        else {

            Write-Log `
                "Phase Applications déjà terminée. Reprise du PostInstall." `
                INFO

        }

        # ==================================================
        # MICROSOFT STORE
        # ==================================================

        if (-not (Test-PostInstallTaskCompleted `
            -State $State `
            -TaskName "MicrosoftStore")) {

            Set-PostInstallPhase `
                -State $State `
                -Phase "MicrosoftStore" |
                Out-Null

            Write-Log `
                "Phase Microsoft Store." `
                INFO

            # --------------------------------------------------
            # Les installations Microsoft Store / winget
            # seront ajoutées ici.
            # --------------------------------------------------

            $State = Complete-PostInstallTask `
                -State $State `
                -TaskName "MicrosoftStore"

            $State = Save-PostInstallState `
                -State $State

            Write-Log `
                "Phase Microsoft Store terminée." `
                SUCCESS

        }
        else {

            Write-Log `
                "Phase Microsoft Store déjà terminée. Reprise du PostInstall." `
                INFO

        }

        # ==================================================
        # CONFIGURATION
        # ==================================================

        if (-not (Test-PostInstallTaskCompleted `
            -State $State `
            -TaskName "Configuration")) {

            Set-PostInstallPhase `
                -State $State `
                -Phase "Configuration" |
                Out-Null

            Write-Log `
                "Phase Configuration." `
                INFO

            # --------------------------------------------------
            # Les opérations de configuration finale seront
            # ajoutées ici.
            # --------------------------------------------------

            $State = Complete-PostInstallTask `
                -State $State `
                -TaskName "Configuration"

            $State = Save-PostInstallState `
                -State $State

            Write-Log `
                "Phase Configuration terminée." `
                SUCCESS

        }
        else {

            Write-Log `
                "Phase Configuration déjà terminée. Reprise du PostInstall." `
                INFO

        }

        # ==================================================
        # CLEANUP
        # ==================================================

        if (-not (Test-PostInstallTaskCompleted `
            -State $State `
            -TaskName "Cleanup")) {

            Set-PostInstallPhase `
                -State $State `
                -Phase "Cleanup" |
                Out-Null

            Write-Log `
                "Phase Cleanup." `
                INFO

            # --------------------------------------------------
            # Les opérations de nettoyage seront ajoutées ici.
            # --------------------------------------------------

            $State = Complete-PostInstallTask `
                -State $State `
                -TaskName "Cleanup"

            $State = Save-PostInstallState `
                -State $State

            Write-Log `
                "Phase Cleanup terminée." `
                SUCCESS

        }
        else {

            Write-Log `
                "Phase Cleanup déjà terminée. Reprise du PostInstall." `
                INFO

        }

        # ==================================================
        # COMPLETED
        # ==================================================

        $State.CurrentPhase = $null

        $State = Set-PostInstallStatus `
            -State $State `
            -Status "Completed"

        $State = Save-PostInstallState `
            -State $State

        Write-Log `
            "PostInstall terminé avec succès." `
            SUCCESS

        return $State

    }
    catch {

        $ErrorMessage = $_.Exception.Message

        if (
            $State.PSObject.Properties.Name -notcontains
            "Errors"
        ) {

            $State |
                Add-Member `
                    -MemberType NoteProperty `
                    -Name Errors `
                    -Value @()

        }

        if ($null -eq $State.Errors) {

            $State.Errors = @()

        }

        $State.Errors += $ErrorMessage

        $State = Set-PostInstallStatus `
            -State $State `
            -Status "Failed"

        $State = Save-PostInstallState `
            -State $State

        Write-Log `
            ("PostInstall échoué : {0}" -f $ErrorMessage) `
            ERROR

        throw

    }

}