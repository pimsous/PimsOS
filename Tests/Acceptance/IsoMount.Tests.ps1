# ==========================================
# Test : Mount ISO
# Projet : PimsOS Builder
# ==========================================

#Requires -Version 7.0

Set-StrictMode -Version Latest

# --------------------------------------------------
# Détermination de la racine du projet
# --------------------------------------------------

$ProjectRoot = Split-Path `
    (Split-Path $PSScriptRoot -Parent) `
    -Parent

# --------------------------------------------------
# Chargement des composants nécessaires
# --------------------------------------------------

. "$ProjectRoot\Modules\Infrastructure\Logger.ps1"
. "$ProjectRoot\Modules\Core\Core.ps1"
. "$ProjectRoot\Modules\Core\BuildContext.ps1"
. "$ProjectRoot\Modules\Image\Iso.ps1"

# --------------------------------------------------
# Initialisation
# --------------------------------------------------

Clear-Host

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "      Test du montage de l'ISO" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$Context = $null
$LoggerStarted = $false
$TestSucceeded = $false

try {

    # --------------------------------------------------
    # BuildContext
    # --------------------------------------------------

    Write-Host `
        "Initialisation du BuildContext..." `
        -ForegroundColor Yellow

    $Context = New-BuildContext

    $Context = Initialize-BuildContext `
        -Context $Context

    # --------------------------------------------------
    # Logger
    # --------------------------------------------------

    if (
        $null -eq $Context.Logger -or
        $Context.Logger.PSObject.Properties.Name -notcontains "Path"
    ) {

        throw "Le chemin du journal est absent du BuildContext."

    }

    Start-Logger `
        -Path $Context.Logger.Path

    $LoggerStarted = $true

    Write-Log `
        "Test du montage de l'ISO démarré." `
        INFO

    Write-Log (
        "Projet : {0}" -f
        $Context.Project.Root
    )

    # --------------------------------------------------
    # Recherche de l'ISO
    # --------------------------------------------------

    Write-Log `
        "Recherche de l'image ISO..." `
        INFO

    $iso = Get-IsoFile

    if ($null -eq $iso) {

        throw "Aucune image ISO n'a été trouvée."

    }

    Write-Host ""
    Write-Host `
        "ISO détectée :" `
        -ForegroundColor Cyan

    Write-Host (
        "Nom     : {0}" -f
        $iso.Name
    )

    Write-Host (
        "Taille  : {0} Go" -f
        $iso.SizeGB
    )

    Write-Host ""

    Write-Log (
        "ISO détectée : {0}" -f
        $iso.Name
    ) SUCCESS

    # --------------------------------------------------
    # Montage ISO
    # --------------------------------------------------

    Write-Log `
        "Montage de l'ISO..." `
        INFO

    $Context = Mount-Iso `
        -Context $Context

    # --------------------------------------------------
    # Vérification du montage
    # --------------------------------------------------

    if (
        $null -eq $Context.ISO -or
        $Context.ISO.PSObject.Properties.Name -notcontains "Mounted"
    ) {

        throw "L'état de montage de l'ISO est absent du BuildContext."

    }

    if (-not [bool]$Context.ISO.Mounted) {

        throw `
            "L'ISO n'est pas indiquée comme montée dans le BuildContext."

    }

    # --------------------------------------------------
    # Informations du lecteur
    # --------------------------------------------------

    Write-Host `
        "Informations du lecteur :" `
        -ForegroundColor Cyan

    Write-Host (
        "Lecteur : {0}" -f
        $Context.ISO.DriveLetter
    )

    Write-Host (
        "Label   : {0}" -f
        $Context.ISO.Label
    )

    Write-Host (
        "Sources : {0}" -f
        $Context.ISO.SourcesPath
    )

    Write-Host ""

    Write-Log (
        "ISO montée sur le lecteur {0}." -f
        $Context.ISO.DriveLetter
    ) SUCCESS

    # --------------------------------------------------
    # Vérification du dossier Sources
    # --------------------------------------------------

    if (
        [string]::IsNullOrWhiteSpace(
            [string]$Context.ISO.SourcesPath
        )
    ) {

        throw "Le chemin du dossier Sources est vide."

    }

    if (-not (Test-Path $Context.ISO.SourcesPath)) {

        throw (
            "Le dossier 'sources' est introuvable : {0}" -f
            $Context.ISO.SourcesPath
        )

    }

    Write-Log `
        "Dossier Sources détecté." `
        SUCCESS

    # --------------------------------------------------
    # Vérification de l'image Windows
    # --------------------------------------------------

    $wim = Join-Path `
        $Context.ISO.SourcesPath `
        "install.wim"

    $esd = Join-Path `
        $Context.ISO.SourcesPath `
        "install.esd"

    if (Test-Path $wim) {

        Write-Log `
            "Image Windows détectée : install.wim." `
            SUCCESS

    }
    elseif (Test-Path $esd) {

        Write-Log `
            "Image Windows détectée : install.esd." `
            SUCCESS

    }
    else {

        throw (
            "Aucun fichier install.wim ou install.esd trouvé dans : {0}" -f
            $Context.ISO.SourcesPath
        )

    }

    # --------------------------------------------------
    # Démontage ISO
    # --------------------------------------------------

    Write-Log `
        "Démontage de l'ISO..." `
        INFO

    if (
        $Context.ISO.PSObject.Properties.Name -contains "FullName" -and
        -not [string]::IsNullOrWhiteSpace(
            [string]$Context.ISO.FullName
        )
    ) {

        Dismount-DiskImage `
            -ImagePath $Context.ISO.FullName `
            -ErrorAction Stop |
            Out-Null

    }
    else {

        throw `
            "Impossible de déterminer le chemin de l'ISO pour le démontage."

    }

    $Context.ISO.Mounted = $false

    Write-Log `
        "ISO démontée." `
        SUCCESS

    # --------------------------------------------------
    # Résultat
    # --------------------------------------------------

    $TestSucceeded = $true

    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "      Test du montage ISO réussi" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host ""

}
catch {

    # --------------------------------------------------
    # Gestion de l'erreur
    # --------------------------------------------------

    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Red
    Write-Host "      Test du montage ISO échoué" -ForegroundColor Red
    Write-Host "==========================================" -ForegroundColor Red
    Write-Host ""

    $ErrorMessage = $_.Exception.Message

    if ($LoggerStarted) {

        Write-Log `
            $ErrorMessage `
            ERROR

    }

    Write-Host (
        "Erreur : {0}" -f
        $ErrorMessage
    ) -ForegroundColor Red

}
finally {

    # --------------------------------------------------
    # Nettoyage de sécurité
    # --------------------------------------------------

    $IsoMounted = $false

    if ($null -ne $Context) {

        # --------------------------------------------------
        # Vérification sécurisée de l'objet ISO
        # --------------------------------------------------

        if (
            $Context.PSObject.Properties.Name -contains "ISO" -and
            $null -ne $Context.ISO
        ) {

            if (
                $Context.ISO.PSObject.Properties.Name -contains "Mounted"
            ) {

                $IsoMounted = [bool]$Context.ISO.Mounted

            }

        }

        # --------------------------------------------------
        # Démontage automatique de l'ISO
        # --------------------------------------------------

        if ($IsoMounted) {

            Write-Host ""
            Write-Host `
                "Nettoyage : démontage de l'ISO..." `
                -ForegroundColor Yellow

            try {

                if (
                    $Context.ISO.PSObject.Properties.Name -contains "FullName" -and
                    -not [string]::IsNullOrWhiteSpace(
                        [string]$Context.ISO.FullName
                    )
                ) {

                    Dismount-DiskImage `
                        -ImagePath $Context.ISO.FullName `
                        -ErrorAction Stop |
                        Out-Null

                    $Context.ISO.Mounted = $false

                    Write-Host `
                        "ISO démontée avec succès." `
                        -ForegroundColor Green

                    if ($LoggerStarted) {

                        Write-Log `
                            "ISO démontée lors du nettoyage." `
                            SUCCESS

                    }

                }
                else {

                    Write-Host `
                        "Impossible de déterminer le chemin de l'ISO." `
                        -ForegroundColor Yellow

                    if ($LoggerStarted) {

                        Write-Log `
                            "Chemin de l'ISO indisponible lors du nettoyage." `
                            WARNING

                    }

                }

            }
            catch {

                $CleanupError = $_.Exception.Message

                Write-Host (
                    "Impossible de démonter automatiquement l'ISO : {0}" -f
                    $CleanupError
                ) -ForegroundColor Red

                if ($LoggerStarted) {

                    Write-Log `
                        $CleanupError `
                        ERROR

                }

            }

        }

    }

    # --------------------------------------------------
    # Arrêt du Logger
    # --------------------------------------------------

    if ($LoggerStarted) {

        Stop-Logger

    }

    # --------------------------------------------------
    # Affichage du journal
    # --------------------------------------------------

    Write-Host ""
    Write-Host `
        "Journal :" `
        -ForegroundColor Cyan

    $LogPath = Get-LogFile

    if (
        $null -ne $LogPath -and
        -not [string]::IsNullOrWhiteSpace(
            [string]$LogPath
        )
    ) {

        Write-Host $LogPath

    }
    else {

        Write-Host `
            "Aucun journal disponible." `
            -ForegroundColor Yellow

    }

    Write-Host ""

}