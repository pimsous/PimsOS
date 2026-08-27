# ==========================================
# Module : Configuration
# Projet : PimsOS Builder
# Version : 1.0.2
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Construit une configuration complète
# --------------------------------------------------

function Get-Configuration {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [string]$Profile

    )

    Write-Log "Construction de la configuration..."

    # --------------------------------------------------
    # Chargement des tweaks
    # --------------------------------------------------

    $Tweaks = Get-TweakDefinitions `
        -Context $Context

    if (@($Tweaks).Count -eq 0) {

        throw "Aucun tweak n'a été chargé."

    }

    # --------------------------------------------------
    # Validation
    # --------------------------------------------------

    $null = Test-TweakDefinitions `
        -Context $Context `
        -Tweaks $Tweaks

    # --------------------------------------------------
    # Chargement du profil
    # --------------------------------------------------

    $ProfileObject = Load-Profile `
        -Context $Context `
        -Name $Profile

    if ($null -eq $ProfileObject) {

        throw "Le profil '$Profile' n'a pas pu être chargé."

    }

    Write-Log (
        "Profil chargé : $Profile"
    ) INFO

    # --------------------------------------------------
    # Fusion
    # --------------------------------------------------

    $Configuration = Merge-Profile `
        -Context $Context `
        -Tweaks $Tweaks `
        -Profile $ProfileObject

    if ($null -eq $Configuration) {

        throw "La fusion du profil a échoué."

    }

    # --------------------------------------------------
    # Mise à jour du contexte
    # --------------------------------------------------

    $Context.Configuration = $Configuration

    $Context.BuildState.Image.TweaksLoaded = $true
    $Context.BuildState.Image.ProfileLoaded = $true
    $Context.BuildState.Image.ProfileMerged = $true
    $Context.BuildState.Image.ConfigLoaded = $true

    # --------------------------------------------------
    # Journal
    # --------------------------------------------------

    Write-Log (
        "{0} tweak(s) sélectionné(s)." -f @($Configuration).Count
    ) SUCCESS

    Write-Log "Configuration construite avec succès." SUCCESS

    return $Context

}
# --------------------------------------------------
# Retourne la configuration globale des drivers
# --------------------------------------------------

function Get-DriverConfiguration {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context

    )

    if ($null -eq $Context) {

        throw "Le contexte de build est null."

    }

    if (-not $Context.PSObject.Properties["Project"]) {

        throw "Le contexte ne contient pas la section Project."

    }

    if (-not $Context.Project.PSObject.Properties["Config"]) {

        throw "Le contexte ne contient pas la configuration globale."

    }

    $Config = $Context.Project.Config

    # --------------------------------------------------
    # Valeurs par défaut
    # --------------------------------------------------

    $Source = "None"
    $Path = $null
    $Recurse = $true
    $ForceUnsigned = $false

    # --------------------------------------------------
    # Lecture de la configuration Drivers
    # --------------------------------------------------

    if (
        $null -ne $Config.PSObject.Properties["Drivers"] -and
        $null -ne $Config.Drivers
    ) {

        $DriverConfig = $Config.Drivers

        if ($DriverConfig.PSObject.Properties["Source"]) {

            if (
                -not [string]::IsNullOrWhiteSpace(
                    [string]$DriverConfig.Source
                )
            ) {

                $Source = [string]$DriverConfig.Source

            }

        }

        if ($DriverConfig.PSObject.Properties["Path"]) {

            if (
                $null -ne $DriverConfig.Path -and
                -not [string]::IsNullOrWhiteSpace(
                    [string]$DriverConfig.Path
                )
            ) {

                $Path = [string]$DriverConfig.Path

            }

        }

        if ($DriverConfig.PSObject.Properties["Recurse"]) {

            $Recurse = [bool]$DriverConfig.Recurse

        }

        if ($DriverConfig.PSObject.Properties["ForceUnsigned"]) {

            $ForceUnsigned = [bool]$DriverConfig.ForceUnsigned

        }

    }

    # --------------------------------------------------
    # Validation de la source
    # --------------------------------------------------

    if ($Source -notin @(
        "None",
        "Folder",
        "CurrentSystem"
    )) {

        throw (
            "La source de drivers '{0}' n'est pas prise en charge." -f
            $Source
        )

    }

    # --------------------------------------------------
    # Validation du mode Folder
    # --------------------------------------------------

    if ($Source -eq "Folder") {

        if ([string]::IsNullOrWhiteSpace($Path)) {

            throw (
                "Le chemin des drivers est obligatoire lorsque la source est 'Folder'."
            )

        }

        $ResolvedPath = $Path

        if (-not [System.IO.Path]::IsPathRooted($ResolvedPath)) {

            $ResolvedPath = Join-Path `
                -Path (Get-ProjectRoot) `
                -ChildPath $ResolvedPath

        }

        if (
            -not (Test-Path `
                -LiteralPath $ResolvedPath `
                -PathType Container)
        ) {

            throw (
                "Le dossier de drivers est introuvable : {0}" -f
                $ResolvedPath
            )

        }

        $Path = (
            Resolve-Path `
                -LiteralPath $ResolvedPath `
                -ErrorAction Stop
        ).Path

    }

    # --------------------------------------------------
    # Normalisation
    # --------------------------------------------------

    return [PSCustomObject]@{

        Source        = $Source
        Path          = $Path
        Recurse       = $Recurse
        ForceUnsigned = $ForceUnsigned

    }

}