# ==========================================
# Module : FeatureManager
# Projet : PimsOS Builder
# Version : 1.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Gestionnaires disponibles
# --------------------------------------------------

$script:FeatureProviders = @{

    DISM = "Invoke-DismFeature"

}

# --------------------------------------------------
# Applique une fonctionnalité Windows
# --------------------------------------------------

function Invoke-Feature {

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

        throw "Le fournisseur de fonctionnalités est obligatoire."

    }

    if ([string]::IsNullOrWhiteSpace($Action.Name)) {

        throw "Le nom de la fonctionnalité est obligatoire."

    }

    # --------------------------------------------------
    # Recherche du gestionnaire
    # --------------------------------------------------

    if (-not $script:FeatureProviders.ContainsKey($Action.Provider)) {

        throw (
            "Le fournisseur '{0}' n'est pas pris en charge." -f
            $Action.Provider
        )

    }

    $Handler = $script:FeatureProviders[$Action.Provider]

    if (-not (Get-Command `
        -Name $Handler `
        -ErrorAction SilentlyContinue)) {

        throw (
            "Le gestionnaire '{0}' est introuvable." -f
            $Handler
        )

    }

    Write-Log (
        "Feature Provider : {0}" -f
        $Action.Provider
    )

    Write-Log (
        "Feature : {0}" -f
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

function Get-FeatureProviders {

    [CmdletBinding()]
    param()

    return $script:FeatureProviders.Keys |
        Sort-Object

}

# --------------------------------------------------
# Enregistre un fournisseur
# --------------------------------------------------

function Register-FeatureProvider {

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

    $script:FeatureProviders[$Name] = $Handler

}

# --------------------------------------------------
# Réinitialise les fournisseurs
# Utilisé par les tests
# --------------------------------------------------

function Reset-FeatureProviders {

    [CmdletBinding()]
    param()

    $script:FeatureProviders = @{

        DISM = "Invoke-DismFeature"

    }

}