# ==========================================
# Module : PostInstall Installer
# Projet : PimsOS Builder
# Version : 1.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Prépare le runtime PostInstall dans une image
# Windows montée
# --------------------------------------------------

function Install-PimsOSPostInstallRuntime {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]$MountPath,

        [Parameter(Mandatory)]
        [string]$SourcePath,

        [Parameter()]
        [string]$ChocolateyProviderPath,

        [Parameter()]
        [string]$ChocolateyCatalogPath,

        [Parameter()]
        [string]$ChocolateyCachePath

    )

    # --------------------------------------------------
    # Validation
    # --------------------------------------------------

    if (-not (Test-Path -LiteralPath $MountPath -PathType Container)) {

        throw (
            "Le chemin de montage Windows est introuvable : {0}" -f
            $MountPath
        )

    }

    if (-not (Test-Path -LiteralPath $SourcePath -PathType Container)) {

        throw (
            "Le runtime PostInstall source est introuvable : {0}" -f
            $SourcePath
        )

    }

    # --------------------------------------------------
    # Chemin du Logger
    # --------------------------------------------------

    $ProjectRoot = Resolve-Path `
        "$PSScriptRoot\..\.." `
        -ErrorAction Stop

    $LoggerSourcePath = Join-Path `
        -Path $ProjectRoot.Path `
        -ChildPath "Modules\Infrastructure\Logger.ps1"

    # --------------------------------------------------
    # Vérifie les fichiers obligatoires
    # --------------------------------------------------

    $RequiredFiles = @(
		"Bootstrap.ps1"
		"Logger.ps1"
		"Network.ps1"
		"UI.ps1"
		"DriverCheck.ps1"
		"Chocolatey.ps1"
		"PostInstall.ps1"
        "Finalize.ps1"
		"State.ps1"
	)

    foreach ($FileName in $RequiredFiles) {

        if ($FileName -eq "Logger.ps1") {

            $SourceFile = $LoggerSourcePath

        }
        elseif ($FileName -eq "Chocolatey.ps1") {

            if ([string]::IsNullOrWhiteSpace($ChocolateyProviderPath)) {
                throw "Le chemin du provider Chocolatey est requis pour le runtime PostInstall."
            }
            $SourceFile = $ChocolateyProviderPath

        }
        else {

            $SourceFile = Join-Path `
                -Path $SourcePath `
                -ChildPath $FileName

        }

        if (-not (Test-Path -LiteralPath $SourceFile -PathType Leaf)) {

            throw (
                "Fichier PostInstall requis introuvable : {0}" -f
                $SourceFile
            )

        }

    }

    # --------------------------------------------------
    # Destination dans Windows
    # --------------------------------------------------

    $DestinationPath = Join-Path `
        -Path $MountPath `
        -ChildPath "ProgramData\PimsOS\PostInstall"

    if (-not (Test-Path -LiteralPath $DestinationPath -PathType Container)) {

        New-Item `
            -ItemType Directory `
            -Path $DestinationPath `
            -Force `
            -ErrorAction Stop |
            Out-Null

    }

    # --------------------------------------------------
    # Copie du runtime
    # --------------------------------------------------

    foreach ($FileName in $RequiredFiles) {

        if ($FileName -eq "Logger.ps1") {

            $SourceFile = $LoggerSourcePath

        }
        elseif ($FileName -eq "Chocolatey.ps1") {

            if ([string]::IsNullOrWhiteSpace($ChocolateyProviderPath)) {
                throw "Le chemin du provider Chocolatey est requis pour le runtime PostInstall."
            }
            $SourceFile = $ChocolateyProviderPath

        }
        else {

            $SourceFile = Join-Path `
                -Path $SourcePath `
                -ChildPath $FileName

        }

        $DestinationFile = Join-Path `
            -Path $DestinationPath `
            -ChildPath $FileName

        Copy-Item `
            -LiteralPath $SourceFile `
            -Destination $DestinationFile `
            -Force `
            -ErrorAction Stop

    }

    # --------------------------------------------------
    # Vérification
    # --------------------------------------------------

    foreach ($FileName in $RequiredFiles) {

        $DestinationFile = Join-Path `
            -Path $DestinationPath `
            -ChildPath $FileName

        if (-not (Test-Path -LiteralPath $DestinationFile -PathType Leaf)) {

            throw (
                "Le fichier PostInstall n'a pas été copié correctement : {0}" -f
                $DestinationFile
            )

        }

    }

    # --------------------------------------------------
    # Catalogue Chocolatey + cache offline
    # --------------------------------------------------

    $RuntimeChocolateyPath = Join-Path $DestinationPath "Chocolatey"
    if (-not (Test-Path -LiteralPath $RuntimeChocolateyPath -PathType Container)) {
        New-Item -ItemType Directory -Path $RuntimeChocolateyPath -Force -ErrorAction Stop | Out-Null
    }

    if (-not [string]::IsNullOrWhiteSpace($ChocolateyCatalogPath)) {
        if (-not (Test-Path -LiteralPath $ChocolateyCatalogPath -PathType Leaf)) {
            throw "Le catalogue Chocolatey est introuvable : $ChocolateyCatalogPath"
        }
        Copy-Item -LiteralPath $ChocolateyCatalogPath -Destination (Join-Path $RuntimeChocolateyPath "Chocolatey.json") -Force -ErrorAction Stop
    }

    if (-not [string]::IsNullOrWhiteSpace($ChocolateyCachePath)) {
        if (-not (Test-Path -LiteralPath $ChocolateyCachePath -PathType Container)) {
            throw "Le cache Chocolatey est introuvable : $ChocolateyCachePath"
        }
        $RuntimeCachePath = Join-Path $RuntimeChocolateyPath "Cache"
        New-Item -ItemType Directory -Path $RuntimeCachePath -Force -ErrorAction Stop | Out-Null
        Get-ChildItem -LiteralPath $ChocolateyCachePath -Filter '*.nupkg' -File -ErrorAction Stop |
            Copy-Item -Destination $RuntimeCachePath -Force -ErrorAction Stop
    }

    return [PSCustomObject]@{

        ObjectType = "PimsOSPostInstallRuntime"

        SourcePath = $SourcePath

        LoggerSourcePath = $LoggerSourcePath

        MountPath = $MountPath

        DestinationPath = $DestinationPath

        Files = $RequiredFiles

        ChocolateyCatalogPath = if ([string]::IsNullOrWhiteSpace($ChocolateyCatalogPath)) { $null } else { Join-Path $RuntimeChocolateyPath "Chocolatey.json" }

        ChocolateyCachePath = if ([string]::IsNullOrWhiteSpace($ChocolateyCachePath)) { $null } else { Join-Path $RuntimeChocolateyPath "Cache" }

        Installed = $true

    }

}

# --------------------------------------------------
# Génère et installe unattend.xml
# --------------------------------------------------

function Install-PimsOSFirstBoot {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]$MountPath,

        [Parameter(Mandatory)]
        [string]$BootstrapPath

    )

    if (-not (Test-Path -LiteralPath $MountPath -PathType Container)) {

        throw (
            "Le chemin de montage Windows est introuvable : {0}" -f
            $MountPath
        )

    }

    if ([string]::IsNullOrWhiteSpace($BootstrapPath)) {

        throw "Le chemin du Bootstrap FirstBoot est vide."

    }

    # --------------------------------------------------
    # Construction de la configuration FirstBoot
    # --------------------------------------------------

    $FirstBootConfiguration =
        New-PimsOSFirstBootConfiguration `
            -BootstrapPath $BootstrapPath

    # --------------------------------------------------
    # Destination unattend
    # --------------------------------------------------

    $UnattendDirectory = Join-Path `
        -Path $MountPath `
        -ChildPath "Windows\Panther"

    if (-not (Test-Path -LiteralPath $UnattendDirectory -PathType Container)) {

        New-Item `
            -ItemType Directory `
            -Path $UnattendDirectory `
            -Force `
            -ErrorAction Stop |
            Out-Null

    }

    $UnattendPath = Join-Path `
        -Path $UnattendDirectory `
        -ChildPath "unattend.xml"

    # --------------------------------------------------
    # Génération
    # --------------------------------------------------

    $null = Export-PimsOSUnattendDocument `
        -FirstBootConfiguration $FirstBootConfiguration `
        -Path $UnattendPath

    # --------------------------------------------------
    # Vérification
    # --------------------------------------------------

    if (-not (Test-Path -LiteralPath $UnattendPath -PathType Leaf)) {

        throw (
            "Le fichier FirstBoot n'a pas été créé : {0}" -f
            $UnattendPath
        )

    }

    return [PSCustomObject]@{

        ObjectType = "PimsOSFirstBoot"

        MountPath = $MountPath

        BootstrapPath = $BootstrapPath

        UnattendPath = $UnattendPath

        Installed = $true

    }

}

# --------------------------------------------------
# Retourne le chemin du runtime PostInstall du projet
# --------------------------------------------------

function Get-PostInstallRuntimePath {

    [CmdletBinding()]
    param()

    $ProjectRoot = Resolve-Path `
        "$PSScriptRoot\..\.." `
        -ErrorAction Stop

    $RuntimePath = Join-Path `
        -Path $ProjectRoot.Path `
        -ChildPath "Modules\PostInstall"

    if (-not (Test-Path -LiteralPath $RuntimePath -PathType Container)) {

        throw (
            "Le runtime PostInstall du projet est introuvable : {0}" -f
            $RuntimePath
        )

    }

    return $RuntimePath

}