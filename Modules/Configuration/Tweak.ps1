# ==========================================
# Module : Tweak
# Projet : PimsOS Builder
# Version : 1.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Construit une action
# --------------------------------------------------

function New-Action {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Definition

    )

    return [PSCustomObject]@{

        # ------------------------------------------
        # Identification
        # ------------------------------------------

        ObjectType = "Action"

        Id   = $Definition.Id
        Type = $Definition.Type

        Description = Get-ObjectProperty `
            -Object $Definition `
            -Name Description

        # ------------------------------------------
        # Configuration
        # ------------------------------------------

        Enabled = Get-ObjectProperty `
            -Object $Definition `
            -Name Enabled `
            -Default $true

        RequiresRestart = Get-ObjectProperty `
            -Object $Definition `
            -Name RequiresRestart `
            -Default $false

        ContinueOnError = Get-ObjectProperty `
            -Object $Definition `
            -Name ContinueOnError `
            -Default $false

        # ------------------------------------------
        # Registry
        # ------------------------------------------

        Hive = Get-ObjectProperty `
            -Object $Definition `
            -Name Hive

        Key = Get-ObjectProperty `
            -Object $Definition `
            -Name Key

        Name = Get-ObjectProperty `
            -Object $Definition `
            -Name Name

        Value = Get-ObjectProperty `
            -Object $Definition `
            -Name Value

        DataType = Get-ObjectProperty `
            -Object $Definition `
            -Name DataType

        # ------------------------------------------
        # Service
        # ------------------------------------------

        StartupType = Get-ObjectProperty `
            -Object $Definition `
            -Name StartupType

        Stop = Get-ObjectProperty `
            -Object $Definition `
            -Name Stop `
            -Default $false
		
		# ------------------------------------------
		# Général (Managers)
		# ------------------------------------------

		Provider = Get-ObjectProperty `
			-Object $Definition `
			-Name Provider

		Command = Get-ObjectProperty `
			-Object $Definition `
			-Name Command

		Version = Get-ObjectProperty `
			-Object $Definition `
			-Name Version

		Source = Get-ObjectProperty `
			-Object $Definition `
			-Name Source

		Destination = Get-ObjectProperty `
			-Object $Definition `
			-Name Destination

		Target = Get-ObjectProperty `
			-Object $Definition `
			-Name Target

		Path = Get-ObjectProperty `
			-Object $Definition `
			-Name Path

		Arguments = Get-ObjectProperty `
			-Object $Definition `
			-Name Arguments

		WorkingDirectory = Get-ObjectProperty `
			-Object $Definition `
			-Name WorkingDirectory

		Timeout = Get-ObjectProperty `
			-Object $Definition `
			-Name Timeout

		Wait = Get-ObjectProperty `
			-Object $Definition `
			-Name Wait `
			-Default $true

		RunAs = Get-ObjectProperty `
			-Object $Definition `
			-Name RunAs `
			-Default $false
			
        # ------------------------------------------
        # Etat d'exécution
        # ------------------------------------------

        Executed = $false
        Success  = $false
        Duration = [timespan]::Zero
        Error    = $null

    }

}

# --------------------------------------------------
# Construit un objet Tweak
# --------------------------------------------------

function New-Tweak {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Definition,

        [Parameter(Mandatory)]
        [string]$CategoryId,

        [Parameter(Mandatory)]
        [string]$SourceFile

    )

    # ------------------------------------------
    # Construction des actions
    # ------------------------------------------

    $Actions = [System.Collections.Generic.List[object]]::new()

    if ($Definition.Actions) {

        foreach ($Action in $Definition.Actions) {

            $Actions.Add(

                (New-Action `
                    -Definition $Action)

            )

        }

    }

    # ------------------------------------------
    # Construction du Tweak
    # ------------------------------------------

    return [PSCustomObject]@{

        # ------------------------------------------
        # Identification
        # ------------------------------------------

        ObjectType = "Tweak"

        CategoryId = $CategoryId

        CategoryName = $null

        Id = $Definition.Id

        Name = $Definition.Name

        Description = $Definition.Description

        SourceFile = $SourceFile

        # ------------------------------------------
        # Documentation
        # ------------------------------------------

        Help = Get-ObjectProperty `
            -Object $Definition `
            -Name Help

        Group = Get-ObjectProperty `
            -Object $Definition `
            -Name Group

        Tags = Get-ObjectProperty `
            -Object $Definition `
            -Name Tags `
            -Default @()

        # ------------------------------------------
        # Configuration
        # ------------------------------------------

        Default = Get-ObjectProperty `
            -Object $Definition `
            -Name Default `
            -Default $false

        Recommended = Get-ObjectProperty `
            -Object $Definition `
            -Name Recommended `
            -Default $false

        Level = Get-ObjectProperty `
            -Object $Definition `
            -Name Level `
            -Default "Official"

        Scores = Get-ObjectProperty `
            -Object $Definition `
            -Name Scores

        Supported = Get-ObjectProperty `
            -Object $Definition `
            -Name Supported

        # ------------------------------------------
        # Exécution
        # ------------------------------------------

        Reversible = Get-ObjectProperty `
            -Object $Definition `
            -Name Reversible `
            -Default $true

        RequiresRestart = Get-ObjectProperty `
            -Object $Definition `
            -Name RequiresRestart `
            -Default $false

        Actions = @($Actions)

        # ------------------------------------------
        # Etat d'exécution
        # ------------------------------------------

        Enabled = $false
        Applied   = $false
        Result    = $null
        Duration  = [timespan]::Zero

        Errors   = @()
        Warnings = @()

        Statistics = [PSCustomObject]@{

            Actions  = @($Actions).Count
            Executed = 0
            Failed   = 0

        }

    }

}