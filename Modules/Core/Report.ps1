# ==========================================
# Module : Report
# Projet : PimsOS Builder
# Version : 1.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Crée un rapport d'environnement
# --------------------------------------------------

function New-EnvironmentReport {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [array]$Checks

    )

    return [PSCustomObject]@{

        Success = ($Checks.Success -notcontains $false)

        Checks  = $Checks

    }

}

# --------------------------------------------------
# Initialise le rapport d'environnement
# --------------------------------------------------

function Set-EnvironmentReport {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [array]$Checks

    )

    $Context.Report.Environment = New-EnvironmentReport `
        -Checks $Checks

    return $Context

}

# --------------------------------------------------
# Ajoute une information au rapport
# --------------------------------------------------

function Add-ReportInformation {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [string]$Message

    )

    if ($Context.Report.Informations -notcontains $Message) {

        $Context.Report.Informations += $Message

    }

    return $Context

}

# --------------------------------------------------
# Ajoute un avertissement au rapport
# --------------------------------------------------

function Add-ReportWarning {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [string]$Message

    )

    if ($Context.Report.Warnings -notcontains $Message) {

        $Context.Report.Warnings += $Message

    }

    return $Context

}

# --------------------------------------------------
# Ajoute une erreur au rapport
# --------------------------------------------------

function Add-ReportError {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [string]$Message

    )

    if ($Context.Report.Errors -notcontains $Message) {

        $Context.Report.Errors += $Message

    }

    return $Context

}