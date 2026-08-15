# ==========================================
# Test : Mount-Wim
# Projet : PimsOS Builder
# ==========================================

#Requires -Version 7.0

Set-StrictMode -Version Latest

# --------------------------------------------------
# Détermination de la racine du projet
# --------------------------------------------------

$ProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

Set-Location $ProjectRoot

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
Write-Host "       Test du montage du WIM" -ForegroundColor Cyan
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

    Write-Log "Test du montage du WIM démarré." INFO

    Write-Log (
        "Projet : {0}" -f
        $Context.Project.Root
    )

    # --------------------------------------------------
    # ISO
    # --------------------------------------------------

    Write-Log "Montage de l'ISO..."

    $Context = Mount-Iso `
        -Context $Context

    if (-not $Context.ISO.Mounted) {

        throw "L'ISO n'est pas indiquée comme montée dans le BuildContext."

    }

    Write-Log "ISO montée avec succès." SUCCESS

    # --------------------------------------------------
    # Détection du WIM
    # --------------------------------------------------

    Write-Log "Recherche de l'image Windows..."

    $Context = Get-WimFile `
        -Context $Context

    if ($null -eq $Context.WIM.Path) {

        throw "Aucun fichier WIM n'a été trouvé."

    }

    Write-Log (
        "Image Windows : {0}" -f
        $Context.WIM.Path
    ) SUCCESS

    # --------------------------------------------------
    # Lecture des éditions
    # --------------------------------------------------

    Write-Log "Lecture des éditions Windows..."

    $Context = Get-WimImages `
        -Context $Context

    if ($null -eq $Context.Images) {

        throw "Aucune édition Windows n'a été détectée."

    }

    if ($Context.Images.Count -eq 0) {

        throw "La liste des éditions Windows est vide."

    }

    Write-Log (
        "{0} édition(s) Windows détectée(s)." -f
        $Context.Images.Count
    ) SUCCESS

    # --------------------------------------------------
    # Sélection de l'image
    # --------------------------------------------------

    Write-Log "Sélection de l'édition Windows..."

    $Context = Select-WimImage `
        -Context $Context

    if ($null -eq $Context.Image) {

        throw "Aucune image Windows n'a été sélectionnée."

    }

    Write-Host ""
    Write-Host "Edition sélectionnée :" -ForegroundColor Cyan
    Write-Host (
        "Nom   : {0}" -f
        $Context.Image.Name
    )
    Write-Host (
        "Index : {0}" -f
        $Context.Image.Index
    )
    Write-Host ""

    Write-Log (
        "Edition sélectionnée : {0} (Index {1})." -f
        $Context.Image.Name,
        $Context.Image.Index
    ) SUCCESS

    # --------------------------------------------------
    # Montage du WIM
    # --------------------------------------------------

    Write-Log "Montage du WIM..."

    $Context = Mount-Wim `
        -Context $Context

    if (-not $Context.BuildState.Image.Mounted) {

        throw "Le WIM n'est pas indiqué comme monté dans le BuildState."

    }

    Write-Log "WIM monté avec succès." SUCCESS

    # --------------------------------------------------
    # Validation
    # --------------------------------------------------

    $windowsFolder = Join-Path `
        $Context.WIM.Mount.Path `
        "Windows"

    if (-not (Test-Path $windowsFolder)) {

        throw (
            "Le dossier Windows est introuvable dans : {0}" -f
            $Context.WIM.Mount.Path
        )

    }

    Write-Host ""
    Write-Host "Le WIM est correctement monté." -ForegroundColor Green
    Write-Host ""

    Write-Host (
        "Edition      : {0}" -f
        $Context.Image.Name
    )

    Write-Host (
        "Index        : {0}" -f
        $Context.Image.Index
    )

    Write-Host (
        "Image WIM    : {0}" -f
        $Context.WIM.Path
    )

    Write-Host (
        "Montage      : {0}" -f
        $Context.WIM.Mount.Path
    )

    Write-Host ""

    Write-Log "Validation du montage du WIM réussie." SUCCESS

    # --------------------------------------------------
    # Résultat
    # --------------------------------------------------

    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "      Test du montage WIM réussi" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host ""

}
catch {

    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Red
    Write-Host "      Test du montage WIM échoué" -ForegroundColor Red
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
    # Démontage du WIM
    # --------------------------------------------------

    if (
        $null -ne $Context -and
        $Context.BuildState.Image.Mounted
    ) {

        Write-Host "Nettoyage : démontage du WIM..." -ForegroundColor Yellow

        try {

            Dismount-Wim `
                -Context $Context

            if ($LoggerStarted) {

                Write-Log "WIM démonté lors du nettoyage." SUCCESS

            }

        }
        catch {

            Write-Host (
                "Impossible de démonter le WIM : {0}" -f
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
    # Démontage de l'ISO
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
Write-Host "Journal :" -ForegroundColor Yellow
Write-Host (Get-LogFile)
Write-Host ""