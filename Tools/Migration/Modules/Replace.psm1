<#
.SYNOPSIS
    Moteur de remplacement du framework de migration PimsOS.

.DESCRIPTION
    Ce module gère la préparation des remplacements de texte.
    Les modifications ne sont pas appliquées immédiatement,
    mais stockées afin d'être validées puis exécutées.

.NOTES

    Projet : PimsOS
    Module : Replace
    Version : 1.0.0

#>

Set-StrictMode -Version Latest

#==================================================
# Crée une nouvelle collection de remplacements
#==================================================

<#
.SYNOPSIS
    Crée une collection vide de remplacements.

.OUTPUTS
    System.Collections.Generic.List[object]

#>

function New-ReplacementCollection {

    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[object]])]

    param()

    return ,([System.Collections.Generic.List[object]]::new())

}

#==================================================
# Crée un remplacement
#==================================================

<#
.SYNOPSIS
    Crée un remplacement.

.OUTPUTS
    PSCustomObject

#>

function New-Replacement {

    [CmdletBinding()]
    [OutputType([PSCustomObject])]

    param(

        [Parameter(Mandatory)]
        [ValidateRange(0,[int]::MaxValue)]
        [int]
        $Start,

        [Parameter(Mandatory)]
        [ValidateRange(0,[int]::MaxValue)]
        [int]
        $End,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]
        $Original,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]
        $Replacement,

        [string]
        $Description = ""

    )

    if ($End -lt $Start)
    {
        throw "La position de fin doit être supérieure ou égale à la position de début."
    }

    return [PSCustomObject]@{

        PSTypeName = 'PimsOS.Migration.Replacement'

        Start       = $Start

        End         = $End

        Length      = $End - $Start

        Original    = $Original

        Replacement = $Replacement

        Description = $Description

        Applied     = $false

    }

}

#==================================================
# Ajoute un remplacement
#==================================================

<#
.SYNOPSIS
    Ajoute un remplacement à une collection.

#>

function Add-Replacement {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
		[object]
		$Collection,

        [Parameter(Mandatory)]
        [PSCustomObject]
        $Replacement

    )

    if (-not (Test-Replacement -Replacement $Replacement))
	{
		throw "Le remplacement fourni est invalide."
	}

	$Collection.Add($Replacement)

}

#==================================================
# Retourne le nombre de remplacements
#==================================================

function Get-ReplacementCount {

    [CmdletBinding()]
    [OutputType([int])]

    param(

        [Parameter(Mandatory)]
		[object]
		$Collection

    )

    return $Collection.Count

}

#==================================================
# Vérifie un remplacement
#==================================================

<#
.SYNOPSIS
    Vérifie qu'un remplacement est valide.

.OUTPUTS
    System.Boolean

#>

function Test-Replacement {

    [CmdletBinding()]
    [OutputType([bool])]

    param(

        [Parameter(Mandatory)]
        [PSCustomObject]
        $Replacement

    )


    $RequiredProperties = @(
		'Start',
		'End',
		'Length',
		'Original',
		'Replacement',
		'Description',
		'Applied'
	)

	foreach ($Property in $RequiredProperties)
	{
		if ($Replacement.PSObject.Properties[$Property] -eq $null)
		{
			return $false
		}
	}

	if ($Replacement.Start -lt 0)
	{
		return $false
	}

	if ($Replacement.End -lt $Replacement.Start)
	{
		return $false
	}

	if ($Replacement.Length -ne ($Replacement.End - $Replacement.Start))
	{
		return $false
	}

	if ($null -eq $Replacement.Replacement)
	{
		return $false
	}

	return $true


}

#==================================================
# Vérifie une collection de remplacements
#==================================================

<#
.SYNOPSIS
    Vérifie qu'une collection est valide.

.DESCRIPTION
    Vérifie :

        - chaque remplacement

        - les chevauchements

.OUTPUTS
    System.Boolean

#>

function Test-Replacements {

    [CmdletBinding()]
    [OutputType([bool])]

    param(

        [Parameter(Mandatory)]
		[AllowEmptyCollection()]
		[System.Collections.Generic.List[object]]
		$Collection

    )

    foreach ($Replacement in $Collection)
    {
        if (-not (Test-Replacement -Replacement $Replacement))
        {
            return $false
        }
    }

    $Sorted = @(
		$Collection |
			Sort-Object Start
	)

    for ($i = 1; $i -lt $Sorted.Count; $i++)
    {
        if ($Sorted[$i].Start -lt $Sorted[$i-1].End)
        {
            return $false
        }
    }

    return $true

}

#==================================================
# Trie les remplacements
#==================================================

<#
.SYNOPSIS
    Trie les remplacements par ordre décroissant.

.DESCRIPTION
    Les remplacements sont triés du dernier vers le premier
    afin de préserver les offsets lors de l'application.

.OUTPUTS
    PSCustomObject[]

#>

function Sort-Replacements {

    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]

    param(

        [Parameter(Mandatory)]
		[AllowEmptyCollection()]
		[System.Collections.Generic.List[object]]
		$Collection

    )

    return $Collection |
        Sort-Object `
			@{Expression='Start';Descending=$true},
			@{Expression='End';Descending=$true}

}

#==================================================
# Applique les remplacements en mémoire
#==================================================

<#
.SYNOPSIS
    Produit le nouveau contenu du fichier.

.OUTPUTS
    System.String

#>

function Convert-Replacements {

    [CmdletBinding()]
    [OutputType([string])]

    param(

        [Parameter(Mandatory)]
        [string]
        $Content,

        [Parameter(Mandatory)]
		[AllowEmptyCollection()]
		[System.Collections.Generic.List[object]]
		$Collection

    )

    if (-not (Test-Replacements -Collection $Collection))
    {
        throw "La collection de remplacements est invalide."
    }

    $Result = $Content

    foreach ($Replacement in (Sort-Replacements -Collection $Collection))
    {
        if ($Replacement.End -gt $Result.Length)
        {
            throw "Le remplacement dépasse la taille du contenu."
        }

        $Current = $Result.Substring(
            $Replacement.Start,
            $Replacement.Length
        )

        if ($Current -ne $Replacement.Original)
		{
			$Message = @(
				"Le remplacement ne peut pas être appliqué."
				""
				"Description : $($Replacement.Description)"
				""
				"Position : $($Replacement.Start)"
				""
				"Attendu :"
				$Replacement.Original
				""
				"Trouvé :"
				$Current
			) -join [Environment]::NewLine

			throw $Message
		}

        $Result = $Result.Remove(
            $Replacement.Start,
            $Replacement.Length
        ).Insert(
            $Replacement.Start,
            $Replacement.Replacement
        )
    }

    return $Result

}

#==================================================
# Applique les remplacements à un fichier
#==================================================

<#
.SYNOPSIS
    Applique les remplacements sur un fichier.

.DESCRIPTION
    Lit le contenu du fichier, applique les remplacements
    puis réécrit le fichier sur le disque.
#>

function Invoke-Replacements {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [System.IO.FileInfo]
        $File,

        [Parameter(Mandatory)]
        [System.Collections.Generic.List[object]]
        $Collection

    )
	
	if (-not $File.Exists)
	{
		throw "Le fichier '$($File.FullName)' est introuvable."
	}

    $Content = Get-Content `
		-Path $File.FullName `
		-Raw

	$NewContent = Convert-Replacements `
		-Content $Content `
		-Collection $Collection

	[System.IO.File]::WriteAllText(
		$File.FullName,
		$NewContent,
		[System.Text.UTF8Encoding]::new($false)
	)

    foreach($Replacement in $Collection)
    {
        $Replacement.Applied = $true
    }

}
#==============================================================================
# Trie les remplacements
#==============================================================================



#==============================================================================
# Retourne les remplacements triés par ordre croissant
#==============================================================================

function Get-Replacements {

    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]

    param(

        [Parameter(Mandatory)]
        [System.Collections.Generic.List[object]]
        $Collection

    )

    return $Collection |
        Sort-Object Start, End

}

#==============================================================================
# Retourne les remplacements déjà appliqués
#==============================================================================

function Get-AppliedReplacements {

    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]

    param(

        [Parameter(Mandatory)]
        [System.Collections.Generic.List[object]]
        $Collection

    )

    return $Collection |
        Where-Object Applied

}

#==============================================================================
# Retourne les remplacements non appliqués
#==============================================================================

function Get-PendingReplacements {

    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]

    param(

        [Parameter(Mandatory)]
        [System.Collections.Generic.List[object]]
        $Collection

    )

    return $Collection |
        Where-Object { -not $_.Applied }

}

#==============================================================================
# Remet les remplacements à l'état initial
#==============================================================================

function Reset-Replacements {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [System.Collections.Generic.List[object]]
        $Collection

    )

    foreach ($Replacement in $Collection)
    {
        $Replacement.Applied = $false
    }

}

#==============================================================================
# Retourne des statistiques
#==============================================================================

function Get-ReplacementStatistics {

    [CmdletBinding()]
    [OutputType([PSCustomObject])]

    param(

        [Parameter(Mandatory)]
        [System.Collections.Generic.List[object]]
        $Collection

    )

    $Applied = Get-AppliedReplacements -Collection $Collection

    $Pending = Get-PendingReplacements -Collection $Collection

    [PSCustomObject]@{

        Total = $Collection.Count

        Applied = $Applied.Count

        Pending = $Pending.Count

        Valid = Test-Replacements -Collection $Collection

    }

}

#==============================================================================
# Lit le contenu d'un fichier
#==============================================================================

function Get-FileContent {

    [CmdletBinding()]
    [OutputType([string])]

    param(

        [Parameter(Mandatory)]
        [System.IO.FileInfo]
        $File

    )

    if (-not $File.Exists)
    {
        throw "Le fichier '$($File.FullName)' est introuvable."
    }

    return Get-Content `
        -LiteralPath $File.FullName `
        -Raw

}

#==============================================================================
# Écrit le contenu d'un fichier en UTF-8 sans BOM
#==============================================================================

function Set-FileContent {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [System.IO.FileInfo]
        $File,

        [Parameter(Mandatory)]
        [string]
        $Content

    )

    [System.IO.File]::WriteAllText(

        $File.FullName,

        $Content,

        [System.Text.UTF8Encoding]::new($false)

    )

}
#==============================================================================
# Applique les remplacements en mémoire
#==============================================================================

function Convert-Replacements {

    [CmdletBinding()]
    [OutputType([string])]

    param(

        [Parameter(Mandatory)]
        [string]
        $Content,

        [Parameter(Mandatory)]
		[AllowEmptyCollection()]
		[System.Collections.Generic.List[object]]
		$Collection

    )

    if (-not (Test-Replacements -Collection $Collection))
    {
        throw "La collection de remplacements est invalide."
    }

    $Result = $Content

    foreach ($Replacement in (Sort-Replacements -Collection $Collection))
    {
        if ($Replacement.End -gt $Result.Length)
        {
            throw "Le remplacement dépasse la taille du contenu."
        }

        $Current = $Result.Substring(
            $Replacement.Start,
            $Replacement.Length
        )

        if ($Current -ne $Replacement.Original)
        {
            $Message = @(
                "Le remplacement ne peut pas être appliqué."
                ""
                "Description : $($Replacement.Description)"
                ""
                "Position : $($Replacement.Start)"
                ""
                "Attendu :"
                $Replacement.Original
                ""
                "Trouvé :"
                $Current
            ) -join [Environment]::NewLine

            throw $Message
        }

        $Result = $Result.Remove(
            $Replacement.Start,
            $Replacement.Length
        ).Insert(
            $Replacement.Start,
            $Replacement.Replacement
        )
    }

    return $Result

}

#==============================================================================
# Applique les remplacements sur un fichier
#==============================================================================

function Invoke-Replacements {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [System.IO.FileInfo]
        $File,

        [Parameter(Mandatory)]
        [System.Collections.Generic.List[object]]
        $Collection

    )

    if (-not $File.Exists)
    {
        throw "Le fichier '$($File.FullName)' est introuvable."
    }

    if (-not (Test-Replacements -Collection $Collection))
    {
        throw "La collection de remplacements est invalide."
    }

    $Content = Get-FileContent -File $File

    $NewContent = Convert-Replacements `
        -Content $Content `
        -Collection $Collection

    Set-FileContent `
        -File $File `
        -Content $NewContent

    foreach ($Replacement in $Collection)
    {
        $Replacement.Applied = $true
    }

}

#==============================================================================
# Export
#==============================================================================

Export-ModuleMember `
    -Function `
        New-ReplacementCollection,
        New-Replacement,
        Add-Replacement,
        Remove-Replacement,
        Clear-Replacements,
        Get-ReplacementCount,
        Find-Replacement,
        Test-Replacement,
        Test-Replacements,
        Sort-Replacements,
        Get-Replacements,
        Get-AppliedReplacements,
        Get-PendingReplacements,
        Reset-Replacements,
        Get-ReplacementStatistics,
        Get-FileContent,
        Set-FileContent,
        Convert-Replacements,
        Invoke-Replacements