function Invoke-MigrationRules {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        $Context

    )

    $Rules = Get-MigrationRules -Context $Context

    foreach ($Rule in $Rules) {

        $Result = New-MigrationResult

        $Result.Rule = $Rule.Name
        $Result.File = $Rule.FullName

        try {

            . $Rule.FullName

            $Result.Modified = $true

        }
        catch {

            $Result.Modified = $false
            $Result.Message = $_.Exception.Message

        }

        $Context.Results.Add($Result)

    }

    return $Context.Results

}