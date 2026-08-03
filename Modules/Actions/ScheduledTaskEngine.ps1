# ==========================================
# Module : ScheduledTaskEngine
# Projet : PimsOS Builder
# Version : 1.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Applique une action ScheduledTask
# --------------------------------------------------

function Invoke-ScheduledTaskAction {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [psobject]$Action

    )

    Write-Log (
        "ScheduledTask : {0}" -f
        $Action.Id
    )

    $Context.BuildState.Status = "ApplyingScheduledTask"

    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {

        if ([string]::IsNullOrWhiteSpace($Action.Name)) {

            throw "Le nom de la tâche planifiée est obligatoire."

        }

        $Context = Invoke-ScheduledTask `
            -Context $Context `
            -Action $Action

        $Stopwatch.Stop()

        $Action.Success = $true

        if ($Action.PSObject.Properties.Match("Duration").Count -gt 0) {

            $Action.Duration = $Stopwatch.Elapsed

        }

        if ($Action.PSObject.Properties.Match("Error").Count -gt 0) {

            $Action.Error = $null

        }

        if ($Context.Statistics.PSObject.Properties.Match("ScheduledTasksProcessed").Count -gt 0) {

            $Context.Statistics.ScheduledTasksProcessed++

        }

        $Context.BuildState.Status = "ScheduledTaskApplied"

        Write-Log (
            "Tâche planifiée '$($Action.Name)' appliquée."
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

        $Context.BuildState.Status = "ScheduledTaskFailed"

        throw (
            "Erreur lors de l'application de la tâche planifiée '{0}'.`r`n{1}" -f
            $Action.Id,
            $_.Exception.Message
        )

    }

}