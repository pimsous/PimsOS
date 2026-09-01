# ==========================================
# Module : Package / Chocolatey
# Projet : PimsOS Builder
# Version : 1.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Retourne le cache Chocolatey PimsOS
# --------------------------------------------------
function Get-ChocolateyCachePath {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context

    )

    if ($null -eq $Context.Workspace) {
        throw "Le contexte ne contient pas de section Workspace."
    }

    $CachePath = $null

    if ($Context.Workspace.PSObject.Properties.Name -contains "PackagesChocolatey") {
        $CachePath = [string]$Context.Workspace.PackagesChocolatey
    }
    elseif ($Context.Workspace.PSObject.Properties.Name -contains "Cache") {
        $CachePath = Join-Path `
            -Path ([string]$Context.Workspace.Cache) `
            -ChildPath "Chocolatey"
    }

    if ([string]::IsNullOrWhiteSpace($CachePath)) {
        throw "Aucun chemin de cache Chocolatey n'est défini dans le contexte."
    }

    if (-not (Test-Path -LiteralPath $CachePath -PathType Container)) {
        New-Item `
            -ItemType Directory `
            -Path $CachePath `
            -Force `
            -ErrorAction Stop |
            Out-Null
    }

    return (Resolve-Path -LiteralPath $CachePath -ErrorAction Stop).Path
}

# --------------------------------------------------
# Vérifie la disponibilité de Chocolatey
# --------------------------------------------------
function Test-ChocolateyAvailable {

    [CmdletBinding()]
    param()

    return $null -ne (
        Get-Command `
            -Name "choco.exe" `
            -CommandType Application `
            -ErrorAction SilentlyContinue
    )
}

# --------------------------------------------------
# Exécute Chocolatey et retourne son code de sortie
# --------------------------------------------------
function Invoke-ChocolateyCli {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string[]]$Arguments

    )

    $Choco = Get-Command `
        -Name "choco.exe" `
        -CommandType Application `
        -ErrorAction Stop

    Write-Log (
        "Chocolatey : choco.exe {0}" -f
        ($Arguments -join " ")
    ) INFO

    & $Choco.Source @Arguments
    $ExitCode = $LASTEXITCODE

    return [pscustomobject]@{
        ExitCode = [int]$ExitCode
    }
}

# --------------------------------------------------
# Cherche un package Chocolatey déjà présent dans le cache
# --------------------------------------------------
function Find-ChocolateyCachedPackage {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]$CachePath,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter()]
        [string]$Version

    )

    $Pattern = if ([string]::IsNullOrWhiteSpace($Version)) {
        "{0}.*.nupkg" -f $Name
    }
    else {
        "{0}.{1}.nupkg" -f $Name, $Version
    }

    return Get-ChildItem `
        -LiteralPath $CachePath `
        -Filter $Pattern `
        -File `
        -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}

# --------------------------------------------------
# Applique un package Chocolatey
# --------------------------------------------------
function Invoke-ChocolateyPackage {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [psobject]$Action

    )

    if ([string]::IsNullOrWhiteSpace($Action.Name)) {
        throw "Le nom du package Chocolatey est obligatoire."
    }

    if (-not (Test-ChocolateyAvailable)) {
        throw "Chocolatey (choco.exe) est introuvable."
    }

    $CachePath = Get-ChocolateyCachePath -Context $Context
    $CommunitySource = "https://community.chocolatey.org/api/v2/"

    $Version = $null
    if ($Action.PSObject.Properties.Name -contains "Version") {
        $Version = [string]$Action.Version
    }

    $CachedPackage = Find-ChocolateyCachedPackage `
        -CachePath $CachePath `
        -Name $Action.Name `
        -Version $Version

    if ($null -ne $CachedPackage) {
        Write-Log (
            "Package Chocolatey trouvé dans le cache : {0}" -f
            $CachedPackage.Name
        ) INFO
    }
    else {
        Write-Log (
            "Package Chocolatey absent du cache : {0}. Chocolatey pourra le récupérer depuis la source configurée." -f
            $Action.Name
        ) INFO
    }

    # Le cache est persistant et partagé entre les installations.
    # La source locale est prioritaire, avec le dépôt communautaire
    # en secours pour les packages/dépendances absents du cache.
    $Source = "{0};{1}" -f $CachePath, $CommunitySource

    $Arguments = @(
        "install",
        $Action.Name,
        "--yes",
        "--no-progress",
        "--cache-location=$CachePath",
        "--source=$Source",
        "--stop-on-first-package-failure"
    )

    if (-not [string]::IsNullOrWhiteSpace($Version)) {
        $Arguments += "--version=$Version"
    }

    if ($Action.PSObject.Properties.Name -contains "PackageParameters" -and
        -not [string]::IsNullOrWhiteSpace([string]$Action.PackageParameters)) {

        $Arguments += "--package-parameters=$($Action.PackageParameters)"
    }

    if ($Action.PSObject.Properties.Name -contains "InstallArguments" -and
        -not [string]::IsNullOrWhiteSpace([string]$Action.InstallArguments)) {

        $Arguments += "--install-arguments=$($Action.InstallArguments)"
    }

    $Result = Invoke-ChocolateyCli -Arguments $Arguments

    # Chocolatey documente 0 comme succès normal et 1641/3010 comme
    # succès avec redémarrage. Ces codes ne doivent pas faire échouer PimsOS.
    if ($Result.ExitCode -notin @(0, 1641, 3010)) {
        throw (
            "Chocolatey a échoué pour '{0}' avec le code de sortie {1}." -f
            $Action.Name,
            $Result.ExitCode
        )
    }

    if ($Result.ExitCode -in @(1641, 3010)) {
        Write-Log (
            "Package '{0}' installé, mais un redémarrage est requis (code {1})." -f
            $Action.Name,
            $Result.ExitCode
        ) WARNING
    }
    else {
        Write-Log (
            "Package Chocolatey '{0}' installé avec succès." -f
            $Action.Name
        ) SUCCESS
    }

    return $Context
}
