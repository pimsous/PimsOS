# ==========================================
# Module : Pipeline
# Projet : PimsOS Builder
# Version : 0.3.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

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

    if (-not $Context.Report.CurrentPhase) {

        throw "Aucune phase active. Appelez Start-BuildPhase avant Invoke-BuildStep."

    }

    Write-Log "Étape : $Name"

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

        $Result = & $Action $Context

        # ------------------------------------------
        # Mise à jour éventuelle du BuildContext
        # ------------------------------------------

        if (
            $null -ne $Result -and
            $Result.PSObject.Properties.Match("Report").Count -gt 0
        ) {

            $Context = $Result

        }

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

        if ($Context.BuildState.Pipeline.Completed -notcontains $Name) {

            $Context.BuildState.Pipeline.Completed += $Name

        }

        $Context.BuildState.Pipeline.Current = $null

        Write-Log "$Name terminé en $($Stopwatch.Elapsed)" SUCCESS

    }
    catch {

        $Stopwatch.Stop()

        # ------------------------------------------
        # Rapport
        # ------------------------------------------

        $Context.Report.CurrentPhase.Success = $false

        $Context.Report.CurrentPhase.Errors += $_.Exception.Message

        $Context.Report.CurrentPhase.Steps += [PSCustomObject]@{

            Name     = $Name
            Success  = $false
            Duration = $Stopwatch.Elapsed

        }

        # ------------------------------------------
        # Etat du pipeline
        # ------------------------------------------

        if ($Context.BuildState.Pipeline.Failed -notcontains $Name) {

            $Context.BuildState.Pipeline.Failed += $Name

        }

        $Context.BuildState.Pipeline.Current = $null

        Write-Log "$Name : $($_.Exception.Message)" ERROR

        throw

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

        @{
            Id   = "MountIso"
            Name = "Montage ISO"

            Action = {

                param($Context)

                Mount-Iso `
                    -Context $Context

            }

        },

        @{
            Id   = "DetectWim"
            Name = "Détection du WIM"

            Action = {

                param($Context)

                Get-WimFile `
                    -Context $Context

            }

        },

        @{
            Id   = "CopyWim"
            Name = "Copie du WIM"

            Condition = {

                param($Context)

                -not $Context.BuildState.Recovery.Wim.CanReuse

            }

            Action = {

                param($Context)

                Copy-WimToWorkspace `
                    -Context $Context

            }

        },

        @{
            Id   = "ReadWimImages"
            Name = "Lecture des images WIM"

            Action = {

                param($Context)

                Get-WimImages `
                    -Context $Context

            }

        },

        @{
            Id   = "SelectImage"
            Name = "Sélection de l'image Windows"

            Action = {

                param($Context)

                Select-WimImage `
                    -Context $Context

            }

        },

        @{
            Id   = "MountWim"
            Name = "Montage du WIM"

            Action = {

                param($Context)

                Mount-Wim `
                    -Context $Context

            }

        },

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

        @{
			Id   = "LoadConfiguration"
			Name = "Chargement de la configuration"

			Action = {

				param($Context)

				return Get-Configuration `
					-Context $Context `
					-Profile $Context.ConfigurationProfile

			}

		},

        @{
            Id   = "ApplyConfiguration"
            Name = "Application de la configuration"

            Action = {

                param($Context)

                Invoke-Configuration `
                    -Context $Context `
                    -Configuration $Context.Configuration

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

    try {

        foreach ($Step in $Pipeline) {

            # ------------------------------------------
            # Déjà exécutée ?
            # ------------------------------------------

            if ($Context.BuildState.Pipeline.Completed -contains $Step.Name) {

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
        # Pipeline terminé
        # ------------------------------------------

        $Context.BuildState.Pipeline.Current = $null
        $Context.BuildState.Status = "PipelineCompleted"

        return $Context

    }
    finally {

        # ------------------------------------------
        # Fin de la phase Pipeline
        # ------------------------------------------

        if ($Context.Report.CurrentPhase) {

            $Context = Complete-BuildPhase `
                -Context $Context

        }

    }

}