# ==========================================
# Module : PostInstall Finalize
# Projet : PimsOS Builder
# Version : 1.0.0
# Compatible : PowerShell 5.1+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Vérifie que le PostInstall est réellement terminé
# --------------------------------------------------

function Test-PimsOSPostInstallCompletion {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$State

    )

    if ($null -eq $State) {

        throw "L'état PostInstall est null."

    }

    $RequiredTasks = @(
        "Initialize",
        "Network",
        "DriverCheck",
        "Chocolatey",
        "Applications",
        "MicrosoftStore",
        "Configuration",
        "Cleanup"
    )

    $CompletedTasks = @()

    if ($State.PSObject.Properties.Name -contains "CompletedTasks") {

        $CompletedTasks = @($State.CompletedTasks)

    }

    $Status = if ($State.PSObject.Properties.Name -contains "Status") {
        [string]$State.Status
    } else {
        ""
    }

    $Completed = if ($State.PSObject.Properties.Name -contains "Completed") {
        [bool]$State.Completed
    } else {
        $false
    }

    $Failed = if ($State.PSObject.Properties.Name -contains "Failed") {
        [bool]$State.Failed
    } else {
        $true
    }

    $CurrentPhase = if ($State.PSObject.Properties.Name -contains "CurrentPhase") {
        $State.CurrentPhase
    } else {
        $null
    }

    $MissingTasks = @(
        $RequiredTasks | Where-Object {
            $CompletedTasks -notcontains $_
        }
    )

    $Success = (
        $Status -eq "Completed" -and
        $Completed -eq $true -and
        $Failed -eq $false -and
        ($null -eq $CurrentPhase -or
            [string]::IsNullOrWhiteSpace([string]$CurrentPhase)) -and
        $MissingTasks.Count -eq 0
    )

    return [PSCustomObject]@{

        Success = $Success

        Status = $Status

        Completed = $Completed

        Failed = $Failed

        CurrentPhase = $CurrentPhase

        MissingTasks = @($MissingTasks)

    }

}

# --------------------------------------------------
# Programme le nettoyage après la fin du Bootstrap
# --------------------------------------------------

function Invoke-PimsOSPostInstallCleanup {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]$RuntimePath,

        [Parameter()]
        [string]$UnattendPath = "C:\Windows\Panther\unattend.xml",

        [Parameter()]
        [int]$DelaySeconds = 10

    )

    if ([string]::IsNullOrWhiteSpace($RuntimePath)) {

        throw "Le chemin du runtime PostInstall est vide."

    }

    if (-not (Test-Path -LiteralPath $RuntimePath -PathType Container)) {

        throw "Le runtime PostInstall est introuvable : $RuntimePath"

    }

    if ($DelaySeconds -lt 1) {

        throw "Le délai de nettoyage doit être supérieur ou égal à 1 seconde."

    }

    $CleanupFiles = @(
        "Bootstrap.ps1",
        "Finalize.ps1",
        "Logger.ps1",
        "Network.ps1",
        "UI.ps1",
        "DriverCheck.ps1",
        "Chocolatey.ps1",
        "PostInstall.ps1",
        "State.ps1"
    )

    $PathsToRemove = @()

    foreach ($FileName in $CleanupFiles) {

        $PathsToRemove += Join-Path -Path $RuntimePath -ChildPath $FileName

    }

    if (-not [string]::IsNullOrWhiteSpace($UnattendPath)) {

        $PathsToRemove += $UnattendPath

    }

    $ExistingPaths = @(
        $PathsToRemove | Where-Object {
            Test-Path -LiteralPath $_
        }
    )

    # --------------------------------------------------
    # Le nettoyage est exécuté dans un processus séparé afin
    # de pouvoir supprimer Bootstrap.ps1 après sa sortie.
    # Les fichiers d'état, logs et cache Chocolatey sont conservés.
    # --------------------------------------------------

    $PowerShellPath = Join-Path $PSHOME "powershell.exe"

    if (-not (Test-Path -LiteralPath $PowerShellPath -PathType Leaf)) {

        $PowerShellPath = "powershell.exe"

    }

    $PathsJson = @($ExistingPaths) | ConvertTo-Json -Compress
    $PathsEncoded = [Convert]::ToBase64String(
        [System.Text.Encoding]::Unicode.GetBytes($PathsJson)
    )

    $CleanupCommand = @"
`$ErrorActionPreference = 'SilentlyContinue'
Start-Sleep -Seconds $DelaySeconds
`$PathsJson = [System.Text.Encoding]::Unicode.GetString([Convert]::FromBase64String('$PathsEncoded'))
`$Paths = @(`$PathsJson | ConvertFrom-Json)
foreach (`$Path in `$Paths) {
    if (Test-Path -LiteralPath `$Path) {
        Remove-Item -LiteralPath `$Path -Force -ErrorAction SilentlyContinue
    }
}
"@

    $EncodedCommand = [Convert]::ToBase64String(
        [System.Text.Encoding]::Unicode.GetBytes($CleanupCommand)
    )

    $Process = Start-Process `
        -FilePath $PowerShellPath `
        -ArgumentList @(
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-EncodedCommand",
            $EncodedCommand
        ) `
        -WindowStyle Hidden `
        -PassThru `
        -ErrorAction Stop

    return [PSCustomObject]@{

        Scheduled = $true

        ProcessId = $Process.Id

        DelaySeconds = $DelaySeconds

        RemovedItems = @($ExistingPaths)

        PreservedItems = @(
            Join-Path -Path $RuntimePath -ChildPath "state.json"
            Join-Path -Path $RuntimePath -ChildPath "PostInstall.log"
            Join-Path -Path $RuntimePath -ChildPath "Chocolatey"
        )

    }

}

# --------------------------------------------------
# Finalise le cycle PostInstall
# --------------------------------------------------

function Complete-PimsOSPostInstall {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$State,

        [Parameter(Mandatory)]
        [string]$RuntimePath,

        [Parameter()]
        [string]$UnattendPath = "C:\Windows\Panther\unattend.xml",

        [Parameter()]
        [int]$DelaySeconds = 10

    )

    $Verification = Test-PimsOSPostInstallCompletion -State $State

    if (-not $Verification.Success) {

        throw (
            "Vérification finale du PostInstall échouée. Tâches manquantes : {0}. Statut : {1}. Phase : {2}." -f
            ($Verification.MissingTasks -join ", "),
            $Verification.Status,
            $Verification.CurrentPhase
        )

    }

    if (
        $State.PSObject.Properties.Name -notcontains "Verification" -or
        $null -eq $State.Verification
    ) {

        $State | Add-Member -MemberType NoteProperty -Name Verification -Value ([PSCustomObject]@{}) -Force

    }

    $State.Verification.Verified = $true
    $State.Verification.VerifiedAt = [DateTime]::UtcNow
    $State.Verification.MissingTasks = @()

    if (
        $State.PSObject.Properties.Name -notcontains "Cleanup" -or
        $null -eq $State.Cleanup
    ) {

        $State | Add-Member -MemberType NoteProperty -Name Cleanup -Value ([PSCustomObject]@{}) -Force

    }

    try {

        $Cleanup = Invoke-PimsOSPostInstallCleanup `
            -RuntimePath $RuntimePath `
            -UnattendPath $UnattendPath `
            -DelaySeconds $DelaySeconds

        $State.Cleanup.Status = "Scheduled"
        $State.Cleanup.Scheduled = $true
        $State.Cleanup.ScheduledAt = [DateTime]::UtcNow
        $State.Cleanup.RemovedItems = @($Cleanup.RemovedItems)
        $State.Cleanup.PreservedItems = @($Cleanup.PreservedItems)
        $State.Cleanup.Errors = @()

    }
    catch {

        $Cleanup = [PSCustomObject]@{

            Scheduled = $false

            ProcessId = $null

            DelaySeconds = $DelaySeconds

            RemovedItems = @()

            PreservedItems = @(
                Join-Path -Path $RuntimePath -ChildPath "state.json"
                Join-Path -Path $RuntimePath -ChildPath "PostInstall.log"
                Join-Path -Path $RuntimePath -ChildPath "Chocolatey"
            )

        }

        $State.Cleanup.Status = "Failed"
        $State.Cleanup.Scheduled = $false
        $State.Cleanup.ScheduledAt = [DateTime]::UtcNow
        $State.Cleanup.RemovedItems = @()
        $State.Cleanup.PreservedItems = @($Cleanup.PreservedItems)
        $State.Cleanup.Errors = @($_.Exception.Message)

    }

    return [PSCustomObject]@{

        State = $State

        Verification = $Verification

        Cleanup = $Cleanup

    }

}
