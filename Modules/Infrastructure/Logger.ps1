# ==========================================
# Module : Logger
# Projet : PimsOS Builder
# Version : 2.1.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# ==================================================
# Variables privées
# ==================================================

$script:LogFile   = $null
$script:Stopwatch = $null
$script:Quiet     = $false

$script:Colors = @{

    INFO    = "Cyan"

    SUCCESS = "Green"

    WARNING = "Yellow"

    ERROR   = "Red"

    DEBUG   = "DarkGray"

}

# ==================================================
# Démarre le Logger
# ==================================================

function Start-Logger {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [switch]$Quiet

    )

    $Directory = Split-Path `
        -Path $Path `
        -Parent

    if (-not (Test-Path $Directory)) {

        New-Item `
            -ItemType Directory `
            -Path $Directory `
            -Force `
            -ErrorAction Stop | Out-Null

    }

    $script:LogFile = $Path
    $script:Quiet = $Quiet.IsPresent

    if ($script:Stopwatch) {

        $script:Stopwatch.Reset()

    }

    $script:Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    if (-not (Test-Path $script:LogFile)) {

        $Utf8NoBom = [System.Text.UTF8Encoding]::new($false)

        [System.IO.File]::WriteAllText(
            $script:LogFile,
            "",
            $Utf8NoBom
        )

    }

}

# ==================================================
# Arrête le Logger
# ==================================================

function Stop-Logger {

    [CmdletBinding()]
    param()

    if ($script:Stopwatch) {

        $script:Stopwatch.Stop()

    }

}

# ==================================================
# Ecriture console
# ==================================================

function Write-Console {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]$Line,

        [Parameter(Mandatory)]
        [ValidateSet(
            "INFO",
            "SUCCESS",
            "WARNING",
            "ERROR",
            "DEBUG"
        )]
        [string]$Level

    )

    if ($script:Quiet) {

        return

    }

    $Color = $script:Colors[$Level]

    if (-not $Color) {

        $Color = "White"

    }

    Write-Host `
        $Line `
        -ForegroundColor $Color

}

# ==================================================
# Ecriture fichier
# ==================================================

function Write-File {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]$Line

    )

    if (-not $script:LogFile) {

        return

    }

    $Utf8NoBom = [System.Text.UTF8Encoding]::new($false)

    [System.IO.File]::AppendAllText(

        $script:LogFile,

        "$Line$([Environment]::NewLine)",

        $Utf8NoBom

    )

}

# ==================================================
# Journalisation
# ==================================================

function Write-Log {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory,Position=0)]
        [string]$Message,

        [Parameter(Position=1)]
        [ValidateSet(
            "INFO",
            "SUCCESS",
            "WARNING",
            "ERROR",
            "DEBUG"
        )]
        [string]$Level = "INFO"

    )

    $Timestamp = Get-Date -Format "HH:mm:ss"

    $LevelText = $Level.PadRight(7)

    $Line = "[$Timestamp] [$LevelText] $Message"

    Write-Console `
        -Line $Line `
        -Level $Level

    Write-File `
        -Line $Line

}

# ==================================================
# Raccourcis
# ==================================================

function Write-Info {

    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Message)

    Write-Log $Message INFO

}

function Write-Success {

    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Message)

    Write-Log $Message SUCCESS

}

function Write-WarningLog {

    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Message)

    Write-Log $Message WARNING

}

function Write-ErrorLog {

    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Message)

    Write-Log $Message ERROR

}

function Write-DebugLog {

    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Message)

    Write-Log $Message DEBUG

}

# ==================================================
# Retourne le fichier de log
# ==================================================

function Get-LogFile {

    [CmdletBinding()]
    param()

    return $script:LogFile

}

# ==================================================
# Durée du Build
# ==================================================

function Get-BuildDuration {

    [CmdletBinding()]
    param()

    if (-not $script:Stopwatch) {

        return [TimeSpan]::Zero

    }

    return $script:Stopwatch.Elapsed

}

# ==================================================
# Réinitialisation
# ==================================================

function Reset-Logger {

    [CmdletBinding()]
    param()

    if ($script:Stopwatch) {

        $script:Stopwatch.Reset()

    }

    $script:LogFile = $null

    $script:Quiet = $false

}