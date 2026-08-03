# ==========================================
# Module : CapabilityEngine
# Projet : PimsOS Builder
# Version : 1.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Applique une action Capability
# --------------------------------------------------

function Invoke-CapabilityAction {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [psobject]$Action

    )

    Write-Log (
        "Capability : {0}" -f
        $Action.Id
    )

    # --------------------------------------------------
    # Etat du Build
    # --------------------------------------------------

    $Context.BuildState.Status = "ApplyingCapability"

    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {

        # --------------------------------------------------
        # Validation
        # --------------------------------------------------

        if ([string]::IsNullOrWhiteSpace($Action.Name)) {

            throw "Le nom de la capability est obligatoire."

        }

        # --------------------------------------------------
        # Application
        # --------------------------------------------------

        $Context = Invoke-Capability `
            -Context $Context `
            -Action $Action

        $Stopwatch.Stop()

        # --------------------------------------------------
        # Etat de l'action
        # --------------------------------------------------

        $Action.Success = $true

        if ($Action.PSObject.Properties.Match("Duration").Count -gt 0) {

            $Action.Duration = $Stopwatch.Elapsed

        }

        if ($Action.PSObject.Properties.Match("Error").Count -gt 0) {

            $Action.Error = $null

        }

        # --------------------------------------------------
        # Statistiques
        # --------------------------------------------------

        if (
            $Context.Statistics.PSObject.Properties.Match("CapabilitiesProcessed").Count -gt 0
        ) {

            $Context.Statistics.CapabilitiesProcessed++

        }

        # --------------------------------------------------
        # Etat du Build
        # --------------------------------------------------

        $Context.BuildState.Status = "CapabilityApplied"

        Write-Log (
            "Capability '$($Action.Name)' appliquée."
        ) SUCCESS

        return $Context

    }
    catch {

        $Stopwatch.Stop()

        $Action.Success = $false

        if ($Action.PSObject.Properties.Match("Duration").Count -gt 0) {

            $Action.Duration = $Stopwatch.Elapsed

        }

        if ($Action.PSObject.Properties.Match("Error").Count -gt 0) {

            $Action.Error = $_.Exception.Message

        }

        $Context.BuildState.Status = "CapabilityFailed"

        throw (
            "Erreur lors de l'application de la capability '{0}'.`r`n{1}" -f
            $Action.Id,
            $_.Exception.Message
        )

    }

}