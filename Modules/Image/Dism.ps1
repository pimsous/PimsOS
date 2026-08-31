# ==========================================
# Module : Dism
# Projet : PimsOS Builder
# Version : 1.0.1
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Retourne les images présentes dans un WIM/ESD
# --------------------------------------------------

function Get-DismImages {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]$ImagePath

    )

    Write-Log "Lecture des images Windows..."

    try {

        return @(
            Get-WindowsImage `
                -ImagePath $ImagePath `
                -ErrorAction Stop
        )

    }
    catch {

        throw (
            "Impossible de lire l'image Windows '{0}'.`r`n{1}" -f
            $ImagePath,
            $_.Exception.Message
        )

    }

}

# --------------------------------------------------
# Retourne les images actuellement montées
# --------------------------------------------------

function Get-DismMountedImages {

    [CmdletBinding()]
    param()

    try {

        return @(
            Get-WindowsImage `
                -Mounted `
                -ErrorAction Stop
        )

    }
    catch {

        throw (
            "Impossible d'obtenir la liste des images montées.`r`n{0}" -f
            $_.Exception.Message
        )

    }

}

# --------------------------------------------------
# Monte une image Windows
# --------------------------------------------------

function Mount-DismImage {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]$ImagePath,

        [Parameter(Mandatory)]
        [int]$Index,

        [Parameter(Mandatory)]
        [string]$MountPath,

        [switch]$ReadOnly

    )

    Write-Log "Montage DISM..."

    # --------------------------------------------------
    # Vérifications
    # --------------------------------------------------

    if (-not (Test-Path -LiteralPath $ImagePath)) {

        throw (
            "L'image Windows est introuvable : {0}" -f
            $ImagePath
        )

    }

    if (-not (Test-Path -LiteralPath $MountPath)) {

        throw (
            "Le dossier de montage est introuvable : {0}" -f
            $MountPath
        )

    }

    $Parameters = @{

        ImagePath = $ImagePath
        Index     = $Index
        Path      = $MountPath

    }

    if ($ReadOnly) {

        $Parameters.ReadOnly = $true

    }

    try {

        $null = Mount-WindowsImage `
            @Parameters `
            -ErrorAction Stop

        Write-Log "Montage DISM terminé." SUCCESS

    }
    catch {

        throw (
            "Impossible de monter l'image Windows.`r`n{0}" -f
            $_.Exception.Message
        )

    }

}

# --------------------------------------------------
# Sauvegarde une image montée
# --------------------------------------------------

function Save-DismImage {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]$MountPath

    )

    Write-Log "Sauvegarde de l'image Windows..."

    if (-not (Test-Path -LiteralPath $MountPath)) {

        throw (
            "Le dossier de montage est introuvable : {0}" -f
            $MountPath
        )

    }

    try {

        $null = Save-WindowsImage `
            -Path $MountPath `
            -ErrorAction Stop

        Write-Log "Image Windows sauvegardée." SUCCESS

    }
    catch {

        throw (
            "Impossible de sauvegarder l'image Windows.`r`n{0}" -f
            $_.Exception.Message
        )

    }

}

# --------------------------------------------------
# Démonte une image Windows
# --------------------------------------------------

function Dismount-DismImage {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]$MountPath,

        [switch]$Discard

    )

    if (-not (Test-Path -LiteralPath $MountPath)) {

        throw (
            "Le dossier de montage est introuvable : {0}" -f
            $MountPath
        )

    }

    try {

        if ($Discard) {

            Write-Log "Abandon des modifications..."

            $null = Dismount-WindowsImage `
                -Path $MountPath `
                -Discard `
                -ErrorAction Stop

            Write-Log "Image Windows démontée sans conserver les modifications." SUCCESS

        }
        else {

            Write-Log "Sauvegarde et démontage..."

            $null = Dismount-WindowsImage `
                -Path $MountPath `
                -Save `
                -ErrorAction Stop

            Write-Log "Image Windows sauvegardée et démontée." SUCCESS

        }

    }
    catch {

        throw (
            "Impossible de démonter l'image Windows.`r`n{0}" -f
            $_.Exception.Message
        )

    }

}
# --------------------------------------------------
# Ajoute des pilotes à une image Windows montée
# --------------------------------------------------

function Add-DismDriver {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]$MountPath,

        [Parameter(Mandatory)]
        [string]$DriverPath,

        [switch]$Recurse,

        [switch]$ForceUnsigned

    )

    Write-Log "Ajout des pilotes à l'image Windows..." INFO

    # --------------------------------------------------
    # Vérifications
    # --------------------------------------------------

    if (-not (Test-Path -LiteralPath $MountPath -PathType Container)) {

        throw (
            "Le dossier de montage est introuvable : {0}" -f
            $MountPath
        )

    }

    if (-not (Test-Path -LiteralPath $DriverPath)) {

        throw (
            "La source des pilotes est introuvable : {0}" -f
            $DriverPath
        )

    }

    # --------------------------------------------------
    # Préparation des paramètres DISM
    # --------------------------------------------------

    $Parameters = @{

        Path        = $MountPath
        Driver      = $DriverPath
        ErrorAction = "Stop"

    }

    if ($Recurse) {

        $Parameters.Recurse = $true

    }

    if ($ForceUnsigned) {

        $Parameters.ForceUnsigned = $true

    }

    # --------------------------------------------------
    # Injection
    # --------------------------------------------------

    try {

        $Result = Add-WindowsDriver @Parameters

        Write-Log (
            "Pilotes ajoutés depuis : {0}" -f
            $DriverPath
        ) SUCCESS

        return $Result

    }
    catch {

        throw (
            "Impossible d'ajouter les pilotes depuis '{0}'.`r`n{1}" -f
            $DriverPath,
            $_.Exception.Message
        )

    }

}
# --------------------------------------------------
# Exporte les pilotes du système actuellement en ligne
# --------------------------------------------------

function Export-DismCurrentSystemDrivers {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]$DestinationPath

    )

    Write-Log (
        "Export des pilotes du système vers : {0}" -f
        $DestinationPath
    ) INFO

    # --------------------------------------------------
    # Préparation du dossier
    # --------------------------------------------------

    if (Test-Path -LiteralPath $DestinationPath) {

        if (
            -not (
                Test-Path `
                    -LiteralPath $DestinationPath `
                    -PathType Container
            )
        ) {

            throw (
                "La destination des pilotes existe mais n'est pas un dossier : {0}" -f
                $DestinationPath
            )

        }

        Write-Log `
            "Nettoyage de l'ancien export de drivers..." `
            INFO

        Get-ChildItem `
            -LiteralPath $DestinationPath `
            -Force `
            -ErrorAction Stop |
            Remove-Item `
                -Recurse `
                -Force `
                -ErrorAction Stop

    }
    else {

        New-Item `
            -ItemType Directory `
            -Path $DestinationPath `
            -Force `
            -ErrorAction Stop |
            Out-Null

    }

    # --------------------------------------------------
    # Export
    # --------------------------------------------------

    try {

        $Result = Export-WindowsDriver `
            -Online `
            -Destination $DestinationPath `
            -ErrorAction Stop

        Write-Log (
            "Export des pilotes terminé : {0}" -f
            $DestinationPath
        ) SUCCESS

        return $Result

    }
    catch {

        throw (
            "Impossible d'exporter les pilotes du système.`r`n{0}" -f
            $_.Exception.Message
        )

    }
}

# --------------------------------------------------
# Applique une fonctionnalité Windows via DISM
# --------------------------------------------------

function Invoke-DismFeature {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [psobject]$Action

    )

    Write-Log (
        "DISM Feature : {0}" -f
        $Action.Name
    ) INFO

    # --------------------------------------------------
    # Validation
    # --------------------------------------------------

    if ([string]::IsNullOrWhiteSpace($Action.Name)) {

        throw "Le nom de la fonctionnalité Windows est obligatoire."

    }

    # --------------------------------------------------
    # Détermination de la cible
    # --------------------------------------------------

    $ImagePath = $null

	if (
		$null -ne $Context.WIM -and
		$null -ne $Context.WIM.Mount -and
		$Context.WIM.Mount.PSObject.Properties.Match("Path").Count -gt 0
	) {

		$ImagePath = $Context.WIM.Mount.Path

	}

    if ([string]::IsNullOrWhiteSpace($ImagePath)) {

        throw "Aucune image Windows montée n'est disponible pour appliquer la fonctionnalité."

    }

    if (-not (Test-Path -LiteralPath $ImagePath -PathType Container)) {

        throw (
            "Le dossier de montage de l'image Windows est introuvable : {0}" -f
            $ImagePath
        )

    }

    # --------------------------------------------------
    # Etat demandé
    # --------------------------------------------------

    $Enable = $true

    if ($Action.PSObject.Properties.Match("Enable").Count -gt 0) {

        $Enable = [bool]$Action.Enable

    }

    # --------------------------------------------------
    # Application
    # --------------------------------------------------

    try {

        if ($Enable) {

            Write-Log (
                "Activation de la fonctionnalité '{0}'..." -f
                $Action.Name
            ) INFO

            $Result = Enable-WindowsOptionalFeature `
                -Path $ImagePath `
                -FeatureName $Action.Name `
                -All `
                -NoRestart `
                -ErrorAction Stop

        }
        else {

            Write-Log (
                "Désactivation de la fonctionnalité '{0}'..." -f
                $Action.Name
            ) INFO

            $Result = Disable-WindowsOptionalFeature `
                -Path $ImagePath `
                -FeatureName $Action.Name `
                -NoRestart `
                -ErrorAction Stop

        }

    }
    catch {

        throw (
            "Impossible de modifier la fonctionnalité Windows '{0}'.`r`n{1}" -f
            $Action.Name,
            $_.Exception.Message
        )

    }

    Write-Log (
        "Fonctionnalité Windows '{0}' appliquée via DISM." -f
        $Action.Name
    ) SUCCESS

    return $Context

`r`n}

# --------------------------------------------------
# Applique une Capability Windows via DISM
# --------------------------------------------------

function Invoke-DismCapability {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [psobject]$Action

    )

    Write-Log (
        "DISM Capability : {0}" -f
        $Action.Name
    ) INFO

    # --------------------------------------------------
    # Validation
    # --------------------------------------------------

    if ([string]::IsNullOrWhiteSpace($Action.Name)) {

        throw "Le nom de la capability Windows est obligatoire."

    }

    # --------------------------------------------------
    # Détermination de la cible
    # --------------------------------------------------

    $ImagePath = $null

    if (
        $null -ne $Context.WIM -and
        $null -ne $Context.WIM.Mount -and
        $Context.WIM.Mount.PSObject.Properties.Match("Path").Count -gt 0
    ) {

        $ImagePath = $Context.WIM.Mount.Path

    }

    if ([string]::IsNullOrWhiteSpace($ImagePath)) {

        throw "Aucune image Windows montée n'est disponible pour appliquer la capability."

    }

    if (-not (Test-Path -LiteralPath $ImagePath -PathType Container)) {

        throw (
            "Le dossier de montage de l'image Windows est introuvable : {0}" -f
            $ImagePath
        )

    }

    # --------------------------------------------------
    # Etat demandé
    # --------------------------------------------------

    $Enable = $true

    if ($Action.PSObject.Properties.Match("Enable").Count -gt 0) {

        $Enable = [bool]$Action.Enable

    }

    # --------------------------------------------------
    # Paramètres optionnels
    # --------------------------------------------------

    $Parameters = @{

        Path        = $ImagePath
        Name        = $Action.Name
        ErrorAction = "Stop"

    }

    if (
        $Action.PSObject.Properties.Match("Source").Count -gt 0 -and
        -not [string]::IsNullOrWhiteSpace($Action.Source)
    ) {

        $Parameters.Source = $Action.Source

    }

    if (
        $Action.PSObject.Properties.Match("LimitAccess").Count -gt 0 -and
        [bool]$Action.LimitAccess
    ) {

        $Parameters.LimitAccess = $true

    }

    # --------------------------------------------------
    # Application
    # --------------------------------------------------

    try {

        if ($Enable) {

            Write-Log (
                "Activation de la capability '{0}'..." -f
                $Action.Name
            ) INFO

            $Result = Add-WindowsCapability @Parameters

        }
        else {

            Write-Log (
                "Désactivation de la capability '{0}'..." -f
                $Action.Name
            ) INFO

            $RemoveParameters = @{

                Path        = $ImagePath
                Name        = $Action.Name
                ErrorAction = "Stop"

            }

            $Result = Remove-WindowsCapability @RemoveParameters

        }

        Write-Log (
            "Capability '{0}' traitée avec succès." -f
            $Action.Name
        ) SUCCESS

        return $Result

    }
    catch {

        throw (
            "Impossible de modifier la capability Windows '{0}'.`r`n{1}" -f
            $Action.Name,
            $_.Exception.Message
        )

    }

}
