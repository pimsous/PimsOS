# ==========================================
# Module : Package / Chocolatey
# Projet : PimsOS Builder
# ==========================================

Set-StrictMode -Version Latest

# Provider volontairement séparé du moteur générique Package.
# L'implémentation réelle sera ajoutée avec le flux PostInstall/cache.
function Invoke-ChocolateyPackage {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [psobject]$Action
    )

    throw (
        "Le provider Chocolatey est déclaré mais pas encore implémenté. " +
        "Il sera activé lors de l'intégration Chocolatey/PostInstall."
    )
}
