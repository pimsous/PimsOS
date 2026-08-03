# ==========================================
# Module : DriverManager
# Projet : PimsOS Builder
# Version : 1.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Gestionnaires disponibles
# --------------------------------------------------

$script:DriverProviders = @{

    DISM  = "Invoke-DismDriver"

    PNP   = "Invoke-PnpDriver"

}

# --------------------------------------------------
# Applique un pilote
# --------------------------------------------------

function Invoke-Driver {

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

        throw "Le fournisseur du pilote est obligatoire."

    }

    if ([string]::IsNullOrWhiteSpace($Action.Source)) {

        throw "La source du pilote est obligatoire."

    }

    # --------------------------------------------------
    # Recherche du gestionnaire
    # --------------------------------------------------

    if (-not $script:DriverProviders.ContainsKey($Action.Provider)) {

        throw (
            "Le fournisseur de pilotes '{0}' n'est pas pris en charge." -f
            $Action.Provider
        )

    }

    $Handler = $script:DriverProviders[$Action.Provider]

    if (-not (Get-Command `
        -Name $Handler `
        -ErrorAction SilentlyContinue)) {

        throw (
            "Le gestionnaire '{0}' est introuvable." -f
            $Handler
        )

    }

    Write-Log (
        "Driver Provider : {0}" -f
        $Action.Provider
    )

    Write-Log (
        "Source : {0}" -f
        $Action.Source
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

function Get-DriverProviders {

    [CmdletBinding()]
    param()

    return $script:DriverProviders.Keys |
        Sort-Object

}

# --------------------------------------------------
# Enregistre un nouveau fournisseur
# --------------------------------------------------

function Register-DriverProvider {

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

    $script:DriverProviders[$Name] = $Handler

}

# --------------------------------------------------
# Réinitialise les fournisseurs
# Utilisé par les tests
# --------------------------------------------------

function Reset-DriverProviders {

    [CmdletBinding()]
    param()

    $script:DriverProviders = @{

        DISM = "Invoke-DismDriver"

        PNP  = "Invoke-PnpDriver"

    }

}