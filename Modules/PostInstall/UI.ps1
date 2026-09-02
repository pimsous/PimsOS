# ==========================================
# Module : PostInstall UI
# Projet : PimsOS Builder
# Version : 1.1.0
# Compatible : PowerShell 5.1+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Affiche l'état réseau du premier démarrage
# --------------------------------------------------

function Show-PostInstallNetworkStatus {

    [CmdletBinding()]
    param(

        [Parameter()]
        [switch]$WaitForNetwork

    )

    try {

        Clear-Host

    }
    catch [System.IO.IOException] {

        # Environnement non interactif (CI, redirection, etc.).
        # L'affichage peut continuer sans effacer l'écran.

    }

    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "                 PimsOS" -ForegroundColor Cyan
    Write-Host "              Premier démarrage" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Vérification de la connexion réseau" -ForegroundColor Yellow
    Write-Host "--------------------------------------------------"
    Write-Host ""

    $NetworkAvailable = Test-PostInstallNetwork

    if ($NetworkAvailable) {

        Write-Host "[OK] Adaptateur réseau détecté" -ForegroundColor Green
        Write-Host "[OK] Connexion réseau disponible" -ForegroundColor Green

        $InternetAvailable = Test-PostInstallInternet

        if ($InternetAvailable) {

            Write-Host "[OK] Accès Internet disponible" -ForegroundColor Green
            Write-Host ""
            Write-Host "Le réseau est disponible." -ForegroundColor Green
            Write-Host "PimsOS peut continuer l'installation."
            Write-Host ""

            return $true

        }

        Write-Host "[X] Accès Internet indisponible" -ForegroundColor Red
        Write-Host ""
        Write-Host "Le réseau local est disponible mais" -ForegroundColor Yellow
        Write-Host "l'accès Internet ne répond pas."
        Write-Host ""

        if (-not $WaitForNetwork) {

            return $false

        }

        Write-Host "PimsOS attend la disponibilité d'Internet..." `
            -ForegroundColor Yellow

        return $false

    }

    Write-Host "[X] Aucune connexion réseau détectée" -ForegroundColor Red
    Write-Host ""

    $Adapters = @()

    try {

        $Adapters = @(
            Get-NetAdapter `
                -ErrorAction Stop |
            Where-Object {
                $_.Status -eq "Up"
            }
        )

    }
    catch {

        $Adapters = @()

    }

    if ($Adapters.Count -eq 0) {

        Write-Host "[X] Aucun adaptateur réseau actif" -ForegroundColor Red
        Write-Host ""
        Write-Host "Windows ne semble disposer d'aucun adaptateur" `
            -ForegroundColor Yellow
        Write-Host "réseau actif."
        Write-Host ""

        Write-Host "Vous pouvez :" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  1. Installer le pilote réseau approprié"
        Write-Host "  2. Vérifier le pilote Wi-Fi"
        Write-Host "  3. Connecter un câble Ethernet"
        Write-Host "  4. Réessayer la détection"
        Write-Host ""

        return $false

    }

    Write-Host "[OK] Adaptateur réseau détecté" -ForegroundColor Green
    Write-Host "[X] Aucun réseau connecté" -ForegroundColor Red
    Write-Host ""

    Write-Host "Veuillez :" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  - connecter un câble Ethernet"
    Write-Host "  - ou vous connecter à un réseau Wi-Fi"
    Write-Host ""
    Write-Host "Une fois connecté, PimsOS pourra reprendre" `
        -ForegroundColor Yellow
    Write-Host "automatiquement l'installation."
    Write-Host ""

    return $false
}


# --------------------------------------------------
# Affiche l'aide lorsque le réseau est indisponible
# --------------------------------------------------

function Show-PostInstallNetworkHelp {

    [CmdletBinding()]
    param()

    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "             Connexion réseau requise" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "PimsOS ne peut pas poursuivre l'installation" `
        -ForegroundColor Yellow
    Write-Host "tant qu'une connexion réseau n'est pas disponible."
    Write-Host ""

    Write-Host "Si vous utilisez Ethernet :" -ForegroundColor Yellow
    Write-Host "  Connectez le câble réseau."
    Write-Host ""

    Write-Host "Si vous utilisez le Wi-Fi :" -ForegroundColor Yellow
    Write-Host "  Connectez-vous à un réseau Wi-Fi depuis Windows."
    Write-Host ""

    Write-Host "Si aucun adaptateur n'est détecté :" -ForegroundColor Yellow
    Write-Host "  Vérifiez ou installez le pilote réseau."
    Write-Host ""

    Write-Host "Après la connexion, PimsOS reprendra" `
        -ForegroundColor Green
    Write-Host "automatiquement le processus."
    Write-Host ""
}


# --------------------------------------------------
# Attend la disponibilité du réseau avec affichage
# --------------------------------------------------

function Wait-PostInstallNetworkUI {

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

        if (Show-PostInstallNetworkStatus -WaitForNetwork) {

            return $true

        }

        if ($TimeoutMinutes -gt 0) {

            $Elapsed = (
                (Get-Date) - $StartTime
            ).TotalMinutes

            if ($Elapsed -ge $TimeoutMinutes) {

                Write-Host ""
                Write-Host "Le délai d'attente réseau est dépassé." `
                    -ForegroundColor Red

                return $false

            }

        }

        Show-PostInstallNetworkHelp

        Write-Host "Nouvelle vérification dans $IntervalSeconds seconde(s)..."
        Write-Host ""

        Start-Sleep `
            -Seconds $IntervalSeconds

    }

}