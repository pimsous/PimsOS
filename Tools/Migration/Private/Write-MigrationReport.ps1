function Write-MigrationReport {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        $Context

    )

    Write-Host ""
    Write-Host "==================================================" `
        -ForegroundColor Cyan

    Write-Host "              Migration terminée" `
        -ForegroundColor Cyan

    Write-Host "==================================================" `
        -ForegroundColor Cyan

    Write-Host ""

    $TotalRules = $Context.Results.Count

    $Succeeded = @(
        $Context.Results |
        Where-Object Modified
    ).Count

    $Failed = @(
        $Context.Results |
        Where-Object { -not $_.Modified }
    ).Count

    Write-Host ("Projet              : {0}" -f $Context.ProjectName)
    Write-Host ("Règles exécutées    : {0}" -f $TotalRules)
    Write-Host ("Modifiées           : {0}" -f $Succeeded)
    Write-Host ("En erreur           : {0}" -f $Failed)

    Write-Host ""

    foreach ($Result in $Context.Results) {

        if ($Result.Modified) {

            Write-Host ("[ OK ] {0}" -f $Result.Rule) `
                -ForegroundColor Green

        }
        else {

            Write-Host ("[ KO ] {0}" -f $Result.Rule) `
                -ForegroundColor Red

            if (-not [string]::IsNullOrWhiteSpace($Result.Message)) {

                Write-Host ("       {0}" -f $Result.Message) `
                    -ForegroundColor DarkRed

            }

        }

    }

    Write-Host ""

}