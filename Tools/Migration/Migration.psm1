<#
.SYNOPSIS
    Lance le framework de migration PimsOS.

.DESCRIPTION
    Initialise le contexte de migration, découvre les règles disponibles
    puis exécute le pipeline de migration.

.NOTES
    Framework : Migration
    Projet    : PimsOS Builder
#>

Set-StrictMode -Version Latest

#==============================================================================
# Chargement des classes
#==============================================================================

$ClassesPath = Join-Path $PSScriptRoot 'Classes'

if (Test-Path -LiteralPath $ClassesPath)
{
    Get-ChildItem `
        -Path $ClassesPath `
        -Filter '*.ps1' `
        -File |
    Sort-Object Name |
    ForEach-Object {

        . $_.FullName

    }
}

#==============================================================================
# Chargement des modules internes
#==============================================================================

$Modules = @(
    'Modules\Common.psm1'
    'Modules\Scanner.psm1'
    'Modules\Ast.psm1'
    'Modules\Replace.psm1'
    'Modules\Backup.psm1'
    'Modules\Report.psm1'
)

foreach ($Module in $Modules)
{
    $ModulePath = Join-Path $PSScriptRoot $Module

    if (-not (Test-Path -LiteralPath $ModulePath))
    {
        throw "Module introuvable : '$Module'."
    }

    Import-Module `
        -Name $ModulePath `
        -Force `
        -DisableNameChecking
}

#==============================================================================
# Chargement des fonctions privées
#==============================================================================

$PrivatePath = Join-Path $PSScriptRoot 'Private'

if (Test-Path -LiteralPath $PrivatePath)
{
    Get-ChildItem `
        -Path $PrivatePath `
        -Filter '*.ps1' `
        -File |
    Sort-Object Name |
    ForEach-Object {

        . $_.FullName

    }
}

#==============================================================================
# Chargement des fonctions publiques
#==============================================================================

$PublicPath = Join-Path $PSScriptRoot 'Public'

if (Test-Path -LiteralPath $PublicPath)
{
    Get-ChildItem `
        -Path $PublicPath `
        -Filter '*.ps1' `
        -File |
    Sort-Object Name |
    ForEach-Object {

        . $_.FullName

    }
}

#==============================================================================
# Export
#==============================================================================

Export-ModuleMember `
    -Function 'Invoke-Migration'