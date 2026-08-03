# ==========================================
# Module : Service
# Projet : PimsOS Builder
# Version : 2.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Conversion StartupType
# --------------------------------------------------

function ConvertTo-ServiceStartupType {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]$StartupType

    )

    switch ($StartupType.Trim().ToLower()) {

        "auto"      { return "Automatic" }
        "automatic" { return "Automatic" }

        "manual"    { return "Manual" }

        "disabled"  { return "Disabled" }

        default {

            throw (
                "StartupType invalide : '{0}'." -f
                $StartupType
            )

        }

    }

}

# --------------------------------------------------
# Vérifie l'existence d'un service
# --------------------------------------------------

function Test-ServiceExists {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]$Name

    )

    return (
        $null -ne (
            Get-Service `
                -Name $Name `
                -ErrorAction SilentlyContinue
        )
    )

}

# --------------------------------------------------
# Retourne le StartupType
# --------------------------------------------------

function Get-ServiceStartupType {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]$Name

    )

    if (-not (Test-ServiceExists -Name $Name)) {

        throw "Le service '$Name' est introuvable."

    }

    $Service = Get-CimInstance `
		-ClassName Win32_Service `
		-Filter "Name='$Name'" `
		-ErrorAction Stop

    return (
		ConvertTo-ServiceStartupType `
			-StartupType $Service.StartMode
	)

}

# --------------------------------------------------
# Modifie le StartupType
# --------------------------------------------------

function Set-ServiceStartupType {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [psobject]$Action

    )

    $DesiredStartupType = ConvertTo-ServiceStartupType `
		-StartupType $Action.StartupType
	
	
    $CurrentStartupType = Get-ServiceStartupType `
        -Name $Action.Name

    if ($CurrentStartupType -eq $DesiredStartupType) {

        Write-Log (
            "Le StartupType du service '$($Action.Name)' est déjà '$DesiredStartupType'."
        ) INFO

        return $Context

    }

    if ($Context.Build.DryRun) {

        Write-Log (
            "[DryRun] StartupType : '$($Action.Name)' -> '$DesiredStartupType'."
        ) INFO

        return $Context

    }

    Write-Log (
        "Modification du StartupType de '$($Action.Name)' vers '$DesiredStartupType'."
    )
	
	$Context.BuildState.Status = "ConfiguringService"
	
    Set-Service `
        -Name $Action.Name `
        -StartupType $DesiredStartupType `
        -ErrorAction Stop
	
	$Context.BuildState.Status = "ServiceConfigured"
	
    Write-Log (
        "StartupType modifié."
    ) SUCCESS

    return $Context

}

# --------------------------------------------------
# Arrêt sécurisé
# --------------------------------------------------

function Stop-ServiceSafe {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [psobject]$Action

    )

    $Service = Get-Service `
        -Name $Action.Name `
        -ErrorAction Stop

    if ($Service.Status -eq "Stopped") {

        Write-Log (
            "Le service '$($Action.Name)' est déjà arrêté."
        ) INFO

        return $Context

    }

    if ($Context.Build.DryRun) {

        Write-Log (
            "[DryRun] Arrêt du service '$($Action.Name)'."
        ) INFO

        return $Context

    }

    Write-Log (
        "Arrêt du service '$($Action.Name)'."
    )
	
	$Context.BuildState.Status = "StoppingService"
	
    Stop-Service `
		-Name $Action.Name `
		-Force `
		-ErrorAction Stop

	$Service.WaitForStatus(
		"Stopped",
		[TimeSpan]::FromSeconds(30)
	)
	

	$Service.Refresh()

	if ($Service.Status -ne "Stopped") {

		throw (
			"Le service '{0}' n'a pas pu être arrêté." -f
			$Action.Name
		)

	}

	$Context.BuildState.Status = "ServiceStopped"
	
    Write-Log (
        "Service arrêté."
    ) SUCCESS

    return $Context

}

# --------------------------------------------------
# Démarrage sécurisé
# --------------------------------------------------

function Start-ServiceSafe {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [psobject]$Action

    )

    $Service = Get-Service `
        -Name $Action.Name `
        -ErrorAction Stop

    if ($Service.Status -eq "Running") {

        Write-Log (
            "Le service '$($Action.Name)' est déjà démarré."
        ) INFO

        return $Context

    }

    if ($Context.Build.DryRun) {

        Write-Log (
            "[DryRun] Démarrage du service '$($Action.Name)'."
        ) INFO

        return $Context

    }

    Write-Log (
        "Démarrage du service '$($Action.Name)'."
    )
	
	$Context.BuildState.Status = "StartingService"
	
    Start-Service `
		-Name $Action.Name `
		-ErrorAction Stop

	$Service.WaitForStatus(
		"Running",
		[TimeSpan]::FromSeconds(30)
	)
	
	$Service.Refresh()

	if ($Service.Status -ne "Running") {

		throw (
			"Le service '{0}' n'a pas pu être démarré." -f
			$Action.Name
		)

	}

	$Context.BuildState.Status = "ServiceStarted"

    Write-Log (
        "Service démarré."
    ) SUCCESS

    return $Context

}

# --------------------------------------------------
# Retourne un service
# --------------------------------------------------

function Get-ServiceInformation {
	
	[OutputType([Microsoft.Management.Infrastructure.CimInstance])]

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]$Name

    )

    if (-not (Test-ServiceExists -Name $Name)) {

        throw "Le service '$Name' est introuvable."

    }

    return Get-CimInstance `
		-ClassName Win32_Service `
		-Filter "Name='$Name'" `
		-ErrorAction Stop

}