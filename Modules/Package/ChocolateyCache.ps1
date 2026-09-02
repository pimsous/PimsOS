# ==========================================
# Module : Package / Chocolatey Cache
# Projet : PimsOS Builder
# Version : 1.0.3
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

        $Mode = if ($Package.PSObject.Properties.Name -contains 'Mode' -and
            -not [string]::IsNullOrWhiteSpace([string]$Package.Mode)) {
            [string]$Package.Mode
        } else {
            'Online'
        }

        if ($Mode -notin @('Offline','Online','Disabled')) {
            throw "Le package '$($Package.Id)' possède un Mode invalide '$Mode'. Valeurs attendues : Offline, Online, Disabled."
        }

        $FailurePolicy = if (
            $Package.PSObject.Properties.Name -contains 'FailurePolicy' -and
            -not [string]::IsNullOrWhiteSpace([string]$Package.FailurePolicy)
        ) {
            [string]$Package.FailurePolicy
        }
        else {
            'Stop'
        }

        if ($FailurePolicy -notin @('Stop','Continue')) {
            throw "Le package '$($Package.Id)' possède une FailurePolicy invalide '$FailurePolicy'. Valeurs attendues : Stop, Continue."
        }
    }

    return $Packages
}

# --------------------------------------------------
# Recherche un package déjà présent dans le cache
# --------------------------------------------------
function Find-ChocolateyCachePackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$CachePath,
        [Parameter(Mandatory)][string]$Name,
        [string]$Version
    )

    if (-not (Test-Path -LiteralPath $CachePath -PathType Container)) {
        return $null
    }

    $Pattern = if ([string]::IsNullOrWhiteSpace($Version)) {
        "$Name*.nupkg"
    }
    else {
        "$Name.$Version.nupkg"
    }

    return Get-ChildItem -LiteralPath $CachePath -File -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -like $Pattern -and
            $_.Extension -ieq '.nupkg'
        } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
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

    $Existing = Find-ChocolateyCachePackage `
        -CachePath $CachePath `
        -Name ([string]$Package.Id) `
        -Version $Version

    if ($null -ne $Existing) {
        return [pscustomobject]@{
            Id         = [string]$Package.Id
            Status     = 'Cached'
            Path       = $Existing.FullName
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
        Id         = [string]$Package.Id
        Status     = 'Downloaded'
        Path       = $Destination
        Downloaded = $true
    }
}

# --------------------------------------------------
# Vérifie que le package bootstrap Chocolatey est bien
# présent et exploitable dans le cache de Build.
# --------------------------------------------------
function Test-ChocolateyBootstrapPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$CachePath
    )

    if (-not (Test-Path -LiteralPath $CachePath -PathType Container)) {
        throw "Le cache Chocolatey est introuvable : $CachePath"
    }

    $Package = Get-ChildItem -LiteralPath $CachePath -File -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -eq 'chocolatey.nupkg' -or $_.Name -like 'chocolatey.*.nupkg'
        } |
        Sort-Object @{Expression={ if ($_.Name -eq 'chocolatey.nupkg') { 0 } else { 1 } }}, Name |
        Select-Object -First 1

    if ($null -eq $Package) {
        throw "Le package bootstrap Chocolatey est absent du cache Build : $CachePath"
    }

    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop
        $Archive = [System.IO.Compression.ZipFile]::OpenRead($Package.FullName)
        try {
            $InstallScript = $Archive.Entries |
                Where-Object { $_.FullName -ieq 'tools/chocolateyInstall.ps1' -or $_.FullName -ieq 'tools\\chocolateyInstall.ps1' } |
                Select-Object -First 1

            if ($null -eq $InstallScript) {
                throw "Le package bootstrap Chocolatey '$($Package.Name)' ne contient pas tools\\chocolateyInstall.ps1."
            }
        }
        finally {
            $Archive.Dispose()
        }
    }
    catch {
        throw "Le package bootstrap Chocolatey '$($Package.Name)' n'est pas un .nupkg exploitable : $($_.Exception.Message)"
    }

    return [pscustomobject]@{
        Present = $true
        Path    = $Package.FullName
        Name    = $Package.Name
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
    $Packages = @(Get-ChocolateyPackageDefinitions -Path $CatalogPath | Where-Object {
        $Mode = if ($_.PSObject.Properties.Name -contains 'Mode' -and -not [string]::IsNullOrWhiteSpace([string]$_.Mode)) { [string]$_.Mode } else { 'Online' }
        $Mode -eq 'Offline'
    })

    $Results = [System.Collections.Generic.List[object]]::new()

    foreach ($Package in $Packages) {
        $Results.Add(
            (Save-ChocolateyPackageToCache -Package $Package -CachePath $CachePath)
        )
    }

    return [pscustomobject]@{
        CachePath     = $CachePath
        Total         = $Packages.Count
        Results       = @($Results)
        Downloaded    = @($Results | Where-Object Downloaded).Count
        AlreadyCached = @($Results | Where-Object { $_.Status -eq 'Cached' }).Count
    }
}
