# ==========================================
# Module : ActionEngine
# Projet : PimsOS Builder
# Version : 1.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Initialise les propriétés runtime d'une action
# --------------------------------------------------

function Initialize-ActionRuntimeProperties {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Action

    )

    # Propriétés utilisées par Invoke-Action
    $Properties = @{

        Executed       = $false
        Success        = $false
        Duration       = [TimeSpan]::Zero
        Error          = $null
        ContinueOnError = $false

    }

    foreach ($PropertyName in $Properties.Keys) {

        $Property = $Action.PSObject.Properties[$PropertyName]

        if ($null -eq $Property) {

            $Action | Add-Member `
                -MemberType NoteProperty `
                -Name $PropertyName `
                -Value $Properties[$PropertyName]

        }

    }

    return $Action
}

# --------------------------------------------------
# Applique une action
# --------------------------------------------------

function Invoke-Action {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [psobject]$Action

    )

    # --------------------------------------------------
    # Initialisation des propriétés runtime
    # --------------------------------------------------

    $Action = Initialize-ActionRuntimeProperties `
        -Action $Action

    # --------------------------------------------------
    # Journalisation
    # --------------------------------------------------

    Write-Log (
        "Action : {0} ({1})" -f
        $Action.Id,
        $Action.Type
    )

    # --------------------------------------------------
    # Etat du Build
    # --------------------------------------------------

    $Context.BuildState.Status = "ApplyingAction"

    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {

        # --------------------------------------------------
        # Recherche du moteur
        # --------------------------------------------------

        $Handler = Get-ActionHandler `
            -Type $Action.Type

        if (-not $Handler) {

            throw (
                "Le type d'action '{0}' n'est pas pris en charge." -f
                $Action.Type
            )

        }

        # --------------------------------------------------
        # Exécution
        # --------------------------------------------------

        $Context = & $Handler `
            -Context $Context `
            -Action $Action

        $Stopwatch.Stop()

        # --------------------------------------------------
        # Etat de l'action
        # --------------------------------------------------

        $Action.Executed = $true
        $Action.Success = $true
        $Action.Duration = $Stopwatch.Elapsed
        $Action.Error = $null

        # --------------------------------------------------
        # Statistiques
        # --------------------------------------------------

        if (
            $null -ne $Context.Statistics -and
            $Context.Statistics.PSObject.Properties.Match("ActionsProcessed").Count -gt 0
        ) {

            $Context.Statistics.ActionsProcessed++

        }

        # --------------------------------------------------
        # Etat du Build
        # --------------------------------------------------

        $Context.BuildState.Status = "ActionApplied"

        return $Context

    }
    catch {

        $Stopwatch.Stop()

        # --------------------------------------------------
        # Etat de l'action
        # --------------------------------------------------

        $Action.Executed = $true
        $Action.Success = $false
        $Action.Duration = $Stopwatch.Elapsed
        $Action.Error = $_.Exception.Message

        # --------------------------------------------------
        # Statistiques
        # --------------------------------------------------

        if (
            $null -ne $Context.Statistics -and
            $Context.Statistics.PSObject.Properties.Match("Errors").Count -gt 0
        ) {

            $Context.Statistics.Errors++

        }

        # --------------------------------------------------
        # Rapport
        # --------------------------------------------------

        $Context = Add-ReportError `
            -Context $Context `
            -Message (
                "Action '{0}' : {1}" -f
                $Action.Id,
                $_.Exception.Message
            )

        # --------------------------------------------------
        # Etat du Build
        # --------------------------------------------------

        $Context.BuildState.Status = "ActionFailed"

        # --------------------------------------------------
        # ContinueOnError
        # --------------------------------------------------

        if ($Action.ContinueOnError) {

            Write-Log (
                "Erreur ignorée : $($_.Exception.Message)"
            ) WARNING

            return $Context

        }

        throw (
            "Erreur lors de l'exécution de l'action '{0}'.`r`n{1}" -f
            $Action.Id,
            $_.Exception.Message
        )

    }
}