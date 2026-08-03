# ==========================================
# PimsOS
# Complete-Build.ps1
# ==========================================

function Complete-Build {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [pscustomobject]$Context,

        [Parameter(Mandatory)]
        [int]$ExitCode

    )

    if ($null -ne $Context) {

        #------------------------------------------
        # Début du nettoyage
        #------------------------------------------

        $Context.BuildState.Status = "Cleaning"

        #------------------------------------------
        # Démonter les ruches du registre
        #------------------------------------------

        if (
            $null -ne $Context.Registry -and
            $null -ne $Context.Registry.Mounted -and
            $Context.Registry.Mounted.Count -gt 0
        ) {

            foreach ($Hive in @($Context.Registry.Mounted)) {

                try {

                    $Context = Dismount-RegistryHive `
                        -Context $Context `
                        -Hive $Hive

                }
                catch {

                    Write-Log $_.Exception.Message ERROR

                }

            }

        }

        #------------------------------------------
        # Démonter le WIM
        #------------------------------------------

        if (
            $null -ne $Context.WIM -and
            $null -ne $Context.BuildState.Image -and
            $Context.BuildState.Image.WimMounted
        ) {

            try {

                $Context = Dismount-Wim `
                    -Context $Context

            }
            catch {

                Write-Log $_.Exception.Message ERROR

            }

        }

        <#
        #------------------------------------------
        # Suppression du WIM temporaire
        #------------------------------------------

        if ($null -ne $Context.WIM) {

            $Context = Remove-WorkspaceImage `
                -Context $Context

        }
        #>

        #------------------------------------------
        # Démonter l'ISO
        #------------------------------------------

        if (
            $null -ne $Context.ISO -and
            $null -ne $Context.BuildState.Image -and
            $Context.BuildState.Image.IsoMounted
        ) {

            try {

                $Context = Dismount-Iso `
                    -Context $Context

            }
            catch {

                Write-Log $_.Exception.Message ERROR

            }

        }

        #------------------------------------------
        # Durée du build
        #------------------------------------------

        $Context.Project.EndTime = Get-Date

        $Context.Project.Duration =
            $Context.Project.EndTime - $Context.Project.StartTime

        Write-Log (
            "Durée : {0}" -f
            $Context.Project.Duration
        )

        #------------------------------------------
        # Réinitialisation du Recovery
        #------------------------------------------

        $Context.BuildState.Recovery.Wim = $null
        $Context.BuildState.Recovery.Iso = $null
        $Context.BuildState.Recovery.Registry = @()

        #------------------------------------------
        # Réinitialisation de l'état Image
        #------------------------------------------

        $Context.BuildState.Image.IsoMounted = $false
        $Context.BuildState.Image.WimMounted = $false
        $Context.BuildState.Image.RegistryLoaded = $false
        $Context.BuildState.Image.CurrentRegistryHive = $null

        $Context.BuildState.Image.ConfigLoaded = $false
        $Context.BuildState.Image.ProfileLoaded = $false
        $Context.BuildState.Image.ProfileMerged = $false

        $Context.BuildState.Image.TweaksLoaded = $false
        $Context.BuildState.Image.TweaksApplied = $false

        #------------------------------------------
        # Etat final du Build
        #------------------------------------------

        $Context.BuildState.Completed = $true
        $Context.BuildState.Success = ($ExitCode -eq 0)

        $Context.BuildState.Status = if ($ExitCode -eq 0) {
            "Completed"
        }
        else {
            "Failed"
        }

        Write-Log "Nettoyage des ressources terminé." SUCCESS

    }

    Write-Log (
        "Code retour : {0}" -f
        $ExitCode
    )

    Write-Log "Fin du build."

    Stop-Logger

    return $Context

}