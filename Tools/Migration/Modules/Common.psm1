<#
.SYNOPSIS
    Fonctions communes du framework de migration PimsOS.

.DESCRIPTION
    Ce module fournit les fonctions utilitaires partagées
    par tous les modules du framework de migration.

.NOTES

    Projet : PimsOS
    Module : Common
    Version : 1.1.0

#>

Set-StrictMode -Version Latest

#==============================================================================
# Variables privées
#==============================================================================

$script:ProjectRoot = (
    Resolve-Path (
        Join-Path $PSScriptRoot "..\..\.."
    )
).Path

$script:MigrationRoot = (
    Resolve-Path (
        Join-Path $PSScriptRoot ".."
    )
).Path

$script:FrameworkName = "PimsOS Migration Framework"

$script:FrameworkVersion = "1.1.0"

$script:ProjectExtensions = @(
    "*.ps1",
    "*.psm1",
    "*.psd1"
)

$script:ExcludedFolders = @(
    ".git",
    ".github",
    ".vs",
    ".vscode",
    "Logs",
    "Output",
    "Mount",
    "ISO",
    "Packages",
    "bin",
    "obj"
)

$script:Colors = @{

    Title    = "White"
    Section  = "Magenta"

    Info     = "Cyan"
    Success  = "Green"
    Warning  = "Yellow"
    Error    = "Red"

    Debug    = "DarkGray"
    Verbose  = "Gray"

}

#==============================================================================
# Informations du framework
#==============================================================================

function Get-ProjectRoot {

    [CmdletBinding()]
    param()

    return $script:ProjectRoot

}

function Get-MigrationRoot {

    [CmdletBinding()]
    param()

    return $script:MigrationRoot

}

function Get-FrameworkName {

    [CmdletBinding()]
    param()

    return $script:FrameworkName

}

function Get-FrameworkVersion {

    [CmdletBinding()]
    param()

    return $script:FrameworkVersion

}

function Get-ProjectExtensions {

    [CmdletBinding()]
    param()

    return $script:ProjectExtensions

}

function Get-ExcludedFolders {

    [CmdletBinding()]
    param()

    return $script:ExcludedFolders

}

#==============================================================================
# Outils généraux
#==============================================================================

function Test-PowerShellVersion {

    [CmdletBinding()]
    param(

        [Version]
        $MinimumVersion = "7.6"

    )

    return (
        $PSVersionTable.PSVersion -ge $MinimumVersion
    )

}

function Test-MigrationPath {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]
        $Path

    )

    return (
        Test-Path `
            -LiteralPath $Path `
            -PathType Any
    )

}

function Get-RelativePath {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]
        $BasePath,

        [Parameter(Mandatory)]
        [string]
        $Path

    )

    return [System.IO.Path]::GetRelativePath(
        $BasePath,
        $Path
    )

}

#==============================================================================
# Chronomètre
#==============================================================================

function New-Stopwatch {

    [CmdletBinding()]
    param()

    return [System.Diagnostics.Stopwatch]::StartNew()

}

function Get-ElapsedTime {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [System.Diagnostics.Stopwatch]
        $Stopwatch

    )

    return $Stopwatch.Elapsed

}

#==============================================================================
# Objets métier
#==============================================================================

function New-MigrationRule {

    [CmdletBinding()]
    param()

    return [PSCustomObject]@{

        ObjectType = "MigrationRule"

        Name        = ""
        Description = ""

        Enabled     = $true
        Priority    = 100

        Script      = $null

    }

}

function New-MigrationContext {

    [CmdletBinding()]
    param()

    return [PSCustomObject]@{

        ObjectType = "MigrationContext"

        # Informations du projet
        ProjectName   = ""
        ProjectRoot   = ""

        # Chemins
        ToolsPath     = ""
        MigrationPath = ""
        ModulesPath   = ""
        TestsPath     = ""

        # Exécution
        Rule          = ""
        AnalyzeOnly   = $false
        ExecuteAll    = $false

        # Résultats
        Results       = [System.Collections.Generic.List[object]]::new()

    }

}

#==============================================================================
# Résultats
#==============================================================================

function New-MigrationResult {

    [CmdletBinding()]
    param(

        [string]
        $File,

        [string]
        $Rule,

        [bool]
        $Modified = $false,

        [string]
        $Message = ""

    )

    return [PSCustomObject]@{

		ObjectType = "MigrationResult"

		File       = $File
		Rule       = $Rule
		Modified   = $Modified
		Message    = $Message

	}

}

function New-MigrationError {

    [CmdletBinding()]
    param(

        [string]
        $File,

        [string]
        $Rule,

        [string]
        $Message

    )

    return [PSCustomObject]@{

		ObjectType = "MigrationError"

		File        = $File
		Rule        = $Rule
		Message     = $Message

	}

}

#==============================================================================
# Affichage
#==============================================================================

function Write-Blank {

    [CmdletBinding()]
    param()

    Write-Host ""

}

function Write-Banner {

    [CmdletBinding()]
    param(

        [string]
        $Title = (Get-FrameworkName),

        [string]
        $Version = (Get-FrameworkVersion)

    )

    Write-Blank

    Write-Host "==================================================" `
        -ForegroundColor Cyan

    Write-Host (" {0}" -f $Title) `
        -ForegroundColor $script:Colors.Title

    Write-Host (" Version : {0}" -f $Version) `
        -ForegroundColor DarkGray

    Write-Host "==================================================" `
        -ForegroundColor Cyan

    Write-Blank

}

function Write-Section {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]
        $Title

    )

    Write-Blank

    Write-Host ("[{0}]" -f $Title) `
        -ForegroundColor $script:Colors.Section

}

function Write-Info {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]
        $Message

    )

    Write-Host $Message `
        -ForegroundColor $script:Colors.Info

}

function Write-Success {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]
        $Message

    )

    Write-Host $Message `
        -ForegroundColor $script:Colors.Success

}

function Write-WarningMessage {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]
        $Message

    )

    Write-Host $Message `
        -ForegroundColor $script:Colors.Warning

}

function Write-ErrorMessage {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]
        $Message

    )

    Write-Host $Message `
        -ForegroundColor $script:Colors.Error

}

#==============================================================================
# Export
#==============================================================================

Export-ModuleMember `
    -Function `
        Get-ProjectRoot,
        Get-MigrationRoot,
        Get-FrameworkName,
        Get-FrameworkVersion,
        Get-ProjectExtensions,
        Get-ExcludedFolders,
        Test-PowerShellVersion,
        Test-MigrationPath,
        Get-RelativePath,
        New-Stopwatch,
        Get-ElapsedTime,
        New-MigrationRule,
        New-MigrationContext,
        New-MigrationResult,
        New-MigrationError,
        Write-Blank,
        Write-Banner,
        Write-Section,
        Write-Info,
        Write-Success,
        Write-WarningMessage,
        Write-ErrorMessage