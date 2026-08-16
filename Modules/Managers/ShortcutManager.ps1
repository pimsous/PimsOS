# ==========================================
# Module : ShortcutManager
# Projet : PimsOS Builder
# Version : 1.0.1
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Gestionnaires disponibles
# --------------------------------------------------

$script:ShortcutProviders = [ordered]@{

    Native = "Invoke-NativeShortcut"

}

# --------------------------------------------------
# Applique un raccourci
# --------------------------------------------------

function Invoke-Shortcut {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [psobject]$Action

    )

    # --------------------------------------------------
    # Validation
    # --------------------------------------------------

    if ([string]::IsNullOrWhiteSpace($Action.Provider)) {

        throw "Le fournisseur est obligatoire."

    }

    if ([string]::IsNullOrWhiteSpace($Action.Target)) {

        throw "La cible du raccourci est obligatoire."

    }

    if ([string]::IsNullOrWhiteSpace($Action.Destination)) {

        throw "La destination du raccourci est obligatoire."

    }

    # --------------------------------------------------
    # Recherche du gestionnaire
    # --------------------------------------------------

    if (-not $script:ShortcutProviders.Contains($Action.Provider)) {

        throw (
            "Le fournisseur '{0}' n'est pas pris en charge." -f
            $Action.Provider
        )

    }

    $Handler = $script:ShortcutProviders[$Action.Provider]

    if (-not (Get-Command `
        -Name $Handler `
        -ErrorAction SilentlyContinue)) {

        throw (
            "Le gestionnaire '{0}' est introuvable." -f
            $Handler
        )

    }

    Write-Log (
        "Shortcut Provider : {0}" -f
        $Action.Provider
    )

    Write-Log (
        "Target : {0}" -f
        $Action.Target
    )

    Write-Log (
        "Destination : {0}" -f
        $Action.Destination
    )

    # --------------------------------------------------
    # Exécution
    # --------------------------------------------------

    return (& $Handler `
        -Context $Context `
        -Action $Action)

}

# --------------------------------------------------
# Retourne les fournisseurs disponibles
# --------------------------------------------------

function Get-ShortcutProviders {

    [CmdletBinding()]
    param()

    return $script:ShortcutProviders.Keys |
        Sort-Object

}

# --------------------------------------------------
# Enregistre un fournisseur
# --------------------------------------------------

function Register-ShortcutProvider {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Handler

    )

    if (-not (Get-Command `
        -Name $Handler `
        -ErrorAction SilentlyContinue)) {

        throw (
            "Le gestionnaire '{0}' est introuvable." -f
            $Handler
        )

    }

    $script:ShortcutProviders[$Name] = $Handler

}

# --------------------------------------------------
# Réinitialise les fournisseurs
# Utilisé par les tests
# --------------------------------------------------

function Reset-ShortcutProviders {

    [CmdletBinding()]
    param()

    $script:ShortcutProviders = [ordered]@{

        Native = "Invoke-NativeShortcut"

    }

}