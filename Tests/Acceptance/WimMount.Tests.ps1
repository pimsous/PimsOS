# ==========================================
# Test : Mount-Wim
# Projet : PimsOS Builder
# ==========================================

#Requires -Version 7.0

Set-StrictMode -Version Latest

# --------------------------------------------------
# Détermination de la racine du projet
# --------------------------------------------------

$ProjectRoot = Split-Path `
    (Split-Path $PSScriptRoot -Parent) `
    -Parent

Set-Location $ProjectRoot

# --------------------------------------------------
# Chargement des composants nécessaires
# --------------------------------------------------

. "$ProjectRoot\Modules\Infrastructure\Logger.ps1"
. "$ProjectRoot\Modules\Core\Core.ps1"
. "$ProjectRoot\Modules\Core\BuildContext.ps1"
. "$ProjectRoot\Modules\Configuration\Configuration.ps1"
. "$ProjectRoot\Modules\Image\Iso.ps1"
. "$ProjectRoot\Modules\Image\Dism.ps1"
. "$ProjectRoot\Modules\Image\Wim.ps1"

# --------------------------------------------------
# Initialisation
# --------------------------------------------------

Clear-Host

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "       Test du montage du WIM" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$Context = $null
$LoggerStarted = $false
$TestSucceeded = $false

try {

    # --------------------------------------------------
    # BuildContext
    # --------------------------------------------------

    Write-Host `
        "Initialisation du BuildContext..." `
        -ForegroundColor Yellow

    $Context = New-BuildContext

    $Context = Initialize-BuildContext `
        -Context $Context

    # --------------------------------------------------
    # Logger
    # --------------------------------------------------

    if (
        $null -eq $Context.Logger -or
        $Context.Logger.PSObject.Properties.Name -notcontains "Path"
    ) {

        throw "Le chemin du journal est absent du BuildContext."

    }

    Start-Logger `
        -Path $Context.Logger.Path

    $LoggerStarted = $true

    Write-Log `
        "Test du montage du WIM démarré." `
        INFO

    Write-Log (
        "Projet : {0}" -f
        $Context.Project.Root
    )

    # --------------------------------------------------
    # Montage ISO
    # --------------------------------------------------

    Write-Log `
        "Montage de l'ISO..." `
        INFO

    $Context = Mount-Iso `
        -Context $Context

    # --------------------------------------------------
    # Vérification du montage ISO
    # --------------------------------------------------

    if (
        $null -eq $Context.ISO -or
        $Context.ISO.PSObject.Properties.Name -notcontains "Mounted"
    ) {

        throw `
            "L'état de montage de l'ISO est absent du BuildContext."

    }

    if (-not [bool]$Context.ISO.Mounted) {

        throw `
            "L'ISO n'est pas indiquée comme montée dans le BuildContext."

    }

    Write-Log `
        "ISO montée avec succès." `
        SUCCESS

    # --------------------------------------------------
    # Détection du WIM
    # --------------------------------------------------

    Write-Log `
        "Recherche de l'image Windows..." `
        INFO

    $Context = Get-WimFile `
        -Context $Context

    # --------------------------------------------------
	# Vérification du fichier WIM
	# --------------------------------------------------

	if ($null -eq $Context.WIM) {

		throw `
			"La section WIM est absente du BuildContext."

	}

	if (
		$Context.WIM.PSObject.Properties.Name -notcontains "FullName"
	) {

		throw `
			"La propriété FullName est absente de la section WIM du BuildContext."

	}

	if (
		[string]::IsNullOrWhiteSpace(
			[string]$Context.WIM.FullName
		)
	) {

		throw `
			"Aucun fichier WIM n'a été trouvé."

	}

	if (-not (Test-Path $Context.WIM.FullName)) {

		throw (
			"Le fichier WIM est introuvable : {0}" -f
			$Context.WIM.FullName
		)

	}

	Write-Log (
		"Image Windows : {0}" -f
		$Context.WIM.FullName
	) SUCCESS
	
	# --------------------------------------------------
	# Copie du WIM dans le Workspace
	# --------------------------------------------------

	Write-Log `
		"Copie de l'image Windows dans le Workspace..." `
		INFO

	$Context = Copy-WimToWorkspace `
		-Context $Context

	# --------------------------------------------------
	# Vérification de la copie
	# --------------------------------------------------

	if (
		$null -eq $Context.WIM -or
		$Context.WIM.PSObject.Properties.Name -notcontains "FullName"
	) {

		throw `
			"Les informations du WIM copié sont absentes du BuildContext."

	}

	if (
		[string]::IsNullOrWhiteSpace(
			[string]$Context.WIM.FullName
		)
	) {

		throw `
			"Le chemin du WIM copié est vide."

	}

	if (-not (Test-Path $Context.WIM.FullName)) {

		throw (
			"Le WIM copié est introuvable : {0}" -f
			$Context.WIM.FullName
		)

	}

	Write-Log (
		"WIM utilisé pour le montage : {0}" -f
		$Context.WIM.FullName
	) SUCCESS

    # --------------------------------------------------
	# Lecture des éditions
	# --------------------------------------------------

	Write-Log `
		"Lecture des éditions Windows..." `
		INFO

	$Context = Get-WimImages `
		-Context $Context

	# --------------------------------------------------
	# Vérification de la structure WIM
	# --------------------------------------------------

	if (
		$null -eq $Context
	) {

		throw `
			"Le BuildContext est null après la lecture des images Windows."

	}

	if (
		$Context.PSObject.Properties.Name -notcontains "WIM"
	) {

		throw `
			"La propriété 'WIM' est absente du BuildContext."

	}

	if (
		$null -eq $Context.WIM
	) {

		throw `
			"Les informations WIM sont absentes du BuildContext."

	}

	# --------------------------------------------------
	# Vérification des images
	# --------------------------------------------------

	if (
		$Context.WIM.PSObject.Properties.Name -notcontains "Images"
	) {

		throw `
			"La propriété 'Images' est absente du BuildContext.WIM."

	}

	if (
		$null -eq $Context.WIM.Images
	) {

		throw `
			"Aucune édition Windows n'a été détectée."

	}

	$ImageCount = @($Context.WIM.Images).Count

	if ($ImageCount -eq 0) {

		throw `
			"La liste des éditions Windows est vide."

	}

	Write-Log (
		"{0} édition(s) Windows détectée(s)." -f
		$ImageCount
	) SUCCESS

	# --------------------------------------------------
	# Sélection de l'image
	# --------------------------------------------------

	Write-Log `
		"Sélection de l'édition Windows..." `
		INFO

	$Context = Select-WimImage `
		-Context $Context

	# --------------------------------------------------
	# Vérification de la sélection
	# --------------------------------------------------

	if (
		$null -eq $Context
	) {

		throw `
			"Le BuildContext est null après la sélection de l'image Windows."

	}

	if (
		$Context.PSObject.Properties.Name -notcontains "Image"
	) {

		throw `
			"La propriété 'Image' est absente du BuildContext."

	}

	if (
		$null -eq $Context.Image
	) {

		throw `
			"Aucune image Windows n'a été sélectionnée."

	}

	# --------------------------------------------------
	# Affichage de l'image sélectionnée
	# --------------------------------------------------

	Write-Host ""
	Write-Host `
		"Edition sélectionnée :" `
		-ForegroundColor Cyan

	Write-Host (
		"Nom   : {0}" -f
		$Context.Image.Name
	)

	Write-Host (
		"Index : {0}" -f
		$Context.Image.Index
	)

	Write-Host ""

	Write-Log (
		"Edition sélectionnée : {0} (Index {1})." -f
		$Context.Image.Name,
		$Context.Image.Index
	) SUCCESS

	# --------------------------------------------------
	# Montage du WIM
	# --------------------------------------------------

	Write-Log `
		"Montage du WIM..." `
		INFO

	$Context = Mount-Wim `
		-Context $Context

	# --------------------------------------------------
	# Vérification du BuildState
	# --------------------------------------------------

	if (
		$null -eq $Context
	) {

		throw `
			"Le BuildContext est null après le montage du WIM."

	}

	if (
		$Context.PSObject.Properties.Name -notcontains "BuildState"
	) {

		throw `
			"La propriété 'BuildState' est absente du BuildContext."

	}

	if (
		$null -eq $Context.BuildState
	) {

		throw `
			"Le BuildState est null après le montage du WIM."

	}

	# --------------------------------------------------
	# Vérification de l'état de l'image
	# --------------------------------------------------

	if (
		$Context.BuildState.PSObject.Properties.Name -notcontains "Image"
	) {

		throw `
			"La propriété 'Image' est absente du BuildState."

	}

	if (
		$null -eq $Context.BuildState.Image
	) {

		throw `
			"L'état de l'image est absent du BuildState."

	}

	if (
		$Context.BuildState.Image.PSObject.Properties.Name -notcontains "Mounted"
	) {

		throw `
			"L'état de montage du WIM est absent du BuildState."

	}

	if (
		-not [bool]$Context.BuildState.Image.Mounted
	) {

		throw `
			"Le WIM n'est pas indiqué comme monté dans le BuildState."

	}

	Write-Log `
		"WIM monté avec succès." `
		SUCCESS

	# --------------------------------------------------
	# Vérification du chemin de montage
	# --------------------------------------------------

	if (
		$Context.WIM.PSObject.Properties.Name -notcontains "Mount"
	) {

		throw `
			"La propriété 'Mount' est absente du BuildContext.WIM."

	}

	if (
		$null -eq $Context.WIM.Mount
	) {

		throw `
			"Les informations de montage du WIM sont absentes du BuildContext."

	}

	if (
		$Context.WIM.Mount.PSObject.Properties.Name -notcontains "Path"
	) {

		throw `
			"Le chemin de montage du WIM est absent du BuildContext."

	}

	if (
		[string]::IsNullOrWhiteSpace(
			[string]$Context.WIM.Mount.Path
		)
	) {

		throw `
			"Le chemin de montage du WIM est vide."

	}

	# --------------------------------------------------
	# Vérification du dossier Windows
	# --------------------------------------------------

	$WindowsFolder = Join-Path `
		$Context.WIM.Mount.Path `
		"Windows"

	if (
		-not (Test-Path $WindowsFolder)
	) {

		throw (
			"Le dossier Windows est introuvable dans : {0}" -f
			$Context.WIM.Mount.Path
		)

	}

	Write-Log (
		"WIM monté sur : {0}" -f
		$Context.WIM.Mount.Path
	) SUCCESS

	Write-Log `
		"Dossier Windows détecté dans l'image montée." `
		SUCCESS

# --------------------------------------------------
# Vérification du chemin de montage
# --------------------------------------------------

if (
    $Context.PSObject.Properties.Name -notcontains "WIM"
) {

    throw `
        "La propriété 'WIM' est absente du BuildContext."

}

if (
    $null -eq $Context.WIM
) {

    throw `
        "Les informations WIM sont absentes du BuildContext."

}

if (
    $Context.WIM.PSObject.Properties.Name -notcontains "Mount"
) {

    throw `
        "La propriété 'Mount' est absente du BuildContext.WIM."

}

if (
    $null -eq $Context.WIM.Mount
) {

    throw `
        "Les informations de montage du WIM sont absentes du BuildContext."

}

if (
    $Context.WIM.Mount.PSObject.Properties.Name -notcontains "Path"
) {

    throw `
        "Le chemin de montage du WIM est absent du BuildContext."

}

if (
    [string]::IsNullOrWhiteSpace(
        [string]$Context.WIM.Mount.Path
    )
) {

    throw `
        "Le chemin de montage du WIM est vide."

}

# --------------------------------------------------
# Vérification du dossier Windows
# --------------------------------------------------

$WindowsFolder = Join-Path `
    $Context.WIM.Mount.Path `
    "Windows"

if (
    -not (Test-Path $WindowsFolder)
) {

    throw (
        "Le dossier Windows est introuvable dans : {0}" -f
        $Context.WIM.Mount.Path
    )

}

Write-Log (
    "WIM monté sur : {0}" -f
    $Context.WIM.Mount.Path
) SUCCESS

Write-Log `
    "Dossier Windows détecté dans l'image montée." `
    SUCCESS

    # --------------------------------------------------
    # Validation du dossier Windows
    # --------------------------------------------------

    $windowsFolder = Join-Path `
        $Context.WIM.Mount.Path `
        "Windows"

    if (-not (Test-Path $windowsFolder)) {

        throw (
            "Le dossier Windows est introuvable dans : {0}" -f
            $Context.WIM.Mount.Path
        )

    }

    Write-Host ""
    Write-Host `
        "Le WIM est correctement monté." `
        -ForegroundColor Green

    Write-Host ""

    Write-Host (
        "Edition      : {0}" -f
        $Context.Image.Name
    )

    Write-Host (
        "Index        : {0}" -f
        $Context.Image.Index
    )

    Write-Host (
		"Image WIM    : {0}" -f
		$Context.WIM.FullName
	)

	Write-Host (
		"Montage      : {0}" -f
		$Context.WIM.Mount.Path
	)

    Write-Host ""

    Write-Log `
        "Validation du montage du WIM réussie." `
        SUCCESS

    # --------------------------------------------------
    # Résultat
    # --------------------------------------------------

    $TestSucceeded = $true

    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "      Test du montage WIM réussi" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host ""

}
catch {

    # --------------------------------------------------
    # Gestion de l'erreur
    # --------------------------------------------------

    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Red
    Write-Host "      Test du montage WIM échoué" -ForegroundColor Red
    Write-Host "==========================================" -ForegroundColor Red
    Write-Host ""

    $ErrorMessage = $_.Exception.Message

    if ($LoggerStarted) {

        Write-Log `
            $ErrorMessage `
            ERROR

    }

    Write-Host (
        "Erreur : {0}" -f
        $ErrorMessage
    ) -ForegroundColor Red

}
finally {

    # --------------------------------------------------
    # Etat sécurisé du WIM
    # --------------------------------------------------

    $WimMounted = $false

    if ($null -ne $Context) {

        if (
            $Context.PSObject.Properties.Name -contains "BuildState" -and
            $null -ne $Context.BuildState
        ) {

            if (
                $Context.BuildState.PSObject.Properties.Name -contains "Image" -and
                $null -ne $Context.BuildState.Image
            ) {

                if (
                    $Context.BuildState.Image.PSObject.Properties.Name -contains "Mounted"
                ) {

                    $WimMounted = [bool]$Context.BuildState.Image.Mounted

                }

            }

        }

    }

    # --------------------------------------------------
    # Démontage automatique du WIM
    # --------------------------------------------------

    if ($WimMounted) {

        Write-Host ""
        Write-Host `
            "Nettoyage : démontage du WIM..." `
            -ForegroundColor Yellow

        try {

            Dismount-Wim `
                -Context $Context `
                -ErrorAction Stop

            Write-Host `
                "WIM démonté avec succès." `
                -ForegroundColor Green

            if ($LoggerStarted) {

                Write-Log `
                    "WIM démonté lors du nettoyage." `
                    SUCCESS

            }

        }
        catch {

            $WimCleanupError = $_.Exception.Message

            Write-Host (
                "Impossible de démonter le WIM : {0}" -f
                $WimCleanupError
            ) -ForegroundColor Red

            if ($LoggerStarted) {

                Write-Log `
                    $WimCleanupError `
                    ERROR

            }

        }

    }

    # --------------------------------------------------
    # Etat sécurisé de l'ISO
    # --------------------------------------------------

    $IsoMounted = $false

    if ($null -ne $Context) {

        if (
            $Context.PSObject.Properties.Name -contains "ISO" -and
            $null -ne $Context.ISO
        ) {

            if (
                $Context.ISO.PSObject.Properties.Name -contains "Mounted"
            ) {

                $IsoMounted = [bool]$Context.ISO.Mounted

            }

        }

    }

    # --------------------------------------------------
    # Démontage automatique de l'ISO
    # --------------------------------------------------

    if ($IsoMounted) {

        Write-Host ""
        Write-Host `
            "Nettoyage : démontage de l'ISO..." `
            -ForegroundColor Yellow

        try {

            if (
                $Context.ISO.PSObject.Properties.Name -contains "FullName" -and
                -not [string]::IsNullOrWhiteSpace(
                    [string]$Context.ISO.FullName
                )
            ) {

                Dismount-DiskImage `
                    -ImagePath $Context.ISO.FullName `
                    -ErrorAction Stop |
                    Out-Null

                $Context.ISO.Mounted = $false

                Write-Host `
                    "ISO démontée avec succès." `
                    -ForegroundColor Green

                if ($LoggerStarted) {

                    Write-Log `
                        "ISO démontée lors du nettoyage." `
                        SUCCESS

                }

            }
            else {

                Write-Host `
                    "Impossible de déterminer le chemin de l'ISO." `
                    -ForegroundColor Yellow

                if ($LoggerStarted) {

                    Write-Log `
                        "Chemin de l'ISO indisponible lors du nettoyage." `
                        WARNING

                }

            }

        }
        catch {

            $IsoCleanupError = $_.Exception.Message

            Write-Host (
                "Impossible de démonter automatiquement l'ISO : {0}" -f
                $IsoCleanupError
            ) -ForegroundColor Red

            if ($LoggerStarted) {

                Write-Log `
                    $IsoCleanupError `
                    ERROR

            }

        }

    }

    # --------------------------------------------------
    # Arrêt du Logger
    # --------------------------------------------------

    if ($LoggerStarted) {

        Stop-Logger

    }

    # --------------------------------------------------
    # Affichage du journal
    # --------------------------------------------------

    Write-Host ""
    Write-Host `
        "Journal :" `
        -ForegroundColor Yellow

    $LogPath = Get-LogFile

    if (
        $null -ne $LogPath -and
        -not [string]::IsNullOrWhiteSpace(
            [string]$LogPath
        )
    ) {

        Write-Host $LogPath

    }
    else {

        Write-Host `
            "Aucun journal disponible." `
            -ForegroundColor Yellow

    }

    Write-Host ""

}