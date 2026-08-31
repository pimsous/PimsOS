# ==========================================
# Module : Engine
# Projet : PimsOS Builder
# Version : 1.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Applique une configuration complète
# --------------------------------------------------

function Invoke-Configuration {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [object[]]$Configuration

    )

    Write-Log "Application de la configuration..."

    # --------------------------------------------------
    # Etat du Build
    # --------------------------------------------------

    $Context.BuildState.Status = "ApplyingConfiguration"

    if (-not $Configuration -or $Configuration.Count -eq 0) {

        Write-Log "Aucun tweak à appliquer." WARNING

        return $Context

    }

    foreach ($Tweak in $Configuration) {

        if ($null -eq $Tweak) {
            throw "La configuration contient un tweak null."
        }

        if ($Tweak.PSObject.Properties.Name -notcontains "Enabled") {
            throw (
                "Tweak sans propriété 'Enabled' : Id='{0}', Name='{1}', Type='{2}'." -f
                $(if ($Tweak.PSObject.Properties["Id"]) { $Tweak.Id } else { "<absent>" }),
                $(if ($Tweak.PSObject.Properties["Name"]) { $Tweak.Name } else { "<absent>" }),
                $Tweak.GetType().FullName
            )
        }

        if (-not [bool]$Tweak.Enabled) {

			Write-Log (
				"Tweak ignoré : $($Tweak.Name)"
			) INFO

			continue

		}

		$Context = Invoke-Tweak `
			-Context $Context `
			-Tweak $Tweak

	}

    $Context.BuildState.Image.TweaksApplied = $true
    $Context.BuildState.Status = "ConfigurationApplied"

    Write-Log "Configuration appliquée." SUCCESS

    return $Context

}

# --------------------------------------------------
# Applique un tweak
# --------------------------------------------------

function Invoke-Tweak {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [psobject]$Tweak

    )

    Write-Log "Application du tweak : $($Tweak.Name)"

    if (-not $Tweak.Actions -or $Tweak.Actions.Count -eq 0) {

        Write-Log "Aucune action à appliquer." WARNING

        $Tweak.Result = "Skipped"

        return $Context

    }

    Write-Log (
        "{0} action(s) détectée(s)." -f $Tweak.Actions.Count
    )

    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {

        foreach ($Action in @($Tweak.Actions)) {

            if ($null -eq $Action) {
                throw ("Le tweak '{0}' contient une action null." -f $Tweak.Id)
            }

            if ($Action.PSObject.Properties.Name -notcontains "Enabled") {
                throw (
                    "Action sans propriété 'Enabled' dans le tweak '{0}' : Id='{1}', Type='{2}'." -f
                    $Tweak.Id,
                    $(if ($Action.PSObject.Properties["Id"]) { $Action.Id } else { "<absent>" }),
                    $(if ($Action.PSObject.Properties["Type"]) { $Action.Type } else { "<absent>" })
                )
            }

            if (-not [bool]$Action.Enabled) {

                continue

            }

            $Context = Invoke-Action `
                -Context $Context `
                -Action $Action

            $Action.Executed = $true
            $Action.Success = $true

            $Tweak.Statistics.Executed++

        }

        $Stopwatch.Stop()

        $Tweak.Applied = $true
        $Tweak.Result = "Success"
        $Tweak.Duration = $Stopwatch.Elapsed

        $Context.Statistics.TweaksApplied++

        Write-Log "Tweak '$($Tweak.Name)' appliqué." SUCCESS

    }
    catch {

        $Stopwatch.Stop()

        $Tweak.Applied = $false
        $Tweak.Result = "Failed"
        $Tweak.Duration = $Stopwatch.Elapsed

        $Tweak.Errors += $_.Exception.Message

        $Tweak.Statistics.Failed++

        Write-Log (
            "Le tweak '$($Tweak.Name)' a échoué : $($_.Exception.Message)"
        ) ERROR

        throw

    }

    return $Context

}