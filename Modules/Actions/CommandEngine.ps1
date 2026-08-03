# ==========================================
# Module : CommandEngine
# Projet : PimsOS Builder
# Version : 1.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Applique une action Command
# --------------------------------------------------

function Invoke-CommandAction {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [psobject]$Action

    )

    Write-Log (
        "Command : {0}" -f
        $Action.Id
    )

    # --------------------------------------------------
    # Etat du Build
    # --------------------------------------------------

    $Context.BuildState.Status = "ApplyingCommand"

    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {

        # --------------------------------------------------
        # Validation
        # --------------------------------------------------

        if ([string]::IsNullOrWhiteSpace($Action.Command)) {

            throw "La commande est obligatoire."

        }

        # --------------------------------------------------
        # Application
        # --------------------------------------------------

        $Context = Invoke-Command `
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
            $Context.Statistics.PSObject.Properties.Match("CommandsProcessed").Count -gt 0
        ) {

            $Context.Statistics.CommandsProcessed++

        }

        # --------------------------------------------------
        # Etat du Build
        # --------------------------------------------------

        $Context.BuildState.Status = "CommandApplied"

        Write-Log (
            "Commande '$($Action.Id)' exécutée."
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

        $Context.BuildState.Status = "CommandFailed"

        throw (
            "Erreur lors de l'exécution de la commande '{0}'.`r`n{1}" -f
            $Action.Id,
            $_.Exception.Message
        )

    }

}