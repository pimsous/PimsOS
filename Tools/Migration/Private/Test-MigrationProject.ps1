<#
.SYNOPSIS
    Vérifie que le projet de migration est valide.

.DESCRIPTION
    Contrôle la présence des principaux dossiers utilisés
    par le framework de migration.

.PARAMETER Context
    Contexte de migration.

.OUTPUTS
    System.Boolean

.NOTES
    Cette fonction est appelée au début de Invoke-Migration.
#>

function Test-MigrationProject {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [PSObject]$Context

    )

    # Vérification du dossier racine
    if (-not (Test-Path -LiteralPath $Context.ProjectRoot -PathType Container)) {

        Write-Verbose "ProjectRoot introuvable : $($Context.ProjectRoot)"
        return $false

    }

    # Vérification du dossier Tools
    if (-not (Test-Path -LiteralPath $Context.ToolsPath -PathType Container)) {

        Write-Verbose "ToolsPath introuvable : $($Context.ToolsPath)"
        return $false

    }

    # Vérification du dossier Migration
    if (-not (Test-Path -LiteralPath $Context.MigrationPath -PathType Container)) {

        Write-Verbose "MigrationPath introuvable : $($Context.MigrationPath)"
        return $false

    }

    # Vérification du dossier Modules
    if (-not (Test-Path -LiteralPath $Context.ModulesPath -PathType Container)) {

        Write-Verbose "ModulesPath introuvable : $($Context.ModulesPath)"
        return $false

    }

    # Vérification du dossier Tests
    if (-not (Test-Path -LiteralPath $Context.TestsPath -PathType Container)) {

        Write-Verbose "TestsPath introuvable : $($Context.TestsPath)"
        return $false

    }

    return $true

}