# ==========================================
# Module : PostInstall Bootstrap
# Projet : PimsOS Builder
# Version : 1.2.0
# Compatible : PowerShell 5.1+
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

    $LoggerPath = Join-Path `
        -Path $RuntimePath `
        -ChildPath "Logger.ps1"

    $StatePath = Join-Path `
        -Path $RuntimePath `
        -ChildPath "State.ps1"

    $NetworkPath = Join-Path `
        -Path $RuntimePath `
        -ChildPath "Network.ps1"

    $UIPath = Join-Path `
        -Path $RuntimePath `
        -ChildPath "UI.ps1"

    $DriverCheckPath = Join-Path `
        -Path $RuntimePath `
        -ChildPath "DriverCheck.ps1"

    $PostInstallPath = Join-Path `
        -Path $RuntimePath `
        -ChildPath "PostInstall.ps1"

    $FinalizePath = Join-Path `
        -Path $RuntimePath `
        -ChildPath "Finalize.ps1"

    $ChocolateyPath = Join-Path `
        -Path $RuntimePath `
        -ChildPath "Chocolatey.ps1"

    foreach ($Path in @(
        $LoggerPath,
        $StatePath,
        $NetworkPath,
        $UIPath,
        $DriverCheckPath,
        $ChocolateyPath,
        $PostInstallPath,
        $FinalizePath
    )) {

        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {

            throw (
                "Fichier PostInstall requis introuvable : {0}" -f
                $Path
            )

        }

    }

    # --------------------------------------------------
    # Initialise le Logger
    # --------------------------------------------------

    . $LoggerPath

    Start-Logger `
        -Path (
            Join-Path `
                -Path $RuntimePath `
                -ChildPath "PostInstall.log"
        )

    . $StatePath
    . $NetworkPath
    . $UIPath
    . $DriverCheckPath
    . $ChocolateyPath
    . $PostInstallPath
    . $FinalizePath

    try {

        $State = Invoke-PostInstall `
            -WaitForNetwork:$WaitForNetwork `
            -NetworkTimeoutMinutes $NetworkTimeoutMinutes

        Write-Log `
            "Vérification finale du PostInstall." `
            INFO

        $Finalization = Complete-PimsOSPostInstall `
            -State $State `
            -RuntimePath $RuntimePath

        $State = Save-PostInstallState `
            -State $Finalization.State

        Write-Log `
            "Vérification finale du PostInstall réussie." `
            SUCCESS

        if ($Finalization.Cleanup.Scheduled) {

            Write-Log `
                ("Nettoyage Bootstrap programmé dans {0} seconde(s)." -f $Finalization.Cleanup.DelaySeconds) `
                SUCCESS

        }
        else {

            Write-Log `
                "Le nettoyage Bootstrap n'a pas pu être programmé. L'état, le journal et le cache Chocolatey sont conservés." `
                WARNING

        }

        return $State

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