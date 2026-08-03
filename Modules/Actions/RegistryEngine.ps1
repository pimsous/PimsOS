# ==========================================
# Module : RegistryEngine
# Projet : PimsOS Builder
# Version : 1.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Applique une action Registre
# --------------------------------------------------

function Invoke-RegistryAction {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [psobject]$Action

    )

    Write-Log (
        "Registry : {0}" -f $Action.Id
    )

    # --------------------------------------------------
    # Etat du Build
    # --------------------------------------------------

    $Context.BuildState.Status = "ApplyingRegistry"

    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {

        # --------------------------------------------------
        # Validation
        # --------------------------------------------------

        if ([string]::IsNullOrWhiteSpace($Action.Hive)) {

            throw "Hive non défini."

        }

        if ([string]::IsNullOrWhiteSpace($Action.Key)) {

            throw "Clé de registre non définie."

        }

        if ([string]::IsNullOrWhiteSpace($Action.Name)) {

            throw "Nom de valeur non défini."

        }

        # --------------------------------------------------
        # Application
        # --------------------------------------------------

        $Context = Set-RegistryValue `
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

        # --------------------------------------------------
        # Etat du Build
        # --------------------------------------------------

        $Context.BuildState.Status = "RegistryApplied"

        Write-Log (
            "Action registre '$($Action.Id)' appliquée."
        ) SUCCESS

    }
    catch {

        $Stopwatch.Stop()

        # --------------------------------------------------
        # Etat de l'action
        # --------------------------------------------------

        $Action.Success = $false

        if ($Action.PSObject.Properties.Match("Duration").Count -gt 0) {

            $Action.Duration = $Stopwatch.Elapsed

        }

        if ($Action.PSObject.Properties.Match("Error").Count -gt 0) {

            $Action.Error = $_.Exception.Message

        }

        # --------------------------------------------------
        # Etat du Build
        # --------------------------------------------------

        $Context.BuildState.Status = "RegistryFailed"

        throw (
            "Erreur lors de l'application de l'action registre '{0}'.`n{1}" -f
            $Action.Id,
            $_.Exception.Message
        )

    }

    return $Context

}