# ==========================================
# Module : PackageManager
# Projet : PimsOS Builder
# Version : 1.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Gestionnaires disponibles
# --------------------------------------------------

$script:PackageProviders = @{

    Chocolatey = "Invoke-ChocolateyPackage"

    Winget     = "Invoke-WingetPackage"

}

# --------------------------------------------------
# Applique un package
# --------------------------------------------------

function Invoke-Package {

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

        throw (
            "Le fournisseur du package est obligatoire."
        )

    }

    if ([string]::IsNullOrWhiteSpace($Action.Name)) {

        throw (
            "Le nom du package est obligatoire."
        )

    }

    # --------------------------------------------------
    # Recherche du gestionnaire
    # --------------------------------------------------

    if (-not $script:PackageProviders.ContainsKey($Action.Provider)) {

        throw (
            "Le fournisseur '{0}' n'est pas pris en charge." -f
            $Action.Provider
        )

    }

    $Handler = $script:PackageProviders[$Action.Provider]

    if (-not (Get-Command `
        -Name $Handler `
        -ErrorAction SilentlyContinue)) {

        throw (
            "Le gestionnaire '{0}' est introuvable." -f
            $Handler
        )

    }

    Write-Log (
        "Provider : {0}" -f
        $Action.Provider
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

function Get-PackageProviders {

    [CmdletBinding()]
    param()

    return $script:PackageProviders.Keys | Sort-Object

}

# --------------------------------------------------
# Enregistre un nouveau fournisseur
# --------------------------------------------------

function Register-PackageProvider {

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

    $script:PackageProviders[$Name] = $Handler

}

# --------------------------------------------------
# Réinitialise les fournisseurs
# Utilisé par les tests
# --------------------------------------------------

function Reset-PackageProviders {

    [CmdletBinding()]
    param()

    $script:PackageProviders = @{

        Chocolatey = "Invoke-ChocolateyPackage"

        Winget     = "Invoke-WingetPackage"

    }

}