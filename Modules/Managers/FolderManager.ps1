# ==========================================
# Module : FolderManager
# Projet : PimsOS Builder
# Version : 1.0.1
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Gestionnaires disponibles
# --------------------------------------------------

$script:FolderProviders = [ordered]@{

    Native = "Invoke-NativeFolder"

}

# --------------------------------------------------
# Applique une opération sur un dossier
# --------------------------------------------------

function Invoke-Folder {

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

        throw "Le fournisseur de dossiers est obligatoire."

    }

    if ([string]::IsNullOrWhiteSpace($Action.Path)) {

        throw "Le chemin du dossier est obligatoire."

    }

    # --------------------------------------------------
    # Recherche du gestionnaire
    # --------------------------------------------------

    if (-not $script:FolderProviders.Contains($Action.Provider)) {

        throw (
            "Le fournisseur '{0}' n'est pas pris en charge." -f
            $Action.Provider
        )

    }

    $Handler = $script:FolderProviders[$Action.Provider]

    if (-not (Get-Command `
        -Name $Handler `
        -ErrorAction SilentlyContinue)) {

        throw (
            "Le gestionnaire '{0}' est introuvable." -f
            $Handler
        )

    }

    Write-Log (
        "Folder Provider : {0}" -f
        $Action.Provider
    )

    Write-Log (
        "Path : {0}" -f
        $Action.Path
    )

    if ($Action.Destination) {

        Write-Log (
            "Destination : {0}" -f
            $Action.Destination
        )

    }

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

function Get-FolderProviders {

    [CmdletBinding()]
    param()

    return $script:FolderProviders.Keys |
        Sort-Object

}

# --------------------------------------------------
# Enregistre un fournisseur
# --------------------------------------------------

function Register-FolderProvider {

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

    $script:FolderProviders[$Name] = $Handler

}

# --------------------------------------------------
# Réinitialise les fournisseurs
# Utilisé par les tests
# --------------------------------------------------

function Reset-FolderProviders {

    [CmdletBinding()]
    param()

    $script:FolderProviders = [ordered]@{

        Native = "Invoke-NativeFolder"

    }

}