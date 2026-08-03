<#
.SYNOPSIS
    Gestion des rapports du framework de migration PimsOS.

.DESCRIPTION
    Ce module crée et gère les rapports de migration.
    Les rapports centralisent les informations produites par les
    différents modules du framework.

.NOTES

    Projet : PimsOS
    Module : Report
    Version : 1.1.0

#>

Set-StrictMode -Version Latest

#==============================================================================
# Crée un nouveau rapport
#==============================================================================

function New-Report {

    [CmdletBinding()]
    [OutputType([PSCustomObject])]

    param()

    return [PSCustomObject]@{

        PSTypeName = 'PimsOS.Migration.Report'

        ReportId = [guid]::NewGuid()

        StartTime = Get-Date

        EndTime = $null

        Duration = [TimeSpan]::Zero

        Files = [System.Collections.Generic.List[object]]::new()

        Replacements = [System.Collections.Generic.List[object]]::new()

        Messages = [System.Collections.Generic.List[object]]::new()

        Warnings = [System.Collections.Generic.List[object]]::new()

        Errors = [System.Collections.Generic.List[object]]::new()

    }

}

#==============================================================================
# Vérifie qu'un rapport est valide
#==============================================================================

function Test-Report {

    [CmdletBinding()]
    [OutputType([bool])]

    param(

        [Parameter(Mandatory)]
        [PSCustomObject]
        $Report

    )

    $RequiredProperties = @(
        'ReportId'
        'StartTime'
        'EndTime'
        'Duration'
        'Files'
        'Replacements'
        'Messages'
        'Warnings'
        'Errors'
    )

    foreach ($Property in $RequiredProperties)
    {
        if ($Report.PSObject.Properties[$Property] -eq $null)
        {
            return $false
        }
    }

    return $true

}

#==============================================================================
# Vide un rapport
#==============================================================================

function Clear-Report {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [PSCustomObject]
        $Report

    )

    if (-not (Test-Report -Report $Report))
    {
        throw "Le rapport est invalide."
    }

    $Report.Files.Clear()

    $Report.Replacements.Clear()

    $Report.Messages.Clear()

    $Report.Warnings.Clear()

    $Report.Errors.Clear()

    $Report.EndTime = $null

    $Report.Duration = [TimeSpan]::Zero

}

#==============================================================================
# Crée une entrée de rapport
#==============================================================================

function New-ReportEntry {

    [CmdletBinding()]
    [OutputType([PSCustomObject])]

    param(

        [Parameter(Mandatory)]
        [ValidateSet(
            'Message',
            'Warning',
            'Error'
        )]
        [string]
        $Type,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Text

    )

    return [PSCustomObject]@{

        PSTypeName = 'PimsOS.Migration.ReportEntry'

        Time = Get-Date

        Type = $Type

        Text = $Text

    }

}

#==============================================================================
# Ajoute un message
#==============================================================================

function Add-ReportMessage {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [PSCustomObject]
        $Report,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Text

    )

    if (-not (Test-Report -Report $Report))
    {
        throw "Le rapport est invalide."
    }

    $Report.Messages.Add(

        (New-ReportEntry `
            -Type Message `
            -Text $Text)

    )

}

#==============================================================================
# Ajoute un avertissement
#==============================================================================

function Add-ReportWarning {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [PSCustomObject]
        $Report,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Text

    )

    if (-not (Test-Report -Report $Report))
    {
        throw "Le rapport est invalide."
    }

    $Report.Warnings.Add(

        (New-ReportEntry `
            -Type Warning `
            -Text $Text)

    )

}

#==============================================================================
# Ajoute une erreur
#==============================================================================

function Add-ReportError {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [PSCustomObject]
        $Report,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Text

    )

    if (-not (Test-Report -Report $Report))
    {
        throw "Le rapport est invalide."
    }

    $Report.Errors.Add(

        (New-ReportEntry `
            -Type Error `
            -Text $Text)

    )

}
#==============================================================================
# Crée une entrée de fichier
#==============================================================================

function New-ReportFile {

    [CmdletBinding()]
    [OutputType([PSCustomObject])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path

    )

    return [PSCustomObject]@{

        PSTypeName = 'PimsOS.Migration.ReportFile'

        Path = $Path

        Time = Get-Date

        Exists = Test-Path -LiteralPath $Path

    }

}

#==============================================================================
# Ajoute un fichier au rapport
#==============================================================================

function Add-ReportFile {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [PSCustomObject]
        $Report,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path

    )

    if (-not (Test-Report -Report $Report))
    {
        throw "Le rapport est invalide."
    }

    $Report.Files.Add(

        (New-ReportFile -Path $Path)

    )

}

#==============================================================================
# Ajoute un remplacement au rapport
#==============================================================================

function Add-ReportReplacement {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [PSCustomObject]
        $Report,

        [Parameter(Mandatory)]
        [PSCustomObject]
        $Replacement

    )

    if (-not (Test-Report -Report $Report))
    {
        throw "Le rapport est invalide."
    }

    if (-not (Test-Replacement -Replacement $Replacement))
    {
        throw "Le remplacement fourni est invalide."
    }

    $Report.Replacements.Add($Replacement)

}

#==============================================================================
# Retourne les messages
#==============================================================================

function Get-ReportMessages {

    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]

    param(

        [Parameter(Mandatory)]
        [PSCustomObject]
        $Report

    )

    if (-not (Test-Report -Report $Report))
    {
        throw "Le rapport est invalide."
    }

    return $Report.Messages

}

#==============================================================================
# Retourne les avertissements
#==============================================================================

function Get-ReportWarnings {

    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]

    param(

        [Parameter(Mandatory)]
        [PSCustomObject]
        $Report

    )

    if (-not (Test-Report -Report $Report))
    {
        throw "Le rapport est invalide."
    }

    return $Report.Warnings

}

#==============================================================================
# Retourne les erreurs
#==============================================================================

function Get-ReportErrors {

    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]

    param(

        [Parameter(Mandatory)]
        [PSCustomObject]
        $Report

    )

    if (-not (Test-Report -Report $Report))
    {
        throw "Le rapport est invalide."
    }

    return $Report.Errors

}

#==============================================================================
# Retourne les fichiers
#==============================================================================

function Get-ReportFiles {

    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]

    param(

        [Parameter(Mandatory)]
        [PSCustomObject]
        $Report

    )

    if (-not (Test-Report -Report $Report))
    {
        throw "Le rapport est invalide."
    }

    return $Report.Files

}

#==============================================================================
# Retourne les remplacements
#==============================================================================

function Get-ReportReplacements {

    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]

    param(

        [Parameter(Mandatory)]
        [PSCustomObject]
        $Report

    )

    if (-not (Test-Report -Report $Report))
    {
        throw "Le rapport est invalide."
    }

    return $Report.Replacements

}
#==============================================================================
# Termine un rapport
#==============================================================================

function Complete-Report {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [PSCustomObject]
        $Report

    )

    if (-not (Test-Report -Report $Report))
    {
        throw "Le rapport est invalide."
    }

    if ($null -ne $Report.EndTime)
    {
        throw "Le rapport est déjà terminé."
    }

    $Report.EndTime = Get-Date

    $Report.Duration =
        $Report.EndTime - $Report.StartTime

}

#==============================================================================
# Retourne la durée d'un rapport
#==============================================================================

function Get-ReportDuration {

    [CmdletBinding()]
    [OutputType([TimeSpan])]

    param(

        [Parameter(Mandatory)]
        [PSCustomObject]
        $Report

    )

    if (-not (Test-Report -Report $Report))
    {
        throw "Le rapport est invalide."
    }

    if ($null -eq $Report.EndTime)
    {
        return (Get-Date) - $Report.StartTime
    }

    return $Report.Duration

}

#==============================================================================
# Retourne les statistiques
#==============================================================================

function Get-ReportStatistics {

    [CmdletBinding()]
    [OutputType([PSCustomObject])]

    param(

        [Parameter(Mandatory)]
        [PSCustomObject]
        $Report

    )

    if (-not (Test-Report -Report $Report))
    {
        throw "Le rapport est invalide."
    }

    $Files        = @(Get-ReportFiles -Report $Report)
	$Replacements = @(Get-ReportReplacements -Report $Report)
	$Messages     = @(Get-ReportMessages -Report $Report)
	$Warnings     = @(Get-ReportWarnings -Report $Report)
	$Errors       = @(Get-ReportErrors -Report $Report)

	return [PSCustomObject]@{

		ReportId = $Report.ReportId

		Files = $Files.Count

		Replacements = $Replacements.Count

		Messages = $Messages.Count

		Warnings = $Warnings.Count

		Errors = $Errors.Count

		Duration = Get-ReportDuration -Report $Report

		Completed = ($null -ne $Report.EndTime)

	}

}

#==============================================================================
# Exporte le rapport au format JSON
#==============================================================================

function Export-ReportJson {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [PSCustomObject]
        $Report,

        [Parameter(Mandatory)]
        [System.IO.FileInfo]
        $File

    )

    if (-not (Test-Report -Report $Report))
    {
        throw "Le rapport est invalide."
    }

    $Json = $Report |
        ConvertTo-Json `
            -Depth 10

    [System.IO.File]::WriteAllText(

        $File.FullName,

        $Json,

        [System.Text.UTF8Encoding]::new($false)

    )

}

#==============================================================================
# Exporte le rapport au format texte
#==============================================================================

function Export-ReportText {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [PSCustomObject]
        $Report,

        [Parameter(Mandatory)]
        [System.IO.FileInfo]
        $File

    )

    if (-not (Test-Report -Report $Report))
    {
        throw "Le rapport est invalide."
    }

    $Stats = Get-ReportStatistics -Report $Report

    $Lines = [System.Collections.Generic.List[string]]::new()

    $Lines.Add("========================================")
    $Lines.Add("        Rapport de migration PimsOS")
    $Lines.Add("========================================")
    $Lines.Add("")
    $Lines.Add("Rapport : $($Report.ReportId)")
    $Lines.Add("Début   : $($Report.StartTime)")
    $Lines.Add("Fin     : $($Report.EndTime)")
    $Lines.Add("Durée   : $($Stats.Duration)")
    $Lines.Add("")
    $Lines.Add("Fichiers      : $($Stats.Files)")
    $Lines.Add("Remplacements : $($Stats.Replacements)")
    $Lines.Add("Messages      : $($Stats.Messages)")
    $Lines.Add("Avertissements: $($Stats.Warnings)")
    $Lines.Add("Erreurs       : $($Stats.Errors)")
    $Lines.Add("")

    if ($Report.Messages.Count)
    {
        $Lines.Add("Messages")
        $Lines.Add("----------------------------------------")

        foreach ($Entry in $Report.Messages)
        {
            $Lines.Add("[$($Entry.Time)] $($Entry.Text)")
        }

        $Lines.Add("")
    }

    if ($Report.Warnings.Count)
    {
        $Lines.Add("Avertissements")
        $Lines.Add("----------------------------------------")

        foreach ($Entry in $Report.Warnings)
        {
            $Lines.Add("[$($Entry.Time)] $($Entry.Text)")
        }

        $Lines.Add("")
    }

    if ($Report.Errors.Count)
    {
        $Lines.Add("Erreurs")
        $Lines.Add("----------------------------------------")

        foreach ($Entry in $Report.Errors)
        {
            $Lines.Add("[$($Entry.Time)] $($Entry.Text)")
        }

        $Lines.Add("")
    }

    [System.IO.File]::WriteAllLines(

        $File.FullName,

        $Lines,

        [System.Text.UTF8Encoding]::new($false)

    )

}

#==============================================================================
# Export
#==============================================================================

Export-ModuleMember `
    -Function `
        New-Report,
        Test-Report,
        Clear-Report,
        New-ReportEntry,
        Add-ReportMessage,
        Add-ReportWarning,
        Add-ReportError,
        New-ReportFile,
        Add-ReportFile,
        Add-ReportReplacement,
        Get-ReportMessages,
        Get-ReportWarnings,
        Get-ReportErrors,
        Get-ReportFiles,
        Get-ReportReplacements,
        Complete-Report,
        Get-ReportDuration,
        Get-ReportStatistics,
        Export-ReportJson,
        Export-ReportText