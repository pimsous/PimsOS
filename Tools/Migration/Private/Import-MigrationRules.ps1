<#
.SYNOPSIS
    Importe les règles de migration.

.DESCRIPTION
    Charge tous les fichiers PowerShell présents dans le
    dossier Rules.

.PARAMETER Context
    Contexte de migration.

.OUTPUTS
    System.Boolean

.NOTES
    Les fichiers sont importés par dot-sourcing afin de
    rendre leurs fonctions et variables disponibles.
#>

function Import-MigrationRules {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        $Context

    )

    $RulesPath = Join-Path $Context.MigrationPath "Rules"

    if (-not (Test-Path -LiteralPath $RulesPath -PathType Container)) {

        Write-Verbose "Dossier Rules introuvable : $RulesPath"
        return $false

    }

    # Réinitialise la collection des règles chargées
    $script:MigrationRules = @()

    $RuleFiles = Get-ChildItem `
        -Path $RulesPath `
        -Filter "*.ps1" `
        -File |
        Sort-Object Name

    foreach ($File in $RuleFiles) {

        $Rule = . $File.FullName

        if ($null -eq $Rule) {

            Write-Warning "La règle '$($File.Name)' n'a retourné aucun objet de migration."
            continue

        }

        # Vérifie qu'il s'agit bien d'une règle créée par New-MigrationRule
        if (
            $Rule -isnot [pscustomobject] -or
            -not ($Rule.PSObject.Properties.Match('Name').Count) -or
            -not ($Rule.PSObject.Properties.Match('Description').Count) -or
            -not ($Rule.PSObject.Properties.Match('Enabled').Count) -or
            -not ($Rule.PSObject.Properties.Match('Priority').Count) -or
            -not ($Rule.PSObject.Properties.Match('Script').Count)
        ) {

            Write-Warning "Le fichier '$($File.Name)' n'a pas retourné une règle de migration valide."
            continue

        }

        $script:MigrationRules += $Rule

        Write-Verbose "Règle importée : $($Rule.Name)"

    }

    return $true

}