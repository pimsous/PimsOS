# ==========================================
# Module : UI / Wizard
# Projet : PimsOS Builder
# Version : 0.4.2
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

        Write-Host (
            "Profil       : {0}" -f
            $Context.ConfigurationProfile
        )

        Write-Host (
            "Tweaks       : {0}" -f
            @(Get-PimsOSTweakConfiguration -Context $Context).Count
        )

        Write-Host (
            "Créer ISO    : {0}" -f
            $Context.Build.CreateISO
        )

        Write-Host (
            "Rapport      : {0}" -f
            $Context.Build.CreateReport
        )

        Write-Host (
            "Dry Run      : {0}" -f
            $Context.Build.DryRun
        )

        Write-Host ""

        Write-Host "[1] Choisir le profil"
        Write-Host "[2] Configurer les Tweaks"
        Write-Host "[3] Options du Build"
        Write-Host "[4] Configuration des drivers"
        Write-Host "[5] Afficher le résumé"
        Write-Host "[6] Valider et continuer" -ForegroundColor Green
        Write-Host "[0] Annuler" -ForegroundColor Red
        Write-Host ""

        $Choice = Read-Host "Votre choix"

        switch ($Choice) {

            "1" {

                Show-PimsOSProfileMenu `
                    -Context $Context
            }

            "2" {

                Show-PimsOSTweakMenu `
                    -Context $Context
            }

            "3" {

                Show-PimsOSBuildOptions `
                    -Context $Context
            }

            "4" {

                Show-PimsOSDriverMenu `
                    -Context $Context
            }

            "5" {

                Show-PimsOSBuildSummary `
                    -Context $Context
            }

            "6" {

                Write-Log `
                    "Configuration du Build validée." `
                    SUCCESS

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


function Get-PimsOSTweakConfiguration {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context

    )

    if ($null -eq $Context.Configuration) {
        return @()
    }

    $Items = @(
        $Context.Configuration
    )

    # Tolère une ancienne configuration stockée comme List[object].
    if (
        $Items.Count -eq 1 -and
        $Items[0] -is [System.Collections.IList]
    ) {
        $Items = @(
            $Items[0]
        )

        if ($Items[0] -is [System.Collections.IList]) {
            $Items = @(
                $Items[0].ToArray()
            )
        }
    }

    $ValidItems = [System.Collections.Generic.List[object]]::new()

    foreach ($Item in $Items) {

        if (
            $null -ne $Item -and
            $Item.PSObject.Properties.Name -contains "Id" -and
            $Item.PSObject.Properties.Name -contains "Name" -and
            $Item.PSObject.Properties.Name -contains "Enabled"
        ) {
            $ValidItems.Add($Item)
        }

    }

    return @(
        $ValidItems.ToArray()
    )
}


function Show-PimsOSTweakMenu {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context

    )

    # --------------------------------------------------
    # Préparation de la configuration des Tweaks
    # --------------------------------------------------

    $Configuration = @(
        Get-PimsOSTweakConfiguration -Context $Context
    )

    # Ne pas reconstruire la configuration à chaque ouverture du menu :
    # les choix effectués par l'utilisateur doivent rester en mémoire.
    if ($Configuration.Count -eq 0) {

        if ($Context.ConfigurationProfile -eq "Custom") {

            Initialize-PimsOSCustomConfiguration `
                -Context $Context | Out-Null

        }
        else {

            $Context = Get-Configuration `
                -Context $Context `
                -Profile $Context.ConfigurationProfile

        }

        $Configuration = @(
            Get-PimsOSTweakConfiguration -Context $Context
        )

    }

    if ($Configuration.Count -eq 0) {

        throw "La configuration des Tweaks est vide ou invalide."

    }

    # --------------------------------------------------
    # Boucle du menu
    # --------------------------------------------------

    while ($true) {

        Clear-PimsOSScreen

        Write-Host ""
        Write-Host "==================================================" -ForegroundColor Cyan
        Write-Host "                   Tweaks PimsOS" -ForegroundColor Cyan
        Write-Host "==================================================" -ForegroundColor Cyan
        Write-Host ""

        # --------------------------------------------------
        # Affichage par catégorie
        # --------------------------------------------------

        $Categories = @(
            $Configuration |
                Group-Object -Property CategoryId |
                Sort-Object Name
        )

        $DisplayedTweaks = [System.Collections.Generic.List[object]]::new()
        $Index = 1

        foreach ($CategoryGroup in $Categories) {

            Write-Host ""

            Write-Host (
                "{0} ──────────────────────────────────────────────" -f
                $CategoryGroup.Name.ToUpper()
            ) -ForegroundColor Cyan

            foreach ($Tweak in $CategoryGroup.Group) {

                $DisplayedTweaks.Add($Tweak)

				if ($Tweak.PSObject.Properties.Name -contains "Enabled") {

					if ($Tweak.Enabled) {
						$Mark = "☑"
					}
					else {
						$Mark = "☐"
					}

				}
				else {

					throw (
						"Tweak sans propriété 'Enabled' : Id='{0}', Name='{1}', Type='{2}'" -f
						$(if ($Tweak.PSObject.Properties["Id"]) { $Tweak.Id } else { "<absent>" }),
						$(if ($Tweak.PSObject.Properties["Name"]) { $Tweak.Name } else { "<absent>" }),
						$Tweak.GetType().FullName
					)

				}

                Write-Host ""

                Write-Host (
                    "[{0}] {1} {2}" -f
                    $Index,
                    $Mark,
                    $Tweak.Name
                )

                if (
                    $Tweak.PSObject.Properties.Name `
                        -contains "Description" -and
                    -not [string]::IsNullOrWhiteSpace(
                        $Tweak.Description
                    )
                ) {

                    Write-Host (
                        "    {0}" -f
                        $Tweak.Description
                    ) -ForegroundColor DarkGray
                }

                $Risk = "N/A"

                if (
                    $Tweak.PSObject.Properties.Name `
                        -contains "Risk"
                ) {

                    $Risk = $Tweak.Risk
                }

                $Reversible = "N/A"

                if (
                    $Tweak.PSObject.Properties.Name `
                        -contains "Reversible"
                ) {

                    $Reversible = $Tweak.Reversible
                }

                $Restart = "N/A"

                if (
                    $Tweak.PSObject.Properties.Name `
                        -contains "RequiresRestart"
                ) {

                    $Restart = $Tweak.RequiresRestart
                }

                Write-Host (
                    "    Risque       : {0}" -f
                    $Risk
                ) -ForegroundColor DarkGray

                Write-Host (
                    "    Réversible   : {0}" -f
                    $Reversible
                ) -ForegroundColor DarkGray

                Write-Host (
                    "    Redémarrage  : {0}" -f
                    $Restart
                ) -ForegroundColor DarkGray

                if (
                    $Tweak.PSObject.Properties.Name `
                        -contains "Impact" -and
                    -not [string]::IsNullOrWhiteSpace(
                        $Tweak.Impact
                    )
                ) {

                    Write-Host (
                        "    Impact       : {0}" -f
                        $Tweak.Impact
                    ) -ForegroundColor DarkGray
                }

                $Index++
            }
        }

        # --------------------------------------------------
        # Résumé
        # --------------------------------------------------

        $EnabledCount = @(
            $Configuration |
                Where-Object Enabled
        ).Count

        Write-Host ""
        Write-Host "--------------------------------------------------"

        Write-Host (
            "Tweaks activés : {0} / {1}" -f
            $EnabledCount,
            $Configuration.Count
        ) -ForegroundColor Yellow

        Write-Host ""
        Write-Host "[1..N]     Activer / désactiver un tweak"
        Write-Host "[1,3,7]   Modifier plusieurs tweaks"
        Write-Host "[2-6]     Modifier une plage de tweaks"
        Write-Host "[A]        Tout activer"
        Write-Host "[D]        Tout désactiver"
        Write-Host "[0]        Retour"
        Write-Host ""

        $Choice = Read-Host "Votre choix"

        # --------------------------------------------------
        # Retour
        # --------------------------------------------------

        if ($Choice -eq "0") {

            return
        }

        # --------------------------------------------------
        # Tout activer
        # --------------------------------------------------

        if ($Choice -eq "A") {

            foreach ($Tweak in $Configuration) {

                $Tweak.Enabled = $true
            }

            $Context.Configuration = @(
                $Configuration
            )

            Write-Log `
                "Tous les Tweaks ont été activés." `
                SUCCESS

            continue
        }

        # --------------------------------------------------
        # Tout désactiver
        # --------------------------------------------------

        if ($Choice -eq "D") {

            foreach ($Tweak in $Configuration) {

                $Tweak.Enabled = $false
            }

            $Context.Configuration = @(
                $Configuration
            )

            Write-Log `
                "Tous les Tweaks ont été désactivés." `
                SUCCESS

            continue
        }

        # --------------------------------------------------
        # Sélection numérique (simple, multiple et plages)
        # --------------------------------------------------

        $SelectedIndexes = [System.Collections.Generic.List[int]]::new()
        $Tokens = $Choice -split '[,;\s]+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        $InvalidSelection = $false

        foreach ($Token in $Tokens) {

            if ($Token -match '^(\d+)-(\d+)$') {

                $RangeStart = [int]$Matches[1]
                $RangeEnd = [int]$Matches[2]

                if ($RangeStart -gt $RangeEnd) {
                    $Temp = $RangeStart
                    $RangeStart = $RangeEnd
                    $RangeEnd = $Temp
                }

                if ($RangeStart -lt 1 -or $RangeEnd -ge $Index) {
                    $InvalidSelection = $true
                    break
                }

                for ($RangeIndex = $RangeStart; $RangeIndex -le $RangeEnd; $RangeIndex++) {
                    if (-not $SelectedIndexes.Contains($RangeIndex)) {
                        $SelectedIndexes.Add($RangeIndex)
                    }
                }

                continue
            }

            $SingleIndex = 0

            if (-not [int]::TryParse($Token, [ref]$SingleIndex)) {
                $InvalidSelection = $true
                break
            }

            if ($SingleIndex -lt 1 -or $SingleIndex -ge $Index) {
                $InvalidSelection = $true
                break
            }

            if (-not $SelectedIndexes.Contains($SingleIndex)) {
                $SelectedIndexes.Add($SingleIndex)
            }
        }

        if ($InvalidSelection -or $SelectedIndexes.Count -eq 0) {

            Write-Host ""
            Write-Host "Choix invalide. Utilisez par exemple : 6,14,17 ou 2-6." -ForegroundColor Red
            $null = Read-Host "Appuyez sur Entrée"
            continue
        }

        foreach ($SelectedIndex in $SelectedIndexes) {

            $SelectedTweak = $DisplayedTweaks[$SelectedIndex - 1]
            $SelectedTweak.Enabled = -not [bool]$SelectedTweak.Enabled

            if ($SelectedTweak.Enabled) {
                Write-Log (
                    "Tweak activé : {0}" -f
                    $SelectedTweak.Id
                ) SUCCESS
            }
            else {
                Write-Log (
                    "Tweak désactivé : {0}" -f
                    $SelectedTweak.Id
                ) INFO
            }
        }

        # --------------------------------------------------
        # Synchronisation du contexte
        # --------------------------------------------------

        $Context.Configuration = @(
            $Configuration
        )
    }
}


function Initialize-PimsOSCustomConfiguration {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context

    )

    Write-Log "Initialisation de la configuration personnalisée..." INFO

    $Tweaks = @(
        Get-TweakDefinitions -Context $Context -Reload
    )

    if ($Tweaks.Count -eq 0) {

        throw "Aucun tweak disponible pour la configuration personnalisée."

    }

    $null = Test-TweakDefinitions `
        -Context $Context `
        -Tweaks $Tweaks

    $Configuration = [System.Collections.Generic.List[object]]::new()

    foreach ($Tweak in $Tweaks) {

        if ($null -eq $Tweak) {

            throw "Une définition de tweak est null."

        }

        if (
            $Tweak.PSObject.Properties.Name -notcontains "Id" -or
            $Tweak.PSObject.Properties.Name -notcontains "Name"
        ) {

            throw (
                "Définition de tweak invalide : les propriétés 'Id' et 'Name' sont obligatoires."
            )

        }

        $Item = New-ConfigurationItem `
            -Tweak $Tweak `
            -Enabled ([bool]$Tweak.Default)

        if ($null -eq $Item) {

            throw (
                "La construction du tweak '$($Tweak.Id)' a retourné `$null."
            )

        }

        if (
            $Item.PSObject.Properties.Name -notcontains "Enabled"
        ) {

            throw (
                "Le tweak '$($Tweak.Id)' ne possède pas la propriété 'Enabled'."
            )

        }

        $Configuration.Add($Item)

    }

    $Context.ConfigurationProfile = "Custom"
    $Context.Configuration = @(
        $Configuration.ToArray()
    )

    # Conserver la collection historique synchronisée sans l'imbriquer.
    $Context.Tweaks = @(
        $Configuration.ToArray()
    )

    $Context.BuildState.Image.TweaksLoaded = $true
    $Context.BuildState.Image.ProfileLoaded = $false
    $Context.BuildState.Image.ProfileMerged = $false
    $Context.BuildState.Image.ConfigLoaded = $true

    Write-Log (
        "Configuration personnalisée initialisée : {0} tweak(s)." -f
        $Configuration.Count
    ) SUCCESS

    return @(
		$Context.Configuration
	)
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

    $Profiles = @(
        Get-ProfileList -Context $Context
    )

    if ($Profiles.Count -eq 0) {
        Write-Host "Aucun profil valide disponible." -ForegroundColor Yellow
        Write-Host ""
        $null = Read-Host "Appuyez sur Entrée"
        return
    }

    for ($Index = 0; $Index -lt $Profiles.Count; $Index++) {
        Write-Host (
            "[{0}] {1}" -f
            ($Index + 1),
            $Profiles[$Index].Name
        )
    }

    Write-Host ""
    Write-Host "[P] Configuration personnalisée (aucun profil)" -ForegroundColor Yellow
    Write-Host "[0] Retour"
    Write-Host ""

    $Choice = Read-Host "Profil"

    if ($Choice -eq "0") {
        return
    }

    if ($Choice -eq "P" -or $Choice -eq "p") {
        Initialize-PimsOSCustomConfiguration -Context $Context | Out-Null
        Write-Log "Configuration personnalisée sélectionnée (aucun profil)." SUCCESS
        $null = Read-Host "Appuyez sur Entrée"
        return
    }

    $SelectedIndex = 0

    if (-not [int]::TryParse($Choice, [ref]$SelectedIndex)) {
        Write-Host "Choix invalide." -ForegroundColor Red
        $null = Read-Host "Appuyez sur Entrée"
        return
    }

    $SelectedIndex--

    if ($SelectedIndex -lt 0 -or $SelectedIndex -ge $Profiles.Count) {
        Write-Host "Choix invalide." -ForegroundColor Red
        $null = Read-Host "Appuyez sur Entrée"
        return
    }

    $SelectedProfileName = [string]$Profiles[$SelectedIndex].Name

    $ProfileObject = Load-Profile `
        -Context $Context `
        -Name $SelectedProfileName

    $Tweaks = @(
        Get-TweakDefinitions -Context $Context
    )

    $null = Test-TweakDefinitions `
        -Context $Context `
        -Tweaks $Tweaks

    $null = Merge-Profile `
        -Context $Context `
        -Tweaks $Tweaks `
        -Profile $ProfileObject

    $Context.ConfigurationProfile = $SelectedProfileName

    Write-Log (
        "Profil sélectionné et appliqué : {0}" -f
        $SelectedProfileName
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

        Write-Host (
            "[1] Créer l'ISO       : {0}" -f
            $Context.Build.CreateISO
        )

        Write-Host (
            "[2] Créer le rapport  : {0}" -f
            $Context.Build.CreateReport
        )

        Write-Host (
            "[3] Dry Run           : {0}" -f
            $Context.Build.DryRun
        )

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

                Write-Host "Choix invalide." `
                    -ForegroundColor Red

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

            $DriverConfiguration = [pscustomobject]@{

                Source        = "None"
                Path          = $null
                Recurse       = $true
                ForceUnsigned = $false

            }

            if (
                $Context.Project.Config.PSObject.Properties.Name `
                    -contains "Drivers"
            ) {

                $Context.Project.Config.Drivers =
                    $DriverConfiguration
            }
            else {

                $Context.Project.Config |
                    Add-Member `
                        -MemberType NoteProperty `
                        -Name "Drivers" `
                        -Value $DriverConfiguration `
                        -Force
            }

            Write-Log `
                "Configuration drivers : aucun driver." `
                SUCCESS
        }

        # --------------------------------------------------
        # Drivers du système actuel
        # --------------------------------------------------

        "2" {

            $DriverConfiguration = [pscustomobject]@{

                Source        = "CurrentSystem"
                Path          = $null
                Recurse       = $true
                ForceUnsigned = $false

            }

            if (
                $Context.Project.Config.PSObject.Properties.Name `
                    -contains "Drivers"
            ) {

                $Context.Project.Config.Drivers =
                    $DriverConfiguration
            }
            else {

                $Context.Project.Config |
                    Add-Member `
                        -MemberType NoteProperty `
                        -Name "Drivers" `
                        -Value $DriverConfiguration `
                        -Force
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

            $DriverConfiguration = [pscustomobject]@{

                Source        = "Folder"
                Path          = $DriverPath
                Recurse       = $true
                ForceUnsigned = $false

            }

            if (
                $Context.Project.Config.PSObject.Properties.Name `
                    -contains "Drivers"
            ) {

                $Context.Project.Config.Drivers =
                    $DriverConfiguration
            }
            else {

                $Context.Project.Config |
                    Add-Member `
                        -MemberType NoteProperty `
                        -Name "Drivers" `
                        -Value $DriverConfiguration `
                        -Force
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

    Write-Host (
        "Projet       : {0}" -f
        $Context.Project.Name
    )

    Write-Host (
        "Version      : {0}" -f
        $Context.Project.Version
    )

    Write-Host (
        "Windows      : {0}" -f
        $Context.Project.Windows.Release
    )

    Write-Host (
        "Build        : {0}" -f
        $Context.Project.Windows.Build
    )

    Write-Host ""

    Write-Host "Configuration" -ForegroundColor Yellow
    Write-Host "------------------------------------------"

    Write-Host (
        "Profil       : {0}" -f
        $Context.ConfigurationProfile
    )

    $SummaryTweaks = @(
        Get-PimsOSTweakConfiguration -Context $Context
    )

    $SummaryEnabledTweaks = @(
        $SummaryTweaks |
            Where-Object { $_.Enabled }
    )

    Write-Host (
        "Tweaks       : {0} / {1}" -f
        $SummaryEnabledTweaks.Count,
        $SummaryTweaks.Count
    )

    Write-Host ""

    Write-Host "Build" -ForegroundColor Yellow
    Write-Host "------------------------------------------"

    Write-Host (
        "Créer ISO    : {0}" -f
        $Context.Build.CreateISO
    )

    Write-Host (
        "Rapport      : {0}" -f
        $Context.Build.CreateReport
    )

    Write-Host (
        "Dry Run      : {0}" -f
        $Context.Build.DryRun
    )

    Write-Host ""

    # --------------------------------------------------
    # Drivers
    # --------------------------------------------------

    if ($null -ne $Context.Project.Config) {

        $ConfigurationObject = $Context.Project.Config

        if (
            $ConfigurationObject.PSObject.Properties.Name `
                -contains "Drivers"
        ) {

            if ($null -ne $ConfigurationObject.Drivers) {

                Write-Host "Drivers" -ForegroundColor Yellow
                Write-Host "------------------------------------------"

                Write-Host (
                    "Source       : {0}" -f
                    $ConfigurationObject.Drivers.Source
                )

                if (
                    $ConfigurationObject.Drivers.PSObject.Properties.Name `
                        -contains "Path"
                ) {

                    Write-Host (
                        "Chemin       : {0}" -f
                        $ConfigurationObject.Drivers.Path
                    )
                }

                if (
                    $ConfigurationObject.Drivers.PSObject.Properties.Name `
                        -contains "Recurse"
                ) {

                    Write-Host (
                        "Récursif     : {0}" -f
                        $ConfigurationObject.Drivers.Recurse
                    )
                }

                if (
                    $ConfigurationObject.Drivers.PSObject.Properties.Name `
                        -contains "ForceUnsigned"
                ) {

                    Write-Host (
                        "Non signés   : {0}" -f
                        $ConfigurationObject.Drivers.ForceUnsigned
                    )
                }

                Write-Host ""
            }
        }
    }

    $null = Read-Host "Appuyez sur Entrée"
}
