# ==========================================
# Module : Package / Chocolatey Cache
# Projet : PimsOS Builder
# Version : 1.0.2
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Charge les définitions de packages Chocolatey
# --------------------------------------------------
function Get-ChocolateyPackageDefinitions {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Le catalogue Chocolatey est introuvable : $Path"
    }

    try {
        $Catalog = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop |
            ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "Impossible de lire le catalogue Chocolatey '$Path' : $($_.Exception.Message)"
    }

    if ($null -eq $Catalog.Packages) {
        throw "Le catalogue Chocolatey ne contient aucune collection 'Packages'."
    }

    $Packages = @($Catalog.Packages | Where-Object {
        $_.PSObject.Properties.Name -contains 'Enabled' -and [bool]$_.Enabled
    })

    foreach ($Package in $Packages) {
        if (-not ($Package.PSObject.Properties.Name -contains 'Id')) {
            throw "Une entrée activée du catalogue Chocolatey ne possède pas d'Id."
        }

        if ([string]::IsNullOrWhiteSpace([string]$Package.Id)) {
            throw "Une entrée activée du catalogue Chocolatey ne possède pas d'Id."
        }
    }

    return $Packages
}

# --------------------------------------------------
# Télécharge un package .nupkg dans le cache
# --------------------------------------------------
function Save-ChocolateyPackageToCache {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][psobject]$Package,
        [Parameter(Mandatory)][string]$CachePath,
        [string]$Source = 'https://community.chocolatey.org/api/v2/package'
    )

    if (-not ($Package.PSObject.Properties.Name -contains 'Id')) {
        throw "L'Id du package Chocolatey est obligatoire."
    }

    if ([string]::IsNullOrWhiteSpace([string]$Package.Id)) {
        throw "L'Id du package Chocolatey est obligatoire."
    }

    if (-not (Test-Path -LiteralPath $CachePath -PathType Container)) {
        New-Item -ItemType Directory -Path $CachePath -Force -ErrorAction Stop | Out-Null
    }

    $CachePath = (Resolve-Path -LiteralPath $CachePath -ErrorAction Stop).Path

    $Version = $null
    if ($Package.PSObject.Properties.Name -contains 'Version' -and
        -not [string]::IsNullOrWhiteSpace([string]$Package.Version)) {
        $Version = [string]$Package.Version
    }

    # Utiliser le même moteur de détection que le provider Chocolatey.
    # Cela garantit un contrat unique pour la reconnaissance des .nupkg
    # versionnés et non versionnés.
    $Existing = Find-ChocolateyCachedPackage `
        -CachePath $CachePath `
        -Name ([string]$Package.Id) `
        -Version $Version

    if ($null -ne $Existing) {
        return [pscustomobject]@{
            Id = [string]$Package.Id
            Status = 'Cached'
            Path = $Existing.FullName
            Downloaded = $false
        }
    }

    $Uri = if ($Version) {
        "$Source/$($Package.Id)/$Version"
    }
    else {
        "$Source/$($Package.Id)"
    }

    $Destination = if ($Version) {
        Join-Path $CachePath "$($Package.Id).$Version.nupkg"
    }
    else {
        Join-Path $CachePath "$($Package.Id).nupkg"
    }

    try {
        Invoke-WebRequest -Uri $Uri -OutFile $Destination -UseBasicParsing -ErrorAction Stop
    }
    catch {
        Remove-Item -LiteralPath $Destination -Force -ErrorAction SilentlyContinue
        throw "Impossible de télécharger le package Chocolatey '$($Package.Id)' : $($_.Exception.Message)"
    }

    if (-not (Test-Path -LiteralPath $Destination -PathType Leaf)) {
        throw "Le téléchargement du package '$($Package.Id)' n'a pas produit de fichier."
    }

    return [pscustomobject]@{
        Id = [string]$Package.Id
        Status = 'Downloaded'
        Path = $Destination
        Downloaded = $true
    }
}

# --------------------------------------------------
# Prépare le cache persistant des packages activés
# --------------------------------------------------
function Initialize-ChocolateyCache {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][psobject]$Context,
        [Parameter(Mandatory)][string]$CatalogPath
    )

    $CachePath = Get-ChocolateyCachePath -Context $Context
    $Packages = @(Get-ChocolateyPackageDefinitions -Path $CatalogPath)
    $Results = [System.Collections.Generic.List[object]]::new()

    foreach ($Package in $Packages) {
        $Results.Add(
            (Save-ChocolateyPackageToCache -Package $Package -CachePath $CachePath)
        )
    }

    return [pscustomobject]@{
        CachePath = $CachePath
        Total = $Packages.Count
        Results = @($Results)
        Downloaded = @($Results | Where-Object Downloaded).Count
        AlreadyCached = @($Results | Where-Object { $_.Status -eq 'Cached' }).Count
    }
}
