# ==========================================
# Module : FileManager
# Projet : PimsOS Builder
# Version : 1.0.1
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Gestionnaires disponibles
# --------------------------------------------------

$script:FileProviders = [ordered]@{

    Native = "Invoke-NativeFile"

}

# --------------------------------------------------
# Applique une opération sur un fichier
# --------------------------------------------------

function Invoke-File {

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

        throw "Le fournisseur de fichiers est obligatoire."

    }

    if ([string]::IsNullOrWhiteSpace($Action.Source)) {

        throw "Le fichier source est obligatoire."

    }

    if ([string]::IsNullOrWhiteSpace($Action.Destination)) {

        throw "La destination est obligatoire."

    }

    # --------------------------------------------------
    # Recherche du gestionnaire
    # --------------------------------------------------

    if (-not $script:FileProviders.Contains($Action.Provider)) {

        throw (
            "Le fournisseur '{0}' n'est pas pris en charge." -f
            $Action.Provider
        )

    }

    $Handler = $script:FileProviders[$Action.Provider]

    if (-not (Get-Command `
        -Name $Handler `
        -ErrorAction SilentlyContinue)) {

        throw (
            "Le gestionnaire '{0}' est introuvable." -f
            $Handler
        )

    }

    Write-Log (
        "File Provider : {0}" -f
        $Action.Provider
    )

    Write-Log (
        "Source : {0}" -f
        $Action.Source
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

function Get-FileProviders {

    [CmdletBinding()]
    param()

    return $script:FileProviders.Keys |
        Sort-Object

}

# --------------------------------------------------
# Enregistre un fournisseur
# --------------------------------------------------

function Register-FileProvider {

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

    $script:FileProviders[$Name] = $Handler

}

# --------------------------------------------------
# Réinitialise les fournisseurs
# Utilisé par les tests
# --------------------------------------------------

function Reset-FileProviders {

    [CmdletBinding()]
    param()

    $script:FileProviders = [ordered]@{

        Native = "Invoke-NativeFile"

    }

}