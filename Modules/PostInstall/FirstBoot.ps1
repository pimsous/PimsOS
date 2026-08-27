# ==========================================
# Module : PostInstall FirstBoot
# Projet : PimsOS Builder
# Version : 1.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Construit la commande FirstLogon
# --------------------------------------------------

function New-PimsOSFirstLogonCommand {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]$BootstrapPath,

        [Parameter()]
        [int]$Order = 1

    )

    # --------------------------------------------------
    # Validation
    # --------------------------------------------------

    if ([string]::IsNullOrWhiteSpace($BootstrapPath)) {

        throw "Le chemin du Bootstrap FirstBoot est vide."

    }

    if ($Order -lt 1) {

        throw "L'ordre FirstBoot doit être supérieur ou égal à 1."

    }

    # --------------------------------------------------
    # Construction de la commande
    # --------------------------------------------------

    $EscapedBootstrapPath =
        $BootstrapPath.Replace('"', '\"')

    $CommandLine = (
        'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "{0}"' -f
        $EscapedBootstrapPath
    )

    return [PSCustomObject]@{

        Order       = $Order
        Description = "Lancement du PostInstall PimsOS"
        CommandLine = $CommandLine

    }

}

# --------------------------------------------------
# Construit la configuration FirstBoot
# --------------------------------------------------

function New-PimsOSFirstBootConfiguration {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]$BootstrapPath

    )

    if ([string]::IsNullOrWhiteSpace($BootstrapPath)) {

        throw "Le chemin du Bootstrap FirstBoot est vide."

    }

    $Command = New-PimsOSFirstLogonCommand `
        -BootstrapPath $BootstrapPath `
        -Order 1

    return [PSCustomObject]@{

        ObjectType = "PimsOSFirstBootConfiguration"

        Version = "1.0.0"

        BootstrapPath = $BootstrapPath

        FirstLogonCommands = @(
            $Command
        )

    }

}

# --------------------------------------------------
# Valide une configuration FirstBoot
# --------------------------------------------------

function Test-PimsOSFirstBootConfiguration {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Configuration

    )

    if ($null -eq $Configuration) {

        throw "La configuration FirstBoot est null."

    }

    if (
        $Configuration.PSObject.Properties.Name -notcontains
        "FirstLogonCommands"
    ) {

        throw "La configuration FirstBoot ne contient pas FirstLogonCommands."

    }

    $Commands = @(
        $Configuration.FirstLogonCommands
    )

    if ($Commands.Count -eq 0) {

        throw "La configuration FirstBoot ne contient aucune commande."

    }

    foreach ($Command in $Commands) {

        if (
            $Command.PSObject.Properties.Name -notcontains
            "Order"
        ) {

            throw "Une commande FirstBoot ne contient pas de propriété Order."

        }

        if (
            $Command.PSObject.Properties.Name -notcontains
            "CommandLine"
        ) {

            throw "Une commande FirstBoot ne contient pas de propriété CommandLine."

        }

        if (
            [string]::IsNullOrWhiteSpace(
                [string]$Command.CommandLine
            )
        ) {

            throw "Une commande FirstBoot possède une ligne de commande vide."

        }

    }

    return $true

}