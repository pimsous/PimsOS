# ==========================================
# Module : ActionRegistry
# Projet : PimsOS Builder
# Version : 1.0.0
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
# Réinitialise le registre des moteurs
# Utilisé uniquement par les tests
# --------------------------------------------------

function Reset-ActionRegistry {

    [CmdletBinding()]
    param()

    $script:ActionRegistry = @{

        Registry = "Invoke-RegistryAction"
        Service  = "Invoke-ServiceAction"

    }

    Write-Log "Registre des moteurs réinitialisé." INFO

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

    if ([string]::IsNullOrWhiteSpace($Type)) {

        throw "Le type d'action est vide."

    }

    if ([string]::IsNullOrWhiteSpace($Handler)) {

        throw "Le nom du moteur est vide."

    }

    # ------------------------------------------
    # Vérifie que le moteur existe
    # ------------------------------------------

    if (-not (Get-Command `
        -Name $Handler `
        -CommandType Function `
        -ErrorAction SilentlyContinue)) {

        throw (
            "Le moteur '{0}' est introuvable." -f
            $Handler
        )

    }

    # ------------------------------------------
    # Déjà enregistré ?
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

    Write-Log (
        "Moteur enregistré : {0} -> {1}" -f
        $Type,
        $Handler
    ) SUCCESS

}

# --------------------------------------------------
# Retourne la liste des moteurs enregistrés
# --------------------------------------------------

function Get-RegisteredActionHandlers {

    [CmdletBinding()]
    param()

    return $script:ActionRegistry.GetEnumerator() |
        Sort-Object Name

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

    return $script:ActionRegistry.ContainsKey($Type)

}