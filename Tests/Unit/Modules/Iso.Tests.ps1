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

    }

    Context "New-IsoMountState" {

        It "Retourne un objet IsoMountState" {

            $State = New-IsoMountState

            $State.ObjectType | Should -Be "IsoMountState"

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

            $Iso = Get-IsoFile `
                -Context $script:Context

            $Iso |
                Should -Not -BeNullOrEmpty

            $Iso.Name |
                Should -Match "\.iso$"

        }

    }

    Context "Test-IsoFile" {

        It "Retourne un résultat de validation" {

            $Result = Test-IsoFile `
                -Context $script:Context

            $Result.Success |
                Should -BeOfType ([bool])

        }

    }

    Context "Get-IsoInformation" {

        It "Retourne les informations principales" {

            $Info = Get-IsoInformation `
                -Context $script:Context

            $Info.Name |
                Should -Not -BeNullOrEmpty

            $Info.SizeGB |
                Should -BeGreaterThan 0

        }

    }

    Context "Copy-IsoToWorkspace" {

        It "Retourne le chemin de destination" {

            Mock Write-Log {}

            $Destination = Copy-IsoToWorkspace `
                -Context $script:Context

            $Destination |
                Should -Not -BeNullOrEmpty

            Test-Path $Destination |
                Should -BeTrue

        }

    }

}