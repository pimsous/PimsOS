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

# ==========================================
# Copie le contenu de l'ISO montée dans
# Workspace\ISO\Source
# ==========================================

function Copy-IsoContentToWorkspace {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context

    )

    if ($null -eq $Context.ISO) {

        throw "Les informations de l'ISO sont absentes du contexte."

    }

    if (
        $Context.ISO.PSObject.Properties.Name -notcontains "Root"
    ) {

        throw "Le chemin racine de l'ISO montée est absent du contexte."

    }

    $SourcePath =
        [string]$Context.ISO.Root

    if ([string]::IsNullOrWhiteSpace($SourcePath)) {

        throw "Le chemin racine de l'ISO montée est vide."

    }

    if (-not (Test-Path -LiteralPath $SourcePath -PathType Container)) {

        throw (
            "Le contenu de l'ISO montée est introuvable : {0}" -f
            $SourcePath
        )

    }

    $Config = Get-Config

    if (
        $null -eq $Config.Workspace -or
        [string]::IsNullOrWhiteSpace(
            [string]$Config.Workspace.ISOSource
        )
    ) {

        throw "Le chemin Workspace.ISOSource est absent de Config.json."

    }

    $DestinationPath =
        Join-Path `
            -Path (Get-ProjectRoot) `
            -ChildPath $Config.Workspace.ISOSource

    Write-Log (
        "Préparation de la source ISO : {0}" -f
        $DestinationPath
    ) INFO

    # --------------------------------------------------
    # Nettoyage de l'ancienne source
    # --------------------------------------------------

    if (Test-Path -LiteralPath $DestinationPath) {

        Write-Log `
            "Nettoyage de l'ancienne source ISO..." `
            INFO

        Remove-Item `
            -LiteralPath $DestinationPath `
            -Recurse `
            -Force `
            -ErrorAction Stop

    }

    # --------------------------------------------------
    # Création du dossier source
    # --------------------------------------------------

    New-Item `
        -ItemType Directory `
        -Path $DestinationPath `
        -Force `
        -ErrorAction Stop |
        Out-Null

    # --------------------------------------------------
    # Copie du contenu ISO
    # --------------------------------------------------

    Write-Log (
        "Copie du contenu ISO depuis {0}..." -f
        $SourcePath
    ) INFO

    Copy-Item `
        -Path (Join-Path $SourcePath "*") `
        -Destination $DestinationPath `
        -Recurse `
        -Force `
        -ErrorAction Stop

	# --------------------------------------------------
    # Préparation du install.wim pour modification
    # --------------------------------------------------

    $InstallWim =
        Join-Path `
            -Path $DestinationPath `
            -ChildPath "sources\install.wim"

    if (Test-Path -LiteralPath $InstallWim -PathType Leaf) {

        Write-Log `
            "Suppression de l'attribut ReadOnly du install.wim..." `
            INFO

        Set-ItemProperty `
            -LiteralPath $InstallWim `
            -Name Attributes `
            -Value ([System.IO.FileAttributes]::Archive) `
            -ErrorAction Stop

    }

    # --------------------------------------------------
    # Validation
    # --------------------------------------------------

    $BootFile =
        Join-Path `
            -Path $DestinationPath `
            -ChildPath "boot\etfsboot.com"

    $EfiBootFile =
        Join-Path `
            -Path $DestinationPath `
            -ChildPath "efi\microsoft\boot\efisys.bin"


    if (-not (Test-Path -LiteralPath $BootFile -PathType Leaf)) {

        throw (
            "Le fichier de démarrage BIOS n'a pas été copié : {0}" -f
            $BootFile
        )

    }

    if (-not (Test-Path -LiteralPath $EfiBootFile -PathType Leaf)) {

        throw (
            "Le fichier de démarrage UEFI n'a pas été copié : {0}" -f
            $EfiBootFile
        )

    }

    if (-not (Test-Path -LiteralPath $InstallWim -PathType Leaf)) {

        throw (
            "Le fichier install.wim n'a pas été copié : {0}" -f
            $InstallWim
        )

    }

    Write-Log `
        "Source ISO préparée avec succès." `
        SUCCESS

    return $Context
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

			OutputPath   = $null
			OutputName   = $null
			OutputSizeGB = 0

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

		OutputPath   = $null
		OutputName   = $null
		OutputSizeGB = 0

    }

	$Context.BuildState.Image.IsoMounted = $true

    Write-Log "ISO montée sur $drive" SUCCESS

    return $Context

}
# ==========================================
# Démontage de l'image ISO
# ==========================================

function Dismount-Iso {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context

    )

    # ------------------------------------------
    # Validation du contexte
    # ------------------------------------------

    if ($null -eq $Context) {

        throw "Le contexte Build est null."

    }

    if (
        -not $Context.PSObject.Properties.Name.Contains("ISO")
    ) {

        throw "Le contexte ne contient pas la section ISO."

    }

    # ------------------------------------------
    # ISO absente
    # ------------------------------------------

    if ($null -eq $Context.ISO) {

        Write-Log `
            "Aucune information ISO dans le contexte." `
            WARNING

        return $Context

    }

    # ------------------------------------------
    # Vérification de l'état
    # ------------------------------------------

    if (
        $Context.ISO.PSObject.Properties.Name -contains "Mounted"
    ) {

        if (-not [bool]$Context.ISO.Mounted) {

            Write-Log `
                "L'image ISO n'est pas montée." `
                INFO

            return $Context

        }

    }

    # ------------------------------------------
    # Récupération du chemin
    # ------------------------------------------

    $IsoPath = $null

    if (
        $Context.ISO.PSObject.Properties.Name -contains "FullName"
    ) {

        $IsoPath = [string]$Context.ISO.FullName

    }

    if ([string]::IsNullOrWhiteSpace($IsoPath)) {

        throw `
            "Le chemin de l'image ISO est absent du contexte."

    }

    Write-Log `
        "Démontage de l'image ISO..." `
        INFO

    # ------------------------------------------
    # Module Storage
    # ------------------------------------------

    Import-Module Storage -Force -ErrorAction Stop

    # ------------------------------------------
    # Vérification avant démontage
    # ------------------------------------------

    $Image = Get-DiskImage `
        -ImagePath $IsoPath `
        -ErrorAction Stop

    if (-not $Image.Attached) {

        Write-Log `
            "L'image ISO est déjà démontée." `
            INFO

    }
    else {

        # --------------------------------------
        # Démontage
        # --------------------------------------

        try {

            Dismount-DiskImage `
                -ImagePath $IsoPath `
                -ErrorAction Stop |
                Out-Null

        }
        catch {

            throw (
                "Impossible de démonter l'image ISO.`n" +
                $_.Exception.Message
            )

        }

        # --------------------------------------
        # Vérification après démontage
        # --------------------------------------

        $Image = Get-DiskImage `
            -ImagePath $IsoPath `
            -ErrorAction Stop

        if ($Image.Attached) {

            throw (
                "L'image ISO est toujours attachée après le démontage.`n" +
                "ISO        : $IsoPath`n" +
                "DevicePath : $($Image.DevicePath)`n" +
                "Number     : $($Image.Number)"
            )

        }

    }

    # ------------------------------------------
    # Mise à jour du contexte ISO
    # ------------------------------------------

    $Context.ISO.Mounted = $false
    $Context.ISO.DriveLetter = $null
    $Context.ISO.Root = $null
    $Context.ISO.SourcesPath = $null

    # ------------------------------------------
    # Mise à jour BuildState
    # ------------------------------------------

    if (
        $null -ne $Context.BuildState -and
        $Context.BuildState.PSObject.Properties.Name -contains "Recovery"
    ) {

        if (
            $null -ne $Context.BuildState.Recovery -and
            $Context.BuildState.Recovery.PSObject.Properties.Name -contains "Iso"
        ) {

            $Context.BuildState.Recovery.Iso =
                New-IsoMountState

        }

    }

    if (
        $null -ne $Context.BuildState -and
        $Context.BuildState.PSObject.Properties.Name -contains "Image"
    ) {

        if (
            $null -ne $Context.BuildState.Image -and
            $Context.BuildState.Image.PSObject.Properties.Name -contains "IsoMounted"
        ) {

            $Context.BuildState.Image.IsoMounted = $false

        }

    }

    Write-Log `
        "ISO démontée." `
        SUCCESS

    return $Context

}
# ==========================================
# Création de l'ISO PimsOS
# ==========================================

function New-PimsOSIso {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context

    )

    Write-Log `
        "Création de l'ISO PimsOS..." `
        INFO

    # --------------------------------------------------
    # Vérification de Windows ADK / oscdimg
    # --------------------------------------------------

    $OsCdImgPath = Get-PimsOSOsCdImgPath

    if (
        [string]::IsNullOrWhiteSpace($OsCdImgPath) -or
        -not (Test-Path -LiteralPath $OsCdImgPath -PathType Leaf)
    ) {

        throw `
            "oscdimg.exe est introuvable. Windows ADK est requis pour créer l'ISO."

    }

	# --------------------------------------------------
    # Détermination de la source ISO
    # --------------------------------------------------

    $Config = Get-Config

    if (
        $null -eq $Config.Workspace -or
        [string]::IsNullOrWhiteSpace(
            [string]$Config.Workspace.ISOSource
        )
    ) {

        throw "Le chemin Workspace.ISOSource est absent de Config.json."

    }

    $SourcePath =
        Join-Path `
            -Path (Get-ProjectRoot) `
            -ChildPath $Config.Workspace.ISOSource

    if (-not (Test-Path -LiteralPath $SourcePath -PathType Container)) {

        throw (
            "Le contenu source de l'ISO est introuvable : {0}" -f
            $SourcePath
        )

    }

    # --------------------------------------------------
    # Chemin de sortie
    # --------------------------------------------------

    $OutputPath = [string]$Context.Project.Paths.Output

    if ([string]::IsNullOrWhiteSpace($OutputPath)) {

        throw `
            "Le chemin Output est absent du contexte."

    }

    if (-not (Test-Path -LiteralPath $OutputPath -PathType Container)) {

        New-Item `
            -ItemType Directory `
            -Path $OutputPath `
            -Force `
            -ErrorAction Stop |
            Out-Null

    }

    # --------------------------------------------------
    # Nom de l'ISO
    # --------------------------------------------------

    $Version = [string]$Context.Project.Version

    if ([string]::IsNullOrWhiteSpace($Version)) {

        $Version = "dev"

    }

    $IsoName =
        "PimsOS_{0}_{1}.iso" -f
        $Version,
        (Get-Date -Format "yyyyMMdd_HHmmss")

    $IsoPath =
        Join-Path `
            -Path $OutputPath `
            -ChildPath $IsoName

    # --------------------------------------------------
    # Vérification des fichiers de démarrage
    # --------------------------------------------------

    $BootFile = Join-Path `
        -Path $SourcePath `
        -ChildPath "boot\etfsboot.com"

    $EfiBootFile = Join-Path `
        -Path $SourcePath `
        -ChildPath "efi\microsoft\boot\efisys.bin"

    if (-not (Test-Path -LiteralPath $BootFile -PathType Leaf)) {

        throw (
            "Fichier de démarrage BIOS introuvable : {0}" -f
            $BootFile
        )

    }

    if (-not (Test-Path -LiteralPath $EfiBootFile -PathType Leaf)) {

        throw (
            "Fichier de démarrage UEFI introuvable : {0}" -f
            $EfiBootFile
        )

    }

    # --------------------------------------------------
    # Création avec oscdimg
    # --------------------------------------------------

    Write-Log (
        "Source ISO : {0}" -f
        $SourcePath
    ) INFO

    Write-Log (
        "ISO de sortie : {0}" -f
        $IsoPath
    ) INFO

    Write-Log (
        "oscdimg : {0}" -f
        $OsCdImgPath
    ) INFO

    $Arguments = @(
		"-m"
		"-o"
		"-u2"
		"-udfver102"
		"-bootdata:2#p0,b$BootFile#pEF,b$EfiBootFile"
		$SourcePath
		$IsoPath
	)

    & $OsCdImgPath @Arguments

    $ExitCode = $LASTEXITCODE

    if ($ExitCode -ne 0) {

        throw (
            "oscdimg a échoué avec le code retour {0}." -f
            $ExitCode
        )

    }

    # --------------------------------------------------
    # Vérification de l'ISO
    # --------------------------------------------------

    if (-not (Test-Path -LiteralPath $IsoPath -PathType Leaf)) {

        throw (
            "oscdimg indique une réussite mais l'ISO n'a pas été créée : {0}" -f
            $IsoPath
        )

    }

    $IsoFile = Get-Item `
        -LiteralPath $IsoPath `
        -ErrorAction Stop

    if ($IsoFile.Length -le 0) {

        throw "L'ISO générée est vide."

    }

    # --------------------------------------------------
    # Mise à jour du contexte
    # --------------------------------------------------

    $Context.ISO.OutputPath = $IsoPath

    $Context.ISO.OutputName = $IsoFile.Name

    $Context.ISO.OutputSizeGB =
        [Math]::Round(
            $IsoFile.Length / 1GB,
            2
        )

    Write-Log (
        "ISO PimsOS créée : {0}" -f
        $IsoPath
    ) SUCCESS

    Write-Log (
        "Taille ISO : {0} Go" -f
        $Context.ISO.OutputSizeGB
    ) SUCCESS

    return $Context
}
