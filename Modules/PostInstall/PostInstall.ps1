# ==========================================
# Module : PostInstall
# Projet : PimsOS Builder
# Version : 1.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Initialise le PostInstall
# --------------------------------------------------

function Initialize-PostInstall {

    [CmdletBinding()]
    param(

        [Parameter()]
        [string]$StatePath =
            "C:\ProgramData\PimsOS\PostInstall\state.json"

    )

    $State = Get-PostInstallState `
        -StatePath $StatePath

    if (
        $State.PSObject.Properties.Name -notcontains "StatePath"
    ) {

        $State |
            Add-Member `
                -MemberType NoteProperty `
                -Name StatePath `
                -Value $StatePath

    }

    $State.StatePath = $StatePath

    return Save-PostInstallState `
        -State $State `
        -StatePath $StatePath

}

# --------------------------------------------------
# Exécute le PostInstall
# --------------------------------------------------

function Invoke-PostInstall {

    [CmdletBinding()]
    param(

        [Parameter()]
        [psobject]$State,

        [Parameter()]
        [switch]$WaitForNetwork,

        [Parameter()]
        [int]$NetworkTimeoutMinutes = 0

    )

    if ($null -eq $State) {

        $State = Initialize-PostInstall

    }

    try {

        $State = Set-PostInstallStatus `
            -State $State `
            -Status "Running"

        $State.CurrentPhase = "Local"

        $State = Save-PostInstallState `
            -State $State

        # --------------------------------------------------
        # Phase locale
        # --------------------------------------------------

        # Les tâches locales seront ajoutées ici.

        $State.CompletedTasks += "Local"

        # --------------------------------------------------
        # Phase réseau
        # --------------------------------------------------

        if ($WaitForNetwork) {

            if (Get-Command Show-PostInstallNetworkStatus `
                -ErrorAction SilentlyContinue) {

                $NetworkAvailable =
                    Show-PostInstallNetworkStatus

            }
            else {

                $NetworkAvailable =
                    Test-PostInstallNetwork

            }

            if (-not $NetworkAvailable) {

                $State = Set-PostInstallStatus `
                    -State $State `
                    -Status "WaitingForNetwork"

                $State.CurrentPhase = "Network"

                $State = Save-PostInstallState `
                    -State $State

                if (Get-Command Wait-PostInstallNetworkUI `
                    -ErrorAction SilentlyContinue) {

                    $NetworkAvailable =
                        Wait-PostInstallNetworkUI `
                            -TimeoutMinutes $NetworkTimeoutMinutes

                }
                else {

                    $NetworkAvailable =
                        Wait-PostInstallNetwork `
                            -TimeoutMinutes $NetworkTimeoutMinutes

                }

                if (-not $NetworkAvailable) {

                    throw (
                        "Le délai d'attente réseau a été dépassé."
                    )

                }

                $State.NetworkAvailable = $true

                $State = Set-PostInstallStatus `
                    -State $State `
                    -Status "Running"

                $State.CurrentPhase = "Network"

                $State = Save-PostInstallState `
                    -State $State

            }
            else {

                $State.NetworkAvailable = $true

            }

        }

        # --------------------------------------------------
        # Tâches réseau
        # --------------------------------------------------

        # Winget / Chocolatey / Microsoft Store
        # seront ajoutés ici.

        if ($WaitForNetwork) {

            $State.CompletedTasks += "Network"

        }

        # --------------------------------------------------
        # Fin
        # --------------------------------------------------

        $State.CurrentPhase = $null

        $State = Set-PostInstallStatus `
            -State $State `
            -Status "Completed"

        $State = Save-PostInstallState `
            -State $State

        return $State

    }
    catch {

        $State.Errors += $_.Exception.Message

        $State = Set-PostInstallStatus `
            -State $State `
            -Status "Failed"

        $State = Save-PostInstallState `
            -State $State

        throw

    }

}
