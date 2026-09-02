# ==========================================
# Module : Package / Chocolatey
# Projet : PimsOS Builder
# Version : 1.0.0
# Compatible : PowerShell 5.1+
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

    # Capture la sortie de choco.exe afin qu'elle ne soit pas mélangée
    # à l'objet de résultat retourné. Ceci est indispensable sous
    # Windows PowerShell 5.1 : l'affectation d'un appel natif peut
    # sinon produire un tableau contenant les lignes stdout + l'objet
    # ExitCode, et $Result.ExitCode échoue alors sur les chaînes.
    $ChocoOutput = @(& $Choco.Source @Arguments 2>&1)
    $ExitCode = $LASTEXITCODE

    foreach ($OutputLine in $ChocoOutput) {
        if ($null -ne $OutputLine -and -not [string]::IsNullOrWhiteSpace([string]$OutputLine)) {
            Write-Log ([string]$OutputLine) INFO
        }
    }

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
# Installe Chocolatey depuis le package embarqué
# --------------------------------------------------
function Install-ChocolateyBootstrap {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$BootstrapPackagePath
    )

    if (Test-ChocolateyAvailable) {
        return $true
    }

    if (-not (Test-Path -LiteralPath $BootstrapPackagePath -PathType Leaf)) {
        throw "Le package bootstrap Chocolatey est introuvable : $BootstrapPackagePath"
    }

    $TempPath = Join-Path $env:TEMP ("PimsOS-ChocolateyBootstrap-" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $TempPath -Force -ErrorAction Stop | Out-Null

    try {
        Write-Log "Installation locale de Chocolatey depuis le cache PimsOS." INFO

        # Un .nupkg Chocolatey est une archive ZIP. Expand-Archive dépend de
        # l'extension .zip et refuse donc certains .nupkg sous Windows
        # PowerShell 5.1 comme sous PowerShell 7. On utilise directement
        # l'API .NET commune aux deux environnements.
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory(
            $BootstrapPackagePath,
            $TempPath
        )

        $InstallScript = Join-Path $TempPath 'tools\chocolateyInstall.ps1'

        if (-not (Test-Path -LiteralPath $InstallScript -PathType Leaf)) {
            throw "Le package bootstrap Chocolatey ne contient pas tools\chocolateyInstall.ps1."
        }

        & $InstallScript
        if ($LASTEXITCODE -notin @(0, $null)) {
            throw "Le script d'installation local de Chocolatey a retourné le code $LASTEXITCODE."
        }

        if (-not (Test-ChocolateyAvailable)) {
            $Candidate = Join-Path $env:ProgramData 'chocolatey\bin\choco.exe'
            if (Test-Path -LiteralPath $Candidate -PathType Leaf) {
                $env:Path = "$(Split-Path $Candidate);$env:Path"
            }
        }

        if (-not (Test-ChocolateyAvailable)) {
            throw "Chocolatey n'est pas disponible après son installation locale."
        }

        Write-Log "Chocolatey installé localement avec succès." SUCCESS
        return $true
    }
    finally {
        Remove-Item -LiteralPath $TempPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# --------------------------------------------------
# Installe les packages du catalogue selon leur Mode
# --------------------------------------------------
function Invoke-ChocolateyCatalog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][psobject]$Context,
        [Parameter(Mandatory)][string]$CatalogPath,
        [Parameter(Mandatory)][string]$RuntimeCachePath
    )

    if (-not (Test-Path -LiteralPath $CatalogPath -PathType Leaf)) {
        throw "Le catalogue Chocolatey runtime est introuvable : $CatalogPath"
    }

    if (-not (Test-Path -LiteralPath $RuntimeCachePath -PathType Container)) {
        New-Item -ItemType Directory -Path $RuntimeCachePath -Force -ErrorAction Stop | Out-Null
    }

    $Catalog = Get-Content -LiteralPath $CatalogPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    $Packages = @($Catalog.Packages | Where-Object { $_.Enabled -eq $true })
    $Results = [System.Collections.Generic.List[object]]::new()

    foreach ($Package in $Packages) {
        $Mode = if ($Package.PSObject.Properties.Name -contains 'Mode' -and -not [string]::IsNullOrWhiteSpace([string]$Package.Mode)) { [string]$Package.Mode } else { 'Online' }
        if ($Mode -eq 'Disabled' -or $Package.Id -eq 'chocolatey') { continue }

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
            throw "FailurePolicy Chocolatey invalide pour '$($Package.Id)' : $FailurePolicy"
        }

        $Action = [pscustomobject]@{
            Name = [string]$Package.Id
            Version = if ($Package.PSObject.Properties.Name -contains 'Version') { [string]$Package.Version } else { $null }
            Mode = $Mode
            FailurePolicy = $FailurePolicy
        }

        Write-Log ("Installation Chocolatey : {0} [{1}]" -f $Action.Name, $Mode) INFO

        try {
            $null = Invoke-ChocolateyPackage -Context $Context -Action $Action
            $Results.Add([pscustomobject]@{
                Id = $Action.Name
                Mode = $Mode
                Status = 'Installed'
                FailurePolicy = $FailurePolicy
                Error = $null
            })
        }
        catch {
            $ErrorMessage = $_.Exception.Message

            if ($FailurePolicy -eq 'Stop') {
                throw
            }

            Write-Log (
                "Package Chocolatey '{0}' en échec, poursuite du PostInstall selon FailurePolicy=Continue : {1}" -f
                $Action.Name,
                $ErrorMessage
            ) WARNING

            $Results.Add([pscustomobject]@{
                Id = $Action.Name
                Mode = $Mode
                Status = 'Failed'
                FailurePolicy = $FailurePolicy
                Error = $ErrorMessage
            })
        }
    }

    return @($Results)
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

    $Mode = if ($Action.PSObject.Properties.Name -contains 'Mode' -and -not [string]::IsNullOrWhiteSpace([string]$Action.Mode)) { [string]$Action.Mode } else { 'Online' }

    if ($Mode -notin @('Offline','Online')) {
        throw "Mode Chocolatey invalide pour '$($Action.Name)' : $Mode"
    }

    $CachedPackage = Find-ChocolateyCachedPackage `
        -CachePath $CachePath `
        -Name $Action.Name `
        -Version $Version

    if ($Mode -eq 'Offline') {
        if ($null -eq $CachedPackage) {
            throw "Le package Chocolatey '$($Action.Name)' est en mode Offline mais absent du cache PimsOS."
        }
        Write-Log ("Package Chocolatey offline trouvé : {0}" -f $CachedPackage.Name) INFO
        $Source = $CachePath
    }
    else {
        if ($null -ne $CachedPackage) {
            Write-Log ("Package Chocolatey online déjà présent dans le cache : {0}" -f $CachedPackage.Name) INFO
        }
        else {
            Write-Log ("Package Chocolatey online : téléchargement depuis Community : {0}" -f $Action.Name) INFO
        }
        $Source = $CommunitySource
    }

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
