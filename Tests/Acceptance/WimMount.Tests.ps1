# ==========================================
# Test : Mount-Wim
# Projet : PimsOS Builder
# ==========================================

#Requires -Version 7.0

$ProjectRoot = Split-Path $PSScriptRoot -Parent
Set-Location $ProjectRoot

# --------------------------------------------------
# Chargement des modules
# --------------------------------------------------

Import-Module "$ProjectRoot\Modules\Core.psm1" -Force
Import-Module "$ProjectRoot\Modules\Logger.psm1" -Force
Import-Module "$ProjectRoot\Modules\Builder.psm1" -Force
Import-Module "$ProjectRoot\Modules\BuildContext.psm1" -Force
Import-Module "$ProjectRoot\Modules\Iso.psm1" -Force
Import-Module "$ProjectRoot\Modules\Dism.psm1" -Force
Import-Module "$ProjectRoot\Modules\Wim.psm1" -Force

Clear-Host

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "       Test du montage du WIM" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Start-Logger

try {

    # --------------------------------------------------
    # Initialisation
    # --------------------------------------------------

    $Config = Get-Config -Reload

    $Context = New-BuildContext

    $Context = Initialize-BuildContext `
        -Context $Context `
        -Config $Config

    # --------------------------------------------------
    # ISO
    # --------------------------------------------------

    $Context = Mount-Iso -Context $Context

    # --------------------------------------------------
    # WIM
    # --------------------------------------------------

    $Context = Get-WimFile -Context $Context

    $Context = Get-WimImages -Context $Context

    $Context = Select-WimImage -Context $Context

    $Context = Mount-Wim -Context $Context

    # --------------------------------------------------
    # Validation
    # --------------------------------------------------

    $windowsFolder = Join-Path `
        $Context.WIM.Mount.Path `
        "Windows"

    if (Test-Path $windowsFolder) {

        Write-Host ""
        Write-Host "Le WIM est correctement monté." -ForegroundColor Green

    }
    else {

        throw "Le dossier Windows est introuvable."

    }

    Write-Host ""

    Write-Host "Edition      : $($Context.Image.Name)"
    Write-Host "Index        : $($Context.Image.Index)"
    Write-Host "Montage      : $($Context.WIM.Mount.Path)"

}
catch {

    Write-Log $_.Exception.Message ERROR

}
finally {

    if ($Context.BuildState.Image.Mounted) {

        Dismount-Wim `
            -Context $Context

    }

    if ($Context.ISO.Mounted) {

        Dismount-DiskImage `
            -ImagePath $Context.ISO.FullName | Out-Null

    }

    Stop-Logger

    Write-Host ""
    Write-Host "Journal :" -ForegroundColor Yellow
    Write-Host $Global:LogFile

}