# ==========================================
# Module : Tweak
# Projet : PimsOS Builder
# Version : 1.0.1
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

    if ($null -eq $Definition) {
        throw "La définition de l'action est null."
    }

    if (-not $Definition.PSObject.Properties["Id"]) {
        throw "Une action ne possède pas de propriété 'Id'."
    }

    if (-not $Definition.PSObject.Properties["Type"]) {
        throw "L'action '$($Definition.Id)' ne possède pas de propriété 'Type'."
    }

    # Conserver toutes les propriétés fonctionnelles de la définition.
    # Les moteurs d'actions sont ainsi extensibles sans devoir modifier
    # ce constructeur à chaque nouveau provider ou type d'action.
    $Action = $Definition.PSObject.Copy()

    $Action | Add-Member `
        -MemberType NoteProperty `
        -Name ObjectType `
        -Value "Action" `
        -Force

    # Valeurs normalisées communes à toutes les actions.
    if (-not $Action.PSObject.Properties["Enabled"]) {
        $Action | Add-Member -MemberType NoteProperty -Name Enabled -Value $true
    }

    if (-not $Action.PSObject.Properties["RequiresRestart"]) {
        $Action | Add-Member -MemberType NoteProperty -Name RequiresRestart -Value $false
    }

    if (-not $Action.PSObject.Properties["ContinueOnError"]) {
        $Action | Add-Member -MemberType NoteProperty -Name ContinueOnError -Value $false
    }

	if (-not $Action.PSObject.Properties["Stop"]) {
		$Action | Add-Member `
			-MemberType NoteProperty `
			-Name Stop `
			-Value $false
	}

	if (-not $Action.PSObject.Properties["Wait"]) {
		$Action | Add-Member `
			-MemberType NoteProperty `
			-Name Wait `
			-Value $true
	}

	if (-not $Action.PSObject.Properties["RunAs"]) {
		$Action | Add-Member `
			-MemberType NoteProperty `
			-Name RunAs `
			-Value $false
	}

    # Etat runtime : ne jamais écraser une valeur fournie par un test
    # ou une couche appelante.
    $RuntimeProperties = @{
        Executed = $false
        Success  = $false
        Duration = [timespan]::Zero
        Error    = $null
    }

    foreach ($PropertyName in $RuntimeProperties.Keys) {
        if (-not $Action.PSObject.Properties[$PropertyName]) {
            $Action | Add-Member `
                -MemberType NoteProperty `
                -Name $PropertyName `
                -Value $RuntimeProperties[$PropertyName]
        }
    }

    return $Action

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

        Risk = Get-ObjectProperty `
            -Object $Definition `
            -Name Risk `
            -Default "Optional"

        Impact = Get-ObjectProperty `
            -Object $Definition `
            -Name Impact `
            -Default ""

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