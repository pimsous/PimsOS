# ==========================================
# Module : DriverManager
# Projet : PimsOS Builder
# Version : 1.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Gestionnaires disponibles
# --------------------------------------------------

$script:DriverProviders = @{

    DISM = "Invoke-DismDriver"

    PNP  = "Invoke-PnpDriver"

}

# --------------------------------------------------
# Provider DISM
# --------------------------------------------------

function Invoke-DismDriver {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [psobject]$Action

    )

    # --------------------------------------------------
    # Validation du contexte
    # --------------------------------------------------

    if ($null -eq $Context) {

        throw "Le contexte de build est null."

    }

    if (-not $Context.PSObject.Properties["WIM"]) {

        throw "Le contexte ne contient pas la section WIM."

    }

    if (-not $Context.WIM.PSObject.Properties["Mount"]) {

        throw "Le contexte ne contient pas la section WIM.Mount."

    }

    if (-not $Context.WIM.Mount.PSObject.Properties["Path"]) {

        throw "Le contexte ne contient pas WIM.Mount.Path."

    }

    $MountPath = [string]$Context.WIM.Mount.Path

    if ([string]::IsNullOrWhiteSpace($MountPath)) {

        throw "Aucun chemin de montage WIM n'est défini."

    }

    if (-not (Test-Path -LiteralPath $MountPath -PathType Container)) {

        throw (
            "Le dossier de montage WIM est introuvable : {0}" -f
            $MountPath
        )

    }

    # --------------------------------------------------
    # Validation de l'action
    # --------------------------------------------------

    if ($null -eq $Action) {

        throw "L'action Driver est null."

    }

    if (
        $null -eq $Action.PSObject.Properties["Name"] -or
        [string]::IsNullOrWhiteSpace([string]$Action.Name)
    ) {

        throw "Le nom du pilote est obligatoire."

    }

    if (
        $null -eq $Action.PSObject.Properties["Source"] -or
        [string]::IsNullOrWhiteSpace([string]$Action.Source)
    ) {

        throw "La source du pilote est obligatoire."

    }

    # --------------------------------------------------
    # Options
    # --------------------------------------------------

    $Parameters = @{

        MountPath  = $MountPath
        DriverPath = [string]$Action.Source

    }

    if (
        $Action.PSObject.Properties.Match("Recurse").Count -gt 0 -and
        [bool]$Action.Recurse
    ) {

        $Parameters.Recurse = $true

    }

    if (
        $Action.PSObject.Properties.Match("ForceUnsigned").Count -gt 0 -and
        [bool]$Action.ForceUnsigned
    ) {

        $Parameters.ForceUnsigned = $true

    }

    # --------------------------------------------------
    # Journal
    # --------------------------------------------------

    Write-Log (
        "Driver DISM : {0}" -f
        $Action.Name
    ) INFO

    Write-Log (
        "Source : {0}" -f
        $Action.Source
    ) INFO

    Write-Log (
        "Montage WIM : {0}" -f
        $MountPath
    ) INFO

    # --------------------------------------------------
    # Injection
    # --------------------------------------------------

    try {

        $null = Add-DismDriver `
            @Parameters `
            -ErrorAction Stop

        Write-Log (
            "Pilote '{0}' injecté avec succès." -f
            $Action.Name
        ) SUCCESS

        return $Context

    }
    catch {

        throw (
            "Erreur lors de l'injection DISM du pilote '{0}'.`r`n{1}" -f
            $Action.Name,
            $_.Exception.Message
        )

    }

}

# --------------------------------------------------
# Applique un pilote
# --------------------------------------------------

function Invoke-Driver {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [psobject]$Action

    )

    # --------------------------------------------------
    # Validation
    # --------------------------------------------------

    if ([string]::IsNullOrWhiteSpace($Action.Provider)) {

        throw "Le fournisseur du pilote est obligatoire."

    }

    if ([string]::IsNullOrWhiteSpace($Action.Source)) {

        throw "La source du pilote est obligatoire."

    }

    # --------------------------------------------------
    # Recherche du gestionnaire
    # --------------------------------------------------

    if (-not $script:DriverProviders.ContainsKey($Action.Provider)) {

        throw (
            "Le fournisseur de pilotes '{0}' n'est pas pris en charge." -f
            $Action.Provider
        )

    }

    $Handler = $script:DriverProviders[$Action.Provider]

    if (-not (Get-Command `
        -Name $Handler `
        -ErrorAction SilentlyContinue)) {

        throw (
            "Le gestionnaire '{0}' est introuvable." -f
            $Handler
        )

    }

    Write-Log (
        "Driver Provider : {0}" -f
        $Action.Provider
    )

    Write-Log (
        "Source : {0}" -f
        $Action.Source
    )

    # --------------------------------------------------
    # Exécution
    # --------------------------------------------------

    return (& $Handler `
        -Context $Context `
        -Action $Action)

}

# --------------------------------------------------
# Retourne les fournisseurs disponibles
# --------------------------------------------------

function Get-DriverProviders {

    [CmdletBinding()]
    param()

    return $script:DriverProviders.Keys |
        Sort-Object

}

# --------------------------------------------------
# Enregistre un nouveau fournisseur
# --------------------------------------------------

function Register-DriverProvider {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Handler

    )

    if (-not (Get-Command `
        -Name $Handler `
        -ErrorAction SilentlyContinue)) {

        throw (
            "Le gestionnaire '{0}' est introuvable." -f
            $Handler
        )

    }

    $script:DriverProviders[$Name] = $Handler

}

# --------------------------------------------------
# Réinitialise les fournisseurs
# Utilisé par les tests
# --------------------------------------------------

function Reset-DriverProviders {

    [CmdletBinding()]
    param()

    $script:DriverProviders = @{

        DISM = "Invoke-DismDriver"

        PNP  = "Invoke-PnpDriver"

    }

}