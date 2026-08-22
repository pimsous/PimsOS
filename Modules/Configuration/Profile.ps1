# ==========================================
# Module : Profile
# Projet : PimsOS Builder
# Version : 1.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# Cache interne
$script:TweakDefinitions = $null

# --------------------------------------------------
# Charge toutes les définitions de tweaks
# --------------------------------------------------

function Get-TweakDefinitions {

    [CmdletBinding()]
    param(

		[Parameter(Mandatory)]
		[psobject]$Context,

		[switch]$Reload

	)

    # --------------------------------------------------
    # Cache
    # --------------------------------------------------

    if ($script:TweakDefinitions -and -not $Reload) {

        Write-Log "Utilisation du cache des tweaks."

        return $script:TweakDefinitions

    }

    Write-Log "Chargement des définitions de tweaks..."

    # --------------------------------------------------
    # Localisation du dossier
    # --------------------------------------------------

    $ProjectRoot = $Context.Project.Root

    $TweaksPath = Join-Path `
        -Path $ProjectRoot `
        -ChildPath "Tweaks"

    if (-not (Test-Path $TweaksPath)) {

        throw "Le dossier '$TweaksPath' est introuvable."

    }

    # --------------------------------------------------
    # Recherche des fichiers JSON
    # --------------------------------------------------

    $Files = @(
		Get-ChildItem `
			-Path $TweaksPath `
			-Filter "*.json" `
			-File `
			-Recurse |
		Sort-Object FullName
	)

    if ($Files.Count -eq 0) {

        throw "Aucun tweak trouvé dans '$TweaksPath'."

    }

    # --------------------------------------------------
    # Collection
    # --------------------------------------------------

    $Definitions = [System.Collections.Generic.List[object]]::new()

    # --------------------------------------------------
    # Lecture des fichiers
    # --------------------------------------------------

    foreach ($File in $Files) {

        $RelativePath = $File.FullName.Substring($TweaksPath.Length + 1)

        Write-Log "Lecture de $RelativePath..."

        try {

			$Raw = Get-Content `
				-Path $File.FullName `
				-Raw `
				-Encoding UTF8 `
				-ErrorAction Stop

			if ([string]::IsNullOrWhiteSpace($Raw)) {

				Write-Log (
					"$RelativePath est vide, fichier ignoré."
				) WARNING

				continue
			}

			$Json = $Raw | ConvertFrom-Json

		}
		catch {

			throw (
				"Impossible de lire '$RelativePath'.`r`n$($_.Exception.Message)"
			)

		}

        # --------------------------------------------------
        # Validation minimale
        # --------------------------------------------------

        foreach ($Property in @(
			"Id",
			"Name",
			"Description",
			"CategoryId",
			"Actions"
		)) {

			if ($null -eq $Json -or $null -eq $Json.PSObject.Properties[$Property]) {

				throw (
					"{0} : propriété '{1}' absente." -f
					$RelativePath,
					$Property
				)

			}

		}

        if (
			$null -eq $Json.Actions -or
			@($Json.Actions).Count -eq 0
		) {

			throw (
				"{0} : aucune action définie." -f
				$RelativePath
			)

		}

        # --------------------------------------------------
        # Construction
        # --------------------------------------------------

        $Definition = New-Tweak `
            -Definition $Json `
            -CategoryId $Json.CategoryId `
            -SourceFile $RelativePath

        $Definitions.Add($Definition)

    }

    # --------------------------------------------------
    # Cache
    # --------------------------------------------------

    $script:TweakDefinitions = $Definitions
	
	if ($Context) {

		$Context.BuildState.Image.TweaksLoaded = $true

	}

    Write-Log (
        "{0} tweak(s) chargé(s)." -f
        $Definitions.Count
    ) SUCCESS

    return $script:TweakDefinitions

}

# --------------------------------------------------
# Retourne la liste des profils disponibles
# --------------------------------------------------

function Get-ProfileList {

    [CmdletBinding()]
    param(

		[Parameter(Mandatory)]
		[psobject]$Context

	)

    Write-Log "Recherche des profils..."

    # --------------------------------------------------
    # Localisation du dossier
    # --------------------------------------------------

    $ProjectRoot = $Context.Project.Root

    $ProfilesPath = Join-Path `
        -Path $ProjectRoot `
        -ChildPath "Profiles"

    if (-not (Test-Path $ProfilesPath)) {

        throw "Le dossier '$ProfilesPath' est introuvable."

    }

    # --------------------------------------------------
    # Recherche des profils
    # --------------------------------------------------

    $Profiles = @(Get-ChildItem `
		-Path $ProfilesPath `
		-Filter "*.json" `
		-File |
		Sort-Object Name)

    if ($Profiles.Count -eq 0) {

        Write-Log "Aucun profil trouvé." WARNING

        return @()

    }

    # --------------------------------------------------
    # Construction de la liste
    # --------------------------------------------------

    $Result = [System.Collections.Generic.List[object]]::new()

    foreach ($Profile in $Profiles) {

        $Result.Add(

            [PSCustomObject]@{

                Name = $Profile.BaseName

                FileName = $Profile.Name

                FullName = $Profile.FullName

            }

        )

    }

    Write-Log (
        "{0} profil(s) trouvé(s)." -f $Result.Count
    ) SUCCESS

    return $Result

}
# --------------------------------------------------
# Charge un profil
# --------------------------------------------------

function Load-Profile {

    [CmdletBinding()]
    param(

		[Parameter(Mandatory)]
		[psobject]$Context,

		[Parameter(Mandatory)]
		[string]$Name

	)

    Write-Log "Chargement du profil '$Name'..."

    # --------------------------------------------------
    # Localisation
    # --------------------------------------------------

    $ProjectRoot = $Context.Project.Root

    $ProfilesPath = Join-Path `
        -Path $ProjectRoot `
        -ChildPath "Profiles"

    if (-not (Test-Path $ProfilesPath)) {

        throw "Le dossier '$ProfilesPath' est introuvable."

    }

    # --------------------------------------------------
    # Profil
    # --------------------------------------------------

    $ProfilePath = Join-Path `
        -Path $ProfilesPath `
        -ChildPath "$Name.json"

    if (-not (Test-Path $ProfilePath)) {

        throw "Le profil '$Name' est introuvable."

    }

    # --------------------------------------------------
    # Lecture
    # --------------------------------------------------

    try {

        $Profile = Get-Content `
			-Path $ProfilePath `
			-Raw `
			-Encoding UTF8 `
			-ErrorAction Stop |
			ConvertFrom-Json

    }
    catch {

        throw "Impossible de charger le profil '$Name'.`n$($_.Exception.Message)"

    }


    Write-Log "Profil '$Name' chargé." SUCCESS
	
	if ($Context) {

		$Context.ConfigurationProfile = $Name

		$Context.BuildState.Image.ProfileLoaded = $true

	}

    return $Profile

}
# --------------------------------------------------
# Construit un élément de configuration
# --------------------------------------------------

function New-ConfigurationItem {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Tweak,

        [Parameter(Mandatory)]
        [bool]$Enabled

    )

    $ConfigurationItem = $Tweak.PSObject.Copy()
	
	# ------------------------------------------
	# Catégorie
	# ------------------------------------------

	$Category = Get-CategoryDefinition `
		-Id $Tweak.CategoryId

	$ConfigurationItem | Add-Member `
		-NotePropertyName Category `
		-NotePropertyValue $Category.Name `
		-Force

	$ConfigurationItem | Add-Member `
		-NotePropertyName CategoryDescription `
		-NotePropertyValue (
			Get-ObjectProperty `
				-Object $Category `
				-Name Description
		) `
		-Force

	$ConfigurationItem | Add-Member `
		-NotePropertyName CategoryColor `
		-NotePropertyValue (
			Get-ObjectProperty `
				-Object $Category `
				-Name Color
		) `
		-Force

	$ConfigurationItem | Add-Member `
		-NotePropertyName CategoryIcon `
		-NotePropertyValue (
			Get-ObjectProperty `
				-Object $Category `
				-Name Icon
		) `
		-Force

	$ConfigurationItem | Add-Member `
		-NotePropertyName CategoryOrder `
		-NotePropertyValue (
			Get-ObjectProperty `
				-Object $Category `
				-Name Order `
				-Default 0
		) `
		-Force

	$ConfigurationItem | Add-Member `
		-NotePropertyName CategoryVisible `
		-NotePropertyValue (
			Get-ObjectProperty `
				-Object $Category `
				-Name Visible `
				-Default $true
		) `
		-Force

	$ConfigurationItem | Add-Member `
		-NotePropertyName CategoryGroups `
		-NotePropertyValue (
			Get-ObjectProperty `
				-Object $Category `
				-Name Groups `
				-Default @()
		) `
		-Force

	# Etat d'activation du profil

	$ConfigurationItem.Enabled = $Enabled
	
	return $ConfigurationItem

}
# --------------------------------------------------
# Fusionne un profil avec les définitions de tweaks
# --------------------------------------------------

function Merge-Profile {

    [CmdletBinding()]
    param(

		[Parameter(Mandatory)]
		[psobject]$Context,

		[Parameter(Mandatory)]
		[object[]]$Tweaks,

		[Parameter(Mandatory)]
		[psobject]$Profile

	)

    Write-Log "Fusion du profil avec les tweaks..."

    $Configuration = [System.Collections.Generic.List[object]]::new()

    foreach ($Tweak in $Tweaks) {

        # ------------------------------------------
        # Valeur par défaut
        # ------------------------------------------

        $Enabled = $Tweak.Default

        # ------------------------------------------
        # Valeur du profil
        # ------------------------------------------

        if ($Profile.PSObject.Properties["Tweaks"] -and
            $Profile.Tweaks.PSObject.Properties[$Tweak.Id]) {

            $Enabled = $Profile.Tweaks.$($Tweak.Id)

        }

        # ------------------------------------------
        # Construction
        # ------------------------------------------

        $Configuration.Add(

            (New-ConfigurationItem `
                -Tweak $Tweak `
                -Enabled $Enabled)

        )

    }

    Write-Log (
        "{0} tweak(s) fusionné(s)." -f $Configuration.Count
    ) SUCCESS

    $Context.BuildState.Image.ProfileMerged = $true

	$Context.Configuration = $Configuration

	return $Configuration

}
