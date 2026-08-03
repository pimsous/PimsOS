# ==========================================
# Module : Recovery
# Projet : PimsOS Builder
# Version : 1.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Vérifie l'environnement de build
# --------------------------------------------------

function Repair-BuildEnvironment {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context

    )

    Write-Log "Préparation de l'environnement de build..."
	
	$Context.BuildState.Status = "Recovering"

    $Context = Start-BuildPhase `
        -Context $Context `
        -Name "Recovery"

    $Context = Repair-Wim `
		-Context $Context

	$Context = Repair-Registry `
		-Context $Context

	$Context = Repair-Iso `
		-Context $Context

	$Context = Repair-Workspace `
		-Context $Context

    $Context = Complete-BuildPhase `
		-Context $Context

	$Context.BuildState.Recovery.Completed = $true
	$Context.BuildState.Status = "RecoveryCompleted"

	Write-Log "Environnement prêt." SUCCESS

    return $Context

}
# --------------------------------------------------
# Vérification du Workspace
# --------------------------------------------------

function Repair-Workspace {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context

    )

    Write-Log "Vérification du Workspace..."
	
	$Cleaned = $false
	
    $Paths = @(
		$Context.Workspace.Sources,
		$Context.Workspace.MountWIM
	)

	foreach ($Path in $Paths) {

		if (
			$Context.BuildState.Recovery.Wim.CanReuse -and
			$Path -eq $Context.Workspace.MountWIM
		) {

			Write-Log (
				"Montage WIM conservé : $Path"
			) INFO

			continue

		}

        if (-not (Test-Path $Path)) {
            continue
        }

        $Items = @(
            Get-ChildItem `
                -Path $Path `
                -Force `
                -ErrorAction SilentlyContinue
        )

        if ($Items.Count -eq 0) {
            continue
        }

        Write-Log (
			"Nettoyage du Workspace : {0}" -f $Path
		) WARNING

		Remove-Item `
            -Path (Join-Path $Path "*") `
            -Recurse `
            -Force `
            -ErrorAction Stop

        $Cleaned = $true
		
		
		Assert-DirectoryEmpty `
			-Path $Path

        Write-Log (
            "Workspace nettoyé : {0}" -f $Path
        ) SUCCESS

    }

    if ($Cleaned) {

        Write-Log "Workspace nettoyé." SUCCESS

    }
    else {

        Write-Log "Workspace déjà propre." SUCCESS

    }

    return $Context

}


# --------------------------------------------------
# Vérification des montages DISM
# --------------------------------------------------

function Repair-Wim {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context

    )

    Write-Log "Vérification des images DISM..."

    $State = Get-WimMountState `
		-Context $Context

	$Context.BuildState.Recovery.Wim = $State

    if (-not $State.Exists) {

        Write-Log "Aucun montage DISM détecté." SUCCESS

        return $Context

    }

    Write-Log (
        "Montage détecté : {0}" -f
        $State.MountPath
    ) INFO

    if ($State.CanReuse) {

        Write-Log (
            "Montage PimsOS valide."
        ) SUCCESS

        return $Context

    }

    if ($State.NeedsCleanup) {

        Write-Log (
            $State.Message
        ) WARNING

        $null = Dismount-DismImage `
			-MountPath $State.MountPath `
			-Discard

        Write-Log (
            "Montage invalide supprimé."
        ) SUCCESS

        return $Context

    }

    Write-Log "Analyse des montages DISM terminée." SUCCESS

    return $Context

}

# --------------------------------------------------
# Vérification des ruches du registre
# --------------------------------------------------

function Repair-Registry {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context

    )

    Write-Log "Vérification des ruches du registre..."

    $MountedHives = @()

    $PimsOSHives = @(
		"PimsOS_SOFTWARE"
		"PimsOS_SYSTEM"
		"PimsOS_DEFAULT"
		"PimsOS_NTUSER"
	)

	foreach ($Hive in $PimsOSHives) {

        if (Test-Path "Registry::HKLM\$Hive") {

            $MountedHives += $Hive

        }

    }

    if ($MountedHives.Count -eq 0) {

        Write-Log "Aucune ruche montée détectée." SUCCESS

        return $Context

    }

    Write-Log (
        "{0} ruche(s) montée(s) détectée(s)." -f
        $MountedHives.Count
    ) WARNING
	
	$Context.BuildState.Recovery.Registry = $MountedHives
	
    return $Context

}

# --------------------------------------------------
# Vérification des images ISO
# --------------------------------------------------

function Repair-Iso {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context

    )

    Write-Log "Vérification des images ISO..."

    $State = Get-IsoMountState `
        -Context $Context

    $Context.BuildState.Recovery.Iso = $State

    if (-not $State.Exists) {

		Write-Log "Aucune image ISO détectée." SUCCESS

		$Context.BuildState.Image.IsoMounted = $false

		return $Context

	}

	if (-not $State.Mounted) {

		Write-Log $State.Message INFO

		$Context.BuildState.Image.IsoMounted = $false

		return $Context

	}

	Write-Log (
		"Image ISO montée : {0}" -f
		$State.DriveLetter
	) INFO

	Write-Log $State.Message SUCCESS

	$Context.BuildState.Image.IsoMounted = $true

	return $Context

}

# --------------------------------------------------
# Vérifie qu'un dossier est vide
# --------------------------------------------------

function Assert-DirectoryEmpty {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]$Path

    )

    $Items = @(
        Get-ChildItem `
            -Path $Path `
            -Force `
            -ErrorAction SilentlyContinue
    )

    if ($Items.Count -ne 0) {

        throw (
            "Le dossier n'est pas vide : {0}" -f
            $Path
        )

    }

}
