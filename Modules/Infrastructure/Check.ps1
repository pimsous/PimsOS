# ==========================================
# Module : Check
# Projet : PimsOS Builder
# Version : 2.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# ==================================================
# Vérifie la version de PowerShell
# ==================================================

function Test-PowerShellVersion {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context

    )

    $Config = $Context.Project.Config

    $RequiredVersion = [int]$Config.Requirements.PowerShellMajor

    return ($PSVersionTable.PSVersion.Major -ge $RequiredVersion)

}

# ==================================================
# Vérifie les droits administrateur
# ==================================================

function Test-Administrator {

    [CmdletBinding()]
    param()

    $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()

    $Principal = [Security.Principal.WindowsPrincipal]::new($Identity)

    return $Principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )

}

# ==================================================
# Retourne l'espace disque libre
# ==================================================

function Get-FreeDiskSpaceGB {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context

    )

    $Drive = $Context.Project.Root.Substring(0,1)

    $Disk = Get-CimInstance Win32_LogicalDisk |
        Where-Object DeviceID -eq "$Drive`:"

    return [Math]::Round($Disk.FreeSpace / 1GB, 2)

}

# ==================================================
# Vérification complète de l'environnement
# ==================================================

function Invoke-EnvironmentChecks {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [pscustomobject]$Context

    )

    Write-Log "Vérification de l'environnement..."

    $Context = Start-BuildPhase `
        -Context $Context `
        -Name "Environment"

    $Config = $Context.Project.Config

    $Checks = @()

    # --------------------------------------------------
    # PowerShell
    # --------------------------------------------------

    $Checks += [PSCustomObject]@{

        Name    = "PowerShell"
        Success = Test-PowerShellVersion `
            -Context $Context

        Value   = $PSVersionTable.PSVersion.ToString()

    }

    # --------------------------------------------------
    # Administrateur
    # --------------------------------------------------

    $IsAdmin = Test-Administrator

    $Checks += [PSCustomObject]@{

        Name    = "Administrator"
        Success = $IsAdmin

        Value = if ($IsAdmin) {

            "Administrateur"

        }
        else {

            "Non administrateur"

        }

    }

    # --------------------------------------------------
    # Git
    # --------------------------------------------------

    $Git = Get-Command git -ErrorAction SilentlyContinue

    $Checks += [PSCustomObject]@{

        Name    = "Git"
        Success = ($null -ne $Git)

        Value = if ($Git) {

            & git --version

        }
        else {

            "Non installé"

        }

    }

    # --------------------------------------------------
    # DISM
    # --------------------------------------------------

    $Dism = Get-Command Get-WindowsImage -ErrorAction SilentlyContinue

    $Checks += [PSCustomObject]@{

        Name    = "DISM"
        Success = ($null -ne $Dism)

        Value = if ($Dism) {

            "Disponible"

        }
        else {

            "Indisponible"

        }

    }

    # --------------------------------------------------
    # ISO
    # --------------------------------------------------

    try {

        $Iso = Get-IsoFile `
            -Context $Context

        $Checks += [PSCustomObject]@{

            Name    = "ISO"
            Success = $true
            Value   = $Iso.Name

        }

    }
    catch {

        $Checks += [PSCustomObject]@{

            Name    = "ISO"
            Success = $false
            Value   = $_.Exception.Message

        }

    }

    # --------------------------------------------------
    # Espace disque
    # --------------------------------------------------

    $FreeGB = Get-FreeDiskSpaceGB `
        -Context $Context

    $Checks += [PSCustomObject]@{

        Name    = "DiskSpace"
        Success = ($FreeGB -ge $Config.Requirements.MinimumFreeSpaceGB)
        Value   = "$FreeGB Go libres"

    }

    # --------------------------------------------------
    # Rapport
    # --------------------------------------------------

    $Context = Set-EnvironmentReport `
        -Context $Context `
        -Checks $Checks

    foreach ($Check in $Checks) {

        if ($Check.Success) {

            Write-Log "$($Check.Name) : $($Check.Value)" SUCCESS

        }
        else {

            Write-Log "$($Check.Name) : $($Check.Value)" ERROR

        }

    }

    $Context = Complete-BuildPhase `
        -Context $Context

    # --------------------------------------------------
    # Etat du Build
    # --------------------------------------------------

    $Context.BuildState.Environment.Checked = $true

    $Context.BuildState.Environment.PowerShell =
        ($Checks | Where-Object Name -eq "PowerShell").Success

    $Context.BuildState.Environment.Administrator =
        ($Checks | Where-Object Name -eq "Administrator").Success

    $Context.BuildState.Environment.Git =
        ($Checks | Where-Object Name -eq "Git").Success

    $Context.BuildState.Environment.Dism =
        ($Checks | Where-Object Name -eq "DISM").Success

    $Context.BuildState.Environment.Iso =
        ($Checks | Where-Object Name -eq "ISO").Success

    $Context.BuildState.Environment.DiskSpace =
        ($Checks | Where-Object Name -eq "DiskSpace").Success

    $Context.BuildState.Status = "EnvironmentChecked"

    return $Context

}