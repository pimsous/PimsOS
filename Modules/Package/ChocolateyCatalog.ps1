# ==========================================
# Module : Package / Chocolatey Catalog
# Projet : PimsOS Builder
# Version : 1.0.0
# ==========================================

Set-StrictMode -Version Latest

function Get-ChocolateyCatalogPath {
    [CmdletBinding()]
    param([Parameter(Mandatory)][psobject]$Context)

    if ($null -eq $Context.Project -or [string]::IsNullOrWhiteSpace([string]$Context.Project.Root)) {
        throw "Le contexte ne contient pas de racine de projet valide."
    }

    return Join-Path ([string]$Context.Project.Root) 'Config\Packages\Chocolatey.json'
}

function Read-ChocolateyCatalog {
    [CmdletBinding()]
    param([Parameter(Mandatory)][psobject]$Context)

    $Path = Get-ChocolateyCatalogPath -Context $Context
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Catalogue Chocolatey introuvable : $Path"
    }

    $Catalog = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($null -eq $Catalog.Packages) {
        $Catalog | Add-Member -MemberType NoteProperty -Name Packages -Value @()
    }

    return $Catalog
}

function Save-ChocolateyCatalog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][psobject]$Context,
        [Parameter(Mandatory)][psobject]$Catalog
    )

    $Path = Get-ChocolateyCatalogPath -Context $Context
    $Directory = Split-Path -Parent $Path
    New-Item -ItemType Directory -Path $Directory -Force -ErrorAction Stop | Out-Null

    $Json = $Catalog | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText(
        $Path,
        $Json + [Environment]::NewLine,
        (New-Object System.Text.UTF8Encoding($false))
    )

    return $Path
}

function Test-ChocolateyCatalogPackageId {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Id)

    return $Id -match '^[a-z0-9][a-z0-9.-]*$'
}

function Add-ChocolateyCatalogPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][psobject]$Context,
        [Parameter(Mandatory)][string]$Id,
        [string]$Version,
        [ValidateSet('Online','Offline','Disabled')][string]$Mode = 'Online',
        [ValidateSet('Stop','Continue')][string]$FailurePolicy = 'Stop',
        [string]$Category = 'Other'
    )

    $Id = $Id.Trim().ToLowerInvariant()
    if (-not (Test-ChocolateyCatalogPackageId -Id $Id)) {
        throw "Identifiant Chocolatey invalide : '$Id'."
    }

    if ($Id -eq 'chocolatey') {
        throw "Le package 'chocolatey' est réservé au bootstrap PimsOS et ne doit pas être ajouté manuellement."
    }

    $Catalog = Read-ChocolateyCatalog -Context $Context
    $Packages = @($Catalog.Packages)

    if ($Packages | Where-Object { [string]$_.Id -ieq $Id }) {
        throw "Le package '$Id' existe déjà dans le catalogue."
    }

    $Package = [ordered]@{
        Id       = $Id
        Enabled  = ($Mode -ne 'Disabled')
        Category = if ([string]::IsNullOrWhiteSpace($Category)) { 'Other' } else { $Category.Trim() }
        Mode          = $Mode
        FailurePolicy = $FailurePolicy
        Version       = if ([string]::IsNullOrWhiteSpace($Version)) { $null } else { $Version.Trim() }
    }

    $Catalog.Packages = @($Packages + [pscustomobject]$Package)
    Save-ChocolateyCatalog -Context $Context -Catalog $Catalog | Out-Null
    Write-Log "Package Chocolatey ajouté au catalogue : $Id ($Mode)." SUCCESS

    return [pscustomobject]$Package
}

function Remove-ChocolateyCatalogPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][psobject]$Context,
        [Parameter(Mandatory)][string]$Id
    )

    $Id = $Id.Trim().ToLowerInvariant()
    if ($Id -eq 'chocolatey') {
        throw "Le package 'chocolatey' est obligatoire pour le bootstrap PimsOS et ne peut pas être supprimé."
    }

    $Catalog = Read-ChocolateyCatalog -Context $Context
    $Packages = @($Catalog.Packages)
    $Match = @($Packages | Where-Object { [string]$_.Id -ieq $Id })

    if ($Match.Count -eq 0) {
        throw "Le package '$Id' n'existe pas dans le catalogue."
    }

    $Catalog.Packages = @($Packages | Where-Object { [string]$_.Id -ine $Id })
    Save-ChocolateyCatalog -Context $Context -Catalog $Catalog | Out-Null
    Write-Log "Package Chocolatey supprimé du catalogue : $Id." INFO
    return $true
}
