# ==========================================
# Module : EnvironmentManager
# Projet : PimsOS Builder
# Version : 1.0.1
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Gestionnaires disponibles
# --------------------------------------------------

$script:EnvironmentProviders = [ordered]@{

    Native = "Invoke-NativeEnvironment"

}

# --------------------------------------------------
# Applique une variable d'environnement
# --------------------------------------------------

function Invoke-Environment {

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

    if ([string]::IsNullOrWhiteSpace($Action.Name)) {

        throw "Le nom de la variable est obligatoire."

    }

    # --------------------------------------------------
    # Recherche du gestionnaire
    # --------------------------------------------------

    if (-not $script:EnvironmentProviders.Contains($Action.Provider)) {

        throw (
            "Le fournisseur '{0}' n'est pas pris en charge." -f
            $Action.Provider
        )

    }

    $Handler = $script:EnvironmentProviders[$Action.Provider]

    if (-not (Get-Command `
        -Name $Handler `
        -ErrorAction SilentlyContinue)) {

        throw (
            "Le gestionnaire '{0}' est introuvable." -f
            $Handler
        )

    }

    Write-Log (
        "Environment Provider : {0}" -f
        $Action.Provider
    )

    Write-Log (
        "Variable : {0}" -f
        $Action.Name
    )

    Write-Log (
        "Valeur : {0}" -f
        $Action.Value
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

function Get-EnvironmentProviders {

    [CmdletBinding()]
    param()

    return $script:EnvironmentProviders.Keys |
        Sort-Object

}

# --------------------------------------------------
# Enregistre un fournisseur
# --------------------------------------------------

function Register-EnvironmentProvider {

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

    $script:EnvironmentProviders[$Name] = $Handler

}

# --------------------------------------------------
# Réinitialise les fournisseurs
# Utilisé par les tests
# --------------------------------------------------

function Reset-EnvironmentProviders {

    [CmdletBinding()]
    param()

    $script:EnvironmentProviders = [ordered]@{

        Native = "Invoke-NativeEnvironment"

    }

}