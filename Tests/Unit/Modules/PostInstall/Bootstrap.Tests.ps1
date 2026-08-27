# ==========================================
# Tests : PostInstall Bootstrap
# Projet : PimsOS Builder
# ==========================================

$ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..\..").Path

Describe "PostInstall Bootstrap" {

    BeforeEach {
		
		$TestProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..\..").Path

		. "$TestProjectRoot\Modules\PostInstall\Bootstrap.ps1"

        $script:RuntimePath = Join-Path `
            $TestDrive `
            "PostInstall"

        New-Item `
            -ItemType Directory `
            -Path $script:RuntimePath `
            -Force |
            Out-Null

        $script:StatePath = Join-Path `
            $script:RuntimePath `
            "State.ps1"

        $script:NetworkPath = Join-Path `
            $script:RuntimePath `
            "Network.ps1"

        $script:PostInstallPath = Join-Path `
            $script:RuntimePath `
            "PostInstall.ps1"

        Set-Content `
            -Path $script:StatePath `
            -Value 'function New-BootstrapState {}' `
            -Encoding UTF8

        Set-Content `
            -Path $script:NetworkPath `
            -Value 'function Test-BootstrapNetwork { return $true }' `
            -Encoding UTF8

        Set-Content `
            -Path $script:PostInstallPath `
            -Value 'function Invoke-PostInstall { return "OK" }' `
            -Encoding UTF8

    }

    Context "Start-PimsOSPostInstall" {

        It "Refuse un répertoire runtime inexistant" {

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

            {

                Start-PimsOSPostInstall `
                    -RuntimePath $script:RuntimePath

            } |
                Should -Throw "*Fichier PostInstall requis introuvable*"

        }

        It "Charge les composants du runtime" {

            $Result = Start-PimsOSPostInstall `
                -RuntimePath $script:RuntimePath

            $Result |
                Should -Be "OK"

        }

        It "Transmet WaitForNetwork" {

            Set-Content `
                -Path $script:PostInstallPath `
                -Value 'function Invoke-PostInstall { param([switch]$WaitForNetwork,[int]$NetworkTimeoutMinutes) if (-not $WaitForNetwork) { throw "WaitForNetwork absent" } return $true }' `
                -Encoding UTF8

            $Result = Start-PimsOSPostInstall `
                -RuntimePath $script:RuntimePath `
                -WaitForNetwork

            $Result |
                Should -BeTrue

        }

        It "Transmet le timeout réseau" {

            Set-Content `
                -Path $script:PostInstallPath `
                -Value 'function Invoke-PostInstall { param([switch]$WaitForNetwork,[int]$NetworkTimeoutMinutes) if ($NetworkTimeoutMinutes -ne 15) { throw "Timeout incorrect" } return $true }' `
                -Encoding UTF8

            $Result = Start-PimsOSPostInstall `
                -RuntimePath $script:RuntimePath `
                -WaitForNetwork `
                -NetworkTimeoutMinutes 15

            $Result |
                Should -BeTrue

        }

        It "Transforme une erreur du moteur en erreur Bootstrap" {

            Set-Content `
                -Path $script:PostInstallPath `
                -Value 'function Invoke-PostInstall { throw "Erreur moteur PostInstall" }' `
                -Encoding UTF8

            {

                Start-PimsOSPostInstall `
                    -RuntimePath $script:RuntimePath

            } |
                Should -Throw "*Bootstrap PimsOS a échoué*"

        }

    }

}


