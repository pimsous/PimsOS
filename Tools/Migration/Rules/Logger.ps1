<#
.SYNOPSIS
    Règle de migration Logger.

.DESCRIPTION
    Convertit les appels Write-Log vers la nouvelle API Logger v2.
#>

$Rule = New-MigrationRule

$Rule.Name = "Logger"
$Rule.Description = "Migration de l'ancienne API Logger vers Logger v2."
$Rule.Priority = 100
$Rule.Enabled = $true

$Rule.Script = {

    param(
        [Parameter(Mandatory)]
        $Context
    )

    $Files = Get-MigrationFiles -Root $Context.ProjectRoot

    foreach ($File in $Files) {

        Write-Verbose "Analyse : $($File.FullName)"

        $Script = Get-ScriptAst -File $File

        if (Test-ParseErrors -Script $Script) {
            continue
        }

        $Commands = Find-LoggerCommands -Script $Script

        if ($Commands.Count -eq 0) {
            continue
        }

        $Replacements = New-ReplacementCollection

        foreach ($Command in $Commands) {

            $Replacement = New-LoggerReplacement -Command $Command

            if ($null -ne $Replacement) {
                Add-Replacement `
                    -Collection $Replacements `
                    -Replacement $Replacement
            }

        }

        if ($Replacements.Count -eq 0) {
            continue
        }

        Invoke-Replacements `
            -File $File `
            -Replacements $Replacements `
            -Context $Context

    }

}

return $Rule