# ==========================================
# Module : Registry
# Projet : PimsOS Builder
# Version : 1.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Retourne le chemin PowerShell d'une ruche montée
# --------------------------------------------------

function Resolve-RegistryHive {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [ValidateSet(
            "SOFTWARE",
			"SYSTEM",
			"DEFAULT",
			"NTUSER",
			"SAM",
			"SECURITY",
			"COMPONENTS"
        )]
        [string]$Hive

    )

    switch ($Hive.ToUpper()) {

        "SOFTWARE" {

            return "HKLM:\PimsOS_SOFTWARE"

        }

        "SYSTEM" {

            return "HKLM:\PimsOS_SYSTEM"

        }

        "DEFAULT" {

            return "HKLM:\PimsOS_DEFAULT"

        }

        "NTUSER" {

            return "HKLM:\PimsOS_NTUSER"

        }
		
		"SAM" {

			return "HKLM:\PimsOS_SAM"

		}

		"SECURITY" {

			return "HKLM:\PimsOS_SECURITY"

		}

		"COMPONENTS" {

			return "HKLM:\PimsOS_COMPONENTS"

		}

        default {

            throw "Ruche inconnue : $Hive"

        }

    }

}

# --------------------------------------------------
# Convertit un type PimsOS en type Registre
# --------------------------------------------------

function ConvertTo-RegistryType {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]$DataType

    )

    switch ($DataType) {

        "String"       { return "String" }

        "ExpandString" { return "ExpandString" }

        "MultiString"  { return "MultiString" }

        "Binary"       { return "Binary" }

        "DWord"        { return "DWord" }

        "QWord"        { return "QWord" }

        default {

            throw "Type de registre inconnu : $DataType"

        }

    }

}
# --------------------------------------------------
# Vérifie qu'une ruche est montée
# --------------------------------------------------
function Test-RegistryHive {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]$Hive

    )

    $HivePath = Resolve-RegistryHive `
        -Hive $Hive

    return (Test-Path $HivePath)

}

# --------------------------------------------------
# Crée une clé du registre si elle n'existe pas
# --------------------------------------------------

function New-RegistryKey {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [ValidateSet(
            "SOFTWARE",
            "SYSTEM",
            "DEFAULT",
            "SAM",
            "SECURITY",
            "COMPONENTS"
        )]
        [string]$Hive,

        [Parameter(Mandatory)]
        [string]$Key

    )

    #--------------------------------------------------
	# Vérification de la ruche
	#--------------------------------------------------

	

	if (-not (Test-RegistryHive -Hive $Hive)) {

		throw "La ruche '$Hive' n'est pas montée."

	}

    #--------------------------------------------------
    # Construction du chemin
    #--------------------------------------------------

    $Root = Resolve-RegistryHive `
        -Hive $Hive

    $RegistryPath = Join-Path `
        -Path $Root `
        -ChildPath $Key

    #--------------------------------------------------
    # Déjà existante ?
    #--------------------------------------------------

    if (Test-Path $RegistryPath) {

        Write-Log (
            "La clé '$Key' existe déjà."
        ) INFO

        return $RegistryPath

    }

    #--------------------------------------------------
    # Création
    #--------------------------------------------------

    try {

        New-Item `
            -Path $RegistryPath `
            -Force `
            -ErrorAction Stop |
            Out-Null

    }
    catch {

        throw (
            "Impossible de créer la clé '$Key'.`n" +
            $_.Exception.Message
        )

    }

    #--------------------------------------------------
    # Validation
    #--------------------------------------------------

    if (-not (Test-Path $RegistryPath)) {

        throw "La création de la clé '$Key' a échoué."

    }

    Write-Log (
		"Clé registre créée : $RegistryPath"
	) SUCCESS

    return $RegistryPath

}

# --------------------------------------------------
# Crée ou modifie une valeur du registre
# --------------------------------------------------

function Set-RegistryValue {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,
		
		[Parameter(Mandatory)]
		[psobject]$Action
		
    )

   

    #--------------------------------------------------
	# Vérification de la ruche
	#--------------------------------------------------

	if ($Context.Registry.Mounted -notcontains $Action.Hive) {

		throw "La ruche '$($Action.Hive)' n'est pas montée."

	}

	if (-not (Test-RegistryHive -Hive $Action.Hive)) {

		throw "La ruche '$($Action.Hive)' est inaccessible."

	}
	
    #--------------------------------------------------
    # Création de la clé
    #--------------------------------------------------

    $RegistryPath = New-RegistryKey `
        -Hive $Action.Hive `
        -Key $Action.Key `
		-ErrorAction Stop
		
    #--------------------------------------------------
    # Conversion du type
    #--------------------------------------------------

    $RegistryType = ConvertTo-RegistryType `
		-DataType $Action.DataType

    #--------------------------------------------------
    # Création / Modification
    #--------------------------------------------------

    try {

        New-ItemProperty `
            -Path $RegistryPath `
            -Name $Action.Name `
            -Value $Action.Value `
            -PropertyType $RegistryType `
            -Force `
            -ErrorAction Stop |
            Out-Null

    }
    catch {

        throw (
            "Impossible d'écrire '$($Action.Name)' dans '$($Action.Key)'.`n" +
            $_.Exception.Message
        )

    }

    #--------------------------------------------------
    # Journal
    #--------------------------------------------------
	
	Write-Log "Application de la valeur registre..."
    Write-Log "Hive      : $($Action.Hive)"
	Write-Log "Key       : $($Action.Key)"
	Write-Log "Name      : $($Action.Name)"
	Write-Log "Value     : $($Action.Value)"
	Write-Log "DataType  : $RegistryType"

    Write-Log "Valeur du registre appliquée." SUCCESS

	return $Context
}

function Get-OfflineRegistryPath {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [ValidateSet(
            "SOFTWARE",
            "SYSTEM",
            "DEFAULT",
            "SAM",
            "SECURITY",
            "COMPONENTS"
        )]
        [string]$Hive

    )

    if (-not $Context.BuildState.Image.WimMounted) {

		throw "Aucune image Windows n'est montée."

	}

    $configPath = Join-Path `
        $Context.WIM.Mount.Path `
        "Windows\System32\Config"

    $path = Join-Path $configPath $Hive

    if (-not (Test-Path $path)) {

        throw "Ruche '$Hive' introuvable."

    }

    return $path

}
function Mount-RegistryHive {

    <#
    .SYNOPSIS
        Monte une ruche du registre d'une image Windows hors ligne.

    .DESCRIPTION
        Monte une ruche (SOFTWARE, SYSTEM, etc.) sous HKLM\PimsOS_<Hive>
        afin de permettre sa modification.

    .EXAMPLE
        $Context = Mount-RegistryHive `
            -Context $Context `
            -Hive SOFTWARE
    #>

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [ValidateSet(
            "SOFTWARE",
            "SYSTEM",
            "DEFAULT",
            "SAM",
            "SECURITY",
            "COMPONENTS"
        )]
        [string]$Hive

    )

    #--------------------------------------------------
	# Vérifications
	#--------------------------------------------------

	Assert-Administrator

	if (-not $Context.BuildState.Image.WimMounted) {

		throw "Aucune image Windows n'est montée."

	}
    

    $hivePath = Get-OfflineRegistryPath `
        -Context $Context `
        -Hive $Hive

    $mountName = "HKLM\PimsOS_$($Hive.ToUpper())"

    #--------------------------------------------------
    # Déjà monté ?
    #--------------------------------------------------

    if (Test-Path "Registry::$mountName") {

        Write-Log "La ruche $Hive est déjà montée." INFO

        if ($Context.Registry.Mounted -notcontains $Hive) {

			$Context.Registry.Mounted += $Hive

		}

		$Context.BuildState.Image.RegistryLoaded = $true
		$Context.BuildState.Image.CurrentRegistryHive = $Hive
		$Context.BuildState.Status = "RegistryMounted"

        return $Context

    }
	
	
    #--------------------------------------------------
    # Montage
    #--------------------------------------------------
	
	$Context.BuildState.Status = "MountingRegistry"
	
    Write-Log "Montage de la ruche $Hive..."

		$null = & reg.exe load `
			$mountName `
			$hivePath

	if ($LASTEXITCODE -ne 0) {

		throw "Impossible de monter la ruche '$Hive' (code $LASTEXITCODE)."

	}

    #--------------------------------------------------
	# Validation
	#--------------------------------------------------

	if (-not (Test-Path "Registry::$mountName")) {

		throw "Le montage de la ruche '$Hive' a échoué."

	}

	#--------------------------------------------------
	# Mise à jour du contexte
	#--------------------------------------------------

	if ($Context.Registry.Mounted -notcontains $Hive) {

		$Context.Registry.Mounted += $Hive

	}

	$Context.BuildState.Image.RegistryLoaded = $true
	$Context.BuildState.Image.CurrentRegistryHive = $Hive
	$Context.BuildState.Status = "RegistryMounted"

	Write-Log "Ruche $Hive montée avec succès." SUCCESS

	return $Context

	}
	
function Dismount-RegistryHive {

    <#
    .SYNOPSIS
        Démonte une ruche du registre d'une image Windows hors ligne.

    .DESCRIPTION
        Décharge une ruche montée sous HKLM\PimsOS_<Hive>.

    .EXAMPLE
        $Context = Dismount-RegistryHive `
            -Context $Context `
            -Hive SOFTWARE
    #>

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [ValidateSet(
            "SOFTWARE",
            "SYSTEM",
            "DEFAULT",
            "SAM",
            "SECURITY",
            "COMPONENTS"
        )]
        [string]$Hive

    )

    #--------------------------------------------------
    # Vérifications
    #--------------------------------------------------

    Assert-Administrator

    $mountName = "HKLM\PimsOS_$($Hive.ToUpper())"

    #--------------------------------------------------
    # Déjà démontée ?
    #--------------------------------------------------

    if (-not (Test-Path "Registry::$mountName")) {

		Write-Log "La ruche $Hive n'est pas montée." INFO

		$Context.BuildState.Status = "RegistryUnmounted"

		return $Context

	}

  

	#--------------------------------------------------
	# Démontage
	#--------------------------------------------------

	$Context.BuildState.Status = "DismountingRegistry"

	Write-Log "Démontage de la ruche $Hive..."

	# Si le shell est positionné sur le provider Registry,
	# reg unload peut échouer avec "Accès refusé".
	Push-Location

	try {

		Set-Location C:\

		# Libère les handles .NET éventuels
		[System.GC]::Collect()
		[System.GC]::WaitForPendingFinalizers()

		Start-Sleep -Milliseconds 300

		# Déchargement de la ruche
		$null = & reg.exe unload $mountName

	}
	finally {

		Pop-Location

	}

	if ($LASTEXITCODE -ne 0) {

		throw "Impossible de démonter la ruche '$Hive' (code $LASTEXITCODE)."

	}

    #--------------------------------------------------
    # Validation
    #--------------------------------------------------

    if (Test-Path "Registry::$mountName") {

        throw "Le démontage de la ruche '$Hive' a échoué."

    }

    #--------------------------------------------------
	# Mise à jour du contexte
	#--------------------------------------------------

	$Context.Registry.Mounted = @(
		@($Context.Registry.Mounted) |
		Where-Object { $_ -ne $Hive }
	)

	if ($Context.Registry.Mounted.Count -eq 0) {

		$Context.BuildState.Image.RegistryLoaded = $false
		$Context.BuildState.Image.CurrentRegistryHive = $null

	}
	elseif (
		$Context.BuildState.Image.CurrentRegistryHive -eq $Hive -and
		$Context.Registry.Mounted.Count -gt 0
	) {

		$Context.BuildState.Image.CurrentRegistryHive =
			$Context.Registry.Mounted[-1]

	}
	
	$Context.BuildState.Status = "RegistryUnmounted"
	
	Write-Log "Ruche $Hive démontée avec succès." SUCCESS

	return $Context

}
function Get-RegistryValue {

    <#
    .SYNOPSIS
        Lit une valeur dans une ruche du registre hors ligne.

    .DESCRIPTION
        Retourne la valeur d'une clé du registre montée sous
        HKLM\PimsOS_<Hive>.

    .EXAMPLE

        Get-RegistryValue `
            -Hive SOFTWARE `
            -Key "Microsoft\Windows NT\CurrentVersion" `
            -Name "ProductName"

    #>

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [ValidateSet(
            "SOFTWARE",
			"SYSTEM",
			"DEFAULT",
			"NTUSER",
			"SAM",
			"SECURITY",
			"COMPONENTS"
        )]
        [string]$Hive,

        [Parameter(Mandatory)]
        [string]$Key,

        [Parameter(Mandatory)]
        [string]$Name

    )

    #--------------------------------------------------
	# Vérifications
	#--------------------------------------------------

	if ($Context.Registry.Mounted -notcontains $Hive) {

		throw "La ruche '$Hive' n'est pas montée."

	}

	$root = Resolve-RegistryHive `
		-Hive $Hive

	if (-not (Test-Path $root)) {

		throw "La ruche '$Hive' est inaccessible."

	}

	$registryKey = Join-Path `
		$root `
		$Key

	if (-not (Test-Path $registryKey)) {

		throw "La clé '$Key' est introuvable."

	}

    #--------------------------------------------------
    # Lecture
    #--------------------------------------------------

    try {

        $value = Get-ItemPropertyValue `
            -Path $registryKey `
            -Name $Name `
            -ErrorAction Stop

    }
    catch {

        throw "La valeur '$Name' est introuvable dans '$Key'."

    }

    Write-Log "Lecture registre : $Hive\$Key\$Name" INFO

    return $value

}

             