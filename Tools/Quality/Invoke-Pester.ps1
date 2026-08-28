# ==========================================
# PimsOS Builder
# Runner Pester
# ==========================================

[CmdletBinding()]
param(
    [ValidateSet("All", "Unit", "Integration", "Legacy")]
    [string]$Scope = "All",

    [switch]$Detailed
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")

$Paths = switch ($Scope) {

    "Unit" {
        @(
            Join-Path $ProjectRoot "Tests\Unit"
        )
    }

    "Integration" {
        @(
            Join-Path $ProjectRoot "Tests\Integration"
        )
    }

    "Legacy" {
        @(
            Join-Path $ProjectRoot "Tests\Legacy"
        )
    }

    "All" {
        @(
            Join-Path $ProjectRoot "Tests\Unit"
            Join-Path $ProjectRoot "Tests\Integration"
        )
    }
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " PimsOS - Pester Test Runner" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Scope : $Scope"
Write-Host ""

$Config = New-PesterConfiguration

$Config.Run.Path = $Paths
$Config.Run.Exit = $false
$Config.Run.PassThru = $true

if ($Detailed) {
    $Config.Output.Verbosity = "Detailed"
}
else {
    $Config.Output.Verbosity = "Normal"
}

Write-Host "Tests exécutés :" -ForegroundColor Yellow

foreach ($Path in $Paths) {
    Write-Host "  $Path"
}

Write-Host ""

$Result = Invoke-Pester -Configuration $Config

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Résultat" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

Write-Host "Tests      : $($Result.TotalCount)"
Write-Host "Réussis    : $($Result.PassedCount)"
Write-Host "Échecs     : $($Result.FailedCount)"
Write-Host "Ignorés     : $($Result.SkippedCount)"
Write-Host ""

if ($Result.FailedCount -gt 0) {
    Write-Host "Pester : ÉCHEC" -ForegroundColor Red
    exit 1
}

Write-Host "Pester : OK" -ForegroundColor Green
exit 0