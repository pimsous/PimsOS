# ==========================================
# Module : Pipeline
# Projet : PimsOS Builder
# Version : 0.4.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# ==========================================
# Dépendances des providers utilisés par le pipeline
# ==========================================

. "$PSScriptRoot\..\Package\Chocolatey.ps1"
. "$PSScriptRoot\..\Package\ChocolateyCache.ps1"



# ==========================================
# Exécute une étape du pipeline
# ==========================================

function Invoke-BuildStep {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [scriptblock]$Action

    )

    # ------------------------------------------
    # Vérification de la phase
    # ------------------------------------------

    if (-not $Context.Report.CurrentPhase) {

        throw (
            "Aucune phase active. " +
            "Appelez Start-BuildPhase avant Invoke-BuildStep."
        )

    }

    Write-Log "Étape : $Name" INFO

    # ------------------------------------------
    # Etat du pipeline
    # ------------------------------------------

    $Context.BuildState.Pipeline.Started = $true
    $Context.BuildState.Pipeline.Current = $Name

    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {

        # ------------------------------------------
        # Exécution de l'action
        # ------------------------------------------

        $Result = @(
            & $Action $Context
        )

        # ------------------------------------------
        # Validation du résultat
        # ------------------------------------------

        if ($Result.Count -eq 0) {

            throw (
                "L'étape '$Name' n'a retourné aucun contexte."
            )

        }

        if ($Result.Count -gt 1) {

            throw (
                "L'étape '$Name' a retourné plusieurs objets " +
                "($($Result.Count)). " +
                "Un seul BuildContext est attendu."
            )

        }

        $CandidateContext = $Result[0]

        # ------------------------------------------
        # Validation du BuildContext
        # ------------------------------------------

        if ($null -eq $CandidateContext) {

            throw (
                "L'étape '$Name' a retourné `$null. " +
                "Un BuildContext est attendu."
            )

        }

        if (
            -not (
                $CandidateContext.PSObject.Properties.Name `
                    -contains "BuildState"
            )
        ) {

            throw (
                "L'étape '$Name' n'a pas retourné un BuildContext valide : " +
                "propriété 'BuildState' absente."
            )

        }

        if (
            -not (
                $CandidateContext.PSObject.Properties.Name `
                    -contains "Report"
            )
        ) {

            throw (
                "L'étape '$Name' n'a pas retourné un BuildContext valide : " +
                "propriété 'Report' absente."
            )

        }

        # ------------------------------------------
        # Remplacement du contexte
        # ------------------------------------------

        $Context = $CandidateContext

        # ------------------------------------------
        # Validation spécifique ISO
        # ------------------------------------------

        if (
            $Context.PSObject.Properties.Name -contains "ISO" -and
            $null -ne $Context.ISO
        ) {

            if ($Context.ISO -is [array]) {

                throw (
                    "Le BuildContext retourné par l'étape '$Name' " +
                    "contient un ISO sous forme de tableau " +
                    "($($Context.ISO.Count) éléments)."
                )

            }

        }

        # ------------------------------------------
        # Validation spécifique WIM
        # ------------------------------------------

        if (
            $Context.PSObject.Properties.Name -contains "WIM" -and
            $null -ne $Context.WIM
        ) {

            if ($Context.WIM -is [array]) {

                throw (
                    "Le BuildContext retourné par l'étape '$Name' " +
                    "contient un WIM sous forme de tableau " +
                    "($($Context.WIM.Count) éléments)."
                )

            }

        }

        # ------------------------------------------
        # Arrêt du chronomètre
        # ------------------------------------------

        $Stopwatch.Stop()

        # ------------------------------------------
        # Rapport
        # ------------------------------------------

        $Context.Report.CurrentPhase.Steps += [PSCustomObject]@{

            Name     = $Name
            Success  = $true
            Duration = $Stopwatch.Elapsed

        }

        # ------------------------------------------
        # Etat du pipeline
        # ------------------------------------------

        if (
            $Context.BuildState.Pipeline.Completed `
                -notcontains $Name
        ) {

            $Context.BuildState.Pipeline.Completed += $Name

        }

        $Context.BuildState.Pipeline.Current = $null

        Write-Log (
            "$Name terminé en $($Stopwatch.Elapsed)"
        ) SUCCESS

    }
    catch {

        $Stopwatch.Stop()

        # ------------------------------------------
        # Rapport
        # ------------------------------------------

        if ($Context.Report.CurrentPhase) {

            $Context.Report.CurrentPhase.Success = $false

            $Context.Report.CurrentPhase.Errors +=
                $_.Exception.Message

            $Context.Report.CurrentPhase.Steps +=
                [PSCustomObject]@{

                    Name     = $Name
                    Success  = $false
                    Duration = $Stopwatch.Elapsed

                }

        }

        # ------------------------------------------
        # Etat du pipeline
        # ------------------------------------------

        if (
            $Context.BuildState.Pipeline.Failed `
                -notcontains $Name
        ) {

            $Context.BuildState.Pipeline.Failed += $Name

        }

        $Context.BuildState.Pipeline.Current = $null

        Write-Log (
            "$Name : $($_.Exception.Message)"
        ) ERROR

        throw

    }

    # ------------------------------------------
    # Retour du BuildContext
    # ------------------------------------------

    return $Context
}


# ==========================================
# Nettoyage sécurisé du pipeline
# ==========================================

function Invoke-PipelineCleanup {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [switch]$Discard

    )

    Write-Log "Nettoyage des ressources du pipeline..." INFO

    $CleanupErrors = @()


    # ------------------------------------------
    # 1. Ruches de registre
    # ------------------------------------------

    try {

        if (
            $null -ne $Context.Registry -and
            $null -ne $Context.Registry.Mounted -and
            $Context.Registry.Mounted.Count -gt 0
        ) {

            Write-Log `
                "Vérification des ruches de registre montées..." `
                INFO

            $Context = Dismount-ConfigurationRegistryHives `
                -Context $Context

        }

    }
    catch {

        $CleanupErrors +=
            "Registre : $($_.Exception.Message)"

        Write-Log (
            "Erreur lors du démontage des ruches de registre : $($_.Exception.Message)"
        ) ERROR

    }


    # ------------------------------------------
    # 2. WIM
    # ------------------------------------------

    try {

        if ($null -ne $Context.WIM) {

            Write-Log `
                "Vérification d'un éventuel montage WIM actif..." `
                INFO

            if ($Discard) {

                $Context = Dismount-Wim `
                    -Context $Context `
                    -Discard

            }
            else {

                $Context = Dismount-Wim `
                    -Context $Context

            }

        }

    }
    catch {

        $CleanupErrors +=
            "WIM : $($_.Exception.Message)"

        Write-Log (
            "Erreur lors du démontage du WIM : $($_.Exception.Message)"
        ) ERROR

    }


    # ------------------------------------------
    # 3. ISO
    # ------------------------------------------

    try {

        if (
            $Context.BuildState.Image.IsoMounted -eq $true
        ) {

            Write-Log "Démontage de l'image ISO..." INFO

            $Context = Dismount-Iso `
                -Context $Context

        }

    }
    catch {

        $CleanupErrors +=
            "ISO : $($_.Exception.Message)"

        Write-Log (
            "Erreur lors du démontage de l'ISO : $($_.Exception.Message)"
        ) ERROR

    }


    # ------------------------------------------
    # Vérification finale de l'état
    # ------------------------------------------

    if (
        $Context.BuildState.Image.RegistryLoaded -eq $true -or
        $Context.BuildState.Image.WimMounted -eq $true -or
        $Context.BuildState.Image.IsoMounted -eq $true
    ) {

        Write-Log (
            "Certaines ressources du pipeline restent montées."
        ) WARNING

    }
    else {

        $Context.BuildState.Image.RegistryLoaded = $false
        $Context.BuildState.Image.CurrentRegistryHive = $null

        $Context.BuildState.Image.WimMounted = $false
        $Context.BuildState.Image.IsoMounted = $false
        $Context.BuildState.Image.Mounted = $false
        $Context.BuildState.Image.MountPath = $null
        $Context.BuildState.Image.Index = $null

        Write-Log "Nettoyage du pipeline terminé." SUCCESS

    }


    # ------------------------------------------
    # Erreurs de nettoyage
    # ------------------------------------------

    if ($CleanupErrors.Count -gt 0) {

        throw (
            "Une ou plusieurs ressources n'ont pas pu être nettoyées : " +
            ($CleanupErrors -join " | ")
        )

    }


    return $Context
}

# ==========================================
# Applique la configuration des drivers
# ==========================================

function Apply-Drivers {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context

    )

    Write-Log "Application de la configuration des drivers..." INFO

    # --------------------------------------------------
    # Lecture de la configuration
    # --------------------------------------------------

    $DriverConfig = Get-DriverConfiguration `
        -Context $Context

    # --------------------------------------------------
    # Source None
    # --------------------------------------------------

    if ($DriverConfig.Source -eq "None") {

        Write-Log `
            "Aucun driver à intégrer." `
            INFO

        return $Context

    }

    # --------------------------------------------------
    # Source Folder
    # --------------------------------------------------

    if ($DriverConfig.Source -eq "Folder") {

        $Action = [PSCustomObject]@{

            Id              = "Drivers.Folder"
            Type            = "Driver"
            Name            = "Drivers"
            Provider        = "DISM"
            Source          = $DriverConfig.Path
            Recurse         = $DriverConfig.Recurse
            ForceUnsigned   = $DriverConfig.ForceUnsigned
            Enabled         = $true
            ContinueOnError = $false

        }

        Write-Log (
            "Source drivers : {0}" -f
            $DriverConfig.Path
        ) INFO

        $Context = Invoke-DriverAction `
            -Context $Context `
            -Action $Action

        $Context.Drivers.Add($Action)

        return $Context

    }

    # --------------------------------------------------
    # Source CurrentSystem
    # --------------------------------------------------

    if ($DriverConfig.Source -eq "CurrentSystem") {

        $Config = Get-Config

        if (
            $null -eq $Config.Workspace -or
            $null -eq $Config.Workspace.Drivers
        ) {

            throw (
                "Le chemin Workspace.Drivers est absent de Config.json."
            )

        }

        $DriversWorkspace = Join-Path `
            -Path (Get-ProjectRoot) `
            -ChildPath $Config.Workspace.Drivers

        $CurrentSystemPath = Join-Path `
            -Path $DriversWorkspace `
            -ChildPath "CurrentSystem"

        Write-Log (
            "Destination des drivers système : {0}" -f
            $CurrentSystemPath
        ) INFO

        $null = Export-DismCurrentSystemDrivers `
            -DestinationPath $CurrentSystemPath `
            -ErrorAction Stop

        $Action = [PSCustomObject]@{

            Id              = "Drivers.CurrentSystem"
            Type            = "Driver"
            Name            = "CurrentSystemDrivers"
            Provider        = "DISM"
            Source          = $CurrentSystemPath
            Recurse         = $DriverConfig.Recurse
            ForceUnsigned   = $DriverConfig.ForceUnsigned
            Enabled         = $true
            ContinueOnError = $false

        }

        Write-Log (
            "Drivers système exportés : {0}" -f
            $CurrentSystemPath
        ) SUCCESS

        $Context = Invoke-DriverAction `
            -Context $Context `
            -Action $Action

        $Context.Drivers.Add($Action)

        return $Context

    }

    throw (
        "La source de drivers '{0}' n'est pas prise en charge." -f
        $DriverConfig.Source
    )

}

# ==========================================
# Prépare le cache Chocolatey Offline
# ==========================================

function Prepare-ChocolateyCache {
    [CmdletBinding()]
    param([Parameter(Mandatory)][psobject]$Context)

    $CatalogPath = Join-Path $Context.Project.Root 'Config\Packages\Chocolatey.json'
    if (-not (Test-Path -LiteralPath $CatalogPath -PathType Leaf)) {
        throw "Le catalogue Chocolatey est introuvable : $CatalogPath"
    }

    Write-Log "Préparation du cache Chocolatey Offline..." INFO
    $Result = Initialize-ChocolateyCache -Context $Context -CatalogPath $CatalogPath

    # Chocolatey est un prérequis du runtime PostInstall : le Build doit
    # impérativement embarquer son .nupkg avant de préparer l'image.
    $Bootstrap = Test-ChocolateyBootstrapPackage -CachePath $Result.CachePath

    if (-not $Bootstrap.Present) {
        throw "Le Build ne peut pas continuer : le bootstrap Chocolatey n'est pas disponible dans le cache."
    }

    Write-Log ("Cache Chocolatey Offline : {0} package(s), {1} téléchargé(s), {2} déjà présent(s)." -f $Result.Total, $Result.Downloaded, $Result.AlreadyCached) SUCCESS
    Write-Log ("Bootstrap Chocolatey prêt pour le runtime : {0}" -f $Bootstrap.Name) SUCCESS

    # Conserve explicitement la preuve de préparation dans le BuildState.
    if ($Context.BuildState.PSObject.Properties.Name -contains 'Chocolatey') {
        $Context.BuildState.Chocolatey.BootstrapReady = $true
        $Context.BuildState.Chocolatey.BootstrapPath = $Bootstrap.Path
    }
    else {
        $Context.BuildState | Add-Member -MemberType NoteProperty -Name Chocolatey -Value ([pscustomobject]@{
            BootstrapReady = $true
            BootstrapPath  = $Bootstrap.Path
            CachePath      = $Result.CachePath
            OfflineCount   = $Result.Total
        }) -Force
    }

    return $Context
}

# ==========================================
# Prépare le PostInstall dans l'image montée
# ==========================================

function Prepare-PostInstall {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context

    )

    Write-Log `
        "Préparation du PostInstall..." `
        INFO

    if (
        $null -eq $Context.BuildState -or
        $null -eq $Context.BuildState.Image -or
        [string]::IsNullOrWhiteSpace(
            [string]$Context.BuildState.Image.MountPath
        )
    ) {

        throw "Le chemin de montage WIM est absent du contexte."

    }

    $MountPath =
        [string]$Context.BuildState.Image.MountPath

    $RuntimeSource =
        Get-PostInstallRuntimePath

    $CatalogPath = Join-Path $Context.Project.Root 'Config\Packages\Chocolatey.json'
    $ProviderPath = Join-Path $Context.Project.Root 'Modules\Package\Chocolatey.ps1'

    $RuntimeResult =
        Install-PimsOSPostInstallRuntime `
            -MountPath $MountPath `
            -SourcePath $RuntimeSource `
            -ChocolateyProviderPath $ProviderPath `
            -ChocolateyCatalogPath $CatalogPath `
            -ChocolateyCachePath (Get-ChocolateyCachePath -Context $Context)

    $BootstrapPath =
        "C:\ProgramData\PimsOS\PostInstall\Bootstrap.ps1"

    $FirstBootResult =
        Install-PimsOSFirstBoot `
            -MountPath $MountPath `
            -BootstrapPath $BootstrapPath

    Write-Log `
        "Runtime PostInstall installé dans l'image." `
        SUCCESS

    Write-Log (
        "FirstBoot configuré : {0}" -f
        $FirstBootResult.UnattendPath
    ) SUCCESS

    return $Context

}

# ==========================================
# Monte les ruches nécessaires à la configuration
# ==========================================

function Mount-ConfigurationRegistryHives {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context

    )

    Write-Log `
        "Analyse des ruches nécessaires à la configuration..." `
        INFO

    # --------------------------------------------------
    # Liste des ruches demandées par les actions registre
    # --------------------------------------------------

    $RequiredHives = @()

    foreach ($Tweak in @($Context.Configuration)) {

        if ($null -eq $Tweak) {
            continue
        }

        if (
            $Tweak.PSObject.Properties.Name -contains "Enabled" -and
            -not [bool]$Tweak.Enabled
        ) {
            continue
        }

        if (
            $Tweak.PSObject.Properties.Name -notcontains "Actions"
        ) {
            continue
        }

        foreach ($Action in @($Tweak.Actions)) {

            if ($null -eq $Action) {
                continue
            }

            if (
                $Action.PSObject.Properties.Name -contains "Enabled" -and
                -not [bool]$Action.Enabled
            ) {
                continue
            }

            if (
                $Action.PSObject.Properties.Name -contains "Type" -and
                $Action.Type -ne "Registry"
            ) {
                continue
            }

            if (
                $Action.PSObject.Properties.Name -contains "Hive" -and
                -not [string]::IsNullOrWhiteSpace(
                    [string]$Action.Hive
                )
            ) {

                $Hive = $Action.Hive.ToUpper()

                if ($RequiredHives -notcontains $Hive) {

                    $RequiredHives += $Hive

                }

            }

        }

    }

    # --------------------------------------------------
    # Aucune ruche nécessaire
    # --------------------------------------------------

    if ($RequiredHives.Count -eq 0) {

        Write-Log `
            "Aucune ruche de registre supplémentaire n'est nécessaire." `
            INFO

        return $Context

    }

    Write-Log (
        "Ruches nécessaires : {0}" -f
        ($RequiredHives -join ", ")
    ) INFO

    # --------------------------------------------------
    # Montage
    # --------------------------------------------------

    foreach ($Hive in $RequiredHives) {

        if (
            $Context.Registry.Mounted -contains $Hive
        ) {

            Write-Log (
                "Ruche $Hive déjà montée."
            ) INFO

            continue

        }

        Write-Log (
            "Montage de la ruche nécessaire : $Hive"
        ) INFO

        $Context = Mount-RegistryHive `
            -Context $Context `
            -Hive $Hive

    }

    Write-Log `
        "Toutes les ruches nécessaires sont montées." `
        SUCCESS

    return $Context
}


# ==========================================
# Démonte les ruches utilisées par la configuration
# ==========================================

function Dismount-ConfigurationRegistryHives {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context

    )

    Write-Log `
        "Démontage des ruches de registre..." `
        INFO

    $MountedHives = @(
        @($Context.Registry.Mounted)
    )

    if ($MountedHives.Count -eq 0) {

        Write-Log `
            "Aucune ruche de registre à démonter." `
            INFO

        return $Context

    }

    [array]::Reverse($MountedHives)

    foreach ($Hive in $MountedHives) {

        if (
            [string]::IsNullOrWhiteSpace([string]$Hive)
        ) {
            continue
        }

        try {

            if (
                $Context.Registry.Mounted -contains $Hive
            ) {

                Write-Log (
                    "Démontage de la ruche $Hive..."
                ) INFO

                $Context = Dismount-RegistryHive `
                    -Context $Context `
                    -Hive $Hive

            }

        }
        catch {

            Write-Log (
                "Erreur lors du démontage de la ruche $Hive : {0}" -f
                $_.Exception.Message
            ) ERROR

            throw

        }

    }

    Write-Log `
        "Toutes les ruches de registre ont été démontées." `
        SUCCESS

    return $Context
}

# ==========================================
# Retourne le pipeline du Build
# ==========================================

function Get-BuildPipeline {

    [CmdletBinding()]
    param()

    return @(

        # ------------------------------------------
        # Montage ISO
        # ------------------------------------------

        @{

            Id   = "MountIso"
            Name = "Montage ISO"

            Action = {

                param($Context)

                Mount-Iso `
                    -Context $Context

            }

        },

        # ------------------------------------------
        # Copie du contenu ISO dans Workspace
        # ------------------------------------------

        @{

            Id   = "CopyIsoContent"
            Name = "Préparation de la source ISO"

            Action = {

                param($Context)

                Copy-IsoContentToWorkspace `
                    -Context $Context

            }

        },

        # ------------------------------------------
        # Détection du WIM
        # ------------------------------------------

        @{

            Id   = "DetectWim"
            Name = "Détection du WIM"

            Action = {

                param($Context)

                Get-WimFile `
                    -Context $Context

            }

        },

        # ------------------------------------------
        # Copie du WIM
        # ------------------------------------------

        @{

            Id   = "CopyWim"
            Name = "Copie du WIM"

            Condition = {

                param($Context)

                $CanReuse = $false

                if (
                    $null -ne $Context.BuildState.Recovery.Wim -and
                    $Context.BuildState.Recovery.Wim.PSObject.Properties.Name -contains "CanReuse"
                ) {

                    $CanReuse =
                        [bool]$Context.BuildState.Recovery.Wim.CanReuse

                }

                -not $CanReuse

            }

            Action = {

                param($Context)

                Copy-WimToWorkspace `
                    -Context $Context

            }

        },

        # ------------------------------------------
        # Lecture des images WIM
        # ------------------------------------------

        @{

            Id   = "ReadWimImages"
            Name = "Lecture des images WIM"

            Action = {

                param($Context)

                Get-WimImages `
                    -Context $Context

            }

        },

        # ------------------------------------------
        # Sélection de l'image Windows
        # ------------------------------------------

        @{

            Id   = "SelectImage"
            Name = "Sélection de l'image Windows"

            Action = {

                param($Context)

                Select-WimImage `
                    -Context $Context

            }

        },

        # ------------------------------------------
        # Montage du WIM
        # ------------------------------------------

        @{

            Id   = "MountWim"
            Name = "Montage du WIM"

            Action = {

                param($Context)

                Mount-Wim `
                    -Context $Context

            }

        },

        # ------------------------------------------
        # Application des drivers
        # ------------------------------------------

        @{

            Id   = "ApplyDrivers"
            Name = "Application des drivers"

            Action = {

                param($Context)

                Apply-Drivers `
                    -Context $Context

            }

        },

        # ------------------------------------------
        # Préparation du cache Chocolatey Offline
        # ------------------------------------------

        @{

            Id   = "PrepareChocolateyCache"
            Name = "Préparation du cache Chocolatey Offline"

            Action = {

                param($Context)

                Prepare-ChocolateyCache `
                    -Context $Context

            }

        },

        # ------------------------------------------
        # Préparation du PostInstall
        # ------------------------------------------

        @{

            Id   = "PreparePostInstall"
            Name = "Préparation du PostInstall"

            Action = {

                param($Context)

                Prepare-PostInstall `
                    -Context $Context

            }

        },

        # ------------------------------------------
        # Chargement de la configuration
        # ------------------------------------------

        @{

            Id   = "LoadConfiguration"
            Name = "Chargement de la configuration"

            Action = {

                param($Context)

                # ------------------------------------------
                # Profil personnalisé
                # ------------------------------------------

                if ($Context.ConfigurationProfile -eq "Custom") {

                    if (
                        $null -eq $Context.Configuration -or
                        @($Context.Configuration).Count -eq 0
                    ) {

                        throw "La configuration personnalisée est absente du contexte."

                    }

                    Write-Log (
                        "Configuration personnalisée conservée : {0} tweak(s)." -f
                        @($Context.Configuration).Count
                    ) INFO

                    return $Context

                }

                # ------------------------------------------
                # Profil standard
                # ------------------------------------------

                $Context = Get-Configuration `
                    -Context $Context `
                    -Profile $Context.ConfigurationProfile

                return $Context

            }



        },

        # ------------------------------------------
        # Montage des ruches nécessaires
        # ------------------------------------------

        @{

            Id   = "MountConfigurationRegistryHives"
            Name = "Montage des ruches de registre"

            Action = {

                param($Context)

                Mount-ConfigurationRegistryHives `
                    -Context $Context

            }

        },

        # ------------------------------------------
        # Application de la configuration
        # ------------------------------------------

        @{

            Id   = "ApplyConfiguration"
            Name = "Application de la configuration"

            Action = {

                param($Context)

                Invoke-Configuration `
                    -Context $Context `
                    -Configuration $Context.Configuration

            }

        },

        # ------------------------------------------
        # Démontage des ruches de registre
        # ------------------------------------------

        @{

            Id   = "DismountConfigurationRegistryHives"
            Name = "Démontage des ruches de registre"

            Action = {

                param($Context)

                Dismount-ConfigurationRegistryHives `
                    -Context $Context

            }

        },

        # ------------------------------------------
        # Validation du déploiement PostInstall
        # ------------------------------------------

        @{

            Id   = "ValidatePostInstallDeployment"
            Name = "Validation du déploiement PostInstall"

            Action = {

                param($Context)

                # --------------------------------------------------
                # Chargement du module de validation
                # --------------------------------------------------

                $ValidationPath = Join-Path `
                    -Path $ProjectRoot `
                    -ChildPath "Modules\PostInstall\DeploymentValidation.ps1"

                if (-not (Test-Path `
                    -LiteralPath $ValidationPath `
                    -PathType Leaf)) {

                    throw (
                        "Module DeploymentValidation introuvable : {0}" -f
                        $ValidationPath
                    )

                }

                . $ValidationPath

                # --------------------------------------------------
                # Chemins dans le WIM
                # --------------------------------------------------

                $MountPath = $Context.WIM.Mount.Path

                $PostInstallPath = Join-Path `
                    -Path $MountPath `
                    -ChildPath "ProgramData\PimsOS\PostInstall"

                $UnattendPath = Join-Path `
                    -Path $MountPath `
                    -ChildPath "Windows\Panther\unattend.xml"

                # --------------------------------------------------
                # Validation
                # --------------------------------------------------

                Write-Log `
                    "Validation du déploiement PostInstall." `
                    INFO

                $ValidationResult =
                    Test-PostInstallDeployment `
                        -PostInstallPath $PostInstallPath `
                        -UnattendPath $UnattendPath

                if (-not $ValidationResult.Success) {

                    if ($ValidationResult.MissingFiles.Count -gt 0) {

                        Write-Log (
                            "Fichiers PostInstall manquants : {0}" -f
                            ($ValidationResult.MissingFiles -join ", ")
                        ) ERROR

                    }

                    throw (
                        "La validation du déploiement PostInstall a échoué."
                    )

                }

                Write-Log `
                    "Déploiement PostInstall validé avec succès." `
                    SUCCESS

                return $Context

            }

        },

        # ------------------------------------------
        # Démontage WIM
        # ------------------------------------------

        @{

            Id   = "DismountWim"
            Name = "Démontage du WIM"

            Action = {

                param($Context)

                Dismount-Wim `
                    -Context $Context

            }

        },

        # ------------------------------------------
        # Synchronisation du WIM dans la source ISO
        # ------------------------------------------

        @{

            Id   = "SyncWimToIsoSource"
            Name = "Synchronisation du WIM"

            Action = {

                param($Context)

                $Config = Get-Config

                $SourceWim = Join-Path `
                    -Path (Get-ProjectRoot) `
                    -ChildPath (
                        Join-Path `
                            -Path $Config.Workspace.Sources `
                            -ChildPath $Context.WIM.Name
                    )

                $IsoWim = Join-Path `
                    -Path (Get-ProjectRoot) `
                    -ChildPath (
                        Join-Path `
                            -Path $Config.Workspace.ISOSource `
                            -ChildPath "sources\$($Context.WIM.Name)"
                    )

                if (-not (Test-Path -LiteralPath $SourceWim -PathType Leaf)) {

                    throw (
                        "WIM de travail introuvable : {0}" -f
                        $SourceWim
                    )

                }

                $IsoSources = Split-Path `
                    -Path $IsoWim `
                    -Parent

                if (-not (Test-Path -LiteralPath $IsoSources -PathType Container)) {

                    New-Item `
                        -ItemType Directory `
                        -Path $IsoSources `
                        -Force `
                        -ErrorAction Stop |
                        Out-Null

                }

                Write-Log (
                    "Synchronisation du WIM : {0} -> {1}" -f
                    $SourceWim,
                    $IsoWim
                ) INFO

                Copy-Item `
                    -LiteralPath $SourceWim `
                    -Destination $IsoWim `
                    -Force `
                    -ErrorAction Stop

                $SourceHash = (
                    Get-FileHash `
                        -LiteralPath $SourceWim `
                        -Algorithm SHA256 `
                        -ErrorAction Stop
                ).Hash

                $IsoHash = (
                    Get-FileHash `
                        -LiteralPath $IsoWim `
                        -Algorithm SHA256 `
                        -ErrorAction Stop
                ).Hash

                if ($SourceHash -ne $IsoHash) {

                    throw `
                        "Échec de synchronisation du WIM : les hashes SHA256 diffèrent."

                }

                Write-Log (
                    "WIM synchronisé avec succès. SHA256 : {0}" -f
                    $IsoHash
                ) SUCCESS

                return $Context

            }

        },

        # ------------------------------------------
        # Démontage ISO
        # ------------------------------------------

        @{

            Id   = "DismountIso"
            Name = "Démontage ISO"

            Action = {

                param($Context)

                Dismount-Iso `
                    -Context $Context

            }

        },

        # ------------------------------------------
        # Création de l'ISO PimsOS
        # ------------------------------------------

        @{

            Id   = "NewPimsOSIso"
            Name = "Création de l'ISO PimsOS"

            Action = {

                param($Context)

                New-PimsOSIso `
                    -Context $Context

            }

        }

    )
}


# ==========================================
# Exécute le pipeline du Build
# ==========================================

function Invoke-BuildPipeline {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [object[]]$Pipeline = (Get-BuildPipeline)

    )

    # ------------------------------------------
    # Phase Pipeline
    # ------------------------------------------

    $Context = Start-BuildPhase `
        -Context $Context `
        -Name "Pipeline"

    $PipelineSucceeded = $false
    $PipelineError = $null

    try {

        foreach ($Step in $Pipeline) {

            # ------------------------------------------
            # Déjà exécutée ?
            # ------------------------------------------

            if (
                $Context.BuildState.Pipeline.Completed -contains $Step.Name
            ) {

                Write-Log (
                    "Étape déjà exécutée : $($Step.Name)"
                ) INFO

                continue

            }

            # ------------------------------------------
            # Condition
            # ------------------------------------------

            if ($Step.ContainsKey("Condition")) {

                $Execute = & $Step.Condition $Context

                if (-not $Execute) {

                    Write-Log (
                        "Étape ignorée : $($Step.Name)"
                    ) INFO

                    continue

                }

            }

            # ------------------------------------------
            # Exécution
            # ------------------------------------------

            $Context = Invoke-BuildStep `
                -Context $Context `
                -Name $Step.Name `
                -Action $Step.Action

        }

        # ------------------------------------------
        # Toutes les étapes ont réussi
        # ------------------------------------------

        $PipelineSucceeded = $true

    }
    catch {

        $PipelineError = $_

        $Context.BuildState.Pipeline.Current = $null
        $Context.BuildState.Status = "PipelineFailed"

        Write-Log (
            "Pipeline en échec : $($_.Exception.Message)"
        ) ERROR

    }
    finally {

        # ------------------------------------------
        # Fin de la phase Pipeline
        # ------------------------------------------

        if ($Context.Report.CurrentPhase) {

            try {

                $Context = Complete-BuildPhase `
                    -Context $Context

            }
            catch {

                Write-Log (
                    "Erreur lors de la clôture de la phase Pipeline : $($_.Exception.Message)"
                ) ERROR

                if ($PipelineSucceeded) {

                    $PipelineSucceeded = $false
                    $PipelineError = $_

                }

            }

        }

    }

    # ------------------------------------------
    # Etat final
    # ------------------------------------------

    if ($PipelineSucceeded) {

        $Context.BuildState.Pipeline.Current = $null
        $Context.BuildState.Status = "PipelineCompleted"

        $Context.BuildState.Success = $true
        $Context.BuildState.Completed = $true

        Write-Log (
            "Pipeline terminé avec succès."
        ) SUCCESS

    }
    else {

        $Context.BuildState.Pipeline.Current = $null
        $Context.BuildState.Status = "PipelineFailed"

        if ($null -ne $PipelineError) {

            throw $PipelineError

        }

    }

    return $Context
}
