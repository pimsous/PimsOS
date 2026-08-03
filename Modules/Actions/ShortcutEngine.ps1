# ==========================================
# Module : ShortcutEngine
# Projet : PimsOS Builder
# Version : 1.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Applique une action Shortcut
# --------------------------------------------------

function Invoke-ShortcutAction {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [psobject]$Action

    )

    Write-Log (
        "Shortcut : {0}" -f
        $Action.Id
    )

    $Context.BuildState.Status = "ApplyingShortcut"

    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {

        if ([string]::IsNullOrWhiteSpace($Action.Target)) {

            throw "La cible du raccourci est obligatoire."

        }

        $Context = Invoke-Shortcut `
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

        if ($Context.Statistics.PSObject.Properties.Match("ShortcutsProcessed").Count -gt 0) {

            $Context.Statistics.ShortcutsProcessed++

        }

        $Context.BuildState.Status = "ShortcutApplied"

        Write-Log (
            "Raccourci '$($Action.Target)' traité."
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

        $Context.BuildState.Status = "ShortcutFailed"

        throw (
            "Erreur lors du traitement du raccourci '{0}'.`r`n{1}" -f
            $Action.Id,
            $_.Exception.Message
        )

    }

}