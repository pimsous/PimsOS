# ==========================================
# PimsOS Builder
# Build-PimsOS.ps1
# ==========================================

#Requires -Version 7.6

[CmdletBinding()]
param()

# ==========================================
# Initialisation
# ==========================================

$ProjectRoot = Split-Path $PSScriptRoot -Parent
$ModulesRoot = Join-Path $ProjectRoot "Modules"

Import-Module `
    (Join-Path $ModulesRoot "PimsOS.psd1") `
    -Force `
    -ErrorAction Stop

# ==========================================
# Version
# ==========================================

$BuilderVersion = "0.3.0-dev"

Clear-Host

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "               PimsOS Builder" -ForegroundColor Cyan
Write-Host ("                    v{0}" -f $BuilderVersion) -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ("PowerShell : {0}" -f $PSVersionTable.PSVersion)
Write-Host ("Projet     : {0}" -f $ProjectRoot)
Write-Host ("Date       : {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
Write-Host ""

$ExitCode = 0
$Context = $null

try {

    # --------------------------------------------------
    # Initialisation
    # --------------------------------------------------

    $Context = Initialize-PimsOS

    # --------------------------------------------------
    # Résumé
    # --------------------------------------------------

    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "            Résumé du Build" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host ""

    if ($Context.BuildState.Image.Mounted) {

        $MountInfo = $Context.WIM.Mount.Path

    }
    elseif (
        $null -ne $Context.BuildState.Recovery.Wim -and
        $Context.BuildState.Recovery.Wim.Exists
    ) {

        $MountInfo = "Démonté"

    }
    else {

        $MountInfo = "Aucun montage"

    }

    Write-Host ("Edition      : {0}" -f $Context.Image.Name)
    Write-Host ("Sélection    : {0}" -f $Context.Image.SelectedBy)
    Write-Host ("Build        : {0}" -f $Context.Build.Id)
    Write-Host ("Index        : {0}" -f $Context.Image.Index)
    Write-Host ("Taille image : {0:N2} Go" -f ($Context.Image.Size / 1GB))
    Write-Host ("ISO          : {0}" -f $Context.ISO.Name)
    Write-Host ("Type WIM     : {0}" -f $Context.WIM.Type)
    Write-Host ("WIM          : {0}" -f $Context.WIM.Name)
    Write-Host ("Montage WIM  : {0}" -f $MountInfo)

}
catch {

    $ExitCode = 1

    Write-Host ""
    Write-Host "===== EXCEPTION =====" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""

    if ($_.ScriptStackTrace) {

        Write-Host $_.ScriptStackTrace -ForegroundColor Yellow
        Write-Host ""

    }

}
finally {

    Remove-Module `
        PimsOS `
        -ErrorAction SilentlyContinue

}

Write-Host ""
Read-Host "Appuyez sur Entrée pour fermer"

exit $ExitCode