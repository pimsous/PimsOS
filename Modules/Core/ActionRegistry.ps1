# ==========================================
# Module : ActionRegistry
# Projet : PimsOS Builder
# Version : 1.0.1
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Registre des moteurs d'actions
# --------------------------------------------------

$script:ActionRegistry = @{
    Registry = "Invoke-RegistryAction"
    Service  = "Invoke-ServiceAction"
}

# --------------------------------------------------
# Journalisation sécurisée
#
# Le module PimsOS fournit normalement Write-Log.
# Les tests unitaires peuvent toutefois charger ce
# fichier indépendamment.
# --------------------------------------------------

function Write-ActionRegistryLog {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter()]
        [string]$Level = "INFO"

    )

    if (
        Get-Command `
            -Name "Write-Log" `
            -CommandType Function `
            -ErrorAction SilentlyContinue
    ) {

        Write-Log $Message $Level
    }
}

# --------------------------------------------------
# Réinitialise le registre des moteurs
# Utilisé notamment par les tests
# --------------------------------------------------

function Reset-ActionRegistry {

    [CmdletBinding()]
    param()

    $script:ActionRegistry = @{
        Registry = "Invoke-RegistryAction"
        Service  = "Invoke-ServiceAction"
    }

    Write-ActionRegistryLog `
        -Message "Registre des moteurs réinitialisé." `
        -Level "INFO"
}

# --------------------------------------------------
# Retourne le moteur associé à un type d'action
# --------------------------------------------------

function Get-ActionHandler {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]$Type

    )

    if ([string]::IsNullOrWhiteSpace($Type)) {

        throw "Le type d'action est vide."
    }

    if (-not $script:ActionRegistry.ContainsKey($Type)) {

        return $null
    }

    return $script:ActionRegistry[$Type]
}

# --------------------------------------------------
# Enregistre un nouveau moteur
# --------------------------------------------------

function Register-ActionHandler {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]$Type,

        [Parameter(Mandatory)]
        [string]$Handler

    )

    # ------------------------------------------
    # Validation du type
    # ------------------------------------------

    if ([string]::IsNullOrWhiteSpace($Type)) {

        throw "Le type d'action est vide."
    }

    # ------------------------------------------
    # Validation du moteur
    # ------------------------------------------

    if ([string]::IsNullOrWhiteSpace($Handler)) {

        throw "Le nom du moteur est vide."
    }

    # ------------------------------------------
    # Vérifie que le moteur existe
    # ------------------------------------------

    if (-not (
        Get-Command `
            -Name $Handler `
            -CommandType Function `
            -ErrorAction SilentlyContinue
    )) {

        throw (
            "Le moteur '{0}' est introuvable." -f
            $Handler
        )
    }

    # ------------------------------------------
    # Vérifie les doublons
    # ------------------------------------------

    if ($script:ActionRegistry.ContainsKey($Type)) {

        throw (
            "Le moteur d'action '{0}' est déjà enregistré." -f
            $Type
        )
    }

    # ------------------------------------------
    # Enregistrement
    # ------------------------------------------

    $script:ActionRegistry[$Type] = $Handler

    Write-ActionRegistryLog `
        -Message (
            "Moteur enregistré : {0} -> {1}" -f
            $Type,
            $Handler
        ) `
        -Level "SUCCESS"
}

# --------------------------------------------------
# Retourne la liste des moteurs enregistrés
# --------------------------------------------------

function Get-RegisteredActionHandlers {

    [CmdletBinding()]
    param()

    return $script:ActionRegistry
}

# --------------------------------------------------
# Vérifie qu'un moteur est enregistré
# --------------------------------------------------

function Test-ActionHandler {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]$Type

    )

    if ([string]::IsNullOrWhiteSpace($Type)) {

        return $false
    }

    return $script:ActionRegistry.ContainsKey($Type)
}