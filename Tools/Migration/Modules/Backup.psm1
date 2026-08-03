<#
.SYNOPSIS
    Gestionnaire des sauvegardes du framework de migration PimsOS.

.DESCRIPTION
    Ce module gère la création, la restauration et la suppression
    des sauvegardes des fichiers modifiés.

.NOTES

    Projet : PimsOS
    Module : Backup
    Version : 1.1.0

#>

Set-StrictMode -Version Latest

#==============================================================================
# Retourne le dossier racine des sauvegardes
#==============================================================================

function Get-BackupRoot {

    [CmdletBinding()]
    [OutputType([string])]

    param()

    return (Join-Path `
        -Path (Get-MigrationRoot) `
        -ChildPath "Backups")

}

#==============================================================================
# Retourne le chemin relatif d'un fichier du projet
#==============================================================================

function Get-RelativeProjectPath {

    [CmdletBinding()]
    [OutputType([string])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.IO.FileInfo]
        $File

    )

    $ProjectRoot = Get-ProjectRoot

    if (-not $File.FullName.StartsWith(
            $ProjectRoot,
            [System.StringComparison]::OrdinalIgnoreCase))
    {
        throw "Le fichier '$($File.FullName)' n'appartient pas au projet."
    }

    return $File.FullName.Substring(
        $ProjectRoot.Length
    ).TrimStart('\')

}

#==============================================================================
# Retourne le dossier d'une session
#==============================================================================

function Get-BackupPath {

    [CmdletBinding()]
    [OutputType([string])]

    param(

        [Parameter(Mandatory)]
        [hashtable]
        $Session

    )

    return $Session.BackupRoot

}

#==============================================================================
# Retourne le chemin d'une sauvegarde
#==============================================================================

function Get-BackupFile {

    [CmdletBinding()]
    [OutputType([string])]

    param(

        [Parameter(Mandatory)]
        [System.IO.FileInfo]
        $File,

        [Parameter(Mandatory)]
        [hashtable]
        $Session

    )

    $RelativePath = Get-RelativeProjectPath -File $File

    return Join-Path `
        -Path (Get-BackupPath -Session $Session) `
        -ChildPath $RelativePath

}

#==============================================================================
# Vérifie une session de sauvegarde
#==============================================================================

function Test-BackupSession {

    [CmdletBinding()]
    [OutputType([bool])]

    param(

        [Parameter(Mandatory)]
        [hashtable]
        $Session

    )

    if ($null -eq $Session)
    {
        return $false
    }

    foreach ($Property in @(
        'Id'
        'Started'
        'BackupRoot'
    ))
    {
        if ($Session[$Property] -eq $null)
        {
            return $false
        }
    }

    return (Test-Path `
        -LiteralPath $Session.BackupRoot `
        -PathType Container)

}

#==============================================================================
# Crée une nouvelle session
#==============================================================================

function New-BackupSession {

    [CmdletBinding()]
    [OutputType([hashtable])]

    param()

    $Id = Get-Date -Format "yyyy-MM-dd_HH-mm-ss-fff"

    $Folder = Join-Path `
        -Path (Get-BackupRoot) `
        -ChildPath $Id

    if (-not (Test-Path -LiteralPath $Folder))
    {
        New-Item `
            -ItemType Directory `
            -Path $Folder `
            -Force | Out-Null
    }

    return @{

        Id = $Id

        Started = (Get-Date).ToUniversalTime()

        BackupRoot = $Folder

    }

}

#==============================================================================
# Retourne tous les fichiers sauvegardés d'une session
#==============================================================================

function Get-BackupFiles {

    [CmdletBinding()]
    [OutputType([System.IO.FileInfo[]])]

    param(

        [Parameter(Mandatory)]
        [hashtable]
        $Session

    )

    if (-not (Test-BackupSession -Session $Session))
    {
        throw "Session de sauvegarde invalide."
    }

    return Get-ChildItem `
        -LiteralPath $Session.BackupRoot `
        -File `
        -Recurse

}
#==============================================================================
# Crée la sauvegarde d'un fichier
#==============================================================================

function New-Backup {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.IO.FileInfo]
        $File,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [hashtable]
        $Session

    )

    if (-not (Test-BackupSession -Session $Session))
    {
        throw "Session de sauvegarde invalide."
    }

    if (-not $File.Exists)
    {
        throw "Le fichier '$($File.FullName)' est introuvable."
    }

    $Destination = Get-BackupFile `
        -File $File `
        -Session $Session

    $DestinationFolder = Split-Path `
        -Path $Destination `
        -Parent

    if (-not (Test-Path -LiteralPath $DestinationFolder))
    {
        New-Item `
            -ItemType Directory `
            -Path $DestinationFolder `
            -Force | Out-Null
    }

    Copy-Item `
        -LiteralPath $File.FullName `
        -Destination $Destination `
        -Force

}

#==============================================================================
# Restaure un fichier sauvegardé
#==============================================================================

function Restore-Backup {

    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([System.IO.FileInfo])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.IO.FileInfo]
        $File,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [hashtable]
        $Session

    )

    if (-not (Test-BackupSession -Session $Session))
    {
        throw "Session de sauvegarde invalide."
    }

    $BackupFile = Get-BackupFile `
        -File $File `
        -Session $Session

    if (-not (Test-Path -LiteralPath $BackupFile))
    {
        throw "Aucune sauvegarde trouvée pour '$($File.FullName)'."
    }

    if ($PSCmdlet.ShouldProcess(
            $File.FullName,
            "Restaurer le fichier"))
    {
        Copy-Item `
            -LiteralPath $BackupFile `
            -Destination $File.FullName `
            -Force
    }

    return Get-Item -LiteralPath $File.FullName

}

#==============================================================================
# Supprime la sauvegarde d'un fichier
#==============================================================================

function Remove-Backup {

    [CmdletBinding(SupportsShouldProcess)]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.IO.FileInfo]
        $File,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [hashtable]
        $Session

    )

    if (-not (Test-BackupSession -Session $Session))
    {
        throw "Session de sauvegarde invalide."
    }

    $BackupFile = Get-BackupFile `
        -File $File `
        -Session $Session

    if (-not (Test-Path -LiteralPath $BackupFile))
    {
        return
    }

    if ($PSCmdlet.ShouldProcess(
            $BackupFile,
            "Supprimer la sauvegarde"))
    {
        Remove-Item `
            -LiteralPath $BackupFile `
            -Force
    }

}

#==============================================================================
# Vérifie qu'une sauvegarde existe
#==============================================================================

function Test-Backup {

    [CmdletBinding()]
    [OutputType([bool])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.IO.FileInfo]
        $File,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [hashtable]
        $Session

    )

    if (-not (Test-BackupSession -Session $Session))
    {
        return $false
    }

    return (Test-Path `
        -LiteralPath (
            Get-BackupFile `
                -File $File `
                -Session $Session
        ))

}

#==============================================================================
# Retourne des statistiques sur une session
#==============================================================================

function Get-BackupStatistics {

    [CmdletBinding()]
    [OutputType([PSCustomObject])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [hashtable]
        $Session

    )

    if (-not (Test-BackupSession -Session $Session))
    {
        throw "Session de sauvegarde invalide."
    }

        $Files = @(Get-BackupFiles -Session $Session)

    $TotalSize = 0

    foreach ($File in $Files)
    {
        $TotalSize += $File.Length
    }

    [PSCustomObject]@{

        Session = $Session.Id

        Started = $Session.Started

        Files = $Files.Count

        Size = $TotalSize

        BackupRoot = $Session.BackupRoot

    }

}
#==============================================================================
# Retourne les sessions de sauvegarde
#==============================================================================

function Get-BackupSessions {

    [CmdletBinding()]
    [OutputType([System.IO.DirectoryInfo[]])]

    param()

    $BackupRoot = Get-BackupRoot

    if (-not (Test-Path -LiteralPath $BackupRoot))
    {
        return @()
    }

    return Get-ChildItem `
        -LiteralPath $BackupRoot `
        -Directory |
        Sort-Object Name -Descending

}

#==============================================================================
# Supprime une session complète
#==============================================================================

function Remove-BackupSession {

    [CmdletBinding(SupportsShouldProcess)]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [hashtable]
        $Session

    )

    if (-not (Test-BackupSession -Session $Session))
    {
        throw "Session de sauvegarde invalide."
    }

    if ($PSCmdlet.ShouldProcess(
            $Session.BackupRoot,
            "Supprimer la session de sauvegarde"))
    {
        Remove-Item `
            -LiteralPath $Session.BackupRoot `
            -Recurse `
            -Force
    }

}

#==============================================================================
# Nettoie les anciennes sauvegardes
#==============================================================================

function Clear-Backups {

    [CmdletBinding(SupportsShouldProcess)]

    param(

        [ValidateRange(1,[int]::MaxValue)]
        [int]
        $Keep = 10

    )

        $Sessions = @(Get-BackupSessions)

    if ($Sessions.Count -le $Keep)
    {
        return
    }

    $Sessions |
        Select-Object -Skip $Keep |
        ForEach-Object {

            if ($PSCmdlet.ShouldProcess(
                    $_.FullName,
                    "Supprimer la session de sauvegarde"))
            {
                Remove-Item `
                    -LiteralPath $_.FullName `
                    -Recurse `
                    -Force
            }

        }

}

#==============================================================================
# Export
#==============================================================================

Export-ModuleMember `
    -Function `
        Get-BackupRoot,
        Get-RelativeProjectPath,
        Get-BackupPath,
        Get-BackupFile,
        Test-BackupSession,
        New-BackupSession,
        Get-BackupFiles,
        New-Backup,
        Restore-Backup,
        Remove-Backup,
        Test-Backup,
        Get-BackupStatistics,
        Get-BackupSessions,
        Remove-BackupSession,
        Clear-Backups