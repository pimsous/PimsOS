# ==========================================
# Module : Profile
# Projet : PimsOS Builder
# Version : 1.0.1
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

        return @(
            $script:TweakDefinitions.ToArray()
        )

    }

    Write-Log "Chargement des définitions de tweaks..."

    # --------------------------------------------------
    # Localisation du dossier
    # --------------------------------------------------

    # Le contexte est la source de vérité pour la racine du projet.
    # Cela permet notamment de tester ou d'exécuter le module avec
    # un BuildContext pointant vers une autre racine que le processus courant.
    if (
        $null -eq $Context.Project -or
        [string]::IsNullOrWhiteSpace([string]$Context.Project.Root)
    ) {

        throw "La racine du projet est absente du contexte."

    }

    $ProjectRoot = [string]$Context.Project.Root

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

    return @(
        $script:TweakDefinitions.ToArray()
    )

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
    # Localisation
    # --------------------------------------------------

    if (
        $null -eq $Context.Project -or
        [string]::IsNullOrWhiteSpace([string]$Context.Project.Root)
    ) {
        throw "La racine du projet est absente du contexte."
    }

    $ProjectRoot = [string]$Context.Project.Root

    $ProfilesPath = Join-Path `
        -Path $ProjectRoot `
        -ChildPath "Profiles"

    if (-not (Test-Path -LiteralPath $ProfilesPath -PathType Container)) {
        throw "Le dossier '$ProfilesPath' est introuvable."
    }

    # --------------------------------------------------
    # Recherche récursive des profils JSON
    # --------------------------------------------------

    $Profiles = @(
        Get-ChildItem `
            -LiteralPath $ProfilesPath `
            -Filter "*.json" `
            -File `
            -Recurse |
            Sort-Object FullName
    )

    if ($Profiles.Count -eq 0) {

        Write-Log "Aucun profil trouvé." WARNING
        return @()

    }

    # --------------------------------------------------
    # Construction de la liste
    # --------------------------------------------------

    $Result = [System.Collections.Generic.List[object]]::new()

    foreach ($Profile in $Profiles) {

        $ProfileLength = 1

        if ($Profile.PSObject.Properties["Length"]) {
            $ProfileLength = [int64]$Profile.Length
        }

        if ($ProfileLength -eq 0) {
            Write-Log (
                "Profil vide ignoré : {0}" -f
                $Profile.FullName
            ) WARNING
            continue
        }

        $RelativePath = $Profile.FullName.Substring(
            $ProfilesPath.Length
        ).TrimStart('\')

        $Extension = [System.IO.Path]::GetExtension($RelativePath)

        $Name = $RelativePath.Substring(
            0,
            $RelativePath.Length - $Extension.Length
        )

        $Result.Add(
            [PSCustomObject]@{
                Name     = $Name
                FileName = $Profile.Name
                FullName = $Profile.FullName
            }
        )

    }

    Write-Log (
        "{0} profil(s) trouvé(s)." -f $Result.Count
    ) SUCCESS

    return @(
        $Result.ToArray()
    )

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

    if (
        $null -eq $Context.Project -or
        [string]::IsNullOrWhiteSpace([string]$Context.Project.Root)
    ) {
        throw "La racine du projet est absente du contexte."
    }

    $ProjectRoot = [string]$Context.Project.Root

    $ProfilesPath = Join-Path `
        -Path $ProjectRoot `
        -ChildPath "Profiles"

    if (-not (Test-Path $ProfilesPath)) {

        throw "Le dossier '$ProfilesPath' est introuvable."

    }

    # --------------------------------------------------
    # Profil
    # --------------------------------------------------

    # Normalise le nom : accepte un chemin relatif (ex. Tests\Registry)
    # et accepte ou non l'extension .json.
    $RelativeName = $Name.Trim().TrimStart('\','/')

    if ([string]::IsNullOrWhiteSpace($RelativeName)) {
        throw "Le nom du profil est vide."
    }

    if ($RelativeName.EndsWith('.json', [System.StringComparison]::OrdinalIgnoreCase)) {
        $RelativeName = $RelativeName.Substring(0, $RelativeName.Length - 5)
    }

    $ProfilePath = Join-Path `
        -Path $ProfilesPath `
        -ChildPath "$RelativeName.json"

    if (-not (Test-Path -LiteralPath $ProfilePath -PathType Leaf)) {
        throw "Le profil '$Name' est introuvable."
    }

    $ProfileFile = Get-Item -LiteralPath $ProfilePath -ErrorAction Stop

    if ($ProfileFile.Length -eq 0) {
        throw "Le profil '$Name' est vide : '$ProfilePath'."
    }

    # --------------------------------------------------
    # Lecture
    # --------------------------------------------------

    try {

        $Raw = Get-Content `
            -LiteralPath $ProfilePath `
            -Raw `
            -Encoding UTF8 `
            -ErrorAction Stop

        if ([string]::IsNullOrWhiteSpace($Raw)) {
            throw "Le fichier est vide."
        }

        $Profile = $Raw | ConvertFrom-Json -ErrorAction Stop

    }
    catch {
        throw "Impossible de charger le profil '$Name'.`n$($_.Exception.Message)"
    }

    if ($null -eq $Profile) {
        throw "Le profil '$Name' ne contient aucune donnée exploitable."
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
                -NotePropertyValue (
                        Get-ObjectProperty `
                                -Object $Category `
                                -Name Name `
                                -Default $Tweak.CategoryId
                ) `
                -Force

        $ConfigurationItem | Add-Member `
                -NotePropertyName CategoryDescription `
                -NotePropertyValue (
                        Get-ObjectProperty `
                                -Object $Category `
                                -Name Description `
                                -Default $null
                ) `
                -Force

        $ConfigurationItem | Add-Member `
                -NotePropertyName CategoryColor `
                -NotePropertyValue (
                        Get-ObjectProperty `
                                -Object $Category `
                                -Name Color `
                                -Default $null
                ) `
                -Force

        $ConfigurationItem | Add-Member `
                -NotePropertyName CategoryIcon `
                -NotePropertyValue (
                        Get-ObjectProperty `
                                -Object $Category `
                                -Name Icon `
                                -Default $null
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

    # --------------------------------------------------
    # Résolution du preset
    # --------------------------------------------------

    $Preset = Resolve-ProfilePreset `
        -Profile $Profile `
        -Tweaks $Tweaks

    $SelectedMap = @{}

    foreach ($Id in $Preset.SelectedIds) {

        $SelectedMap[[string]$Id] = $true

    }

    $DisabledMap = @{}

    foreach ($Id in $Preset.DisabledIds) {

        $DisabledMap[[string]$Id] = $true

    }

    foreach ($Tweak in $Tweaks) {

        # ------------------------------------------
        # Valeur par défaut
        # ------------------------------------------

        $Enabled = [bool]$Tweak.Default

        # ------------------------------------------
        # Valeur explicite du profil
        # ------------------------------------------

        if ($SelectedMap.ContainsKey([string]$Tweak.Id)) {

            $Enabled = $true

        }
        elseif ($DisabledMap.ContainsKey([string]$Tweak.Id)) {

            $Enabled = $false

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

    # Le BuildContext expose toujours une configuration de tweaks plate.
    $Context.Configuration = @(
        $Configuration.ToArray()
    )

    return $Context.Configuration

}

# --------------------------------------------------
# Résout un preset de profil
# --------------------------------------------------

function Resolve-ProfilePreset {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Profile,

        [Parameter(Mandatory)]
        [object[]]$Tweaks

    )

    $SelectedIds = [System.Collections.Generic.List[string]]::new()
    $DisabledIds = [System.Collections.Generic.List[string]]::new()

    # --------------------------------------------------
    # Format historique :
    #
    # "Tweaks": [
    #     {
    #         "Id": "Privacy.DisableTelemetry",
    #         "Enabled": true
    #     }
    # ]
    # --------------------------------------------------

    if (
        $Profile.PSObject.Properties["Tweaks"] -and
        $Profile.Tweaks -is [System.Collections.IEnumerable] -and
        -not ($Profile.Tweaks -is [string])
    ) {

        foreach ($Item in @($Profile.Tweaks)) {

            if (
                $null -eq $Item -or
                [string]::IsNullOrWhiteSpace([string]$Item.Id)
            ) {

                continue

            }

            $Id = [string]$Item.Id

            $Enabled = $true

            if ($Item.PSObject.Properties["Enabled"]) {

                $Enabled = [bool]$Item.Enabled

            }

            if ($Enabled) {

                if (-not $SelectedIds.Contains($Id)) {

                    $SelectedIds.Add($Id)

                }

            }
            else {

                if (-not $DisabledIds.Contains($Id)) {

                    $DisabledIds.Add($Id)

                }

            }

        }

    }

    # --------------------------------------------------
    # Nouveau format :
    #
    # "Tweaks": {
    #     "Privacy.DisableTelemetry": true,
    #     "Xbox.DisableGameBar": false
    # }
    # --------------------------------------------------

    elseif ($Profile.PSObject.Properties["Tweaks"]) {

        foreach ($Property in $Profile.Tweaks.PSObject.Properties) {

            $Id = [string]$Property.Name

            if ([string]::IsNullOrWhiteSpace($Id)) {

                continue

            }

            $Enabled = [bool]$Property.Value

            if ($Enabled) {

                if (-not $SelectedIds.Contains($Id)) {

                    $SelectedIds.Add($Id)

                }

            }
            else {

                if (-not $DisabledIds.Contains($Id)) {

                    $DisabledIds.Add($Id)

                }

            }

        }

    }

    # --------------------------------------------------
    # Vérification des identifiants
    # --------------------------------------------------

    $KnownIds = @{}

    foreach ($Tweak in $Tweaks) {

        if (
            $null -ne $Tweak -and
            -not [string]::IsNullOrWhiteSpace([string]$Tweak.Id)
        ) {

            $KnownIds[[string]$Tweak.Id] = $true

        }

    }

    $SelectedIds =
        @(
            $SelectedIds |
                Where-Object {
                    $KnownIds.ContainsKey($_)
                }
        )

    $DisabledIds =
        @(
            $DisabledIds |
                Where-Object {
                    $KnownIds.ContainsKey($_)
                }
        )

    return [PSCustomObject]@{

        Name        = if ($Profile.PSObject.Properties["Name"]) {
            [string]$Profile.Name
        }
        else {
            ""
        }

        Description = if ($Profile.PSObject.Properties["Description"]) {
            [string]$Profile.Description
        }
        else {
            ""
        }

        SelectedIds = @($SelectedIds)
        DisabledIds = @($DisabledIds)

    }

}

# --------------------------------------------------
# Résout la sélection finale des Tweaks
# --------------------------------------------------

function Resolve-TweakSelection {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [object[]]$Tweaks,

        [object[]]$SelectedIds = @(),

        [object[]]$DisabledIds = @()

    )

    $SelectedMap = @{}

    foreach ($Id in $SelectedIds) {

        if (-not [string]::IsNullOrWhiteSpace([string]$Id)) {

            $SelectedMap[[string]$Id] = $true

        }

    }

    $DisabledMap = @{}

    foreach ($Id in $DisabledIds) {

        if (-not [string]::IsNullOrWhiteSpace([string]$Id)) {

            $DisabledMap[[string]$Id] = $true

        }

    }

    $Result = [System.Collections.Generic.List[object]]::new()

    foreach ($Tweak in $Tweaks) {

        if (
            $null -eq $Tweak -or
            [string]::IsNullOrWhiteSpace([string]$Tweak.Id)
        ) {

            continue

        }

        $Id = [string]$Tweak.Id

        # --------------------------------------------------
        # Sélection explicite utilisateur
        # --------------------------------------------------

        if ($SelectedMap.ContainsKey($Id)) {

            if (-not $DisabledMap.ContainsKey($Id)) {

                $Result.Add($Tweak)

            }

            continue

        }

        # --------------------------------------------------
        # Désactivation explicite utilisateur
        # --------------------------------------------------

        if ($DisabledMap.ContainsKey($Id)) {

            continue

        }

        # --------------------------------------------------
        # Aucun choix explicite :
        # utiliser Default
        # --------------------------------------------------

        $Enabled = $false

        if ($Tweak.PSObject.Properties["Default"]) {

            $Enabled = [bool]$Tweak.Default

        }

        if ($Enabled) {

            $Result.Add($Tweak)

        }

    }

    return @($Result)

}
