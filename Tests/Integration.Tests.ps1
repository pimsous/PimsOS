# ==========================================
# Test d'intégration
# Projet : PimsOS Builder
# ==========================================

Clear-Host

$ProjectRoot = Split-Path $PSScriptRoot -Parent

Import-Module `
    "$ProjectRoot\Modules\PimsOS.psm1" `
    -Force

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "      Test d'intégration PimsOS" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# ----------------------------------------------------------
# Initialisation
# ----------------------------------------------------------

try {

    Write-Host "[1/2] Initialisation..." -ForegroundColor Yellow

    $Context = Initialize-PimsOS

    Write-Host "OK" -ForegroundColor Green

}
catch {

    Write-Host ""
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1

}

# ----------------------------------------------------------
# Vérification du BuildContext
# ----------------------------------------------------------

try {

    Write-Host "[2/2] Vérification du BuildContext..." -ForegroundColor Yellow

    if ($null -eq $Context) {

        throw "Le BuildContext est null."

    }

    if ($null -eq $Context.Project) {

        throw "Project absent."

    }

    if ($null -eq $Context.Workspace) {

        throw "Workspace absent."

    }

    if ($null -eq $Context.Report) {

        throw "Report absent."

    }

    Write-Host "OK" -ForegroundColor Green

}
catch {

    Write-Host ""
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1

}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "  Test d'intégration réussi" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""