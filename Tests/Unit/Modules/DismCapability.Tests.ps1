# ==========================================
# Tests : Dism Capability Provider
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"

    # --------------------------------------------------
    # Providers DISM simulés
    # --------------------------------------------------

    function global:Add-WindowsCapability {

        param(
            [string]$Path,
            [string]$Name,
            [string]$Source,
            [switch]$LimitAccess,
            [string]$ErrorAction
        )

        $script:ReceivedAdd = [pscustomobject]@{
            Path        = $Path
            Name        = $Name
            Source      = $Source
            LimitAccess = [bool]$LimitAccess
        }

    }

    function global:Remove-WindowsCapability {

        param(
            [string]$Path,
            [string]$Name,
            [string]$ErrorAction
        )

        $script:ReceivedRemove = [pscustomobject]@{
            Path = $Path
            Name = $Name
        }

    }

    . "$ProjectRoot\Modules\Image\Dism.ps1"

}

Describe "Invoke-DismCapability" {

    BeforeEach {

        Reset-Logger

        Mock Write-Log {}

        $script:ReceivedAdd = $null
        $script:ReceivedRemove = $null

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

        It "Active une capability Windows via DISM" {

            $Action = [pscustomobject]@{

                Name   = "Microsoft.Windows.Notepad"
                Enable = $true

            }

            $Result = Invoke-DismCapability `
                -Context $script:Context `
                -Action $Action

            $Result |
                Should -Be $null

            $script:ReceivedAdd.Name |
                Should -Be "Microsoft.Windows.Notepad"

            $script:ReceivedAdd.Path |
                Should -Be $MountPath

            $script:ReceivedAdd.LimitAccess |
                Should -BeFalse

        }

    }


    Context "Desactivation" {

        It "Desactive une capability Windows via DISM" {

            $Action = [pscustomobject]@{

                Name   = "Microsoft.Windows.Notepad"
                Enable = $false

            }

            $Result = Invoke-DismCapability `
                -Context $script:Context `
                -Action $Action

            $Result |
                Should -Be $null

            $script:ReceivedRemove.Name |
                Should -Be "Microsoft.Windows.Notepad"

            $script:ReceivedRemove.Path |
                Should -Be $MountPath

        }

    }


    Context "Validation" {

        It "Refuse un nom absent" {

            $Action = [pscustomobject]@{

                Name   = $null
                Enable = $true

            }

            {

                Invoke-DismCapability `
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

                Name   = "Microsoft.Windows.Notepad"
                Enable = $true

            }

            {

                Invoke-DismCapability `
                    -Context $Context `
                    -Action $Action

            } |
                Should -Throw

        }

    }

}
