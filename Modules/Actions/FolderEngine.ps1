# ==========================================
# Module : FolderEngine
# Projet : PimsOS Builder
# Version : 1.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Applique une action Folder
# --------------------------------------------------

function Invoke-FolderAction {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [psobject]$Action

    )

    Write-Log (
        "Folder : {0}" -f
        $Action.Id
    )

    $Context.BuildState.Status = "ApplyingFolder"

    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {

        if ([string]::IsNullOrWhiteSpace($Action.Path)) {

            throw "Le chemin du dossier est obligatoire."

        }

        $Context = Invoke-Folder `
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

        if ($Context.Statistics.PSObject.Properties.Match("FoldersProcessed").Count -gt 0) {

            $Context.Statistics.FoldersProcessed++

        }

        $Context.BuildState.Status = "FolderApplied"

        Write-Log (
            "Dossier '$($Action.Path)' traité."
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

        $Context.BuildState.Status = "FolderFailed"

        throw (
            "Erreur lors du traitement du dossier '{0}'.`r`n{1}" -f
            $Action.Id,
            $_.Exception.Message
        )

    }

}