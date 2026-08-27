# ==========================================
# Module : PostInstall State
# Projet : PimsOS Builder
# Version : 1.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Crée un nouvel état PostInstall
# --------------------------------------------------

function New-PostInstallState {

    [CmdletBinding()]
    param(

        [Parameter()]
        [string]$StatePath = "C:\ProgramData\PimsOS\PostInstall\state.json"

    )

    return [PSCustomObject]@{

        ObjectType = "PostInstallState"

        Version = "1.0.0"

        Status = "Pending"

        Started = $false

        Completed = $false

        Failed = $false

        WaitingForNetwork = $false

        NetworkAvailable = $false

        LastUpdate = [DateTime]::UtcNow

        CurrentPhase = $null

        StatePath = $StatePath

        Errors = @()

        CompletedTasks = @()

        PendingTasks = @()

    }

}

# --------------------------------------------------
# Charge l'état PostInstall
# --------------------------------------------------

function Get-PostInstallState {

    [CmdletBinding()]
    param(

        [Parameter()]
        [string]$StatePath = "C:\ProgramData\PimsOS\PostInstall\state.json"

    )

    if (-not (Test-Path -LiteralPath $StatePath -PathType Leaf)) {

        return New-PostInstallState `
            -StatePath $StatePath

    }

    try {

        $State = Get-Content `
            -LiteralPath $StatePath `
            -Raw `
            -Encoding UTF8 `
            -ErrorAction Stop |
            ConvertFrom-Json

        return $State

    }
    catch {

        throw (
            "Impossible de charger l'état PostInstall '{0}'.`r`n{1}" -f
            $StatePath,
            $_.Exception.Message
        )

    }

}

# --------------------------------------------------
# Sauvegarde l'état PostInstall
# --------------------------------------------------

function Save-PostInstallState {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$State,

        [Parameter()]
        [string]$StatePath

    )

    if ($null -eq $State) {

        throw "L'état PostInstall est null."

    }

    if ([string]::IsNullOrWhiteSpace($StatePath)) {

        if (
            $State.PSObject.Properties.Name -contains "StatePath" -and
            -not [string]::IsNullOrWhiteSpace(
                [string]$State.StatePath
            )
        ) {

            $StatePath = [string]$State.StatePath

        }
        else {

            $StatePath =
                "C:\ProgramData\PimsOS\PostInstall\state.json"

        }

    }

    $Directory = Split-Path `
        -Path $StatePath `
        -Parent

    if (-not (Test-Path -LiteralPath $Directory)) {

        New-Item `
            -ItemType Directory `
            -Path $Directory `
            -Force `
            -ErrorAction Stop |
            Out-Null

    }

    $State.LastUpdate = [DateTime]::UtcNow

    $State.StatePath = $StatePath

    try {

        $State |
            ConvertTo-Json `
                -Depth 10 |
            Set-Content `
                -LiteralPath $StatePath `
                -Encoding UTF8 `
                -ErrorAction Stop

    }
    catch {

        throw (
            "Impossible de sauvegarder l'état PostInstall '{0}'.`r`n{1}" -f
            $StatePath,
            $_.Exception.Message
        )

    }

    return $State

}

# --------------------------------------------------
# Met à jour le statut PostInstall
# --------------------------------------------------

function Set-PostInstallStatus {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$State,

        [Parameter(Mandatory)]
        [ValidateSet(
            "Pending",
            "Running",
            "WaitingForNetwork",
            "Completed",
            "Failed"
        )]
        [string]$Status

    )

    $State.Status = $Status

    $State.Started = $true

    switch ($Status) {

        "WaitingForNetwork" {

            $State.WaitingForNetwork = $true

            $State.Completed = $false
            $State.Failed = $false

        }

        "Completed" {

            $State.WaitingForNetwork = $false

            $State.Completed = $true
            $State.Failed = $false

        }

        "Failed" {

            $State.WaitingForNetwork = $false

            $State.Completed = $false
            $State.Failed = $true

        }

        default {

            $State.WaitingForNetwork = $false

            $State.Completed = $false
            $State.Failed = $false

        }

    }

    $State.LastUpdate = [DateTime]::UtcNow

    return $State

}
