# ==========================================
# Module : CapabilityManager
# Projet : PimsOS Builder
# Version : 1.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Gestionnaires disponibles
# --------------------------------------------------

$script:CapabilityProviders = @{

    DISM = "Invoke-DismCapability"

}

# --------------------------------------------------
# Applique une Capability Windows
# --------------------------------------------------

function Invoke-Capability {

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

        throw "Le fournisseur des capacités Windows est obligatoire."

    }

    if ([string]::IsNullOrWhiteSpace($Action.Name)) {

        throw "Le nom de la capacité Windows est obligatoire."

    }

    # --------------------------------------------------
    # Recherche du gestionnaire
    # --------------------------------------------------

    if (-not $script:CapabilityProviders.ContainsKey($Action.Provider)) {

        throw (
            "Le fournisseur '{0}' n'est pas pris en charge." -f
            $Action.Provider
        )

    }

    $Handler = $script:CapabilityProviders[$Action.Provider]

    if (-not (Get-Command `
        -Name $Handler `
        -ErrorAction SilentlyContinue)) {

        throw (
            "Le gestionnaire '{0}' est introuvable." -f
            $Handler
        )

    }

    Write-Log (
        "Capability Provider : {0}" -f
        $Action.Provider
    )

    Write-Log (
        "Capability : {0}" -f
        $Action.Name
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

function Get-CapabilityProviders {

    [CmdletBinding()]
    param()

    return $script:CapabilityProviders.Keys |
        Sort-Object

}

# --------------------------------------------------
# Enregistre un fournisseur
# --------------------------------------------------

function Register-CapabilityProvider {

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

    $script:CapabilityProviders[$Name] = $Handler

}

# --------------------------------------------------
# Réinitialise les fournisseurs
# Utilisé par les tests
# --------------------------------------------------

function Reset-CapabilityProviders {

    [CmdletBinding()]
    param()

    $script:CapabilityProviders = @{

        DISM = "Invoke-DismCapability"

    }

}