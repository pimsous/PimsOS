function Get-MigrationRules {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        $Context

    )

    if (-not $script:MigrationRules) {
        return @()
    }

    return $script:MigrationRules |
        Sort-Object Priority, Name

}