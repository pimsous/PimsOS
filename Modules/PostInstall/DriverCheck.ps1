# ==========================================
# Module : PostInstall DriverCheck
# Projet : PimsOS Builder
# Version : 1.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Vérifie l'état des périphériques et pilotes
# --------------------------------------------------

function Test-PostInstallDrivers {

    [CmdletBinding()]
    param()

    try {

        $Devices = @(
            Get-PnpDevice `
                -PresentOnly `
                -ErrorAction Stop
        )

        $ProblemDevices = @(
            $Devices |
                Where-Object {
                    $_.Status -ne "OK"
                }
        )

        if ($ProblemDevices.Count -eq 0) {

            Write-Log `
                "Aucun périphérique avec un problème de pilote détecté." `
                SUCCESS

            return [PSCustomObject]@{

                Available      = $true
                Success        = $true
                ProblemCount   = 0
                ProblemDevices = @()

            }

        }

        Write-Log (
            "{0} périphérique(s) présente(nt) un problème de pilote." -f
            $ProblemDevices.Count
        ) WARNING

        foreach ($Device in $ProblemDevices) {

            Write-Log (
                "Périphérique en erreur : {0} [{1}]" -f
                $Device.FriendlyName,
                $Device.Status
            ) WARNING

        }

        return [PSCustomObject]@{

            Available      = $true
            Success        = $false
            ProblemCount   = $ProblemDevices.Count
            ProblemDevices = $ProblemDevices

        }

    }
    catch {

        Write-Log `
            ("Impossible de vérifier les pilotes : {0}" -f $_.Exception.Message) `
            WARNING

        return [PSCustomObject]@{

            Available      = $false
            Success        = $false
            ProblemCount   = 0
            ProblemDevices = @()

        }

    }

}