# ==========================================
# Module : Wim
# Projet : PimsOS Builder
# Version : 0.2.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Vérifie la validité du contexte WIM
# --------------------------------------------------

function Test-WimContext {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context

    )

    if ($null -eq $Context) {

        throw "Le contexte de build est null."

    }

    if (-not $Context.PSObject.Properties["WIM"]) {

        throw "Le contexte ne contient pas la section WIM."

    }

}

function New-WimMountState {

    [CmdletBinding()]
    param()

    return [PSCustomObject]@{

        ObjectType = "WimMountState"

        # ------------------------------------------
        # Etat général
        # ------------------------------------------

        Exists = $false

        Valid = $false

        CanReuse = $false

        NeedsCleanup = $false

        # ------------------------------------------
        # Diagnostic
        # ------------------------------------------

        MountStatus = $null

        Message = $null

        # ------------------------------------------
        # Informations DISM
        # ------------------------------------------

        MountPath = $null

        ImagePath = $null

        ImageIndex = $null

        # ------------------------------------------
        # Vérifications
        # ------------------------------------------

        WindowsFolderExists = $false

        ImageMatches = $false

        WorkspaceReady = $false

        RegistryMounted = $false

    }

}

# --------------------------------------------------
# Met à jour l'état de montage WIM
# --------------------------------------------------

function Set-WimMountedState {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [bool]$Mounted

    )

    $Context.BuildState.Image.WimMounted = $Mounted

    if (-not $Mounted) {

        $Context.BuildState.Image.RegistryLoaded = $false
        $Context.BuildState.Image.CurrentRegistryHive = $null

        $Context.BuildState.Image.ConfigLoaded = $false
        $Context.BuildState.Image.TweaksLoaded = $false
        $Context.BuildState.Image.TweaksApplied = $false
		
		$Context.BuildState.Image.ProfileLoaded = $false
		$Context.BuildState.Image.ProfileMerged = $false
    }

    return $Context

}

# --------------------------------------------------
# Analyse l'état du montage WIM
# --------------------------------------------------

function Get-WimMountState {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context

    )

    Test-WimContext `
        -Context $Context

    $State = New-WimMountState

    $Mounted = Get-WindowsImage -Mounted |
        Where-Object {
            $_.Path -eq $Context.Workspace.MountWIM
        }

    if (-not $Mounted) {

        $State.Message = "Aucun montage détecté."

        return $State

    }

    $State.Exists      = $true
	$State.MountStatus = $Mounted.MountStatus
	$State.MountPath   = $Mounted.Path
	$State.ImagePath   = $Mounted.ImagePath
	$State.ImageIndex  = $Mounted.ImageIndex

	# --------------------------------------------------
	# Vérifications complémentaires
	# --------------------------------------------------

	$State.WindowsFolderExists = Test-Path (
		Join-Path $Mounted.Path "Windows"
	)

	$State.ImageMatches =
	(
		$Mounted.ImagePath -eq $Context.WIM.FullName
	) -and
	(
		$Mounted.ImageIndex -eq $Context.Image.Index
	)

	$State.WorkspaceReady =
		Test-Path $Context.Workspace.Sources

	$State.RegistryMounted =
		Test-Path "Registry::HKLM\PimsOS_SOFTWARE"

    switch ($Mounted.MountStatus) {

    "Ok" {

        $State.Valid = $true

        if (-not $State.WindowsFolderExists) {

            $State.NeedsCleanup = $true
            $State.Message = "Montage incomplet (dossier Windows absent)."

            break

        }
		
		if (-not $State.WorkspaceReady) {

			$State.NeedsCleanup = $true
			$State.Message = "Workspace incomplet."

			break

		}

		if (-not $State.RegistryMounted) {

			$State.NeedsCleanup = $true
			$State.Message = "Les ruches PimsOS ne sont plus montées."

			break

		}

        if (-not $State.ImageMatches) {

            $State.NeedsCleanup = $true
            $State.Message = "Montage invalide (image ou index différent)."

            break

        }

        $State.CanReuse = $true
        $State.Message = "Montage valide (réutilisable)."

    }

    "NeedsRemount" {

        $State.NeedsCleanup = $true
        $State.Message = "Montage à reconstruire."

    }

    "Invalid" {

        $State.NeedsCleanup = $true
        $State.Message = "Montage invalide."

    }

    default {

        $State.NeedsCleanup = $true
        $State.Message = "Etat inconnu : $($Mounted.MountStatus)"

    }

}

    return $State

}

# --------------------------------------------------
# Vérifie qu'un WIM est chargé
# --------------------------------------------------

function Test-WimLoaded {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context

    )

    Test-WimContext `
        -Context $Context

    if ([string]::IsNullOrWhiteSpace($Context.WIM.FullName)) {

        throw "Aucun fichier WIM n'est chargé."

    }

}

# --------------------------------------------------
# Vérifie qu'une image Windows est sélectionnée
# --------------------------------------------------

function Test-WimImageSelected {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context

    )

    Test-WimLoaded `
        -Context $Context

    if ($null -eq $Context.Image.Index) {

        throw "Aucune image Windows sélectionnée."

    }

}

# --------------------------------------------------
# Vérifie qu'une image est montée
# --------------------------------------------------

function Test-WimMounted {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context

    )

    Test-WimImageSelected `
        -Context $Context

    if (-not $Context.BuildState.Image.WimMounted) {

		throw "Aucune image Windows n'est montée."

	}

    if (-not (Test-Path $Context.WIM.Mount.Path)) {

        throw "Le dossier de montage est introuvable."

    }

}
# --------------------------------------------------
# Recherche le fichier install.wim / install.esd
# --------------------------------------------------

function Get-WimFile {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context

    )

    Test-WimContext `
        -Context $Context

    Write-Log "Recherche du fichier image Windows..."

    $Sources = $Context.ISO.SourcesPath

    if (-not (Test-Path $Sources)) {

        throw "Le dossier '$Sources' est introuvable."

    }

    foreach ($Name in @(
        "install.wim",
        "install.esd"
    )) {

        $Path = Join-Path `
            -Path $Sources `
            -ChildPath $Name

        if (Test-Path $Path) {

            $File = Get-Item $Path

            $Context.WIM.Type = $File.Extension.TrimStart(".").ToUpper()

            $Context.WIM.Name = $File.Name

            $Context.WIM.FullName = $File.FullName

            $Context.WIM.SizeGB =
                [Math]::Round($File.Length / 1GB,2)

            $Context.WIM.Images = @()

            $Context.WIM.Mount.Path = $null

            $Context = Set-WimMountedState `
				-Context $Context `
				-Mounted $false

            $Context.WIM.Mount.ReadOnly = $false

            Write-Log (
                "Image détectée : {0}" -f $File.Name
            ) SUCCESS

            return $Context

        }

    }

    throw "Aucun fichier install.wim ou install.esd n'a été trouvé."

}

# --------------------------------------------------
# Copie l'image Windows dans le Workspace
# --------------------------------------------------

function Copy-WimToWorkspace {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context

    )

    Test-WimLoaded `
        -Context $Context

    Write-Log "Copie de l'image Windows..."

    $Destination = Join-Path `
        -Path $Context.Workspace.Sources `
        -ChildPath $Context.WIM.Name

    if (-not (Test-Path $Context.Workspace.Sources)) {

        New-Item `
            -ItemType Directory `
            -Path $Context.Workspace.Sources `
            -Force |
            Out-Null

    }

    Copy-Item `
		-Path $Context.WIM.FullName `
		-Destination $Destination `
		-Force `
		-ErrorAction Stop

    if (-not (Test-Path $Destination)) {

        throw "La copie de l'image Windows a échoué."

    }

    $File = Get-Item $Destination
	
	$File.Attributes =
		$File.Attributes -band (-bnot [System.IO.FileAttributes]::ReadOnly)

	$File.Refresh()
	
	

    $Context.WIM.FullName = $File.FullName

    $Context.WIM.Name = $File.Name

    $Context.WIM.SizeGB =
        [Math]::Round($File.Length / 1GB,2)

    Write-Log (
        "Image copiée dans le Workspace."
    ) SUCCESS
	

    return $Context

}
# --------------------------------------------------
# Lecture des images Windows
# --------------------------------------------------

function Get-WimImages {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context

    )

    Test-WimLoaded `
        -Context $Context

    Write-Log "Lecture des images Windows..."

    try {

        $Images = @(Get-DismImages `
            -ImagePath $Context.WIM.FullName)

    }
    catch {

        throw (
            "Impossible de lire le contenu du WIM.`n" +
            $_.Exception.Message
        )

    }

    if ($Images.Count -eq 0) {

        throw "Aucune image Windows n'a été trouvée."

    }

    $Context.WIM.Images = @()

    foreach ($Image in $Images) {

        $Context.WIM.Images += [PSCustomObject]@{

            Index       = $Image.ImageIndex
            Name        = $Image.ImageName
            Description = $Image.ImageDescription
            Size        = $Image.ImageSize

        }

    }

    Write-Log (
        "{0} image(s) détectée(s)." -f $Context.WIM.Images.Count
    ) SUCCESS

    return $Context

}

# --------------------------------------------------
# Sélection interactive d'une image Windows
# --------------------------------------------------

function Select-WimImageInteractive {
	
	[CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context

    )

    Write-Log "Aucune édition configurée." WARNING

	Write-Host ""
	Write-Host "==========================================" -ForegroundColor Cyan
	Write-Host "      Editions Windows disponibles"
	Write-Host "==========================================" -ForegroundColor Cyan
	Write-Host ""

	foreach ($Image in $Context.WIM.Images) {

		Write-Host (
			"[{0}] {1}" -f
			$Image.Index,
			$Image.Name
		)

	}

	Write-Host ""

	do {
		Write-Host ""
		$Choice = Read-Host "Choisissez l'index de l'édition"

		$Index = 0

		if (-not [int]::TryParse($Choice, [ref]$Index)) {

			Write-Log "Veuillez saisir un numéro." WARNING

			continue

		}

		$Selected = $Context.WIM.Images |
			Where-Object Index -eq $Index

		if (-not $Selected) {

			Write-Log "Index invalide." WARNING

		}

	}
	until ($Selected)
	
	$Context.Image.Index = $Selected.Index

	$Context.Image.Name = $Selected.Name

	$Context.Image.Description = $Selected.Description

	$Context.Image.Size = $Selected.Size

	$Context.Image.SelectedBy = "Utilisateur"

	$Context.Image.Interactive = $true

	Write-Log (
		"Edition sélectionnée : {0} (Index {1})" -f
		$Context.Image.Name,
		$Context.Image.Index
	) SUCCESS

	return $Context
}

# --------------------------------------------------
# Sélection de l'image Windows
# --------------------------------------------------

function Select-WimImage {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context

    )

    Test-WimLoaded `
        -Context $Context

    if (-not $Context.WIM.Images) {

        throw "Les images Windows n'ont pas été chargées."

    }

    if ($Context.WIM.Images.Count -eq 0) {

        throw "Aucune image Windows disponible."

    }

    $EditionName = $Context.Image.Name

	if (-not [string]::IsNullOrWhiteSpace($EditionName)) {

		Write-Log (
			"Edition demandée : {0}" -f
			$EditionName
		)

	}
    
	$Selected = $null


    # --------------------------------------------------
	# Sélection par nom
	# --------------------------------------------------

    if (-not $Selected -and
        -not [string]::IsNullOrWhiteSpace($EditionName)) {

        $Selected = $Context.WIM.Images |
            Where-Object {

                $_.Name -like "*$EditionName*"

            } |
            Select-Object -First 1

    }

    if (-not $Selected) {

		if ([string]::IsNullOrWhiteSpace($EditionName)) {

			return Select-WimImageInteractive `
				-Context $Context

		}

		$Available = $Context.WIM.Images |
			ForEach-Object {
				"[{0}] {1}" -f $_.Index, $_.Name
			}

		throw (
			"Impossible de trouver l'édition demandée.`n" +
			"Images disponibles :`n" +
			($Available -join "`n")
		)

	}

    $Context.Image.Index = $Selected.Index

    $Context.Image.Name = $Selected.Name

    $Context.Image.Description = $Selected.Description

    $Context.Image.Size = $Selected.Size
	
	$Context.Image.SelectedBy =
		if ([string]::IsNullOrWhiteSpace($EditionName)) {
			"Utilisateur"
		}
		else {
			"Configuration"
		}

	$Context.Image.Interactive =
		[string]::IsNullOrWhiteSpace($EditionName)

    Write-Log (
        "Edition sélectionnée : {0} (Index {1})" -f
        $Context.Image.Name,
        $Context.Image.Index
    ) SUCCESS

    return $Context

}
# --------------------------------------------------
# Monte l'image Windows
# --------------------------------------------------

function Mount-Wim {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [switch]$ReadOnly

    )

    Test-WimImageSelected `
        -Context $Context

    Write-Log "Initialisation du montage de l'image Windows..."

    # --------------------------------------------------
    # Préparation du dossier de montage
    # --------------------------------------------------

    $MountPath = $Context.Workspace.MountWIM

    $Context.WIM.Mount.Path = $MountPath

    # --------------------------------------------------
    # Déjà montée dans le contexte ?
    # --------------------------------------------------

    if ($Context.BuildState.Image.WimMounted) {

        Write-Log "Une image est déjà montée." WARNING

        return $Context

    }

    # --------------------------------------------------
    # Réutilisation d'un montage existant
    # --------------------------------------------------

    $State = $Context.BuildState.Recovery.Wim

		if ($null -eq $State) {

			throw "Le BuildState ne contient aucun état de récupération WIM."

		}

    if ($null -ne $State -and $State.CanReuse) {

        Write-Log (
            "Réutilisation du montage WIM existant."
        ) SUCCESS

        $Context.WIM.Mount.Path = $State.MountPath
        $Context = Set-WimMountedState `
			-Context $Context `
			-Mounted $true
        $Context.WIM.Mount.ReadOnly = $ReadOnly.IsPresent

        return $Context

    }

    # --------------------------------------------------
    # Préparation du dossier de montage
    # --------------------------------------------------

    if (Test-Path $MountPath) {

        Remove-Item `
            -Path $MountPath `
            -Recurse `
            -Force

    }

    New-Item `
        -ItemType Directory `
        -Path $MountPath `
        -Force |
        Out-Null

    # --------------------------------------------------
    # Vérification du dossier de montage
    # --------------------------------------------------

    $WindowsFolder = Join-Path `
        -Path $MountPath `
        -ChildPath "Windows"

    if (Test-Path $WindowsFolder) {

        throw (
            "Le dossier de montage contient encore une image Windows.`n" +
            "Chemin : $MountPath"
        )

    }

    # --------------------------------------------------
    # Montage DISM
    # --------------------------------------------------


    try {

        $null = Mount-DismImage `
            -ImagePath $Context.WIM.FullName `
            -Index $Context.Image.Index `
            -MountPath $MountPath `
            -ReadOnly:$ReadOnly

    }
    catch {

        throw (
            "Impossible de monter l'image Windows.`n" +
            $_.Exception.Message
        )

    }

    # --------------------------------------------------
    # Validation
    # --------------------------------------------------

    if (-not (Test-Path $MountPath)) {

        throw "Le dossier de montage est introuvable."

    }

    $WindowsFolder = Join-Path `
        -Path $MountPath `
        -ChildPath "Windows"

    if (-not (Test-Path $WindowsFolder)) {

        throw (
            "Le montage semble avoir échoué : dossier Windows introuvable."
        )

    }

    # --------------------------------------------------
    # Mise à jour du contexte
    # --------------------------------------------------

    $Context.WIM.Mount.Path = $MountPath
    $Context = Set-WimMountedState `
		-Context $Context `
		-Mounted $true
    $Context.WIM.Mount.ReadOnly = $ReadOnly.IsPresent

    Write-Log "Image Windows montée avec succès." SUCCESS

    return $Context

}

# --------------------------------------------------
# Démonte l'image Windows
# --------------------------------------------------

function Dismount-Wim {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [switch]$Discard

    )

    Test-WimContext `
        -Context $Context

    if (-not $Context.BuildState.Image.WimMounted) {

        Write-Log "Aucune image Windows montée." INFO

        return $Context

    }

    Write-Log "Démontage de l'image Windows..."

    # --------------------------------------------------
    # Démontage
    # --------------------------------------------------

    try {

        $null = Dismount-DismImage `
			-MountPath $Context.WIM.Mount.Path `
			-Discard:$Discard

    }
    catch {

        throw (
            "Impossible de démonter l'image Windows.`n" +
            $_.Exception.Message
        )

    }

    # --------------------------------------------------
    # Validation
    # --------------------------------------------------

    $Mounted = Get-WindowsImage -Mounted |
		Where-Object {

			$_.Path -eq $Context.WIM.Mount.Path

		}

	if ($Mounted) {

		throw (
			"Le WIM est toujours enregistré par DISM " +
			"État       : $($Mounted.MountStatus)`n" +
			"Montage    : $($Mounted.Path)`n" +
			"Image      : $($Mounted.ImagePath)"
		)

	}

    # --------------------------------------------------
    # Mise à jour du contexte
    # --------------------------------------------------
	
	$Context.WIM.Mount.Path = $null

    $Context = Set-WimMountedState `
		-Context $Context `
		-Mounted $false

    $Context.WIM.Mount.ReadOnly = $false

    Write-Log "Image Windows démontée." SUCCESS

    return $Context

}
# --------------------------------------------------
# Supprime l'image temporaire du Workspace
# --------------------------------------------------

function Remove-WorkspaceImage {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context

    )

    Test-WimContext `
        -Context $Context
		
	# --------------------------------------------------
	# Sécurité : ne jamais supprimer un WIM encore monté
	# --------------------------------------------------

	$Mounted = Get-WindowsImage -Mounted |
		Where-Object {

			$_.ImagePath -eq $Context.WIM.FullName -and
			$_.Path -eq $Context.WIM.Mount.Path

		}

	if ($Mounted) {

		Write-Log (
			"Montage détecté : $($Mounted.Path)"
		) INFO
		Write-Log (
			"Le WIM est encore monté. Suppression annulée."
		) WARNING
		

		return $Context

	}

    if ([string]::IsNullOrWhiteSpace($Context.WIM.FullName)) {

        Write-Log "Aucune image temporaire à supprimer." INFO

        return $Context

    }

    if (-not (Test-Path $Context.WIM.FullName)) {

        Write-Log "L'image temporaire n'existe plus." INFO

        return $Context

    }

    Write-Log "Suppression de l'image temporaire..."

   
		
	if ($Context.BuildState.Image.WimMounted) {

		Write-Log (
			"Le contexte indique que le WIM est encore monté."
		) WARNING

		return $Context

	}	

    try {

		Remove-Item `
			-Path $Context.WIM.FullName `
			-Force `
			-ErrorAction Stop

	}
    catch {

        Write-Log (
            "Impossible de supprimer l'image temporaire : " +
            $_.Exception.Message
        ) WARNING

        return $Context

    }
	
	# --------------------------------------------------
	# Validation
	# --------------------------------------------------

	if (Test-Path $Context.WIM.FullName) {

		Write-Log "L'image temporaire est toujours présente." WARNING

		return $Context

	}

    # --------------------------------------------------
    # Mise à jour du contexte
    # --------------------------------------------------

    $Context.WIM.FullName = $null

    $Context.WIM.Name = $null

    $Context.WIM.Type = $null

    $Context.WIM.SizeGB = 0

    $Context.WIM.Images = @()

    $Context.WIM.Mount.Path = $null

    $Context = Set-WimMountedState `
		-Context $Context `
		-Mounted $false

    $Context.WIM.Mount.ReadOnly = $false

    Write-Log "[WIM] Image temporaire supprimée." SUCCESS

    return $Context

}

