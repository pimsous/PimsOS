# ==========================================
# Module : Iso
# Projet : PimsOS Builder
# Version : 0.1.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Etat d'un montage ISO
# --------------------------------------------------

function New-IsoMountState {

    [CmdletBinding()]
    param()

    return [PSCustomObject]@{

        ObjectType = "IsoMountState"

        Exists = $false

        Mounted = $false

        DriveLetter = $null

        FullName = $null

        Message = $null

    }

}

# --------------------------------------------------
# Analyse le montage ISO
# --------------------------------------------------

function Get-IsoMountState {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context

    )

    $State = New-IsoMountState

    $iso = Get-IsoFile `
    -Context $Context

    $DiskImage = Get-DiskImage `
		-ImagePath $iso.FullName `
		-ErrorAction SilentlyContinue

    if ($null -eq $DiskImage) {

        $State.Message = "ISO non montée."

        return $State

    }

    $Volume = $DiskImage | Get-Volume

	if ($null -eq $Volume) {

		$State.Exists = $true
		$State.Mounted = $false
		$State.FullName = $iso.FullName
		$State.Message = "Image ISO détectée mais aucun volume n'est monté."

		return $State

	}

	$State.Exists = $true
	$State.Mounted = $true
	$State.FullName = $iso.FullName
	$State.DriveLetter = "$($Volume.DriveLetter):"
	$State.Message = "ISO montée."

	return $State

}

function Get-IsoFile {

    [CmdletBinding()]
    param(

		[psobject]$Context

	)

    $isoFolder = Get-ProjectPath ISO

    $isoFiles = @(Get-ChildItem -Path $isoFolder -Filter *.iso -File -ErrorAction Stop)

    if ($isoFiles.Count -eq 0) {
        throw "Aucune image ISO trouvée dans '$isoFolder'."
    }

    if ($isoFiles.Count -gt 1) {
        throw "Plusieurs images ISO sont présentes dans '$isoFolder'."
    }

    $file = $isoFiles[0]

    return [PSCustomObject]@{
        Name       = $file.Name
        FullName   = $file.FullName
        Directory  = $file.DirectoryName
        SizeBytes  = $file.Length
        SizeGB     = [Math]::Round($file.Length / 1GB, 2)
        LastWrite  = $file.LastWriteTime
    }

}

function Test-IsoFile {

    [CmdletBinding()]
    param(

		[psobject]$Context

	)

    $iso = Get-IsoFile `
    -Context $Context
	

    if ($iso.SizeGB -lt 3) {

        return [PSCustomObject]@{

            Success = $false
            Message = "La taille de l'ISO semble incorrecte ($($iso.SizeGB) Go)."

            Iso = $iso

        }

    }

    return [PSCustomObject]@{

        Success = $true
        Message = "ISO valide."

        Iso = $iso

    }

}

function Copy-IsoToWorkspace {

    [CmdletBinding()]
    param(

		[psobject]$Context

	)

    $iso = Get-IsoFile `
    -Context $Context

    $config = Get-Config

    $destinationFolder = Join-Path `
        (Get-ProjectRoot) `
        $config.Workspace.ISO

    if (-not (Test-Path $destinationFolder)) {

        New-Item `
            -ItemType Directory `
            -Path $destinationFolder `
            -Force | Out-Null

    }

    $destination = Join-Path `
        $destinationFolder `
        $iso.Name

    Write-Log "Copie de l'ISO..."

    Copy-Item `
		-Path $iso.FullName `
		-Destination $destination `
		-Force `
		-ErrorAction Stop

    Write-Log "ISO copiée dans Workspace." SUCCESS

    return $destination

}

function Get-IsoInformation {

    [CmdletBinding()]
    param(

		[psobject]$Context

	)

    $iso = Get-IsoFile `
    -Context $Context

    return [PSCustomObject]@{

        Name      = $iso.Name
        SizeGB    = $iso.SizeGB
        LastWrite = $iso.LastWrite

    }
}
	
function Mount-Iso {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$Context
    )

    $iso = Get-IsoFile `
    -Context $Context

	$State = $Context.BuildState.Recovery.Iso

	if (
		$null -ne $State -and
		$State.Exists -and
		$State.Mounted
	) {

		Write-Log (
			"Réutilisation du montage ISO existant."
		) SUCCESS

		$Context.ISO = [PSCustomObject]@{

			Name        = $iso.Name
			FullName    = $iso.FullName

			DriveLetter = $State.DriveLetter
			Root        = "$($State.DriveLetter)\"
			SourcesPath = Join-Path "$($State.DriveLetter)\" "sources"

			Label       = $null

			Mounted     = $true

		}
		
		$Context.BuildState.Image.IsoMounted = $true
		
		return $Context

	}

	Write-Log "Montage de l'image ISO..."

    $null = Mount-DiskImage `
		-ImagePath $iso.FullName `
		-StorageType ISO `
		-PassThru

    $timeout = 20

do {

    Start-Sleep -Milliseconds 500

    $diskImage = Get-DiskImage -ImagePath $iso.FullName

    $volume = $diskImage | Get-Volume

    $timeout--

}
until ($volume.DriveLetter -or $timeout -le 0)

if (-not $volume.DriveLetter) {

    throw "Impossible de récupérer la lettre du lecteur après le montage."

}

    $drive = "$($volume.DriveLetter):"

    $Context.ISO = [PSCustomObject]@{

        Name = $iso.Name

        FullName = $iso.FullName

        DriveLetter = $drive

        Root = "$drive\"

        SourcesPath = Join-Path "$drive\" "sources"

        Label = $volume.FileSystemLabel

        Mounted = $true

    }
	
	$Context.BuildState.Image.IsoMounted = $true
	
    Write-Log "ISO montée sur $drive" SUCCESS

    return $Context

}
function Dismount-Iso {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context

    )

    if (-not $Context.ISO.Mounted) {

        return $Context

    }

    Write-Log "Démontage de l'image ISO..."

    try {

		$null = Dismount-DiskImage `
			-ImagePath $Context.ISO.FullName `
			-ErrorAction Stop

	}
    catch {

        throw (
            "Impossible de démonter l'image ISO.`n" +
            $_.Exception.Message
        )

    }

    $Context.ISO.Mounted = $false
    $Context.ISO.DriveLetter = $null
    $Context.ISO.Root = $null
    $Context.ISO.SourcesPath = $null

    Write-Log "ISO démontée." SUCCESS
	
	$Context.BuildState.Recovery.Iso = New-IsoMountState
	$Context.BuildState.Image.IsoMounted = $false
	
    return $Context

}
