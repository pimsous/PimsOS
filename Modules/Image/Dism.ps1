# ==========================================
# Module : Dism
# Projet : PimsOS Builder
# Version : 1.0.0
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

        return @(Get-WindowsImage `
            -ImagePath $ImagePath `
            -ErrorAction Stop)

    }
    catch {

        throw (
            "Impossible de lire l'image Windows '{0}'.`n{1}" -f
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

        return @(Get-WindowsImage `
            -Mounted `
            -ErrorAction Stop)

    }
    catch {

        throw (
            "Impossible d'obtenir la liste des images montées.`n{0}" -f
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

    if (-not (Test-Path $ImagePath)) {

        throw (
            "L'image Windows est introuvable : {0}" -f
            $ImagePath
        )

    }

    if (-not (Test-Path $MountPath)) {

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
            "Impossible de monter l'image Windows.`n{0}" -f
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

    if (-not (Test-Path $MountPath)) {

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
            "Impossible de sauvegarder l'image Windows.`n{0}" -f
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

    if (-not (Test-Path $MountPath)) {

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

        }
        else {

            Write-Log "Sauvegarde et démontage..."

            $null = Dismount-WindowsImage `
                -Path $MountPath `
                -Save `
                -ErrorAction Stop

        }

        Write-Log "Image Windows démontée." SUCCESS

    }
    catch {

        throw (
            "Impossible de démonter l'image Windows.`n{0}" -f
            $_.Exception.Message
        )

    }

}