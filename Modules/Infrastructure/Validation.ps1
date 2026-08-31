# ==========================================
# Module : Validation
# Projet : PimsOS Builder
# Version : 1.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Configuration du module
# --------------------------------------------------

Set-Variable `
    -Scope Script `
    -Option ReadOnly `
    -Name AllowedActionTypes `
    -Value @(
        "Registry"
        "Package"
        "Feature"
        "Service"
        "Command"
        "ScheduledTask"
        "File"
        "Folder"
        "Environment"
        "Driver"
        "Capability"
        "Shortcut"
    )

Set-Variable `
    -Scope Script `
    -Option ReadOnly `
    -Name AllowedServiceStartupTypes `
    -Value @(
        "Automatic"
        "AutomaticDelayedStart"
        "Manual"
        "Disabled"
    )

Set-Variable `
    -Scope Script `
    -Option ReadOnly `
    -Name AllowedRegistryHives `
    -Value @(
        "SOFTWARE"
        "SYSTEM"
        "DEFAULT"
        "NTUSER"
    )

Set-Variable `
    -Scope Script `
    -Option ReadOnly `
    -Name AllowedRegistryDataTypes `
    -Value @(
        "String"
        "ExpandString"
        "MultiString"
        "Binary"
        "DWord"
        "QWord"
    )

# --------------------------------------------------
# Infrastructure
# --------------------------------------------------
# --------------------------------------------------
# Vérifie qu'une valeur est un entier
# --------------------------------------------------

function Test-IsInteger {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        $Value

    )

    return (
        $Value -is [byte]  -or
        $Value -is [int16] -or
        $Value -is [int32] -or
        $Value -is [int64]
    )

}
function New-ValidationError {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]$File,

        [Parameter(Mandatory)]
        [string]$Tweak,

        [Parameter(Mandatory)]
        [string]$Message

    )

    throw @"
==========================================
Erreur de validation
==========================================

Fichier : $File
Tweak   : $Tweak

$Message
"@

}

# --------------------------------------------------
# Validation globale
# --------------------------------------------------

function Test-TweakDefinitions {

	[CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [object[]]$Tweaks

    )

    Write-Log "Validation des définitions de tweaks..."

    Test-TweakRequiredProperties `
		-Context $Context `
		-Tweaks $Tweaks

	Test-TweakIds `
		-Context $Context `
		-Tweaks $Tweaks

	Test-TweakCategory `
		-Context $Context `
		-Tweaks $Tweaks

	Test-TweakTags `
		-Context $Context `
		-Tweaks $Tweaks

	Test-TweakLevel `
		-Context $Context `
		-Tweaks $Tweaks

	Test-TweakGroup `
		-Context $Context `
		-Tweaks $Tweaks

	Test-TweakSupported `
		-Context $Context `
		-Tweaks $Tweaks

	Test-TweakScores `
		-Context $Context `
		-Tweaks $Tweaks

	Test-TweakActions `
		-Context $Context `
		-Tweaks $Tweaks	
	
    Write-Log "Validation terminée." SUCCESS

}

# --------------------------------------------------
# Validation des tweaks
# --------------------------------------------------

function Test-TweakRequiredProperties {

	[CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [object[]]$Tweaks

    )

    Write-Log "Validation des propriétés obligatoires..."

    foreach ($Tweak in $Tweaks) {

        foreach ($Property in @(
            "Id",
            "Name",
            "Description",
            "Default",
            "Recommended",
            "Actions"
        )) {

            if (-not $Tweak.PSObject.Properties[$Property]) {

                New-ValidationError `
					-File $Tweak.SourceFile `
					-Tweak $Tweak.Id `
					-Message (
						"La propriété '{0}' est absente." -f
						$Property
					)

            }

        }

    }

    Write-Log "Propriétés obligatoires validées." SUCCESS

}
# --------------------------------------------------
# Vérifie l'unicité des identifiants
# --------------------------------------------------

function Test-TweakIds {

	[CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [object[]]$Tweaks

    )

    Write-Log "Validation des identifiants..."

    $Ids = @{}

    foreach ($Tweak in $Tweaks) {

        if ($Ids.ContainsKey($Tweak.Id)) {

            New-ValidationError `
				-File $Tweak.SourceFile `
				-Tweak $Tweak.Id `
				-Message (
					"L'identifiant '{0}' est utilisé plusieurs fois." -f
					$Tweak.Id
				)

        }

        $Ids[$Tweak.Id] = $true

    }

    Write-Log "Identifiants validés." SUCCESS

}
# --------------------------------------------------
# Validation des catégories
# --------------------------------------------------

function Test-TweakCategory {

	[CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [object[]]$Tweaks

    )

    Write-Log "Validation des catégories..."

    foreach ($Tweak in $Tweaks) {

        if (-not $Tweak.PSObject.Properties["CategoryId"]) {

            New-ValidationError `
                -File $Tweak.SourceFile `
                -Tweak $Tweak.Id `
                -Message "La propriété 'CategoryId' est absente."

        }

        if (-not (Test-CategoryExists -Id $Tweak.CategoryId)) {

            New-ValidationError `
                -File $Tweak.SourceFile `
                -Tweak $Tweak.Id `
                -Message (
                    "La catégorie '{0}' est inconnue." -f
                    $Tweak.CategoryId
                )

        }

    }

    Write-Log "Catégories validées." SUCCESS

}
# --------------------------------------------------
# Validation du niveau des tweaks
# --------------------------------------------------

function Test-TweakLevel {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [object[]]$Tweaks

    )

    Write-Log "Validation des niveaux..."

    $AllowedLevels = Get-CategoryLevels

    foreach ($Tweak in $Tweaks) {

        # ------------------------------------------
        # Facultatif
        # ------------------------------------------

        if (-not $Tweak.PSObject.Properties["Level"]) {

            continue

        }

        if ([string]::IsNullOrWhiteSpace($Tweak.Level)) {

            continue

        }

        # ------------------------------------------
        # Valeur autorisée
        # ------------------------------------------

        if ($Tweak.Level -notin $AllowedLevels) {

            New-ValidationError `
                -File $Tweak.SourceFile `
                -Tweak $Tweak.Id `
                -Message (
                    "Le niveau '{0}' n'est pas supporté." -f
                    $Tweak.Level
                )

        }

    }

    Write-Log "Niveaux validés." SUCCESS

}
# --------------------------------------------------
# Validation des groupes
# --------------------------------------------------

function Test-TweakGroup {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [object[]]$Tweaks

    )

    Write-Log "Validation des groupes..."

    foreach ($Tweak in $Tweaks) {

        # ------------------------------------------
        # Facultatif
        # ------------------------------------------

        if (-not $Tweak.PSObject.Properties["Group"]) {

            continue

        }

        if ([string]::IsNullOrWhiteSpace($Tweak.Group)) {

            continue

        }

        # ------------------------------------------
        # Groupes autorisés
        # ------------------------------------------

        $AllowedGroups = Get-CategoryGroups `
            -Id $Tweak.CategoryId

        if (@($AllowedGroups).Count -eq 0) {

            continue

        }

        # ------------------------------------------
        # Validation
        # ------------------------------------------

        if ($Tweak.Group -notin $AllowedGroups) {

            New-ValidationError `
                -File $Tweak.SourceFile `
                -Tweak $Tweak.Id `
                -Message (
                    "Le groupe '{0}' n'est pas valide pour la catégorie '{1}'." -f
                    $Tweak.Group,
                    $Tweak.CategoryId
                )

        }

    }

    Write-Log "Groupes validés." SUCCESS

}

# --------------------------------------------------
# Vérifie les tags
# --------------------------------------------------

function Test-TweakTags {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [object[]]$Tweaks

    )

    Write-Log "Validation des tags..."

    foreach ($Tweak in $Tweaks) {

        #
        # Tags facultatifs
        #

        if (-not $Tweak.PSObject.Properties["Tags"]) {

            continue

        }

        if (-not $Tweak.Tags) {

            continue

        }

        foreach ($Tag in $Tweak.Tags) {

            if ([string]::IsNullOrWhiteSpace($Tag)) {

                New-ValidationError `
                    -File $Tweak.SourceFile `
                    -Tweak $Tweak.Id `
                    -Message "Un tag est vide."

            }

        }

    }

    Write-Log "Tags validés." SUCCESS

}
# --------------------------------------------------
# Vérifie les versions Windows supportées
# --------------------------------------------------

function Test-TweakSupported {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [object[]]$Tweaks

    )

    Write-Log "Validation des versions supportées..."

    foreach ($Tweak in $Tweaks) {

        # ------------------------------------------
        # Supported facultatif
        # ------------------------------------------

        if (-not $Tweak.PSObject.Properties["Supported"]) {

            continue

        }

        if (-not $Tweak.Supported) {

            continue

        }

        # ------------------------------------------
        # MinBuild
        # ------------------------------------------

        if (-not $Tweak.Supported.PSObject.Properties["MinBuild"]) {

            New-ValidationError `
                -File $Tweak.SourceFile `
                -Tweak $Tweak.Id `
                -Message "La propriété 'Supported.MinBuild' est absente."

        }

        # ------------------------------------------
        # MaxBuild
        # ------------------------------------------

        if (-not $Tweak.Supported.PSObject.Properties["MaxBuild"]) {

            New-ValidationError `
                -File $Tweak.SourceFile `
                -Tweak $Tweak.Id `
                -Message "La propriété 'Supported.MaxBuild' est absente."

        }

        # ------------------------------------------
		# MinBuild numérique
		# ------------------------------------------

		if ($null -ne $Tweak.Supported.MinBuild -and
			$Tweak.Supported.MinBuild -isnot [int] -and
			$Tweak.Supported.MinBuild -isnot [long]) {

			New-ValidationError `
				-File $Tweak.SourceFile `
				-Tweak $Tweak.Id `
				-Message "'Supported.MinBuild' doit être un entier."

		}

		# ------------------------------------------
		# MaxBuild numérique
		# ------------------------------------------

		if ($null -ne $Tweak.Supported.MaxBuild -and
			$Tweak.Supported.MaxBuild -isnot [int] -and
			$Tweak.Supported.MaxBuild -isnot [long]) {

			New-ValidationError `
				-File $Tweak.SourceFile `
				-Tweak $Tweak.Id `
				-Message "'Supported.MaxBuild' doit être un entier ou null."

		}

        # ------------------------------------------
        # Cohérence Min / Max
        # ------------------------------------------

        if ($null -ne $Tweak.Supported.MaxBuild) {

            if ($Tweak.Supported.MinBuild -gt $Tweak.Supported.MaxBuild) {

                New-ValidationError `
                    -File $Tweak.SourceFile `
                    -Tweak $Tweak.Id `
                    -Message (
                        "MinBuild ({0}) est supérieur à MaxBuild ({1})." -f
                        $Tweak.Supported.MinBuild,
                        $Tweak.Supported.MaxBuild
                    )

            }

        }

    }

    Write-Log "Versions supportées validées." SUCCESS

}
# --------------------------------------------------
# Vérifie les scores des tweaks
# --------------------------------------------------

function Test-TweakScores {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [object[]]$Tweaks

    )

    Write-Log "Validation des scores..."

    foreach ($Tweak in $Tweaks) {

        # ------------------------------------------
        # Scores facultatifs
        # ------------------------------------------

        if (-not $Tweak.PSObject.Properties["Scores"]) {

            continue

        }

        if (-not $Tweak.Scores) {

            continue

        }

        foreach ($Property in @(
            "Privacy",
            "Performance",
            "Memory",
            "Compatibility"
        )) {

            if (-not $Tweak.Scores.PSObject.Properties[$Property]) {

                New-ValidationError `
                    -File $Tweak.SourceFile `
                    -Tweak $Tweak.Id `
                    -Message (
                        "La propriété 'Scores.{0}' est absente." -f
                        $Property
                    )

            }

            $Value = $Tweak.Scores.$Property

			if (-not (Test-IsInteger -Value $Value)) {

				New-ValidationError `
					-File $Tweak.SourceFile `
					-Tweak $Tweak.Id `
					-Message (
						"'Scores.{0}' doit être un entier." -f
						$Property
					)

			}

            if ($Value -lt 0 -or $Value -gt 5) {

                New-ValidationError `
                    -File $Tweak.SourceFile `
                    -Tweak $Tweak.Id `
                    -Message (
                        "'Scores.{0}' doit être compris entre 0 et 5." -f
                        $Property
                    )

            }

        }

    }

    Write-Log "Scores validés." SUCCESS

}
# --------------------------------------------------
# Validation des actions
# --------------------------------------------------

function Test-TweakActions {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [object[]]$Tweaks

    )

    Write-Log "Validation des actions..."

    foreach ($Tweak in $Tweaks) {

        # ------------------------------------------
        # La propriété Actions doit exister
        # ------------------------------------------

        if (-not $Tweak.PSObject.Properties["Actions"]) {

            New-ValidationError `
                -File $Tweak.SourceFile `
                -Tweak $Tweak.Id `
                -Message "La propriété 'Actions' est absente."

        }

        # ------------------------------------------
        # Au moins une action
        # ------------------------------------------

        if (@($Tweak.Actions).Count -eq 0) {

            New-ValidationError `
                -File $Tweak.SourceFile `
                -Tweak $Tweak.Id `
                -Message "Le tweak ne contient aucune action."

        }

        $ActionIds = @{}

        foreach ($Action in $Tweak.Actions) {

            foreach ($Property in @(
                "Id",
                "Type",
                "Enabled"
            )) {

                if (-not $Action.PSObject.Properties[$Property]) {

                    New-ValidationError `
                        -File $Tweak.SourceFile `
                        -Tweak $Tweak.Id `
                        -Message (
                            "Une action ne contient pas la propriété '{0}'." -f
                            $Property
                        )

                }

            }

            if ([string]::IsNullOrWhiteSpace($Action.Id)) {

                New-ValidationError `
                    -File $Tweak.SourceFile `
                    -Tweak $Tweak.Id `
                    -Message "L'identifiant de l'action est vide."

            }

            if ($ActionIds.ContainsKey($Action.Id)) {

                New-ValidationError `
                    -File $Tweak.SourceFile `
                    -Tweak $Tweak.Id `
                    -Message (
                        "L'identifiant d'action '{0}' est utilisé plusieurs fois." -f
                        $Action.Id
                    )

            }

            $ActionIds[$Action.Id] = $true

            if ($Action.Type -notin $script:AllowedActionTypes) {

                New-ValidationError `
                    -File $Tweak.SourceFile `
                    -Tweak $Tweak.Id `
                    -Message (
                        "Le type d'action '{0}' n'est pas supporté." -f
                        $Action.Type
                    )

            }

            switch ($Action.Type) {

                "Registry" {

                    Test-RegistryAction `
                        -Context $Context `
                        -Tweak $Tweak `
                        -Action $Action

                }

                "Service" {

                    Test-ServiceAction `
                        -Context $Context `
                        -Tweak $Tweak `
                        -Action $Action

                }

                default { }

            }

        }

    }

    Write-Log "Actions validées." SUCCESS

}

# --------------------------------------------------
# Vérifie une action Registry
# --------------------------------------------------

function Test-RegistryAction {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [psobject]$Tweak,

        [Parameter(Mandatory)]
        [psobject]$Action

    )

    foreach ($Property in @(
        "Hive",
        "Key",
        "Name",
        "Value",
        "DataType"
    )) {

        if (-not $Action.PSObject.Properties[$Property]) {

            New-ValidationError `
                -File $Tweak.SourceFile `
                -Tweak $Tweak.Id `
                -Message (
                    "L'action Registry '{0}' ne contient pas la propriété '{1}'." -f
                    $Action.Id,
                    $Property
                )

        }

    }

    if ($Action.Hive -notin $script:AllowedRegistryHives) {

        New-ValidationError `
            -File $Tweak.SourceFile `
            -Tweak $Tweak.Id `
            -Message (
                "La ruche '{0}' n'est pas supportée." -f
                $Action.Hive
            )

    }

    if ($Action.DataType -notin $script:AllowedRegistryDataTypes) {

        New-ValidationError `
            -File $Tweak.SourceFile `
            -Tweak $Tweak.Id `
            -Message (
                "Le type de données '{0}' n'est pas supporté." -f
                $Action.DataType
            )

    }

}

# --------------------------------------------------
# Vérifie une action Service
# --------------------------------------------------

function Test-ServiceAction {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [psobject]$Tweak,

        [Parameter(Mandatory)]
        [psobject]$Action

    )

    foreach ($Property in @(
        "Name",
        "StartupType"
    )) {

        if (-not $Action.PSObject.Properties[$Property]) {

            New-ValidationError `
                -File $Tweak.SourceFile `
                -Tweak $Tweak.Id `
                -Message (
                    "L'action Service '{0}' ne contient pas la propriété '{1}'." -f
                    $Action.Id,
                    $Property
                )

        }

    }

    if ($Action.StartupType -notin $script:AllowedServiceStartupTypes) {

        New-ValidationError `
            -File $Tweak.SourceFile `
            -Tweak $Tweak.Id `
            -Message (
                "Le StartupType '{0}' n'est pas supporté." -f
                $Action.StartupType
            )

    }

    if (
        $Action.PSObject.Properties.Match("Stop").Count -gt 0 -and
        $Action.Stop -isnot [bool]
    ) {

        New-ValidationError `
            -File $Tweak.SourceFile `
            -Tweak $Tweak.Id `
            -Message "La propriété 'Stop' doit être un booléen."

    }

}
