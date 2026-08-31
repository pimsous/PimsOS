# ==========================================
# Tests : Dism Feature Provider
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"

    # --------------------------------------------------
    # Providers DISM simulés
    # --------------------------------------------------

    function global:Enable-WindowsOptionalFeature {

        param(
            [string]$Path,
            [string]$FeatureName,
            [switch]$All,
            [switch]$NoRestart,
            [string]$ErrorAction
        )

        $script:ReceivedEnable = [pscustomobject]@{
            Path        = $Path
            FeatureName = $FeatureName
            All         = [bool]$All
            NoRestart   = [bool]$NoRestart
        }

    }

    function global:Disable-WindowsOptionalFeature {

        param(
            [string]$Path,
            [string]$FeatureName,
            [switch]$NoRestart,
            [string]$ErrorAction
        )

        $script:ReceivedDisable = [pscustomobject]@{
            Path        = $Path
            FeatureName = $FeatureName
            NoRestart   = [bool]$NoRestart
        }

    }

    . "$ProjectRoot\Modules\Image\Dism.ps1"

}

Describe "Invoke-DismFeature" {

    BeforeEach {

        Reset-Logger

        Mock Write-Log {}

        $script:ReceivedEnable = $null
        $script:ReceivedDisable = $null

        $MountPath = Join-Path $TestDrive "Mount"

        New-Item `
            -ItemType Directory `
            -Path $MountPath `
            -Force |
            Out-Null

        $script:Context = [pscustomobject]@{

            WIM = [pscustomobject]@{

                Mount = [pscustomobject]@{

                    Path = $MountPath

                }

            }

        }

    }


    Context "Activation" {

        It "Active une fonctionnalité Windows via DISM" {

            $Action = [pscustomobject]@{

                Name   = "Microsoft-Windows-Feature"
                Enable = $true

            }

            $Result = Invoke-DismFeature `
                -Context $script:Context `
                -Action $Action

            $Result |
                Should -Be $script:Context

            $script:ReceivedEnable.FeatureName |
                Should -Be "Microsoft-Windows-Feature"

            $script:ReceivedEnable.Path |
                Should -Be $MountPath

            $script:ReceivedEnable.All |
                Should -BeTrue

            $script:ReceivedEnable.NoRestart |
                Should -BeTrue

        }

    }


    Context "Desactivation" {

        It "Desactive une fonctionnalité Windows via DISM" {

            $Action = [pscustomobject]@{

                Name   = "Microsoft-Windows-Feature"
                Enable = $false

            }

            $Result = Invoke-DismFeature `
                -Context $script:Context `
                -Action $Action

            $Result |
                Should -Be $script:Context

            $script:ReceivedDisable.FeatureName |
                Should -Be "Microsoft-Windows-Feature"

            $script:ReceivedDisable.Path |
                Should -Be $MountPath

            $script:ReceivedDisable.NoRestart |
                Should -BeTrue

        }

    }


    Context "Validation" {

        It "Refuse un nom absent" {

            $Action = [pscustomobject]@{

                Name   = $null
                Enable = $true

            }

            {

                Invoke-DismFeature `
                    -Context $script:Context `
                    -Action $Action

            } |
                Should -Throw

        }


        It "Refuse une image non montée" {

            $Context = [pscustomobject]@{

                WIM = [pscustomobject]@{

                    Mount = [pscustomobject]@{

                        Path = $null

                    }

                }

            }

            $Action = [pscustomobject]@{

                Name   = "Microsoft-Windows-Feature"
                Enable = $true

            }

            {

                Invoke-DismFeature `
                    -Context $Context `
                    -Action $Action

            } |
                Should -Throw

        }

    }

}
