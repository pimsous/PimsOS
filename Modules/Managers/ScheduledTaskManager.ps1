# ==========================================
# Module : ScheduledTaskManager
# Projet : PimsOS Builder
# Version : 1.0.1
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Gestionnaires disponibles
# --------------------------------------------------

$script:ScheduledTaskProviders = [ordered]@{

    Native = "Invoke-NativeScheduledTask"

}

# --------------------------------------------------
# Applique une tâche planifiée
# --------------------------------------------------

function Invoke-ScheduledTask {

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

        throw "Le nom de la tâche planifiée est obligatoire."

    }

    # --------------------------------------------------
    # Recherche du gestionnaire
    # --------------------------------------------------

    if (-not $script:ScheduledTaskProviders.Contains($Action.Provider)) {

        throw (
            "Le fournisseur '{0}' n'est pas pris en charge." -f
            $Action.Provider
        )

    }

    $Handler = $script:ScheduledTaskProviders[$Action.Provider]

    if (-not (Get-Command `
        -Name $Handler `
        -ErrorAction SilentlyContinue)) {

        throw (
            "Le gestionnaire '{0}' est introuvable." -f
            $Handler
        )

    }

    Write-Log (
        "ScheduledTask Provider : {0}" -f
        $Action.Provider
    )

    Write-Log (
        "Tâche : {0}" -f
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

function Get-ScheduledTaskProviders {

    [CmdletBinding()]
    param()

    return $script:ScheduledTaskProviders.Keys |
        Sort-Object

}

# --------------------------------------------------
# Enregistre un fournisseur
# --------------------------------------------------

function Register-ScheduledTaskProvider {

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

    $script:ScheduledTaskProviders[$Name] = $Handler

}

# --------------------------------------------------
# Réinitialise les fournisseurs
# Utilisé par les tests
# --------------------------------------------------

function Reset-ScheduledTaskProviders {

    [CmdletBinding()]
    param()

    $script:ScheduledTaskProviders = [ordered]@{

        Native = "Invoke-NativeScheduledTask"

    }

}