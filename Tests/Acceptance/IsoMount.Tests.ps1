# ==========================================
# Test : Mount ISO
# Projet : PimsOS Builder
# ==========================================

$ProjectRoot = Split-Path $PSScriptRoot -Parent

Import-Module "$ProjectRoot\Modules\Core.psm1" -Force
Import-Module "$ProjectRoot\Modules\Logger.psm1" -Force
Import-Module "$ProjectRoot\Modules\BuildContext.psm1" -Force
Import-Module "$ProjectRoot\Modules\Iso.psm1" -Force

Clear-Host

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "      Test du montage de l'ISO" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Start-Logger

$Context = New-BuildContext

try {

    Write-Log "Recherche de l'image ISO..."

    $iso = Get-IsoFile

    Write-Host ""
    Write-Host "ISO détectée :" -ForegroundColor Cyan
    Write-Host ("Nom     : {0}" -f $iso.Name)
    Write-Host ("Taille  : {0} Go" -f $iso.SizeGB)
    Write-Host ""

    $Context = Mount-Iso -Context $Context

    Write-Host "Informations du lecteur :" -ForegroundColor Cyan
    Write-Host ("Lecteur : {0}" -f $Context.ISO.DriveLetter)
    Write-Host ("Label   : {0}" -f $Context.ISO.Label)
    Write-Host ("Sources : {0}" -f $Context.ISO.SourcesPath)
    Write-Host ""

    if (-not (Test-Path $Context.ISO.SourcesPath)) {

        throw "Le dossier 'sources' est introuvable."

    }

    $wim = Join-Path $Context.ISO.SourcesPath "install.wim"
    $esd = Join-Path $Context.ISO.SourcesPath "install.esd"

    if ((Test-Path $wim) -or (Test-Path $esd)) {

        Write-Log "Image Windows détectée." SUCCESS

    }
    else {

        throw "Aucun fichier install.wim ou install.esd trouvé."

    }

    Dismount-DiskImage `
    -ImagePath $Context.ISO.FullName | Out-Null

    Write-Log "ISO démontée." SUCCESS

}
catch {

    Write-Log $_.Exception.Message ERROR

}
finally {

    Stop-Logger

}

Write-Host ""
Write-Host "Journal :" -ForegroundColor Cyan
Write-Host (Get-LogFile)
Write-Host ""