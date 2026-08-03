# ==========================================
# Module : ServiceEngine
# Projet : PimsOS Builder
# Version : 1.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

$script:ModuleVersion = "1.0.0"

# --------------------------------------------------
# Applique une action Service
# --------------------------------------------------

function Invoke-ServiceAction {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [psobject]$Action

    )

    Write-Log (
        "Service : {0}" -f $Action.Id
    )

    # --------------------------------------------------
    # Etat du Build
    # --------------------------------------------------

    $Context.BuildState.Status = "ApplyingService"

    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {

        # --------------------------------------------------
        # Validation
        # --------------------------------------------------

        if ([string]::IsNullOrWhiteSpace($Action.Name)) {

            throw "Le nom du service est obligatoire."

        }

        if ([string]::IsNullOrWhiteSpace($Action.StartupType)) {

            throw "Le type de démarrage est obligatoire."

        }

        if (-not (Test-ServiceExists -Name $Action.Name)) {

            throw "Le service '$($Action.Name)' est introuvable."

        }

        # --------------------------------------------------
        # Informations
        # --------------------------------------------------

        Write-Log (
            "Service     : {0}" -f $Action.Name
        )

        Write-Log (
            "StartupType : {0}" -f $Action.StartupType
        )

        if ($Action.PSObject.Properties.Match("Stop").Count -gt 0) {

            Write-Log (
                "Stop        : {0}" -f $Action.Stop
            )

        }

        # --------------------------------------------------
        # Configuration du service
        # --------------------------------------------------

        $Context = Set-ServiceStartupType `
            -Context $Context `
            -Action $Action

        # --------------------------------------------------
        # Arrêt éventuel
        # --------------------------------------------------

        if (
            $Action.PSObject.Properties.Match("Stop").Count -gt 0 -and
            $Action.Stop
        ) {

            $Context = Stop-ServiceSafe `
                -Context $Context `
                -Action $Action

        }

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
        # Etat du Build
        # --------------------------------------------------

        $Context.BuildState.Status = "ServiceApplied"

        Write-Log "Action Service appliquée avec succès." SUCCESS

        return $Context

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

        $Context.BuildState.Status = "ServiceFailed"

        throw (
            "Erreur lors de l'application de l'action Service '{0}'.`r`n{1}" -f
            $Action.Id,
            $_.Exception.Message
        )

    }

}