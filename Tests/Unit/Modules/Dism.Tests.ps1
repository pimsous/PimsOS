# ==========================================
# Tests : Dism
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    # --------------------------------------------------
    # Logger minimal pour les tests
    # --------------------------------------------------

    function global:Write-Log {

        param(
            [Parameter(Mandatory)]
            [string]$Message,

            [string]$Level = "INFO"
        )

    }

    # --------------------------------------------------
    # Chargement du module
    # --------------------------------------------------

    . "$ProjectRoot\Modules\Image\Dism.ps1"
}

Describe "Dism" {

    # ==================================================
    # Get-DismImages
    # ==================================================

    Context "Get-DismImages" {

        It "Retourne les images Windows" {

            function global:Get-WindowsImage {

                param(
                    [string]$ImagePath,
                    [switch]$Mounted
                )

                return @(
                    [pscustomobject]@{
                        ImageIndex = 1
                        ImageName  = "Windows 11 Pro"
                    }
                )
            }

            $Result = Get-DismImages `
                -ImagePath "C:\Test\install.wim"

            $Result.Count |
                Should -Be 1

            $Result[0].ImageIndex |
                Should -Be 1

        }

        It "Lève une exception si Get-WindowsImage échoue" {

            function global:Get-WindowsImage {

                throw "Erreur DISM"

            }

            {

                Get-DismImages `
                    -ImagePath "C:\Test\install.wim"

            } | Should -Throw "*Impossible de lire l'image Windows*"

        }

    }

    # ==================================================
    # Get-DismMountedImages
    # ==================================================

    Context "Get-DismMountedImages" {

        It "Retourne les images montées" {

            function global:Get-WindowsImage {

                param(
                    [string]$ImagePath,
                    [switch]$Mounted
                )

                return @(
                    [pscustomobject]@{
                        ImageIndex = 1
                        MountPath  = "C:\Mount"
                    }
                )
            }

            $Result = Get-DismMountedImages

            $Result.Count |
                Should -Be 1

            $Result[0].MountPath |
                Should -Be "C:\Mount"

        }

        It "Lève une exception si la récupération échoue" {

            function global:Get-WindowsImage {

                throw "Erreur DISM"

            }

            {

                Get-DismMountedImages

            } | Should -Throw "*Impossible d'obtenir la liste des images montées*"

        }

    }

    # ==================================================
    # Mount-DismImage
    # ==================================================

    Context "Mount-DismImage" {

        BeforeEach {

            $script:MountCalled = $false
            $script:MountParameters = $null

            function global:Mount-WindowsImage {

                param(
                    [string]$ImagePath,
                    [int]$Index,
                    [string]$Path,
                    [switch]$ReadOnly
                )

                $script:MountCalled = $true

                $script:MountParameters = [pscustomobject]@{
                    ImagePath = $ImagePath
                    Index     = $Index
                    Path      = $Path
                    ReadOnly  = $ReadOnly.IsPresent
                }

            }

        }

        It "Monte une image Windows" {

            $ImagePath = Join-Path $TestDrive "install.wim"
            $MountPath = Join-Path $TestDrive "Mount"

            New-Item `
                -ItemType File `
                -Path $ImagePath `
                -Force |
                Out-Null

            New-Item `
                -ItemType Directory `
                -Path $MountPath `
                -Force |
                Out-Null

            Mount-DismImage `
                -ImagePath $ImagePath `
                -Index 1 `
                -MountPath $MountPath

            $script:MountCalled |
                Should -BeTrue

            $script:MountParameters.ImagePath |
                Should -Be $ImagePath

            $script:MountParameters.Index |
                Should -Be 1

            $script:MountParameters.Path |
                Should -Be $MountPath

            $script:MountParameters.ReadOnly |
                Should -BeFalse

        }

        It "Transmet ReadOnly au moteur DISM" {

            $ImagePath = Join-Path $TestDrive "install.wim"
            $MountPath = Join-Path $TestDrive "Mount"

            New-Item `
                -ItemType File `
                -Path $ImagePath `
                -Force |
                Out-Null

            New-Item `
                -ItemType Directory `
                -Path $MountPath `
                -Force |
                Out-Null

            Mount-DismImage `
                -ImagePath $ImagePath `
                -Index 1 `
                -MountPath $MountPath `
                -ReadOnly

            $script:MountParameters.ReadOnly |
                Should -BeTrue

        }

        It "Refuse une image inexistante" {

            $MountPath = Join-Path $TestDrive "Mount"

            New-Item `
                -ItemType Directory `
                -Path $MountPath `
                -Force |
                Out-Null

            {

                Mount-DismImage `
                    -ImagePath (Join-Path $TestDrive "Inconnu.wim") `
                    -Index 1 `
                    -MountPath $MountPath

            } | Should -Throw "*image Windows est introuvable*"

        }

        It "Refuse un dossier de montage inexistant" {

            $ImagePath = Join-Path $TestDrive "install.wim"

            New-Item `
                -ItemType File `
                -Path $ImagePath `
                -Force |
                Out-Null

            {

                Mount-DismImage `
                    -ImagePath $ImagePath `
                    -Index 1 `
                    -MountPath (Join-Path $TestDrive "MountInconnu")

            } | Should -Throw "*dossier de montage est introuvable*"

        }

        It "Lève une exception si le montage DISM échoue" {

            $ImagePath = Join-Path $TestDrive "install.wim"
            $MountPath = Join-Path $TestDrive "Mount"

            New-Item `
                -ItemType File `
                -Path $ImagePath `
                -Force |
                Out-Null

            New-Item `
                -ItemType Directory `
                -Path $MountPath `
                -Force |
                Out-Null

            function global:Mount-WindowsImage {

                throw "Erreur montage"

            }

            {

                Mount-DismImage `
                    -ImagePath $ImagePath `
                    -Index 1 `
                    -MountPath $MountPath

            } | Should -Throw "*Impossible de monter l'image Windows*"

        }

    }

    # ==================================================
    # Save-DismImage
    # ==================================================

    Context "Save-DismImage" {

        It "Sauvegarde une image montée" {

            $MountPath = Join-Path $TestDrive "Mount"

            New-Item `
                -ItemType Directory `
                -Path $MountPath `
                -Force |
                Out-Null

            $script:SaveCalled = $false

            function global:Save-WindowsImage {

                param(
                    [string]$Path
                )

                $script:SaveCalled = $true

            }

            Save-DismImage `
                -MountPath $MountPath

            $script:SaveCalled |
                Should -BeTrue

        }

        It "Refuse un dossier de montage inexistant" {

            {

                Save-DismImage `
                    -MountPath (Join-Path $TestDrive "MountInconnu")

            } | Should -Throw "*dossier de montage est introuvable*"

        }

        It "Lève une exception si la sauvegarde échoue" {

            $MountPath = Join-Path $TestDrive "Mount"

            New-Item `
                -ItemType Directory `
                -Path $MountPath `
                -Force |
                Out-Null

            function global:Save-WindowsImage {

                throw "Erreur sauvegarde"

            }

            {

                Save-DismImage `
                    -MountPath $MountPath

            } | Should -Throw "*Impossible de sauvegarder l'image Windows*"

        }

    }

    # ==================================================
    # Dismount-DismImage
    # ==================================================

    Context "Dismount-DismImage" {

        BeforeEach {

            $script:DismountParameters = $null

            function global:Dismount-WindowsImage {

                param(
                    [string]$Path,
                    [switch]$Save,
                    [switch]$Discard
                )

                $script:DismountParameters = [pscustomobject]@{
                    Path    = $Path
                    Save    = $Save.IsPresent
                    Discard = $Discard.IsPresent
                }

            }

        }

        It "Démonte une image en sauvegardant les modifications" {

            $MountPath = Join-Path $TestDrive "Mount"

            New-Item `
                -ItemType Directory `
                -Path $MountPath `
                -Force |
                Out-Null

            Dismount-DismImage `
                -MountPath $MountPath

            $script:DismountParameters.Path |
                Should -Be $MountPath

            $script:DismountParameters.Save |
                Should -BeTrue

            $script:DismountParameters.Discard |
                Should -BeFalse

        }

        It "Démonte une image sans conserver les modifications" {

            $MountPath = Join-Path $TestDrive "Mount"

            New-Item `
                -ItemType Directory `
                -Path $MountPath `
                -Force |
                Out-Null

            Dismount-DismImage `
                -MountPath $MountPath `
                -Discard

            $script:DismountParameters.Path |
                Should -Be $MountPath

            $script:DismountParameters.Save |
                Should -BeFalse

            $script:DismountParameters.Discard |
                Should -BeTrue

        }

        It "Refuse un dossier de montage inexistant" {

            {

                Dismount-DismImage `
                    -MountPath (Join-Path $TestDrive "MountInconnu")

            } | Should -Throw "*dossier de montage est introuvable*"

        }

        It "Lève une exception si le démontage échoue" {

            $MountPath = Join-Path $TestDrive "Mount"

            New-Item `
                -ItemType Directory `
                -Path $MountPath `
                -Force |
                Out-Null

            function global:Dismount-WindowsImage {

                throw "Erreur démontage"

            }

            {

                Dismount-DismImage `
                    -MountPath $MountPath

            } | Should -Throw "*Impossible de démonter l'image Windows*"

        }

    }

}