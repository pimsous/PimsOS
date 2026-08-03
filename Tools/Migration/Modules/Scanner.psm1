<#
.SYNOPSIS
    Scanner du framework de migration PimsOS.

.DESCRIPTION
    Ce module est responsable de la découverte des fichiers
    utilisés par le framework de migration.

.NOTES

    Projet : PimsOS
    Module : Scanner
    Version : 1.1.0

#>

Set-StrictMode -Version Latest

#==============================================================================
# Vérifie si un fichier est situé dans un dossier exclu
#==============================================================================

function Test-IsExcluded {

    [CmdletBinding()]
    [OutputType([bool])]

    param(

        [Parameter(Mandatory)]
        [System.IO.FileInfo]
        $File,

        [string[]]
        $ExcludedFolders = (Get-ExcludedFolders)

    )

    foreach ($Folder in $ExcludedFolders)
    {
        if ($File.FullName -match "\\$([Regex]::Escape($Folder))(\\|$)")
        {
            return $true
        }
    }

    return $false

}

#==============================================================================
# Retourne tous les fichiers PowerShell
#==============================================================================

function Get-PowerShellFiles {

    [CmdletBinding()]
    [OutputType([System.IO.FileInfo[]])]

    param(

        [string]
        $Root = (Get-ProjectRoot)

    )

    Get-ProjectFiles `
        -Root $Root |
    Where-Object {

        $_.Extension -in ".ps1", ".psm1", ".psd1"

    }

}

#==============================================================================
# Retourne les fichiers Markdown
#==============================================================================

function Get-MarkdownFiles {

    [CmdletBinding()]
    [OutputType([System.IO.FileInfo[]])]

    param(

        [string]
        $Root = (Get-ProjectRoot)

    )

    if (-not (Test-MigrationPath $Root))
    {
        return @()
    }

    Get-ChildItem `
        -LiteralPath $Root `
        -Filter "*.md" `
        -File `
        -Recurse

}

#==============================================================================
# Retourne les fichiers JSON
#==============================================================================

function Get-JsonFiles {

    [CmdletBinding()]
    [OutputType([System.IO.FileInfo[]])]

    param(

        [string]
        $Root = (Get-ProjectRoot)

    )

    if (-not (Test-MigrationPath $Root))
    {
        return @()
    }

    Get-ChildItem `
        -LiteralPath $Root `
        -Filter "*.json" `
        -File `
        -Recurse

}

#==============================================================================
# Retourne tous les fichiers du projet
#==============================================================================

function Get-ProjectFiles {

    [CmdletBinding()]
    [OutputType([System.IO.FileInfo[]])]

    param(

        [string]
        $Root = (Get-ProjectRoot),

        [string[]]
        $Extensions = (Get-ProjectExtensions)

    )

    if (-not (Test-MigrationPath $Root))
    {
        throw "Le dossier '$Root' est introuvable."
    }

    $Files = foreach ($Extension in $Extensions)
    {
        Get-ChildItem `
            -LiteralPath $Root `
            -Recurse `
            -Filter $Extension `
            -File
    }

    $Files |
        Sort-Object FullName -Unique

}

#==============================================================================
# Retourne les fichiers pouvant être migrés
#==============================================================================

function Get-MigrationFiles {

    [CmdletBinding()]
    [OutputType([System.IO.FileInfo[]])]

    param(

        [string]
        $Root = (Get-ProjectRoot)

    )

    Get-ProjectFiles `
        -Root $Root |
    Where-Object {

        -not (Test-IsExcluded $_)

    } |
    Sort-Object FullName

}

#==============================================================================
# Retourne les règles de migration
#==============================================================================

function Get-RuleFiles {

    [CmdletBinding()]
    [OutputType([System.IO.FileInfo[]])]

    param()

    $RulesFolder = Join-Path `
        (Get-MigrationRoot) `
        "Rules"

    if (-not (Test-MigrationPath $RulesFolder))
    {
        return @()
    }

    Get-ChildItem `
        -LiteralPath $RulesFolder `
        -Filter "*.ps1" `
        -File |
    Sort-Object Name

}

#==============================================================================
# Retourne les modules du framework
#==============================================================================

function Get-ModuleFiles {

    [CmdletBinding()]
    [OutputType([System.IO.FileInfo[]])]

    param()

    $ModulesFolder = Join-Path `
        (Get-MigrationRoot) `
        "Modules"

    if (-not (Test-MigrationPath $ModulesFolder))
    {
        return @()
    }

    Get-ChildItem `
        -LiteralPath $ModulesFolder `
        -Filter "*.psm1" `
        -File |
    Sort-Object Name

}

#==============================================================================
# Inventaire complet du projet
#==============================================================================

function Get-ProjectInventory {

    [CmdletBinding()]
    [OutputType([pscustomobject])]

    param(

        [string]
        $Root = (Get-ProjectRoot)

    )

    [PSCustomObject]@{

        PowerShell = Get-PowerShellFiles -Root $Root
        Markdown   = Get-MarkdownFiles  -Root $Root
        Json       = Get-JsonFiles      -Root $Root

        Migration  = Get-MigrationFiles -Root $Root
        Rules      = Get-RuleFiles
        Modules    = Get-ModuleFiles

    }

}

#==============================================================================
# Export
#==============================================================================

Export-ModuleMember `
    -Function `
        Test-IsExcluded,
        Get-PowerShellFiles,
        Get-MarkdownFiles,
        Get-JsonFiles,
        Get-ProjectFiles,
        Get-MigrationFiles,
        Get-RuleFiles,
        Get-ModuleFiles,
        Get-ProjectInventory