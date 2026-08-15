# ==========================================
# Test d'intégration
# Projet : PimsOS Builder
# ==========================================

#Requires -Version 7.0

Set-StrictMode -Version Latest

# --------------------------------------------------
# Détermination du projet
# --------------------------------------------------

$ProjectRoot = Split-Path $PSScriptRoot -Parent

$ModuleManifest = Join-Path `
    $ProjectRoot `
    "Modules\PimsOS.psd1"

# --------------------------------------------------
# Chargement du module PimsOS
# --------------------------------------------------

if (-not (Test-Path $ModuleManifest)) {

    throw "Manifest PimsOS introuvable : $ModuleManifest"
}

Import-Module `
    $ModuleManifest `
    -Force `
    -ErrorAction Stop

# --------------------------------------------------
# En-tête
# --------------------------------------------------

Clear-Host

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "      Test d'intégration PimsOS" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# --------------------------------------------------
# Initialisation
# --------------------------------------------------

$Context = $null

try {

    Write-Host "[1/2] Initialisation..." -ForegroundColor Yellow

    $Context = Initialize-PimsOS

    if ($null -eq $Context) {

        throw "Initialize-PimsOS a retourné un BuildContext null."

    }

    Write-Host "OK" -ForegroundColor Green

}
catch {

    Write-Host ""
    Write-Host "ERREUR lors de l'initialisation :" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# --------------------------------------------------
# Vérification du BuildContext
# --------------------------------------------------

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
    Write-Host "ERREUR lors de la vérification du BuildContext :" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# --------------------------------------------------
# Résultat
# --------------------------------------------------

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "  Test d'intégration réussi" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""