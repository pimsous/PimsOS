# ==========================================
# Module : PostInstall Network
# Projet : PimsOS Builder
# Version : 1.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Vérifie la disponibilité du réseau
# --------------------------------------------------

function Test-PostInstallNetwork {

    [CmdletBinding()]
    param()

    try {

        $Profiles = Get-NetConnectionProfile `
            -ErrorAction Stop

        $Connected = @(
            $Profiles |
                Where-Object {
                    $_.IPv4Connectivity -notin @(
                        "Disconnected",
                        "NoTraffic",
                        "Unknown"
                    ) -or
                    $_.IPv6Connectivity -notin @(
                        "Disconnected",
                        "NoTraffic",
                        "Unknown"
                    )
                }
        )

        return ($Connected.Count -gt 0)

    }
    catch {

        try {

            $Adapters = @(
                Get-NetAdapter `
                    -ErrorAction Stop |
                Where-Object {
                    $_.Status -eq "Up"
                }
            )

            return ($Adapters.Count -gt 0)

        }
        catch {

            return $false

        }

    }

}

# --------------------------------------------------
# Vérifie l'accès Internet
# --------------------------------------------------

function Test-PostInstallInternet {

    [CmdletBinding()]
    param()

    if (-not (Test-PostInstallNetwork)) {

        return $false

    }

    try {

        return (
            Test-Connection `
                -ComputerName "www.microsoft.com" `
                -Count 1 `
                -Quiet `
                -ErrorAction Stop
        )

    }
    catch {

        return $false

    }

}

# --------------------------------------------------
# Attend que le réseau soit disponible
# --------------------------------------------------

function Wait-PostInstallNetwork {

    [CmdletBinding()]
    param(

        [Parameter()]
        [int]$IntervalSeconds = 5,

        [Parameter()]
        [int]$TimeoutMinutes = 0

    )

    if ($IntervalSeconds -lt 1) {

        $IntervalSeconds = 1

    }

    $StartTime = Get-Date

    while ($true) {

        if (Test-PostInstallNetwork) {

            return $true

        }

        if ($TimeoutMinutes -gt 0) {

            $Elapsed = (
                (Get-Date) - $StartTime
            ).TotalMinutes

            if ($Elapsed -ge $TimeoutMinutes) {

                return $false

            }

        }

        Start-Sleep `
            -Seconds $IntervalSeconds

    }

}
