# ==========================================
# Module : Pipeline
# Projet : PimsOS Builder
# Version : 0.4.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest


# ==========================================
# Exécute une étape du pipeline
# ==========================================

function Invoke-BuildStep {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [scriptblock]$Action

    )

    # ------------------------------------------
    # Vérification de la phase
    # ------------------------------------------

    if (-not $Context.Report.CurrentPhase) {

        throw (
            "Aucune phase active. " +
            "Appelez Start-BuildPhase avant Invoke-BuildStep."
        )

    }

    Write-Log "Étape : $Name" INFO

    # ------------------------------------------
    # Etat du pipeline
    # ------------------------------------------

    $Context.BuildState.Pipeline.Started = $true
    $Context.BuildState.Pipeline.Current = $Name

    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {

        # ------------------------------------------
        # Exécution de l'action
        # ------------------------------------------

        $Result = @(
            & $Action $Context
        )

        # ------------------------------------------
        # Validation du résultat
        # ------------------------------------------

        if ($Result.Count -eq 0) {

            throw (
                "L'étape '$Name' n'a retourné aucun contexte."
            )

        }

        if ($Result.Count -gt 1) {

            throw (
                "L'étape '$Name' a retourné plusieurs objets " +
                "($($Result.Count)). " +
                "Un seul BuildContext est attendu."
            )

        }

        $CandidateContext = $Result[0]

        # ------------------------------------------
        # Validation du BuildContext
        # ------------------------------------------

        if ($null -eq $CandidateContext) {

            throw (
                "L'étape '$Name' a retourné `$null. " +
                "Un BuildContext est attendu."
            )

        }

        if (
            -not (
                $CandidateContext.PSObject.Properties.Name `
                    -contains "BuildState"
            )
        ) {

            throw (
                "L'étape '$Name' n'a pas retourné un BuildContext valide : " +
                "propriété 'BuildState' absente."
            )

        }

        if (
            -not (
                $CandidateContext.PSObject.Properties.Name `
                    -contains "Report"
            )
        ) {

            throw (
                "L'étape '$Name' n'a pas retourné un BuildContext valide : " +
                "propriété 'Report' absente."
            )

        }

        # ------------------------------------------
        # Remplacement du contexte
        # ------------------------------------------

        $Context = $CandidateContext

        # ------------------------------------------
        # Validation spécifique ISO
        # ------------------------------------------

        if (
            $Context.PSObject.Properties.Name -contains "ISO" -and
            $null -ne $Context.ISO
        ) {

            if ($Context.ISO -is [array]) {

                throw (
                    "Le BuildContext retourné par l'étape '$Name' " +
                    "contient un ISO sous forme de tableau " +
                    "($($Context.ISO.Count) éléments)."
                )

            }

        }

        # ------------------------------------------
        # Validation spécifique WIM
        # ------------------------------------------

        if (
            $Context.PSObject.Properties.Name -contains "WIM" -and
            $null -ne $Context.WIM
        ) {

            if ($Context.WIM -is [array]) {

                throw (
                    "Le BuildContext retourné par l'étape '$Name' " +
                    "contient un WIM sous forme de tableau " +
                    "($($Context.WIM.Count) éléments)."
                )

            }

        }

        # ------------------------------------------
        # Arrêt du chronomètre
        # ------------------------------------------

        $Stopwatch.Stop()

        # ------------------------------------------
        # Rapport
        # ------------------------------------------

        $Context.Report.CurrentPhase.Steps += [PSCustomObject]@{

            Name     = $Name
            Success  = $true
            Duration = $Stopwatch.Elapsed

        }

        # ------------------------------------------
        # Etat du pipeline
        # ------------------------------------------

        if (
            $Context.BuildState.Pipeline.Completed `
                -notcontains $Name
        ) {

            $Context.BuildState.Pipeline.Completed += $Name

        }

        $Context.BuildState.Pipeline.Current = $null

        Write-Log (
            "$Name terminé en $($Stopwatch.Elapsed)"
        ) SUCCESS

    }
    catch {

        $Stopwatch.Stop()

        # ------------------------------------------
        # Rapport
        # ------------------------------------------

        if ($Context.Report.CurrentPhase) {

            $Context.Report.CurrentPhase.Success = $false

            $Context.Report.CurrentPhase.Errors +=
                $_.Exception.Message

            $Context.Report.CurrentPhase.Steps +=
                [PSCustomObject]@{

                    Name     = $Name
                    Success  = $false
                    Duration = $Stopwatch.Elapsed

                }

        }

        # ------------------------------------------
        # Etat du pipeline
        # ------------------------------------------

        if (
            $Context.BuildState.Pipeline.Failed `
                -notcontains $Name
        ) {

            $Context.BuildState.Pipeline.Failed += $Name

        }

        $Context.BuildState.Pipeline.Current = $null

        Write-Log (
            "$Name : $($_.Exception.Message)"
        ) ERROR

        throw

    }

    # ------------------------------------------
    # Retour du BuildContext
    # ------------------------------------------

    return $Context
}


# ==========================================
# Nettoyage sécurisé du pipeline
# ==========================================

function Invoke-PipelineCleanup {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [switch]$Discard

    )

    Write-Log "Nettoyage des ressources du pipeline..." INFO

    $CleanupErrors = @()


    # ------------------------------------------
    # 1. Ruche SOFTWARE
    # ------------------------------------------

    try {

        if (
            $Context.BuildState.Image.RegistryLoaded -eq $true
        ) {

            Write-Log "Démontage de la ruche SOFTWARE..." INFO

            $Context = Dismount-RegistryHive `
                -Context $Context `
                -Hive SOFTWARE

        }

    }
    catch {

        $CleanupErrors +=
            "Ruche SOFTWARE : $($_.Exception.Message)"

        Write-Log (
            "Erreur lors du démontage de SOFTWARE : $($_.Exception.Message)"
        ) ERROR

    }


    # ------------------------------------------
	# 2. WIM
	# ------------------------------------------

	try {

		if ($null -ne $Context.WIM) {

			Write-Log `
				"Vérification d'un éventuel montage WIM actif..." `
				INFO

			if ($Discard) {

				$Context = Dismount-Wim `
					-Context $Context `
					-Discard

			}
			else {

				$Context = Dismount-Wim `
					-Context $Context

			}

		}

	}
	catch {

		$CleanupErrors +=
			"WIM : $($_.Exception.Message)"

		Write-Log (
			"Erreur lors du démontage du WIM : $($_.Exception.Message)"
		) ERROR

	}


    # ------------------------------------------
    # 3. ISO
    # ------------------------------------------

    try {

        if (
            $Context.BuildState.Image.IsoMounted -eq $true
        ) {

            Write-Log "Démontage de l'image ISO..." INFO

            $Context = Dismount-Iso `
                -Context $Context

        }

    }
    catch {

        $CleanupErrors +=
            "ISO : $($_.Exception.Message)"

        Write-Log (
            "Erreur lors du démontage de l'ISO : $($_.Exception.Message)"
        ) ERROR

    }


    # ------------------------------------------
    # Vérification finale de l'état
    # ------------------------------------------

    if (
        $Context.BuildState.Image.RegistryLoaded -eq $true -or
        $Context.BuildState.Image.WimMounted -eq $true -or
        $Context.BuildState.Image.IsoMounted -eq $true
    ) {

        Write-Log (
            "Certaines ressources du pipeline restent montées."
        ) WARNING

    }
    else {

        $Context.BuildState.Image.RegistryLoaded = $false
        $Context.BuildState.Image.CurrentRegistryHive = $null

        $Context.BuildState.Image.WimMounted = $false
        $Context.BuildState.Image.IsoMounted = $false
        $Context.BuildState.Image.Mounted = $false
        $Context.BuildState.Image.MountPath = $null
        $Context.BuildState.Image.Index = $null

        Write-Log "Nettoyage du pipeline terminé." SUCCESS

    }


    # ------------------------------------------
    # Erreurs de nettoyage
    # ------------------------------------------

    if ($CleanupErrors.Count -gt 0) {

        throw (
            "Une ou plusieurs ressources n'ont pas pu être nettoyées : " +
            ($CleanupErrors -join " | ")
        )

    }


    return $Context
}


# ==========================================
# Retourne le pipeline du Build
# ==========================================

function Get-BuildPipeline {

    [CmdletBinding()]
    param()

    return @(

        # ------------------------------------------
        # Montage ISO
        # ------------------------------------------

        @{

            Id   = "MountIso"
            Name = "Montage ISO"

            Action = {

                param($Context)

                Mount-Iso `
                    -Context $Context

            }

        },


        # ------------------------------------------
        # Détection du WIM
        # ------------------------------------------

        @{

            Id   = "DetectWim"
            Name = "Détection du WIM"

            Action = {

                param($Context)

                Get-WimFile `
                    -Context $Context

            }

        },


        # ------------------------------------------
        # Copie du WIM
        # ------------------------------------------

        @{

            Id   = "CopyWim"
            Name = "Copie du WIM"

            Condition = {

                param($Context)

                $CanReuse = $false

                if (
                    $null -ne $Context.BuildState.Recovery.Wim -and
                    $Context.BuildState.Recovery.Wim.PSObject.Properties.Name -contains "CanReuse"
                ) {

                    $CanReuse =
                        [bool]$Context.BuildState.Recovery.Wim.CanReuse

                }

                -not $CanReuse

            }

            Action = {

                param($Context)

                Copy-WimToWorkspace `
                    -Context $Context

            }

        },


        # ------------------------------------------
        # Lecture des images WIM
        # ------------------------------------------

        @{

            Id   = "ReadWimImages"
            Name = "Lecture des images WIM"

            Action = {

                param($Context)

                Get-WimImages `
                    -Context $Context

            }

        },


        # ------------------------------------------
        # Sélection de l'image Windows
        # ------------------------------------------

        @{

            Id   = "SelectImage"
            Name = "Sélection de l'image Windows"

            Action = {

                param($Context)

                Select-WimImage `
                    -Context $Context

            }

        },


        # ------------------------------------------
        # Montage du WIM
        # ------------------------------------------

        @{

            Id   = "MountWim"
            Name = "Montage du WIM"

            Action = {

                param($Context)

                Mount-Wim `
                    -Context $Context

            }

        },


        # ------------------------------------------
        # Montage de la ruche SOFTWARE
        # ------------------------------------------

        @{

            Id   = "MountSoftwareHive"
            Name = "Montage de la ruche SOFTWARE"

            Action = {

                param($Context)

                Mount-RegistryHive `
                    -Context $Context `
                    -Hive SOFTWARE

            }

        },


        # ------------------------------------------
        # Chargement de la configuration
        # ------------------------------------------

        @{

            Id   = "LoadConfiguration"
            Name = "Chargement de la configuration"

            Action = {

                param($Context)

                Get-Configuration `
                    -Context $Context `
                    -Profile $Context.ConfigurationProfile

            }

        },


        # ------------------------------------------
        # Application de la configuration
        # ------------------------------------------

        @{

            Id   = "ApplyConfiguration"
            Name = "Application de la configuration"

            Action = {

                param($Context)

                Invoke-Configuration `
                    -Context $Context `
                    -Configuration $Context.Configuration

            }

        },


        # ------------------------------------------
        # Démontage de la ruche SOFTWARE
        # ------------------------------------------

        @{

            Id   = "DismountSoftwareHive"
            Name = "Démontage de la ruche SOFTWARE"

            Action = {

                param($Context)

                Dismount-RegistryHive `
                    -Context $Context `
                    -Hive SOFTWARE

            }

        },


        # ------------------------------------------
        # Démontage du WIM
        # ------------------------------------------

        @{

            Id   = "DismountWim"
            Name = "Démontage du WIM"

            Action = {

                param($Context)

                Dismount-Wim `
                    -Context $Context

            }

        },


        # ------------------------------------------
        # Démontage ISO
        # ------------------------------------------

        @{

            Id   = "DismountIso"
            Name = "Démontage ISO"

            Action = {

                param($Context)

                Dismount-Iso `
                    -Context $Context

            }

        }

    )
}


# ==========================================
# Exécute le pipeline du Build
# ==========================================

function Invoke-BuildPipeline {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [object[]]$Pipeline = (Get-BuildPipeline)

    )


    # ------------------------------------------
    # Phase Pipeline
    # ------------------------------------------

    $Context = Start-BuildPhase `
        -Context $Context `
        -Name "Pipeline"


    $PipelineSucceeded = $false
    $PipelineError = $null


    try {

        foreach ($Step in $Pipeline) {

            # ------------------------------------------
            # Déjà exécutée ?
            # ------------------------------------------

            if (
                $Context.BuildState.Pipeline.Completed -contains $Step.Name
            ) {

                Write-Log (
                    "Étape déjà exécutée : $($Step.Name)"
                ) INFO

                continue

            }


            # ------------------------------------------
            # Condition
            # ------------------------------------------

            if ($Step.ContainsKey("Condition")) {

                $Execute = & $Step.Condition $Context

                if (-not $Execute) {

                    Write-Log (
                        "Étape ignorée : $($Step.Name)"
                    ) INFO

                    continue

                }

            }


            # ------------------------------------------
            # Exécution
            # ------------------------------------------

            $Context = Invoke-BuildStep `
                -Context $Context `
                -Name $Step.Name `
                -Action $Step.Action

        }


        # ------------------------------------------
        # Toutes les étapes ont réussi
        # ------------------------------------------

        $PipelineSucceeded = $true

    }
    catch {

        $PipelineError = $_

        $Context.BuildState.Pipeline.Current = $null
        $Context.BuildState.Status = "PipelineFailed"

        Write-Log (
            "Pipeline en échec : $($_.Exception.Message)"
        ) ERROR

    }
    finally {

        # ------------------------------------------
        # Fin de la phase Pipeline
        # ------------------------------------------

        if ($Context.Report.CurrentPhase) {

            try {

                $Context = Complete-BuildPhase `
                    -Context $Context

            }
            catch {

                Write-Log (
                    "Erreur lors de la clôture de la phase Pipeline : $($_.Exception.Message)"
                ) ERROR

                if ($PipelineSucceeded) {

                    $PipelineSucceeded = $false
                    $PipelineError = $_

                }

            }

        }

    }


    # ------------------------------------------
	# Etat final
	# ------------------------------------------

	if ($PipelineSucceeded) {

		$Context.BuildState.Pipeline.Current = $null
		$Context.BuildState.Status = "PipelineCompleted"

		$Context.BuildState.Success = $true
		$Context.BuildState.Completed = $true

		Write-Log (
			"Pipeline terminé avec succès."
		) SUCCESS

	}
    else {

        $Context.BuildState.Pipeline.Current = $null
        $Context.BuildState.Status = "PipelineFailed"

        if ($null -ne $PipelineError) {

            throw $PipelineError

        }

    }


    return $Context
}


# ==========================================
# Export des fonctions
# ==========================================

Export-ModuleMember -Function @(
    "Invoke-BuildStep",
    "Get-BuildPipeline",
    "Invoke-BuildPipeline"
)