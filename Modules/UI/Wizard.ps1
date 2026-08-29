# ==========================================
# Module : UI / Wizard
# Projet : PimsOS Builder
# Version : 0.4.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

function Clear-PimsOSScreen {

    if ($env:GITHUB_ACTIONS -eq "true") {
        return
    }

    Clear-Host
}



function Show-PimsOSBuildWizard {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$Context
    )

    while ($true) {

        Clear-PimsOSScreen
        Write-Host ""
        Write-Host "==================================================" -ForegroundColor Cyan
        Write-Host "                 PimsOS Builder" -ForegroundColor Cyan
        Write-Host "                    Assistant" -ForegroundColor Cyan
        Write-Host "==================================================" -ForegroundColor Cyan
        Write-Host ""

        Write-Host "Configuration actuelle" -ForegroundColor Yellow
        Write-Host "------------------------------------------"
        Write-Host ("Profil       : {0}" -f $Context.ConfigurationProfile)
        Write-Host ("Créer ISO    : {0}" -f $Context.Build.CreateISO)
        Write-Host ("Rapport      : {0}" -f $Context.Build.CreateReport)
        Write-Host ("Dry Run      : {0}" -f $Context.Build.DryRun)
        Write-Host ""

        Write-Host "[1] Choisir le profil"
        Write-Host "[2] Options du Build"
        Write-Host "[3] Configuration des drivers"
        Write-Host "[4] Afficher le résumé"
        Write-Host "[5] Valider et continuer" -ForegroundColor Green
        Write-Host "[0] Annuler" -ForegroundColor Red
        Write-Host ""

        $Choice = Read-Host "Votre choix"

        switch ($Choice) {

            "1" {
                Show-PimsOSProfileMenu `
                    -Context $Context
            }

            "2" {
                Show-PimsOSBuildOptions `
                    -Context $Context
            }

            "3" {
                Show-PimsOSDriverMenu `
                    -Context $Context
            }

            "4" {
                Show-PimsOSBuildSummary `
                    -Context $Context
            }

            "5" {
                Write-Log "Configuration du Build validée." SUCCESS
                return $Context
            }

            "0" {
                throw "Build annulé par l'utilisateur."
            }

            default {
                Write-Host ""
                Write-Host "Choix invalide." -ForegroundColor Red
                $null = Read-Host "Appuyez sur Entrée"
            }
        }
    }
}


function Show-PimsOSProfileMenu {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$Context
    )

    Clear-PimsOSScreen
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "                 Profil PimsOS" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host ""

    $ProfilesRoot = Join-Path `
        -Path (Get-ProjectRoot) `
        -ChildPath "Config\Profiles"

    if (-not (Test-Path -LiteralPath $ProfilesRoot)) {

        Write-Host "Aucun dossier de profils trouvé :" -ForegroundColor Yellow
        Write-Host $ProfilesRoot
        Write-Host ""

        $null = Read-Host "Appuyez sur Entrée"
        return
    }

    $Profiles = @(
        Get-ChildItem `
            -LiteralPath $ProfilesRoot `
            -File `
            -Recurse `
            -Include *.json,*.psd1,*.ps1 `
            -ErrorAction SilentlyContinue
    )

    if ($Profiles.Count -eq 0) {

        Write-Host "Aucun profil disponible." -ForegroundColor Yellow
        Write-Host ""

        $null = Read-Host "Appuyez sur Entrée"
        return
    }

    for ($Index = 0; $Index -lt $Profiles.Count; $Index++) {

        $RelativePath = $Profiles[$Index].FullName.Substring(
            $ProfilesRoot.Length
        ).TrimStart(
            '\'
        )

        Write-Host (
            "[{0}] {1}" -f
            ($Index + 1),
            $RelativePath
        )
    }

    Write-Host ""
    Write-Host "[0] Retour"
    Write-Host ""

    $Choice = Read-Host "Profil"

    if ($Choice -eq "0") {
        return
    }

    $SelectedIndex = 0

    if (
        -not [int]::TryParse(
            $Choice,
            [ref]$SelectedIndex
        )
    ) {
        Write-Host "Choix invalide." -ForegroundColor Red
        $null = Read-Host "Appuyez sur Entrée"
        return
    }

    $SelectedIndex--

    if (
        $SelectedIndex -lt 0 -or
        $SelectedIndex -ge $Profiles.Count
    ) {
        Write-Host "Choix invalide." -ForegroundColor Red
        $null = Read-Host "Appuyez sur Entrée"
        return
    }

    $SelectedProfile = $Profiles[$SelectedIndex].FullName.Substring(
        (Get-ProjectRoot).Length
    ).TrimStart('\')

    $Context.ConfigurationProfile = $SelectedProfile

    Write-Log (
        "Profil sélectionné : {0}" -f
        $SelectedProfile
    ) SUCCESS

    $null = Read-Host "Appuyez sur Entrée"
}


function Show-PimsOSBuildOptions {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$Context
    )

    while ($true) {

        Clear-PimsOSScreen
        Write-Host ""
        Write-Host "==================================================" -ForegroundColor Cyan
        Write-Host "                 Options du Build" -ForegroundColor Cyan
        Write-Host "==================================================" -ForegroundColor Cyan
        Write-Host ""

        Write-Host "[1] Créer l'ISO       : $($Context.Build.CreateISO)"
        Write-Host "[2] Créer le rapport  : $($Context.Build.CreateReport)"
        Write-Host "[3] Dry Run            : $($Context.Build.DryRun)"
        Write-Host "[0] Retour"
        Write-Host ""

        $Choice = Read-Host "Votre choix"

        switch ($Choice) {

            "1" {
                $Context.Build.CreateISO =
                    -not [bool]$Context.Build.CreateISO
            }

            "2" {
                $Context.Build.CreateReport =
                    -not [bool]$Context.Build.CreateReport
            }

            "3" {
                $Context.Build.DryRun =
                    -not [bool]$Context.Build.DryRun
            }

            "0" {
                return
            }

            default {
                Write-Host "Choix invalide." -ForegroundColor Red
                $null = Read-Host "Appuyez sur Entrée"
            }
        }
    }
}


function Show-PimsOSDriverMenu {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$Context
    )

    Clear-PimsOSScreen
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "                 Drivers PimsOS" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host ""

    $DriverPath = Join-Path `
        -Path (Get-ProjectRoot) `
        -ChildPath "Drivers"

    Write-Host "[1] Aucun driver"
    Write-Host "[2] Importer les drivers du poste actuel"
    Write-Host "[3] Utiliser les drivers du dossier projet"
    Write-Host "[0] Retour"
    Write-Host ""

    Write-Host (
        "Dossier projet : {0}" -f
        $DriverPath
    ) -ForegroundColor DarkGray

    Write-Host ""

    $Choice = Read-Host "Votre choix"

    switch ($Choice) {

        # --------------------------------------------------
        # Aucun driver
        # --------------------------------------------------

        "1" {

            $Context.Configuration.Drivers =
                [pscustomobject]@{

                    Source        = "None"
                    Path          = $null
                    Recurse       = $true
                    ForceUnsigned = $false

                }

            Write-Log `
                "Configuration drivers : aucun driver." `
                SUCCESS
        }

        # --------------------------------------------------
        # Drivers du système actuel
        # --------------------------------------------------

        "2" {

            $Context.Configuration.Drivers =
                [pscustomobject]@{

                    Source        = "CurrentSystem"
                    Path          = $null
                    Recurse       = $true
                    ForceUnsigned = $false

                }

            Write-Log `
                "Configuration drivers : système actuel." `
                SUCCESS
        }

        # --------------------------------------------------
        # Drivers du dossier projet
        # --------------------------------------------------

        "3" {

            if (
                -not (
                    Test-Path `
                        -LiteralPath $DriverPath `
                        -PathType Container
                )
            ) {

                Write-Host ""
                Write-Host (
                    "Le dossier drivers est introuvable : {0}" -f
                    $DriverPath
                ) -ForegroundColor Red

                $null = Read-Host "Appuyez sur Entrée"
                return
            }

            $Context.Configuration.Drivers =
                [pscustomobject]@{

                    Source        = "Folder"
                    Path          = $DriverPath
                    Recurse       = $true
                    ForceUnsigned = $false

                }

            Write-Log (
                "Configuration drivers : dossier projet ({0})." -f
                $DriverPath
            ) SUCCESS
        }

        # --------------------------------------------------
        # Retour
        # --------------------------------------------------

        "0" {
            return
        }

        # --------------------------------------------------
        # Choix invalide
        # --------------------------------------------------

        default {

            Write-Host ""
            Write-Host "Choix invalide." -ForegroundColor Red
            $null = Read-Host "Appuyez sur Entrée"
            return
        }
    }

    Write-Host ""
	$null = Read-Host "Appuyez sur Entrée"
}


function Show-PimsOSBuildSummary {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$Context
    )

    Clear-PimsOSScreen
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "              Résumé du Build" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host ""

    Write-Host ("Projet       : {0}" -f $Context.Project.Name)
    Write-Host ("Version      : {0}" -f $Context.Project.Version)
    Write-Host ("Windows      : {0}" -f $Context.Project.Windows.Release)
    Write-Host ("Build        : {0}" -f $Context.Project.Windows.Build)
    Write-Host ""

    Write-Host "Configuration" -ForegroundColor Yellow
    Write-Host "------------------------------------------"
    Write-Host ("Profil       : {0}" -f $Context.ConfigurationProfile)
    Write-Host ""

    Write-Host "Build" -ForegroundColor Yellow
    Write-Host "------------------------------------------"
    Write-Host ("Créer ISO    : {0}" -f $Context.Build.CreateISO)
    Write-Host ("Rapport      : {0}" -f $Context.Build.CreateReport)
    Write-Host ("Dry Run      : {0}" -f $Context.Build.DryRun)
    Write-Host ""

    if ($null -ne $Context.Configuration) {

        if (
            $Context.Configuration.PSObject.Properties.Name `
                -contains "Drivers"
        ) {

            Write-Host "Drivers" -ForegroundColor Yellow
            Write-Host "------------------------------------------"

            Write-Host (
                "Source       : {0}" -f
                $Context.Configuration.Drivers.Source
            )

            if (
                $Context.Configuration.Drivers.PSObject.Properties.Name `
                    -contains "Path"
            ) {
                Write-Host (
                    "Chemin       : {0}" -f
                    $Context.Configuration.Drivers.Path
                )
            }

            Write-Host ""
        }
    }

    $null = Read-Host "Appuyez sur Entrée"
}



