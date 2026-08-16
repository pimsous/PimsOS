# ==========================================
# Module : CommandManager
# Projet : PimsOS Builder
# Version : 1.0.1
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Gestionnaires disponibles
# --------------------------------------------------

$script:CommandProviders = [ordered]@{

    Native     = "Invoke-NativeCommand"

    PowerShell = "Invoke-PowerShellCommand"

    CMD        = "Invoke-CmdCommand"

}

# --------------------------------------------------
# Exécute une commande
# --------------------------------------------------

function Invoke-Command {

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

        throw "Le fournisseur de commande est obligatoire."

    }

    if ([string]::IsNullOrWhiteSpace($Action.Command)) {

        throw "La commande est obligatoire."

    }

    # --------------------------------------------------
    # Recherche du gestionnaire
    # --------------------------------------------------

    if (-not $script:CommandProviders.Contains($Action.Provider)) {

        throw (
            "Le fournisseur '{0}' n'est pas pris en charge." -f
            $Action.Provider
        )

    }

    $Handler = $script:CommandProviders[$Action.Provider]

    if (-not (Get-Command `
        -Name $Handler `
        -ErrorAction SilentlyContinue)) {

        throw (
            "Le gestionnaire '{0}' est introuvable." -f
            $Handler
        )

    }

    Write-Log (
        "Command Provider : {0}" -f
        $Action.Provider
    )

    Write-Log (
        "Commande : {0}" -f
        $Action.Command
    )

    if ($Action.Arguments) {

        Write-Log (
            "Arguments : {0}" -f
            $Action.Arguments
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

function Get-CommandProviders {

    [CmdletBinding()]
    param()

    return $script:CommandProviders.Keys

}

# --------------------------------------------------
# Enregistre un fournisseur
# --------------------------------------------------

function Register-CommandProvider {

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

    $script:CommandProviders[$Name] = $Handler

}

# --------------------------------------------------
# Réinitialise les fournisseurs
# Utilisé par les tests
# --------------------------------------------------

function Reset-CommandProviders {

    [CmdletBinding()]
    param()

    $script:CommandProviders = [ordered]@{

        Native     = "Invoke-NativeCommand"

        PowerShell = "Invoke-PowerShellCommand"

        CMD        = "Invoke-CmdCommand"

    }

}