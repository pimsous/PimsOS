
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
        [string]$SourcePath

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
    # Vérifie les fichiers obligatoires
    # --------------------------------------------------

    $RequiredFiles = @(
        "Bootstrap.ps1"
        "Network.ps1"
        "PostInstall.ps1"
        "State.ps1"
    )

    foreach ($FileName in $RequiredFiles) {

        $SourceFile = Join-Path `
            -Path $SourcePath `
            -ChildPath $FileName

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

        $SourceFile = Join-Path `
            -Path $SourcePath `
            -ChildPath $FileName

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

    return [PSCustomObject]@{

        ObjectType = "PimsOSPostInstallRuntime"

        SourcePath = $SourcePath

        MountPath = $MountPath

        DestinationPath = $DestinationPath

        Files = $RequiredFiles

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