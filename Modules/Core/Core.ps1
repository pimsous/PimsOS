# ==========================================
# Module : Core
# Projet : PimsOS Builder
# Version : 2.1.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# ==================================================
# Variables privées
# ==================================================

$script:ProjectRoot = $null
$script:Config      = $null
$script:Version     = $null

# ==================================================
# Initialisation du module
# ==================================================

function Initialize-Core {

    [CmdletBinding()]
    param()

    if ($script:ProjectRoot) {

        return

    }

    $script:ProjectRoot = (
        Resolve-Path (
            Join-Path $PSScriptRoot "..\.."
        )
    ).Path

}

# ==================================================
# Retourne le dossier racine du projet
# ==================================================

function Get-ProjectRoot {

    [CmdletBinding()]
    param()

    if (-not $script:ProjectRoot) {

        Initialize-Core

    }

    return $script:ProjectRoot

}

# ==================================================
# Charge la configuration
# ==================================================

function Get-Config {

    [CmdletBinding()]
    param(

        [switch]$Reload

    )

    if (
        $script:Config -and
        -not $Reload
    ) {

        return $script:Config

    }

    if (-not $script:ProjectRoot) {

        Initialize-Core

    }

    $ConfigPath = Join-Path `
        $script:ProjectRoot `
        "Config\Config.json"

    if (-not (Test-Path $ConfigPath)) {

        throw (
            "Le fichier de configuration est introuvable : {0}" -f
            $ConfigPath
        )

    }

    try {

        $script:Config = Get-Content `
            -Path $ConfigPath `
            -Raw `
            -Encoding UTF8 `
            -ErrorAction Stop |
            ConvertFrom-Json

    }
    catch {

        throw @"

Impossible de charger le fichier de configuration.

$ConfigPath

$($_.Exception.Message)

"@

    }

    return $script:Config

}

# ==================================================
# Retourne les informations de version
# ==================================================

function Get-ProjectVersion {

    [CmdletBinding()]
    param(

        [switch]$Reload

    )

    if (
        $script:Version -and
        -not $Reload
    ) {

        return $script:Version

    }

    if (-not $script:ProjectRoot) {

        Initialize-Core

    }

    $VersionPath = Join-Path `
        $script:ProjectRoot `
        "version.json"

    if (-not (Test-Path $VersionPath)) {

        throw (
            "Le fichier de version est introuvable : {0}" -f
            $VersionPath
        )

    }

    try {

        $script:Version = Get-Content `
            -Path $VersionPath `
            -Raw `
            -Encoding UTF8 `
            -ErrorAction Stop |
            ConvertFrom-Json

        return $script:Version

    }
    catch {

        throw @"

Impossible de charger le fichier version.json.

$VersionPath

$($_.Exception.Message)

"@

    }

}

# ==================================================
# Retourne une propriété d'un objet
# ==================================================

function Get-ObjectProperty {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Object,

        [Parameter(Mandatory)]
        [string]$Name,

        $Default = $null

    )

    if (
        $null -ne $Object -and
        $Object.PSObject.Properties[$Name]
    ) {

        return $Object.$Name

    }

    return $Default

}

# ==================================================
# Retourne un chemin du projet
# ==================================================

function Get-ProjectPath {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [ValidateSet(
            "ISO",
            "Logs",
            "Output",
            "Mount",
            "Temp"
        )]
        [string]$Name

    )

    $Config = Get-Config

    $RelativePath = Get-ObjectProperty `
        -Object $Config.Paths `
        -Name $Name

    if ([string]::IsNullOrWhiteSpace($RelativePath)) {

        throw (
            "Le chemin '{0}' est absent du fichier Config.json." -f
            $Name
        )

    }

    return Join-Path `
        (Get-ProjectRoot) `
        $RelativePath

}

# ==================================================
# Recharge complètement le module Core
# ==================================================

function Reset-Core {

    [CmdletBinding()]
    param()

    $script:Config = $null

    $script:ProjectRoot = $null
	
	$script:Version = $null
	
    Initialize-Core

}

# ==================================================
# Initialisation automatique
# ==================================================

Initialize-Core