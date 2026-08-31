# ==========================================
# Module : Package / Winget
# Projet : PimsOS Builder
# ==========================================

Set-StrictMode -Version Latest

# Provider volontairement séparé du moteur générique Package.
# Winget sera également utilisé comme base pour le flux Microsoft Store.
function Invoke-WingetPackage {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [psobject]$Action
    )

    throw (
        "Le provider Winget est déclaré mais pas encore implémenté. " +
        "Il sera activé avec l'intégration des applications et du Microsoft Store."
    )
}
