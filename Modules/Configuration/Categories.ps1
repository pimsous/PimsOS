# ==========================================
# Module : Categories
# Projet : PimsOS Builder
# Version : 1.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Cache interne
# --------------------------------------------------

$script:Categories = $null

# --------------------------------------------------
# Charge les catégories
# --------------------------------------------------

function Get-CategoryDefinitions {

    [CmdletBinding()]
    param(

        [switch]$Reload

    )

    # --------------------------------------------------
    # Cache
    # --------------------------------------------------

    if ($script:Categories -and -not $Reload) {

        return $script:Categories

    }

    Write-Log "Chargement des catégories..."

    # --------------------------------------------------
    # Localisation
    # --------------------------------------------------

    $ProjectRoot = Get-ProjectRoot

    $CategoriesPath = Join-Path `
        -Path $ProjectRoot `
        -ChildPath "Config\Categories.json"

    if (-not (Test-Path $CategoriesPath)) {

        throw (
            "Le fichier '{0}' est introuvable." -f
            $CategoriesPath
        )

    }

    # --------------------------------------------------
    # Lecture
    # --------------------------------------------------

    try {

        $Json = Get-Content `
            -Path $CategoriesPath `
            -Raw `
            -Encoding UTF8 `
            -ErrorAction Stop |
            ConvertFrom-Json

    }
    catch {

        throw (
            "Impossible de lire Categories.json.`n{0}" -f
            $_.Exception.Message
        )

    }

    # --------------------------------------------------
    # Validation minimale
    # --------------------------------------------------

    if (-not $Json.PSObject.Properties["Categories"]) {

        throw "Categories.json : section 'Categories' absente."

    }

    if (@($Json.Categories).Count -eq 0) {

        throw "Categories.json ne contient aucune catégorie."

    }

    # --------------------------------------------------
    # Mise en cache
    # --------------------------------------------------

    $script:Categories = @($Json.Categories)

    Write-Log (
        "{0} catégorie(s) chargée(s)." -f
        $script:Categories.Count
    ) SUCCESS

    return $script:Categories

}

# --------------------------------------------------
# Retourne une catégorie
# --------------------------------------------------

function Get-CategoryDefinition {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]$Id

    )

    $Categories = Get-CategoryDefinitions

    $Category = $Categories |
        Where-Object Id -EQ $Id |
        Select-Object -First 1

    if (-not $Category) {

        throw (
            "La catégorie '{0}' est introuvable." -f
            $Id
        )

    }

    return $Category

}

# --------------------------------------------------
# Retourne les groupes d'une catégorie
# --------------------------------------------------

function Get-CategoryGroups {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]$Id

    )

    $Category = Get-CategoryDefinition `
        -Id $Id

    if (-not $Category.PSObject.Properties["Groups"]) {

        return @()

    }

    if (-not $Category.Groups) {

        return @()

    }

    return @($Category.Groups)

}

# --------------------------------------------------
# Retourne les niveaux disponibles
# --------------------------------------------------

function Get-CategoryLevels {

    [CmdletBinding()]
    param()

    return @(
        "Official"
        "Advanced"
        "Experimental"
    )

}

# --------------------------------------------------
# Vérifie qu'une catégorie existe
# --------------------------------------------------

function Test-CategoryExists {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]$Id

    )

    try {

        $null = Get-CategoryDefinition `
            -Id $Id

        return $true

    }
    catch {

        return $false

    }

}