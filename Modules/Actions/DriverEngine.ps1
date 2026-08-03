# ==========================================
# Module : DriverEngine
# Projet : PimsOS Builder
# Version : 1.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Applique une action Driver
# --------------------------------------------------

function Invoke-DriverAction {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [psobject]$Action

    )

    Write-Log (
        "Driver : {0}" -f
        $Action.Id
    )

    # --------------------------------------------------
    # Etat du Build
    # --------------------------------------------------

    $Context.BuildState.Status = "ApplyingDriver"

    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {

        # --------------------------------------------------
        # Validation
        # --------------------------------------------------

        if ([string]::IsNullOrWhiteSpace($Action.Name)) {

            throw "Le nom du pilote est obligatoire."

        }

        # --------------------------------------------------
        # Application
        # --------------------------------------------------

        $Context = Invoke-Driver `
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
            $Context.Statistics.PSObject.Properties.Match("DriversProcessed").Count -gt 0
        ) {

            $Context.Statistics.DriversProcessed++

        }

        # --------------------------------------------------
        # Etat du Build
        # --------------------------------------------------

        $Context.BuildState.Status = "DriverApplied"

        Write-Log (
            "Pilote '$($Action.Name)' appliqué."
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

        $Context.BuildState.Status = "DriverFailed"

        throw (
            "Erreur lors de l'application du pilote '{0}'.`r`n{1}" -f
            $Action.Id,
            $_.Exception.Message
        )

    }

}