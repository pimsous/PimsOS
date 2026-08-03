# ==========================================
# Module : Security
# Projet : PimsOS Builder
# Version : 1.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Vérifie si PowerShell est exécuté
# avec des privilèges administrateur
# --------------------------------------------------

function Test-IsAdministrator {

    <#
    .SYNOPSIS
        Indique si PowerShell est exécuté
        avec des privilèges administrateur.
    #>

    [CmdletBinding()]
    param()

    $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()

    $Principal = [Security.Principal.WindowsPrincipal]::new($Identity)

    return $Principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )

}

# --------------------------------------------------
# Vérifie les privilèges administrateur
# --------------------------------------------------

function Assert-Administrator {

    <#
    .SYNOPSIS
        Arrête le script si PowerShell
        n'est pas exécuté en administrateur.
    #>

    [CmdletBinding()]
    param()

    if (Test-IsAdministrator) {

        return

    }

    throw @"

Les opérations DISM nécessitent des privilèges administrateur.

Relancez PowerShell en tant qu'administrateur
ou utilisez Build-PimsOS.ps1 qui effectue
l'élévation automatiquement.

"@

}

# --------------------------------------------------
# Relance PowerShell en administrateur
# --------------------------------------------------

function Start-Elevated {

    [CmdletBinding()]
    param(

        [string]$ScriptPath = $PSCommandPath,

        [string[]]$Arguments = @()

    )

    # --------------------------------------------------
    # Déjà administrateur ?
    # --------------------------------------------------

    if (Test-IsAdministrator) {

        return

    }

    # --------------------------------------------------
    # Vérification
    # --------------------------------------------------

    if ([string]::IsNullOrWhiteSpace($ScriptPath)) {

        throw "Impossible de déterminer le script à relancer."

    }

    Write-Log "Relancement en mode administrateur..." WARNING

    # --------------------------------------------------
    # Construction des arguments
    # --------------------------------------------------

    $ArgumentList = @(
        "-NoProfile"
        "-ExecutionPolicy"
        "Bypass"
        "-File"
        "`"$ScriptPath`""
    ) + $Arguments

    # --------------------------------------------------
    # Relancement
    # --------------------------------------------------

    Start-Process `
        -FilePath "pwsh.exe" `
        -Verb RunAs `
        -ArgumentList $ArgumentList `
        -ErrorAction Stop

    exit

}