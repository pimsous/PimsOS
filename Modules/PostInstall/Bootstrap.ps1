# ==========================================
# Module : PostInstall Bootstrap
# Projet : PimsOS Builder
# Version : 1.1.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Lance le moteur PostInstall
# --------------------------------------------------

function Start-PimsOSPostInstall {

    [CmdletBinding()]
    param(

        [Parameter()]
        [string]$RuntimePath = $PSScriptRoot,

        [Parameter()]
        [switch]$WaitForNetwork,

        [Parameter()]
        [int]$NetworkTimeoutMinutes = 0

    )

    if ([string]::IsNullOrWhiteSpace($RuntimePath)) {

        throw "Le chemin du runtime PostInstall est vide."

    }

    if (-not (Test-Path -LiteralPath $RuntimePath -PathType Container)) {

        throw (
            "Le répertoire du runtime PostInstall est introuvable : {0}" -f
            $RuntimePath
        )

    }

    $StatePath = Join-Path `
        -Path $RuntimePath `
        -ChildPath "State.ps1"

    $NetworkPath = Join-Path `
        -Path $RuntimePath `
        -ChildPath "Network.ps1"

    $UIPath = Join-Path `
        -Path $RuntimePath `
        -ChildPath "UI.ps1"

    $PostInstallPath = Join-Path `
        -Path $RuntimePath `
        -ChildPath "PostInstall.ps1"

    foreach ($Path in @(
        $StatePath,
        $NetworkPath,
        $UIPath,
        $PostInstallPath
    )) {

        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {

            throw (
                "Fichier PostInstall requis introuvable : {0}" -f
                $Path
            )

        }

    }

    . $StatePath
    . $NetworkPath
    . $UIPath
    . $PostInstallPath

    try {

        return Invoke-PostInstall `
            -WaitForNetwork:$WaitForNetwork `
            -NetworkTimeoutMinutes $NetworkTimeoutMinutes

    }
    catch {

        throw (
            "Le Bootstrap PimsOS a échoué.`r`n{0}" -f
            $_.Exception.Message
        )

    }

}

# --------------------------------------------------
# Point d'entrée
# --------------------------------------------------

Start-PimsOSPostInstall