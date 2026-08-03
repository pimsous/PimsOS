<#
.SYNOPSIS
    Lance une migration PimsOS.

.DESCRIPTION
    Point d'entrée public du framework de migration.

.PARAMETER Rule
    Nom d'une règle à exécuter.

.PARAMETER AnalyzeOnly
    Analyse uniquement les fichiers sans les modifier.

.PARAMETER ExecuteAll
    Exécute toutes les règles disponibles.
#>

function Invoke-Migration {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(

        [string]$Rule,

        [switch]$AnalyzeOnly,

        [switch]$ExecuteAll

    )

    Write-Verbose "Initialisation de la migration..."

    $Context = New-MigrationContext

    $Context.ProjectName = "PimsOS"

    $Context.ProjectRoot = Resolve-Path (
        Join-Path $PSScriptRoot "..\.."
    )

    $Context.ProjectRoot = $Context.ProjectRoot.Path

    $Context.ToolsPath = Join-Path `
        $Context.ProjectRoot `
        "Tools"

    $Context.MigrationPath = Join-Path `
        $Context.ToolsPath `
        "Migration"

    $Context.ModulesPath = Join-Path `
        $Context.MigrationPath `
        "Modules"

    $Context.TestsPath = Join-Path `
        $Context.MigrationPath `
        "Tests"

    $Context.Rule = $Rule

    $Context.AnalyzeOnly = $AnalyzeOnly.IsPresent

    $Context.ExecuteAll = $ExecuteAll.IsPresent

    Write-Verbose "Projet          : $($Context.ProjectRoot)"
    Write-Verbose "Migration       : $($Context.MigrationPath)"

    if (-not (Test-MigrationProject -Context $Context)) {
        throw "Le projet de migration n'est pas valide."
    }

    if (-not (Import-MigrationRules -Context $Context)) {
        throw "Impossible d'importer les règles."
    }

    $Rules = Get-MigrationRules -Context $Context

    if ($Rules.Count -eq 0) {
        Write-Warning "Aucune règle disponible."
        return
    }

    Write-Verbose ("{0} règle(s) chargée(s)." -f $Rules.Count)

    Invoke-MigrationRules `
        -Context $Context `
        -Rules $Rules

    Write-MigrationReport `
        -Context $Context

}