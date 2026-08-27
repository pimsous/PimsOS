# ==========================================
# Tests : Dism
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    # --------------------------------------------------
    # Logger minimal pour les tests
    # --------------------------------------------------

    function Write-Log {

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

            Mock Get-WindowsImage {
				@(
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

            Mock Get-WindowsImage {
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

            Mock Get-WindowsImage {
				@(
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

            Mock Get-WindowsImage {
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

			Mock Mount-WindowsImage {
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

            Mock Mount-WindowsImage {
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

			Mock Save-WindowsImage {
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

            Mock Save-WindowsImage {
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

			Mock Dismount-WindowsImage {
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

            Mock Dismount-WindowsImage {
				throw "Erreur démontage"
			}

            {

                Dismount-DismImage `
                    -MountPath $MountPath

            } | Should -Throw "*Impossible de démonter l'image Windows*"

        }

    }
	# ==================================================
    # Add-DismDriver
    # ==================================================

    Context "Add-DismDriver" {

        It "Ajoute les pilotes à une image montée" {

            $MountPath = Join-Path $TestDrive "Mount"
            $DriverPath = Join-Path $TestDrive "Drivers"

            New-Item `
                -ItemType Directory `
                -Path $MountPath `
                -Force |
                Out-Null

            New-Item `
                -ItemType Directory `
                -Path $DriverPath `
                -Force |
                Out-Null

            Mock Add-WindowsDriver {

                [PSCustomObject]@{
                    Driver = "TestDriver"
                }

            }

            $Result = Add-DismDriver `
                -MountPath $MountPath `
                -DriverPath $DriverPath

            $Result |
                Should -Not -BeNullOrEmpty

            Should -Invoke Add-WindowsDriver -Times 1 -Exactly `
                -ParameterFilter {

                    $Path -eq $MountPath -and
                    $Driver -eq $DriverPath

                }

        }

        It "Transmet Recurse à DISM" {

            $MountPath = Join-Path $TestDrive "Mount"
            $DriverPath = Join-Path $TestDrive "Drivers"

            New-Item `
                -ItemType Directory `
                -Path $MountPath `
                -Force |
                Out-Null

            New-Item `
                -ItemType Directory `
                -Path $DriverPath `
                -Force |
                Out-Null

            Mock Add-WindowsDriver {}

            $null = Add-DismDriver `
                -MountPath $MountPath `
                -DriverPath $DriverPath `
                -Recurse

            Should -Invoke Add-WindowsDriver -Times 1 -Exactly `
                -ParameterFilter {

                    $Recurse -eq $true

                }

        }

        It "Transmet ForceUnsigned lorsqu'il est demandé" {

            $MountPath = Join-Path $TestDrive "Mount"
            $DriverPath = Join-Path $TestDrive "Drivers"

            New-Item `
                -ItemType Directory `
                -Path $MountPath `
                -Force |
                Out-Null

            New-Item `
                -ItemType Directory `
                -Path $DriverPath `
                -Force |
                Out-Null

            Mock Add-WindowsDriver {}

            $null = Add-DismDriver `
                -MountPath $MountPath `
                -DriverPath $DriverPath `
                -ForceUnsigned

            Should -Invoke Add-WindowsDriver -Times 1 -Exactly `
                -ParameterFilter {

                    $ForceUnsigned -eq $true

                }

        }

        It "Refuse un dossier de montage inexistant" {

            $DriverPath = Join-Path $TestDrive "Drivers"

            New-Item `
                -ItemType Directory `
                -Path $DriverPath `
                -Force |
                Out-Null

            {

                Add-DismDriver `
                    -MountPath (Join-Path $TestDrive "MissingMount") `
                    -DriverPath $DriverPath

            } |
                Should -Throw "*dossier de montage est introuvable*"

        }

        It "Refuse une source de pilotes inexistante" {

            $MountPath = Join-Path $TestDrive "Mount"

            New-Item `
                -ItemType Directory `
                -Path $MountPath `
                -Force |
                Out-Null

            {

                Add-DismDriver `
                    -MountPath $MountPath `
                    -DriverPath (Join-Path $TestDrive "MissingDrivers")

            } |
                Should -Throw "*source des pilotes est introuvable*"

        }

        It "Transforme une erreur DISM en exception PimsOS" {

            $MountPath = Join-Path $TestDrive "Mount"
            $DriverPath = Join-Path $TestDrive "Drivers"

            New-Item `
                -ItemType Directory `
                -Path $MountPath `
                -Force |
                Out-Null

            New-Item `
                -ItemType Directory `
                -Path $DriverPath `
                -Force |
                Out-Null

            Mock Add-WindowsDriver {

                throw "Erreur DISM de test"

            }

            {

                Add-DismDriver `
                    -MountPath $MountPath `
                    -DriverPath $DriverPath

            } |
                Should -Throw "*Erreur DISM de test*"

        }

    }
    # ==================================================
    # Export-DismCurrentSystemDrivers
    # ==================================================

    Context "Export-DismCurrentSystemDrivers" {

        It "Exporte les drivers du système actuel" {

            $DestinationPath = Join-Path `
                $TestDrive `
                "Drivers"

            Mock Export-WindowsDriver {

                [PSCustomObject]@{

                    Driver = "oem-test.inf"

                }

            }

            $Result = Export-DismCurrentSystemDrivers `
                -DestinationPath $DestinationPath

            $Result |
                Should -Not -BeNullOrEmpty

            Test-Path `
                -LiteralPath $DestinationPath `
                -PathType Container |
                Should -BeTrue

            Should -Invoke `
                -CommandName Export-WindowsDriver `
                -Times 1 `
                -Exactly `
                -ParameterFilter {

                    $Online -eq $true -and
                    $Destination -eq $DestinationPath

                }

        }

        It "Crée le dossier de destination s'il n'existe pas" {

            $DestinationPath = Join-Path `
                $TestDrive `
                "NewDrivers"

            Mock Export-WindowsDriver {}

            $null = Export-DismCurrentSystemDrivers `
                -DestinationPath $DestinationPath

            Test-Path `
                -LiteralPath $DestinationPath `
                -PathType Container |
                Should -BeTrue

        }

        It "Refuse une destination qui est un fichier" {

            $DestinationPath = Join-Path `
                $TestDrive `
                "Drivers.txt"

            New-Item `
                -ItemType File `
                -Path $DestinationPath `
                -Force |
                Out-Null

            {

                Export-DismCurrentSystemDrivers `
                    -DestinationPath $DestinationPath

            } |
                Should -Throw "*n'est pas un dossier*"

        }

        It "Nettoie un ancien export avant l'export" {

            $DestinationPath = Join-Path `
                $TestDrive `
                "Drivers"

            New-Item `
                -ItemType Directory `
                -Path $DestinationPath `
                -Force |
                Out-Null

            $OldFile = Join-Path `
                $DestinationPath `
                "old-driver.txt"

            Set-Content `
                -Path $OldFile `
                -Value "old" `
                -Encoding UTF8

            Mock Export-WindowsDriver {}

            $null = Export-DismCurrentSystemDrivers `
                -DestinationPath $DestinationPath

            Test-Path `
                -LiteralPath $OldFile |
                Should -BeFalse

            Should -Invoke `
                -CommandName Export-WindowsDriver `
                -Times 1 `
                -Exactly

        }

        It "Transforme une erreur Export-WindowsDriver" {

            $DestinationPath = Join-Path `
                $TestDrive `
                "Drivers"

            Mock Export-WindowsDriver {

                throw "Erreur export de test"

            }

            {

                Export-DismCurrentSystemDrivers `
                    -DestinationPath $DestinationPath

            } |
                Should -Throw "*Erreur export de test*"

        }

    }
}