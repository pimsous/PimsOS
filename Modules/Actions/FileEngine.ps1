# ==========================================
# Module : FileEngine
# Projet : PimsOS Builder
# Version : 1.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Applique une action File
# --------------------------------------------------

function Invoke-FileAction {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [psobject]$Action

    )

    Write-Log (
        "File : {0}" -f
        $Action.Id
    )

    $Context.BuildState.Status = "ApplyingFile"

    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {

        if ([string]::IsNullOrWhiteSpace($Action.Source)) {

            throw "Le fichier source est obligatoire."

        }

        $Context = Invoke-File `
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

        if ($Context.Statistics.PSObject.Properties.Match("FilesProcessed").Count -gt 0) {

            $Context.Statistics.FilesProcessed++

        }

        $Context.BuildState.Status = "FileApplied"

        Write-Log (
            "Fichier '$($Action.Source)' traité."
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

        $Context.BuildState.Status = "FileFailed"

        throw (
            "Erreur lors du traitement du fichier '{0}'.`r`n{1}" -f
            $Action.Id,
            $_.Exception.Message
        )

    }

}