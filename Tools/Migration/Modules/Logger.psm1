Set-StrictMode -Version Latest

#==================================================
# Recherche les appels Write-Log
#==================================================

function Find-LoggerCommands {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Script
    )

    return Find-Commands `
        -Script $Script `
        -Name "Write-Log"

}

#==================================================
# Analyse un appel Write-Log
#==================================================

function Get-LoggerCallInfo {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.Language.CommandAst]
        $Command
    )

    $Info = [ordered]@{

        MessageExpression = $null

        Level = "INFO"

        Start = $Command.Extent.StartOffset

        End = $Command.Extent.EndOffset

    }

    $Elements = $Command.CommandElements

    for ($i = 1; $i -lt $Elements.Count; $i++) {

        $Current = $Elements[$i]

        if ($Current -is [System.Management.Automation.Language.CommandParameterAst]) {

            switch ($Current.ParameterName) {

                "Message" {

                    if ($i + 1 -lt $Elements.Count) {
                        $Info.MessageExpression =
                            $Elements[$i + 1].Extent.Text
                    }

                }

                "Level" {

                    if ($i + 1 -lt $Elements.Count) {
                        $Info.Level =
                            $Elements[$i + 1].Extent.Text.ToUpper()
                    }

                }

            }

            continue

        }

    }

    if (-not $Info.MessageExpression) {

        if ($Elements.Count -ge 2) {
            $Info.MessageExpression =
                $Elements[1].Extent.Text
        }

    }

    if ($Info.Level -eq "INFO") {

        if ($Elements.Count -ge 3) {

            $Candidate =
                $Elements[2].Extent.Text.ToUpper()

            if ($Candidate -match "SUCCESS|WARNING|ERROR|DEBUG") {
                $Info.Level = $Candidate
            }

        }

    }

    return [PSCustomObject]$Info

}

#==================================================
# Détermine la nouvelle commande
#==================================================

function Get-NewLoggerCommand {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]
        $Call
    )

    switch ($Call.Level) {

        "SUCCESS" {
            $Command = "Write-Success"
        }

        "WARNING" {
            $Command = "Write-WarningLog"
        }

        "ERROR" {
            $Command = "Write-ErrorLog"
        }

        "DEBUG" {
            $Command = "Write-DebugLog"
        }

        default {
            $Command = "Write-Info"
        }

    }

    return "$Command $($Call.MessageExpression)"

}

#==================================================
# Crée un remplacement Logger
#==================================================

function New-LoggerReplacement {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.Language.CommandAst]
        $Command
    )

    $Call = Get-LoggerCallInfo -Command $Command

    $ReplacementText = Get-NewLoggerCommand -Call $Call

    return New-Replacement `
        -Start $Call.Start `
        -End $Call.End `
        -Text $ReplacementText

}

Export-ModuleMember -Function `
    Find-LoggerCommands, `
    Get-LoggerCallInfo, `
    Get-NewLoggerCommand, `
    New-LoggerReplacement