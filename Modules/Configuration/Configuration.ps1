# ==========================================
# Module : Configuration
# Projet : PimsOS Builder
# Version : 1.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Construit une configuration complète
# --------------------------------------------------

function Get-Configuration {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [string]$Profile

    )

    Write-Log "Construction de la configuration..."

    # --------------------------------------------------
    # Chargement des tweaks
    # --------------------------------------------------

    $Tweaks = Get-TweakDefinitions `
        -Context $Context

    if (@($Tweaks).Count -eq 0) {

        throw "Aucun tweak n'a été chargé."

    }

    # --------------------------------------------------
    # Validation
    # --------------------------------------------------

    Test-TweakDefinitions `
        -Context $Context `
        -Tweaks $Tweaks

    # --------------------------------------------------
    # Chargement du profil
    # --------------------------------------------------

    $ProfileObject = Load-Profile `
        -Context $Context `
        -Name $Profile

    if ($null -eq $ProfileObject) {

        throw "Le profil '$Profile' n'a pas pu être chargé."

    }

    Write-Log (
        "Profil chargé : $Profile"
    ) INFO

    # --------------------------------------------------
    # Fusion
    # --------------------------------------------------

    $Configuration = Merge-Profile `
        -Context $Context `
        -Tweaks $Tweaks `
        -Profile $ProfileObject

    if ($null -eq $Configuration) {

        throw "La fusion du profil a échoué."

    }

    # --------------------------------------------------
    # Mise à jour du contexte
    # --------------------------------------------------

    $Context.Configuration = $Configuration

    $Context.BuildState.Image.TweaksLoaded = $true
    $Context.BuildState.Image.ProfileLoaded = $true
    $Context.BuildState.Image.ProfileMerged = $true
    $Context.BuildState.Image.ConfigLoaded = $true

    Write-Log (
        "{0} tweak(s) sélectionné(s)." -f @($Configuration).Count
    ) SUCCESS

    Write-Log "Configuration construite avec succès." SUCCESS

    return $Context

}