# ==========================================
# Tests : PostInstall Bootstrap
# Projet : PimsOS Builder
# ==========================================

$ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..\..").Path

Describe "PostInstall Bootstrap" {

    BeforeEach {

        $TestProjectRoot = (
            Resolve-Path "$PSScriptRoot\..\..\..\.."
        ).Path

        $script:RuntimePath = Join-Path `
            $TestDrive `
            "PostInstall"

        New-Item `
            -ItemType Directory `
            -Path $script:RuntimePath `
            -Force |
            Out-Null

        # --------------------------------------------------
        # Chemins du runtime
        # --------------------------------------------------

        $script:BootstrapPath = Join-Path `
            $script:RuntimePath `
            "Bootstrap.ps1"

        $script:LoggerPath = Join-Path `
            $script:RuntimePath `
            "Logger.ps1"

        $script:StatePath = Join-Path `
            $script:RuntimePath `
            "State.ps1"

        $script:NetworkPath = Join-Path `
            $script:RuntimePath `
            "Network.ps1"

        $script:UIPath = Join-Path `
            $script:RuntimePath `
            "UI.ps1"

        $script:DriverCheckPath = Join-Path `
            $script:RuntimePath `
            "DriverCheck.ps1"

        $script:ChocolateyPath = Join-Path `
            $script:RuntimePath `
            "Chocolatey.ps1"

        $script:PostInstallPath = Join-Path `
            $script:RuntimePath `
            "PostInstall.ps1"

        $script:FinalizePath = Join-Path `
            $script:RuntimePath `
            "Finalize.ps1"

        # --------------------------------------------------
        # Logger de test
        # --------------------------------------------------

        Set-Content `
            -Path $script:LoggerPath `
            -Value @'
$script:TestLoggerStarted = $false
$script:TestLoggerPath = $null

function Start-Logger {

    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [switch]$Quiet
    )

    $script:TestLoggerStarted = $true
    $script:TestLoggerPath = $Path

}

function Write-Log {

    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

}
'@ `
            -Encoding UTF8

        # --------------------------------------------------
        # State
        # --------------------------------------------------

        Set-Content `
            -Path $script:StatePath `
            -Value @'
function New-BootstrapState {
    return [pscustomobject]@{ StatePath = $null }
}

function Save-PostInstallState {
    param(
        [Parameter(Mandatory)]
        [psobject]$State,

        [string]$StatePath
    )

    return $State
}
'@ `
            -Encoding UTF8

        # --------------------------------------------------
        # Network
        # --------------------------------------------------

        Set-Content `
            -Path $script:NetworkPath `
            -Value 'function Test-BootstrapNetwork { return $true }' `
            -Encoding UTF8

        # --------------------------------------------------
        # UI
        # --------------------------------------------------

        Set-Content `
            -Path $script:UIPath `
            -Value 'function Show-BootstrapUI {}' `
            -Encoding UTF8

        # --------------------------------------------------
        # DriverCheck
        # --------------------------------------------------

        Set-Content `
            -Path $script:DriverCheckPath `
            -Value 'function Test-PostInstallDrivers { return [pscustomobject]@{ Available = $true; Problems = @() } }' `
            -Encoding UTF8

        # --------------------------------------------------
        # Chocolatey
        # --------------------------------------------------

        Set-Content `
            -Path $script:ChocolateyPath `
            -Value 'function Invoke-ChocolateyCatalog { return $true }' `
            -Encoding UTF8

        # --------------------------------------------------
        # PostInstall
        # --------------------------------------------------

        Set-Content `
            -Path $script:PostInstallPath `
            -Value 'function Invoke-PostInstall { return [pscustomobject]@{ StatePath = "state.json" } }' `
            -Encoding UTF8

$script:FinalizeCalled = $false

        Set-Content `
            -Path $script:FinalizePath `
            -Value 'function Complete-PimsOSPostInstall { param($State,$RuntimePath) $script:FinalizeCalled = $true; return [pscustomobject]@{ State = $State; Cleanup = [pscustomobject]@{ Scheduled = $true; DelaySeconds = 10 } } }' `
            -Encoding UTF8

        # --------------------------------------------------
        # Bootstrap source
        # --------------------------------------------------

        Copy-Item `
            -LiteralPath (
                Join-Path `
                    $TestProjectRoot `
                    "Modules\PostInstall\Bootstrap.ps1"
            ) `
            -Destination $script:BootstrapPath `
            -Force

    }

    # ==================================================
    # Start-PimsOSPostInstall
    # ==================================================

    Context "Start-PimsOSPostInstall" {

        It "Refuse un répertoire runtime inexistant" {

            $BootstrapContent = Get-Content `
                -LiteralPath $script:BootstrapPath `
                -Raw `
                -Encoding UTF8

            $BootstrapContent = $BootstrapContent -replace `
                '(?ms)\r?\n# --------------------------------------------------\r?\n# Point d''entrée\r?\n# --------------------------------------------------\r?\n\r?\nStart-PimsOSPostInstall\s*$', ''

            . ([scriptblock]::Create($BootstrapContent))

            {

                Start-PimsOSPostInstall `
                    -RuntimePath (
                        Join-Path `
                            $TestDrive `
                            "Missing"
                    )

            } |
                Should -Throw "*répertoire du runtime PostInstall est introuvable*"

        }


        It "Refuse un runtime incomplet" {

            Remove-Item `
                -LiteralPath $script:NetworkPath `
                -Force

            $BootstrapContent = Get-Content `
                -LiteralPath $script:BootstrapPath `
                -Raw `
                -Encoding UTF8

            $BootstrapContent = $BootstrapContent -replace `
                '(?ms)\r?\n# --------------------------------------------------\r?\n# Point d''entrée\r?\n# --------------------------------------------------\r?\n\r?\nStart-PimsOSPostInstall\s*$', ''

            . ([scriptblock]::Create($BootstrapContent))

            {

                Start-PimsOSPostInstall `
                    -RuntimePath $script:RuntimePath

            } |
                Should -Throw "*Fichier PostInstall requis introuvable*"

        }


        It "Charge les composants du runtime" {

            $BootstrapContent = Get-Content `
                -LiteralPath $script:BootstrapPath `
                -Raw `
                -Encoding UTF8

            $BootstrapContent = $BootstrapContent -replace `
                '(?ms)\r?\n# --------------------------------------------------\r?\n# Point d''entrée\r?\n# --------------------------------------------------\r?\n\r?\nStart-PimsOSPostInstall\s*$', ''

            . ([scriptblock]::Create($BootstrapContent))

            $Result =
                Start-PimsOSPostInstall `
                    -RuntimePath $script:RuntimePath

            $Result.StatePath |
                Should -Be "state.json"

        }


        It "Charge Logger.ps1" {

            $BootstrapContent = Get-Content `
                -LiteralPath $script:BootstrapPath `
                -Raw `
                -Encoding UTF8

            $BootstrapContent = $BootstrapContent -replace `
                '(?ms)\r?\n# --------------------------------------------------\r?\n# Point d''entrée\r?\n# --------------------------------------------------\r?\n\r?\nStart-PimsOSPostInstall\s*$', ''

            . ([scriptblock]::Create($BootstrapContent))

            $null =
                Start-PimsOSPostInstall `
                    -RuntimePath $script:RuntimePath

            $script:TestLoggerStarted |
                Should -BeTrue

        }


        It "Initialise le Logger avec le chemin PostInstall.log" {

            $BootstrapContent = Get-Content `
                -LiteralPath $script:BootstrapPath `
                -Raw `
                -Encoding UTF8

            $BootstrapContent = $BootstrapContent -replace `
                '(?ms)\r?\n# --------------------------------------------------\r?\n# Point d''entrée\r?\n# --------------------------------------------------\r?\n\r?\nStart-PimsOSPostInstall\s*$', ''

            . ([scriptblock]::Create($BootstrapContent))

            $null =
                Start-PimsOSPostInstall `
                    -RuntimePath $script:RuntimePath

            $script:TestLoggerPath |
                Should -Be (
                    Join-Path `
                        $script:RuntimePath `
                        "PostInstall.log"
                )

        }



        It "Effectue la vérification finale après le PostInstall" {

            $BootstrapContent = Get-Content `
                -LiteralPath $script:BootstrapPath `
                -Raw `
                -Encoding UTF8

            $BootstrapContent = $BootstrapContent -replace `
                '(?ms)\r?\n# --------------------------------------------------\r?\n# Point d''entrée\r?\n# --------------------------------------------------\r?\n\r?\nStart-PimsOSPostInstall\s*$', ''

            . ([scriptblock]::Create($BootstrapContent))

            $null = Start-PimsOSPostInstall -RuntimePath $script:RuntimePath

            $script:FinalizeCalled | Should -BeTrue

        }

        It "Transmet WaitForNetwork" {

            Set-Content `
                -Path $script:PostInstallPath `
                -Value 'function Invoke-PostInstall { param([switch]$WaitForNetwork,[int]$NetworkTimeoutMinutes) if (-not $WaitForNetwork) { throw "WaitForNetwork absent" } return [pscustomobject]@{ StatePath = "state.json" } }' `
                -Encoding UTF8

            $BootstrapContent = Get-Content `
                -LiteralPath $script:BootstrapPath `
                -Raw `
                -Encoding UTF8

            $BootstrapContent = $BootstrapContent -replace `
                '(?ms)\r?\n# --------------------------------------------------\r?\n# Point d''entrée\r?\n# --------------------------------------------------\r?\n\r?\nStart-PimsOSPostInstall\s*$', ''

            . ([scriptblock]::Create($BootstrapContent))

            $Result =
                Start-PimsOSPostInstall `
                    -RuntimePath $script:RuntimePath `
                    -WaitForNetwork

            $Result.StatePath |
                Should -Be "state.json"

        }


        It "Transmet le timeout réseau" {

            Set-Content `
                -Path $script:PostInstallPath `
                -Value 'function Invoke-PostInstall { param([switch]$WaitForNetwork,[int]$NetworkTimeoutMinutes) if ($NetworkTimeoutMinutes -ne 15) { throw "Timeout incorrect" } return [pscustomobject]@{ StatePath = "state.json" } }' `
                -Encoding UTF8

            $BootstrapContent = Get-Content `
                -LiteralPath $script:BootstrapPath `
                -Raw `
                -Encoding UTF8

            $BootstrapContent = $BootstrapContent -replace `
                '(?ms)\r?\n# --------------------------------------------------\r?\n# Point d''entrée\r?\n# --------------------------------------------------\r?\n\r?\nStart-PimsOSPostInstall\s*$', ''

            . ([scriptblock]::Create($BootstrapContent))

            $Result =
                Start-PimsOSPostInstall `
                    -RuntimePath $script:RuntimePath `
                    -WaitForNetwork `
                    -NetworkTimeoutMinutes 15

            $Result.StatePath |
                Should -Be "state.json"

        }


        It "Transforme une erreur du moteur en erreur Bootstrap" {

            Set-Content `
                -Path $script:PostInstallPath `
                -Value 'function Invoke-PostInstall { throw "Erreur moteur PostInstall" }' `
                -Encoding UTF8

            $BootstrapContent = Get-Content `
                -LiteralPath $script:BootstrapPath `
                -Raw `
                -Encoding UTF8

            $BootstrapContent = $BootstrapContent -replace `
                '(?ms)\r?\n# --------------------------------------------------\r?\n# Point d''entrée\r?\n# --------------------------------------------------\r?\n\r?\nStart-PimsOSPostInstall\s*$', ''

            . ([scriptblock]::Create($BootstrapContent))

            {

                Start-PimsOSPostInstall `
                    -RuntimePath $script:RuntimePath

            } |
                Should -Throw "*Bootstrap PimsOS a échoué*"

        }

    }

}