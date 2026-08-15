# ==========================================
# Test : Mount ISO
# Projet : PimsOS Builder
# ==========================================

#Requires -Version 7.0

Set-StrictMode -Version Latest

# --------------------------------------------------
# Détermination de la racine du projet
# --------------------------------------------------

$ProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

# --------------------------------------------------
# Chargement du module principal
# --------------------------------------------------

Import-Module `
    "$ProjectRoot\Modules\PimsOS.psd1" `
    -Force `
    -ErrorAction Stop

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

try {

    # --------------------------------------------------
    # BuildContext
    # --------------------------------------------------

    Write-Host "Initialisation du BuildContext..." -ForegroundColor Yellow

    $Context = New-BuildContext

    $Context = Initialize-BuildContext `
        -Context $Context

    # --------------------------------------------------
    # Logger
    # --------------------------------------------------

    Start-Logger `
        -Path $Context.Logger.Path

    $LoggerStarted = $true

    Write-Log "Test du montage de l'ISO démarré." INFO

    Write-Log (
        "Projet : {0}" -f
        $Context.Project.Root
    )

    # --------------------------------------------------
    # Recherche de l'ISO
    # --------------------------------------------------

    Write-Log "Recherche de l'image ISO..."

    $iso = Get-IsoFile

    if ($null -eq $iso) {

        throw "Aucune image ISO n'a été trouvée."

    }

    Write-Host ""
    Write-Host "ISO détectée :" -ForegroundColor Cyan
    Write-Host ("Nom     : {0}" -f $iso.Name)
    Write-Host ("Taille  : {0} Go" -f $iso.SizeGB)
    Write-Host ""

    Write-Log (
        "ISO détectée : {0}" -f
        $iso.Name
    ) SUCCESS

    # --------------------------------------------------
    # Montage ISO
    # --------------------------------------------------

    Write-Log "Montage de l'ISO..."

    $Context = Mount-Iso `
        -Context $Context

    # --------------------------------------------------
    # Vérification du montage
    # --------------------------------------------------

    if (-not $Context.ISO.Mounted) {

        throw "L'ISO n'est pas indiquée comme montée dans le BuildContext."

    }

    Write-Host "Informations du lecteur :" -ForegroundColor Cyan
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

    if (-not (Test-Path $Context.ISO.SourcesPath)) {

        throw "Le dossier 'sources' est introuvable : $($Context.ISO.SourcesPath)"

    }

    Write-Log "Dossier Sources détecté." SUCCESS

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

        Write-Log "Image Windows détectée : install.wim." SUCCESS

    }
    elseif (Test-Path $esd) {

        Write-Log "Image Windows détectée : install.esd." SUCCESS

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

    Write-Log "Démontage de l'ISO..."

    Dismount-DiskImage `
        -ImagePath $Context.ISO.FullName `
        -ErrorAction Stop |
        Out-Null

    $Context.ISO.Mounted = $false

    Write-Log "ISO démontée." SUCCESS

    # --------------------------------------------------
    # Résultat
    # --------------------------------------------------

    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "      Test du montage ISO réussi" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host ""

}
catch {

    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Red
    Write-Host "      Test du montage ISO échoué" -ForegroundColor Red
    Write-Host "==========================================" -ForegroundColor Red
    Write-Host ""

    if ($LoggerStarted) {

        Write-Log `
            $_.Exception.Message `
            ERROR

    }

    Write-Host (
        "Erreur : {0}" -f
        $_.Exception.Message
    ) -ForegroundColor Red

    throw

}
finally {

    # --------------------------------------------------
    # Nettoyage de sécurité
    # --------------------------------------------------

    if (
        $null -ne $Context -and
        $Context.ISO.Mounted
    ) {

        Write-Host "Nettoyage : démontage de l'ISO..." -ForegroundColor Yellow

        try {

            Dismount-DiskImage `
                -ImagePath $Context.ISO.FullName `
                -ErrorAction Stop |
                Out-Null

            $Context.ISO.Mounted = $false

            if ($LoggerStarted) {

                Write-Log "ISO démontée lors du nettoyage." SUCCESS

            }

        }
        catch {

            Write-Host (
                "Impossible de démonter automatiquement l'ISO : {0}" -f
                $_.Exception.Message
            ) -ForegroundColor Red

            if ($LoggerStarted) {

                Write-Log `
                    $_.Exception.Message `
                    ERROR

            }

        }

    }

    # --------------------------------------------------
    # Arrêt du Logger
    # --------------------------------------------------

    if ($LoggerStarted) {

        Stop-Logger

    }

}

# --------------------------------------------------
# Affichage du journal
# --------------------------------------------------

Write-Host ""
Write-Host "Journal :" -ForegroundColor Cyan
Write-Host (Get-LogFile)
Write-Host ""