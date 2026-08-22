# ==========================================
# Tests : Iso
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Core\Core.ps1"
    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"
    . "$ProjectRoot\Modules\Image\Iso.ps1"

}

Describe "Iso" {

    BeforeEach {

        Reset-Core
        Reset-Logger

        $script:Context = [pscustomobject]@{}

        # --------------------------------------------------
        # Environnement ISO de test
        # --------------------------------------------------

        $script:IsoFolder = Join-Path $TestDrive "ISO"

        New-Item `
            -ItemType Directory `
            -Path $script:IsoFolder `
            -Force |
            Out-Null

        # Get-IsoFile utilise Get-ProjectPath ISO.
        # On redirige donc le chemin ISO vers TestDrive.
        Mock Get-ProjectPath {

            param(
                [string]$Name
            )

            if ($Name -eq "ISO") {

                return $script:IsoFolder

            }

            throw "Get-ProjectPath non prévu dans ce test : $Name"
        }

    }

    Context "New-IsoMountState" {

        It "Retourne un objet IsoMountState" {

            $State = New-IsoMountState

            $State.ObjectType |
                Should -Be "IsoMountState"

        }

        It "Initialise Exists à False" {

            (New-IsoMountState).Exists |
                Should -BeFalse

        }

        It "Initialise Mounted à False" {

            (New-IsoMountState).Mounted |
                Should -BeFalse

        }

    }

    Context "Get-IsoFile" {

        It "Retourne les informations de l'ISO" {

            $IsoPath = Join-Path `
                $script:IsoFolder `
                "Win11_25H2_French_x64.iso"

            New-Item `
                -ItemType File `
                -Path $IsoPath `
                -Force |
                Out-Null

            $Iso = Get-IsoFile `
                -Context $script:Context

            $Iso |
                Should -Not -BeNullOrEmpty

            $Iso.Name |
                Should -Be "Win11_25H2_French_x64.iso"

            $Iso.FullName |
                Should -Be $IsoPath

        }

    }

    Context "Test-IsoFile" {

        It "Retourne un résultat de validation" {

            Mock Get-IsoFile {

                return [PSCustomObject]@{
                    Name      = "Test.iso"
                    FullName  = "C:\Test\Test.iso"
                    SizeGB    = 5.0
                    LastWrite = Get-Date
                }

            }

            $Result = Test-IsoFile `
                -Context $script:Context

            $Result |
                Should -Not -BeNullOrEmpty

            $Result.Success |
                Should -BeTrue

            $Result.Message |
                Should -Be "ISO valide."

        }

    }

    Context "Get-IsoInformation" {

        It "Retourne les informations principales" {

            $LastWrite = Get-Date

            Mock Get-IsoFile {

                return [PSCustomObject]@{
                    Name      = "Test.iso"
                    FullName  = "C:\Test\Test.iso"
                    SizeGB    = 5.0
                    LastWrite = $LastWrite
                }

            }

            $Info = Get-IsoInformation `
                -Context $script:Context

            $Info |
                Should -Not -BeNullOrEmpty

            $Info.Name |
                Should -Be "Test.iso"

            $Info.SizeGB |
                Should -Be 5.0

            $Info.LastWrite |
                Should -Be $LastWrite

        }

    }

    Context "Copy-IsoToWorkspace" {

        It "Retourne le chemin de destination" {

            Mock Write-Log {}

            Mock Get-Config {

                return [PSCustomObject]@{
                    Workspace = [PSCustomObject]@{
                        ISO = "Workspace\ISO"
                    }
                }

            }

            Mock Get-ProjectRoot {
                return $TestDrive
            }

            $IsoPath = Join-Path `
                $script:IsoFolder `
                "Win11_25H2_French_x64.iso"

            Set-Content `
                -Path $IsoPath `
                -Value "ISO TEST" `
                -Encoding UTF8

            $Destination = Copy-IsoToWorkspace `
                -Context $script:Context

            $ExpectedDestination = Join-Path `
                $TestDrive `
                "Workspace\ISO\Win11_25H2_French_x64.iso"

            $Destination |
                Should -Be $ExpectedDestination

            Test-Path $Destination |
                Should -BeTrue

            Get-Content $Destination |
                Should -Be "ISO TEST"

        }

    }

}