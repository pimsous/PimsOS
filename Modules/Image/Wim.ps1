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

# --------------------------------------------------
# Vérifie qu'un fichier WIM est chargé
# --------------------------------------------------

function Test-WimLoaded {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context

    )

    # --------------------------------------------------
    # Vérification du contexte général
    # --------------------------------------------------

    Test-WimContext `
        -Context $Context

    # --------------------------------------------------
    # Vérification de la propriété FullName
    # --------------------------------------------------

    if (
        $null -eq $Context.WIM.PSObject.Properties["FullName"]
    ) {

        throw `
            "La propriété WIM.FullName est absente du BuildContext."

    }

    # --------------------------------------------------
    # Vérification du chemin
    # --------------------------------------------------

    if (
        [string]::IsNullOrWhiteSpace(
            [string]$Context.WIM.FullName
        )
    ) {

        throw `
            "Aucun fichier WIM n'est chargé dans le BuildContext."

    }

    # --------------------------------------------------
    # Vérification physique du fichier
    # --------------------------------------------------

    if (
        -not (Test-Path `
            -LiteralPath $Context.WIM.FullName `
            -PathType Leaf)
    ) {

        throw (
            "Le fichier WIM est introuvable : {0}" -f
            $Context.WIM.FullName
        )

    }

    # --------------------------------------------------
    # Validation
    # --------------------------------------------------

    Write-Log (
        "WIM chargé : {0}" -f
        $Context.WIM.FullName
    ) INFO

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
# Analyse l'état réel d'un montage WIM
# --------------------------------------------------

function Get-WimMountState {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context

    )

    Test-WimContext `
        -Context $Context

    # --------------------------------------------------
    # Initialisation
    # --------------------------------------------------

    $State = New-WimMountState

    # --------------------------------------------------
    # Vérification de DISM
    # --------------------------------------------------

    try {

        $MountedImages = @(
            Get-WindowsImage -Mounted `
                -ErrorAction Stop
        )

    }
    catch {

        $State.Exists = $false
        $State.Valid = $false
        $State.CanReuse = $false
        $State.NeedsCleanup = $false

        $State.Message =
            "Impossible d'interroger les images WIM montées : " +
            $_.Exception.Message

        return $State
    }

    # --------------------------------------------------
    # Aucun montage
    # --------------------------------------------------

    if ($MountedImages.Count -eq 0) {

        $State.Exists = $false
        $State.Valid = $false
        $State.CanReuse = $false
        $State.NeedsCleanup = $false

        $State.MountStatus = $null
        $State.Message =
            "Aucun montage WIM détecté."

        return $State
    }

    # --------------------------------------------------
    # Recherche du montage correspondant au Workspace
    # --------------------------------------------------

    $ExpectedMountPath = $null

    if (
        $null -ne $Context.Workspace -and
        $Context.Workspace.PSObject.Properties.Name -contains "MountWIM"
    ) {

        $ExpectedMountPath =
            [string]$Context.Workspace.MountWIM

    }

    $Mounted = $null

    if (-not [string]::IsNullOrWhiteSpace($ExpectedMountPath)) {

        $Mounted = $MountedImages |
            Where-Object {

                $_.Path -eq $ExpectedMountPath

            } |
            Select-Object -First 1

    }

    # --------------------------------------------------
    # Aucun montage sur notre chemin
    # --------------------------------------------------

    if ($null -eq $Mounted) {

        $State.Exists = $true
        $State.Valid = $false
        $State.CanReuse = $false
        $State.NeedsCleanup = $false

        $State.MountStatus = "Other"

        $State.Message =
            "Un montage WIM existe, mais aucun montage ne correspond au Workspace PimsOS."

        return $State
    }

    # --------------------------------------------------
    # Informations du montage
    # --------------------------------------------------

    $State.Exists = $true

    $State.MountPath =
        [string]$Mounted.Path

    $State.ImagePath =
        [string]$Mounted.ImagePath

    $State.ImageIndex =
        $Mounted.ImageIndex

    $State.MountStatus =
        [string]$Mounted.MountStatus

    # --------------------------------------------------
    # Vérification du dossier Windows
    # --------------------------------------------------

    $WindowsFolder = Join-Path `
        -Path $State.MountPath `
        -ChildPath "Windows"

    $State.WindowsFolderExists =
        Test-Path $WindowsFolder

    # --------------------------------------------------
    # Vérification de l'image attendue
    # --------------------------------------------------

    $State.ImageMatches = $true

    if (
        $Context.WIM.PSObject.Properties.Name -contains "FullName" -and
        -not [string]::IsNullOrWhiteSpace(
            [string]$Context.WIM.FullName
        )
    ) {

        $ExpectedImagePath =
            [System.IO.Path]::GetFullPath(
                [string]$Context.WIM.FullName
            )

        try {

            $ActualImagePath =
                [System.IO.Path]::GetFullPath(
                    [string]$State.ImagePath
                )

            $State.ImageMatches =
                $ExpectedImagePath -eq $ActualImagePath

        }
        catch {

            $State.ImageMatches = $false

        }

    }

    # --------------------------------------------------
    # Vérification du Workspace
    # --------------------------------------------------

    $State.WorkspaceReady = $true

    if (
        $null -ne $Context.Workspace -and
        $Context.Workspace.PSObject.Properties.Name -contains "Sources"
    ) {

        $State.WorkspaceReady =
            Test-Path $Context.Workspace.Sources

    }

    # --------------------------------------------------
    # Vérification du registre
    # --------------------------------------------------

    $State.RegistryMounted =
        Test-Path "Registry::HKLM\PimsOS_SOFTWARE"

    # --------------------------------------------------
    # Evaluation de l'état
    # --------------------------------------------------

    $MountIsOk =
        $State.MountStatus -eq "Ok"

    $State.Valid =
        $MountIsOk -and
        $State.WindowsFolderExists -and
        $State.ImageMatches

    # --------------------------------------------------
    # Montage réutilisable
    # --------------------------------------------------

    if ($State.Valid) {

        $State.CanReuse = $true
        $State.NeedsCleanup = $false

        $State.Message =
            "Montage WIM valide et réutilisable."

        return $State
    }

    # --------------------------------------------------
    # Montage invalide
    # --------------------------------------------------

    $State.CanReuse = $false
    $State.NeedsCleanup = $true

    $State.Message =
        "Montage WIM invalide ou incohérent avec le Workspace."

    return $State
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

    # --------------------------------------------------
    # Vérification du contexte
    # --------------------------------------------------

    if ($null -eq $Context) {

        throw "Le contexte est null."

    }

    # --------------------------------------------------
    # Vérification du BuildState
    # --------------------------------------------------

    if ($null -eq $Context.BuildState) {

        throw "Le BuildState est absent du BuildContext."

    }

    if (
        $Context.BuildState.PSObject.Properties.Name -notcontains "Image"
    ) {

        throw "La section Image est absente du BuildState."

    }

    if ($null -eq $Context.BuildState.Image) {

        throw "La section Image du BuildState est null."

    }

    # --------------------------------------------------
    # Etat principal du montage WIM
    # --------------------------------------------------

    if (
        $Context.BuildState.Image.PSObject.Properties.Name -contains "WimMounted"
    ) {

        $Context.BuildState.Image.WimMounted = $Mounted

    }
    else {

        $Context.BuildState.Image |
            Add-Member `
                -MemberType NoteProperty `
                -Name "WimMounted" `
                -Value $Mounted

    }

    if (
        $Context.BuildState.Image.PSObject.Properties.Name -contains "Mounted"
    ) {

        $Context.BuildState.Image.Mounted = $Mounted

    }
    else {

        $Context.BuildState.Image |
            Add-Member `
                -MemberType NoteProperty `
                -Name "Mounted" `
                -Value $Mounted

    }

    # --------------------------------------------------
    # Informations de montage
    # --------------------------------------------------

    if ($Mounted) {

        # ----------------------------------------------
        # MountPath
        # ----------------------------------------------

        $MountPath = $null

        if (
            $Context.PSObject.Properties.Name -contains "WIM" -and
            $null -ne $Context.WIM -and
            $Context.WIM.PSObject.Properties.Name -contains "Mount" -and
            $null -ne $Context.WIM.Mount
        ) {

            if (
                $Context.WIM.Mount.PSObject.Properties.Name -contains "Path"
            ) {

                $MountPath = $Context.WIM.Mount.Path

            }

        }

        if (
            $Context.BuildState.Image.PSObject.Properties.Name -contains "MountPath"
        ) {

            $Context.BuildState.Image.MountPath = $MountPath

        }
        else {

            $Context.BuildState.Image |
                Add-Member `
                    -MemberType NoteProperty `
                    -Name "MountPath" `
                    -Value $MountPath

        }

        # ----------------------------------------------
        # Index
        # ----------------------------------------------

        $ImageIndex = $null

        if (
            $Context.PSObject.Properties.Name -contains "Image" -and
            $null -ne $Context.Image
        ) {

            if (
                $Context.Image.PSObject.Properties.Name -contains "Index"
            ) {

                $ImageIndex = $Context.Image.Index

            }

        }

        if (
            $Context.BuildState.Image.PSObject.Properties.Name -contains "Index"
        ) {

            $Context.BuildState.Image.Index = $ImageIndex

        }
        else {

            $Context.BuildState.Image |
                Add-Member `
                    -MemberType NoteProperty `
                    -Name "Index" `
                    -Value $ImageIndex

        }

    }
    else {

        # --------------------------------------------------
        # Nettoyage des informations de montage
        # --------------------------------------------------

        if (
            $Context.BuildState.Image.PSObject.Properties.Name -contains "MountPath"
        ) {

            $Context.BuildState.Image.MountPath = $null

        }

        if (
            $Context.BuildState.Image.PSObject.Properties.Name -contains "Index"
        ) {

            $Context.BuildState.Image.Index = $null

        }

        # --------------------------------------------------
        # Nettoyage de l'état Registre
        # --------------------------------------------------

        if (
            $Context.BuildState.Image.PSObject.Properties.Name -contains "RegistryLoaded"
        ) {

            $Context.BuildState.Image.RegistryLoaded = $false

        }

        if (
            $Context.BuildState.Image.PSObject.Properties.Name -contains "CurrentRegistryHive"
        ) {

            $Context.BuildState.Image.CurrentRegistryHive = $null

        }

        # --------------------------------------------------
        # Nettoyage de l'état Configuration
        # --------------------------------------------------

        if (
            $Context.BuildState.Image.PSObject.Properties.Name -contains "ConfigLoaded"
        ) {

            $Context.BuildState.Image.ConfigLoaded = $false

        }

        # --------------------------------------------------
        # Nettoyage de l'état Tweaks
        # --------------------------------------------------

        if (
            $Context.BuildState.Image.PSObject.Properties.Name -contains "TweaksLoaded"
        ) {

            $Context.BuildState.Image.TweaksLoaded = $false

        }

        if (
            $Context.BuildState.Image.PSObject.Properties.Name -contains "TweaksApplied"
        ) {

            $Context.BuildState.Image.TweaksApplied = $false

        }

        # --------------------------------------------------
        # Nettoyage de l'état Profile
        # --------------------------------------------------

        if (
            $Context.BuildState.Image.PSObject.Properties.Name -contains "ProfileLoaded"
        ) {

            $Context.BuildState.Image.ProfileLoaded = $false

        }

        if (
            $Context.BuildState.Image.PSObject.Properties.Name -contains "ProfileMerged"
        ) {

            $Context.BuildState.Image.ProfileMerged = $false

        }

    }

    # --------------------------------------------------
    # Retourne le contexte
    # --------------------------------------------------

    return $Context
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

    Test-WimContext `
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

    $Config = Get-Config

	if (
		$null -eq $Config.Workspace -or
		[string]::IsNullOrWhiteSpace(
			[string]$Config.Workspace.ISOSource
		)
	) {

		throw "Le chemin Workspace.ISOSource est absent de Config.json."

	}

	$IsoSourceRoot =
		Join-Path `
			-Path (Get-ProjectRoot) `
			-ChildPath $Config.Workspace.ISOSource

	$Sources =
		Join-Path `
			-Path $IsoSourceRoot `
			-ChildPath "sources"

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

    # --------------------------------------------------
    # Vérification du contexte
    # --------------------------------------------------

    Test-WimContext `
        -Context $Context

    # --------------------------------------------------
    # Vérification du fichier WIM source
    # --------------------------------------------------

    if (
        $null -eq $Context.WIM.FullName -or
        [string]::IsNullOrWhiteSpace(
            [string]$Context.WIM.FullName
        )
    ) {

        throw `
            "Le chemin du fichier WIM source est absent du BuildContext."

    }

    if (-not (Test-Path $Context.WIM.FullName)) {

        throw (
            "Le fichier WIM source est introuvable : {0}" -f
            $Context.WIM.FullName
        )

    }

    # --------------------------------------------------
    # Vérification du Workspace
    # --------------------------------------------------

    if (
        $null -eq $Context.Workspace -or
        -not $Context.Workspace.PSObject.Properties["Sources"]
    ) {

        throw `
            "Le chemin Workspace.Sources est absent du BuildContext."

    }

    if (
        [string]::IsNullOrWhiteSpace(
            [string]$Context.Workspace.Sources
        )
    ) {

        throw `
            "Le chemin Workspace.Sources est vide."

    }

    # --------------------------------------------------
    # Préparation du dossier Sources
    # --------------------------------------------------

    if (-not (Test-Path $Context.Workspace.Sources)) {

        Write-Log `
            "Création du dossier Sources du Workspace..." `
            INFO

        New-Item `
            -ItemType Directory `
            -Path $Context.Workspace.Sources `
            -Force `
            -ErrorAction Stop |
            Out-Null

    }

    # --------------------------------------------------
    # Détermination de la destination
    # --------------------------------------------------

    $SourceFile = Get-Item `
        -Path $Context.WIM.FullName `
        -ErrorAction Stop

    $Destination = Join-Path `
        -Path $Context.Workspace.Sources `
        -ChildPath $SourceFile.Name

    # --------------------------------------------------
    # Copie / réutilisation
    # --------------------------------------------------

    if (Test-Path $Destination) {

        $ExistingFile = Get-Item `
            -Path $Destination `
            -ErrorAction Stop

        Write-Log (
            "Une image existe déjà dans le Workspace : {0}" -f
            $Destination
        ) WARNING

        # --------------------------------------------------
        # Même taille : réutilisation
        # --------------------------------------------------

        if ($ExistingFile.Length -eq $SourceFile.Length) {

            Write-Log `
                "L'image existante possède la même taille. Réutilisation du fichier." `
                INFO

        }
        else {

            Write-Log `
                "L'image existante possède une taille différente. Remplacement..." `
                WARNING

            Copy-Item `
                -Path $SourceFile.FullName `
                -Destination $Destination `
                -Force `
                -ErrorAction Stop

        }

    }
    else {

        Write-Log `
            "Copie de l'image Windows..." `
            INFO

        Copy-Item `
            -Path $SourceFile.FullName `
            -Destination $Destination `
            -Force `
            -ErrorAction Stop

    }

    # --------------------------------------------------
    # Vérification de la destination
    # --------------------------------------------------

    if (-not (Test-Path $Destination)) {

        throw `
            "La copie de l'image Windows a échoué."

    }

    $File = Get-Item `
        -Path $Destination `
        -ErrorAction Stop

    # --------------------------------------------------
    # Suppression de l'attribut ReadOnly
    # --------------------------------------------------

    if (
        ($File.Attributes -band [System.IO.FileAttributes]::ReadOnly) -ne 0
    ) {

        $File.Attributes =
            $File.Attributes -band (
                -bnot [System.IO.FileAttributes]::ReadOnly
            )

        $File.Refresh()

    }

    # --------------------------------------------------
    # Mise à jour du contexte WIM
    # --------------------------------------------------

    $Context.WIM.FullName = $File.FullName

    $Context.WIM.Name = $File.Name

    $Context.WIM.SizeGB =
        [Math]::Round(
            $File.Length / 1GB,
            2
        )

    # --------------------------------------------------
    # Type de l'image
    # --------------------------------------------------

    $Extension = $File.Extension.ToLowerInvariant()

    if ($Extension -eq ".wim") {

        $Context.WIM.Type = "WIM"

    }
    elseif ($Extension -eq ".esd") {

        $Context.WIM.Type = "ESD"

    }
    else {

        $Context.WIM.Type = $Extension.TrimStart(".")

    }

    # --------------------------------------------------
    # Résultat
    # --------------------------------------------------

    Write-Log `
        "Image copiée dans le Workspace." `
        SUCCESS

    Write-Log (
        "WIM utilisé pour le montage : {0}" -f
        $Context.WIM.FullName
    ) SUCCESS

    Write-Log (
        "Taille : {0} Go" -f
        $Context.WIM.SizeGB
    ) INFO

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

    Test-WimContext `
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

    Test-WimContext `
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

    # --------------------------------------------------
    # Validation du contexte
    # --------------------------------------------------

    Test-WimImageSelected `
        -Context $Context

    Write-Log `
        "Initialisation du montage de l'image Windows..." `
        INFO

    # --------------------------------------------------
    # Préparation du dossier de montage
    # --------------------------------------------------

    $MountPath = $Context.Workspace.MountWIM

    $Context.WIM.Mount.Path = $MountPath

    # --------------------------------------------------
    # Déjà montée dans le contexte ?
    # --------------------------------------------------

    if (
        $null -ne $Context.BuildState.Image -and
        $Context.BuildState.Image.PSObject.Properties.Name -contains "WimMounted" -and
        [bool]$Context.BuildState.Image.WimMounted
    ) {

        Write-Log `
            "Une image WIM est déjà indiquée comme montée dans le contexte." `
            WARNING

        return $Context

    }

    # --------------------------------------------------
    # Analyse de l'état réel du montage WIM
    # --------------------------------------------------

    Write-Log `
        "Vérification d'un éventuel montage WIM existant..." `
        INFO

    $State = Get-WimMountState `
        -Context $Context

    # --------------------------------------------------
    # Réutilisation d'un montage valide
    # --------------------------------------------------

    if (
        $null -ne $State -and
        $State.CanReuse
    ) {

        Write-Log `
            "Réutilisation du montage WIM existant." `
            SUCCESS

        # --------------------------------------------------
        # Vérification du chemin de montage récupéré
        # --------------------------------------------------

        if (
            [string]::IsNullOrWhiteSpace(
                [string]$State.MountPath
            )
        ) {

            throw `
                "Le montage WIM est indiqué comme réutilisable, mais son chemin est absent."

        }

        $Context.WIM.Mount.Path = $State.MountPath

        # --------------------------------------------------
        # Mise à jour de l'état
        # --------------------------------------------------

        $Context = Set-WimMountedState `
            -Context $Context `
            -Mounted $true

        $Context.WIM.Mount.ReadOnly = $ReadOnly.IsPresent

        Write-Log `
            "Montage WIM existant réutilisé avec succès." `
            SUCCESS

        return $Context

    }

    # --------------------------------------------------
    # Montage existant mais nécessitant un nettoyage
    # --------------------------------------------------

    if (
        $null -ne $State -and
        $State.NeedsCleanup
    ) {

        Write-Log (
            "Un montage WIM existant nécessite un nettoyage : {0}" -f
            $State.Message
        ) WARNING

        if (
            -not [string]::IsNullOrWhiteSpace(
                [string]$State.MountPath
            )
        ) {

            Write-Log `
                "Nettoyage du montage WIM existant..." `
                INFO

            try {

                Dismount-DismImage `
                    -MountPath $State.MountPath `
                    -Discard `
                    -ErrorAction Stop

                Write-Log `
                    "Montage WIM existant nettoyé." `
                    SUCCESS

            }
            catch {

                throw (
                    "Impossible de nettoyer le montage WIM existant.`n" +
                    $_.Exception.Message
                )

            }

        }

    }
    else {

        Write-Log `
            "Aucun montage WIM réutilisable détecté." `
            INFO

    }

    # --------------------------------------------------
    # Préparation du dossier de montage
    # --------------------------------------------------

    if (Test-Path $MountPath) {

        Write-Log (
            "Nettoyage du dossier de montage : {0}" -f
            $MountPath
        ) INFO

        Remove-Item `
            -Path $MountPath `
            -Recurse `
            -Force `
            -ErrorAction Stop

    }

    New-Item `
        -ItemType Directory `
        -Path $MountPath `
        -Force `
        -ErrorAction Stop |
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

    Write-Log `
        "Montage DISM..." `
        INFO

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
    # Validation du montage
    # --------------------------------------------------

    if (-not (Test-Path $MountPath)) {

        throw `
            "Le dossier de montage est introuvable après le montage DISM."

    }

    $WindowsFolder = Join-Path `
        -Path $MountPath `
        -ChildPath "Windows"

    if (-not (Test-Path $WindowsFolder)) {

        throw `
            "Le montage semble avoir échoué : dossier Windows introuvable."

    }

    # --------------------------------------------------
    # Mise à jour du contexte
    # --------------------------------------------------

    $Context.WIM.Mount.Path = $MountPath

    $Context = Set-WimMountedState `
        -Context $Context `
        -Mounted $true

    $Context.WIM.Mount.ReadOnly = $ReadOnly.IsPresent

    # --------------------------------------------------
	# Mise à jour de l'état de récupération
	# --------------------------------------------------

	if (
		$null -ne $Context.BuildState -and
		$Context.BuildState.PSObject.Properties.Name -contains "Recovery"
	) {

		# --------------------------------------------------
		# Création de la section Recovery si nécessaire
		# --------------------------------------------------

		if ($null -eq $Context.BuildState.Recovery) {

			$Context.BuildState.Recovery = [PSCustomObject]@{}

		}

		# --------------------------------------------------
		# Création de l'état Recovery.Wim si nécessaire
		# --------------------------------------------------

		if (
			$Context.BuildState.Recovery.PSObject.Properties.Name -contains "Wim" -and
			$null -ne $Context.BuildState.Recovery.Wim
		) {

			$RecoveryState =
				$Context.BuildState.Recovery.Wim

		}
		else {

			$RecoveryState =
				New-WimMountState

			$Context.BuildState.Recovery.Wim =
				$RecoveryState

		}

		# --------------------------------------------------
		# Mise à jour de l'état
		# --------------------------------------------------

		$RecoveryState.Exists = $true
		$RecoveryState.Valid = $true
		$RecoveryState.CanReuse = $true
		$RecoveryState.NeedsCleanup = $false

		$RecoveryState.MountStatus = "Ok"

		$RecoveryState.MountPath =
			$Context.WIM.Mount.Path

		$RecoveryState.ImagePath =
			$Context.WIM.FullName

		$RecoveryState.ImageIndex =
			$Context.Image.Index

		$RecoveryState.WindowsFolderExists =
			Test-Path (
				Join-Path `
					-Path $Context.WIM.Mount.Path `
					-ChildPath "Windows"
			)

		$RecoveryState.ImageMatches = $true

		$RecoveryState.WorkspaceReady =
			Test-Path $Context.Workspace.Sources

		$RecoveryState.RegistryMounted =
			Test-Path "Registry::HKLM\PimsOS_SOFTWARE"

		$RecoveryState.Message =
			"Montage WIM valide."

	}

    # --------------------------------------------------
    # Résultat
    # --------------------------------------------------

    Write-Log `
        "Image Windows montée avec succès." `
        SUCCESS

    Write-Log (
        "Montage WIM : {0}" -f
        $Context.WIM.Mount.Path
    ) SUCCESS

    Write-Log (
        "Index : {0}" -f
        $Context.Image.Index
    ) INFO

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

    # --------------------------------------------------
    # Vérification de l'état réel du montage
    # --------------------------------------------------

    $MountPath = $null

    if (
        $null -ne $Context.WIM -and
        $null -ne $Context.WIM.Mount -and
        $Context.WIM.Mount.PSObject.Properties.Name -contains "Path"
    ) {

        $MountPath = [string]$Context.WIM.Mount.Path

    }

    # --------------------------------------------------
    # Recherche du montage réel dans DISM
    # --------------------------------------------------

    $MountedImages = @(
        Get-WindowsImage -Mounted -ErrorAction SilentlyContinue
    )

    $Mounted = $null

    if (-not [string]::IsNullOrWhiteSpace($MountPath)) {

        $Mounted = $MountedImages |
            Where-Object {
                $_.Path -eq $MountPath
            } |
            Select-Object -First 1

    }

    # --------------------------------------------------
    # Aucun montage réel détecté
    # --------------------------------------------------

    if ($null -eq $Mounted) {

        Write-Log `
            "Aucune image Windows montée." `
            INFO

        $Context = Set-WimMountedState `
            -Context $Context `
            -Mounted $false

        return $Context
    }

    # --------------------------------------------------
    # Montage réel détecté
    # --------------------------------------------------

    Write-Log (
        "Montage WIM détecté par DISM : {0}" -f
        $Mounted.Path
    ) INFO

    Write-Log (
        "Image : {0}" -f
        $Mounted.ImagePath
    ) INFO

    Write-Log (
        "Index : {0}" -f
        $Mounted.ImageIndex
    ) INFO

    # --------------------------------------------------
    # Utilisation du chemin réellement retourné par DISM
    # --------------------------------------------------

    $MountPath = [string]$Mounted.Path

    if ([string]::IsNullOrWhiteSpace($MountPath)) {

        throw `
            "DISM indique qu'une image est montée, mais le chemin de montage est absent."

    }

    Write-Log `
        "Démontage de l'image Windows..." `
        INFO

    # --------------------------------------------------
    # Démontage DISM
    # --------------------------------------------------

    try {

        $null = Dismount-DismImage `
            -MountPath $MountPath `
            -Discard:$Discard `
            -ErrorAction Stop

    }
    catch {

        throw (
            "Impossible de démonter l'image Windows.`n" +
            $_.Exception.Message
        )

    }

    # --------------------------------------------------
    # Validation DISM
    # --------------------------------------------------

    $StillMounted = @(
        Get-WindowsImage -Mounted `
            -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Path -eq $MountPath
        }
    )

    if ($StillMounted.Count -gt 0) {

        $Remaining = $StillMounted[0]

        throw (
            "Le WIM est toujours enregistré par DISM.`n" +
            "État       : $($Remaining.MountStatus)`n" +
            "Montage    : $($Remaining.Path)`n" +
            "Image      : $($Remaining.ImagePath)"
        )

    }

    # --------------------------------------------------
    # Mise à jour du contexte
    # --------------------------------------------------

    $Context.WIM.Mount.Path = $null
    $Context.WIM.Mount.ReadOnly = $false

    $Context = Set-WimMountedState `
        -Context $Context `
        -Mounted $false

    # --------------------------------------------------
    # Invalidation de l'état Recovery.Wim
    # --------------------------------------------------

    if (
        $null -ne $Context.BuildState -and
        $Context.BuildState.PSObject.Properties.Name -contains "Recovery" -and
        $null -ne $Context.BuildState.Recovery -and
        $Context.BuildState.Recovery.PSObject.Properties.Name -contains "Wim" -and
        $null -ne $Context.BuildState.Recovery.Wim
    ) {

        $RecoveryState =
            $Context.BuildState.Recovery.Wim

        $RecoveryState.Exists = $false
        $RecoveryState.Valid = $false
        $RecoveryState.CanReuse = $false
        $RecoveryState.NeedsCleanup = $false

        $RecoveryState.MountStatus = $null
        $RecoveryState.MountPath = $null
        $RecoveryState.ImagePath = $null
        $RecoveryState.ImageIndex = $null

        $RecoveryState.WindowsFolderExists = $false
        $RecoveryState.ImageMatches = $false
        $RecoveryState.WorkspaceReady = $false
        $RecoveryState.RegistryMounted = $false

        $RecoveryState.Message =
            "Aucun montage WIM actif."

    }

    Write-Log `
		"Montage WIM PimsOS nettoyé avec succès." `
		SUCCESS

    return $Context
}
