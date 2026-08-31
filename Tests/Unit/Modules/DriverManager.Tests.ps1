# ==========================================
# Tests : DriverManager
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"
    . "$ProjectRoot\Modules\Image\Dism.ps1"
    . "$ProjectRoot\Modules\Managers\DriverManager.ps1"

    # --------------------------------------------------
    # Provider de test
    # --------------------------------------------------

    function global:Invoke-TestDriverProvider {

        param(
            [psobject]$Context,
            [psobject]$Action
        )

        return $Context

    }

}

Describe "DriverManager" {

    BeforeEach {

        Reset-Logger

        Mock Write-Log {}

        Reset-DriverProviders

        # ==========================================
        # Environnement WIM
        # ==========================================

        $script:MountPath = Join-Path $TestDrive "Mount"
        $script:DriverPath = Join-Path $TestDrive "Drivers"

        New-Item `
            -ItemType Directory `
            -Path $script:MountPath `
            -Force |
            Out-Null

        New-Item `
            -ItemType Directory `
            -Path $script:DriverPath `
            -Force |
            Out-Null

        # ==========================================
        # Contexte
        # ==========================================

        $script:Context = [pscustomobject]@{

            BuildState = [pscustomobject]@{

                Status = "Idle"

            }

            WIM = [pscustomobject]@{

                Mount = [pscustomobject]@{

                    Path = $script:MountPath

                }

            }

        }

        # ==========================================
        # Action
        # ==========================================

        $script:Action = [pscustomobject]@{

            Provider       = "DISM"
            Source         = $script:DriverPath
            Name           = "TestDriver"
            Recurse        = $false
            ForceUnsigned  = $false

        }

        # ==========================================
        # Dépendance technique DISM
        # ==========================================

        Mock Add-DismDriver {}

    }

    # ==================================================
    # Get-DriverProviders
    # ==================================================

    Context "Get-DriverProviders" {

        It "Retourne DISM par défaut" {

            $Providers = @(
                Get-DriverProviders
            )

            $Providers |
                Should -Contain "DISM"

        }

        It "Retourne PNP par défaut" {

            $Providers = @(
                Get-DriverProviders
            )

            $Providers |
                Should -Contain "PNP"

        }

        It "Retourne les fournisseurs triés" {

            Register-DriverProvider `
                -Name "AAA" `
                -Handler "Invoke-TestDriverProvider"

            $Providers = @(
                Get-DriverProviders
            )

            $Sorted = @(
                $Providers | Sort-Object
            )

            $Providers |
                Should -Be $Sorted

        }

    }

    # ==================================================
    # Invoke-Driver
    # ==================================================

    Context "Invoke-Driver" {

        It "Applique un pilote avec DISM" {

            $Result = Invoke-Driver `
                -Context $script:Context `
                -Action $script:Action

            $Result |
                Should -Be $script:Context

            Should -Invoke Add-DismDriver -Times 1 -Exactly

        }

        It "Applique un pilote avec PNP" {

            $script:Action.Provider = "PNP"

            $Result = Invoke-Driver `
                -Context $script:Context `
                -Action $script:Action

            $Result |
                Should -Be $script:Context

        }

		It "Applique le provider PNP avec l'action sélectionnée" {

			$script:Action.Provider = "PNP"

			Mock Get-Command {

				[pscustomobject]@{
					Source = "pnputil.exe"
				}

			} -ParameterFilter {
				$Name -eq "pnputil.exe"
			}

			Mock Test-Path {
				$true
			} -ParameterFilter {
				$LiteralPath -eq $script:DriverPath
			}

			Mock pnputil.exe {
				$global:LASTEXITCODE = 0
			}

			$Result = Invoke-Driver `
				-Context $script:Context `
				-Action $script:Action

			$Result |
				Should -Be $script:Context

		}

		It "Utilise réellement le provider PNP lorsqu'il est sélectionné" {

			$script:Action.Provider = "PNP"

			Mock Get-Command {

				[pscustomobject]@{
					Source = "pnputil.exe"
				}

			} -ParameterFilter {
				$Name -eq "pnputil.exe"
			}

			Mock Test-Path {
				$true
			} -ParameterFilter {
				$LiteralPath -eq $script:DriverPath
			}

			Mock pnputil.exe {
				$global:LASTEXITCODE = 0
			}

			$null = Invoke-Driver `
				-Context $script:Context `
				-Action $script:Action

			Should -Invoke `
				-CommandName pnputil.exe `
				-Times 1 `
				-Exactly

		}

        It "Refuse un provider absent" {

            $script:Action.Provider = $null

            {

                Invoke-Driver `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }

        It "Refuse une source absente" {

            $script:Action.Source = $null

            {

                Invoke-Driver `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }

        It "Refuse un provider inconnu" {

            $script:Action.Provider = "Unknown"

            {

                Invoke-Driver `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }

        It "Transmet l'action au handler" {

            $script:ReceivedAction = $null

            function global:Invoke-TestDriverProvider {

                param(
                    [psobject]$Context,
                    [psobject]$Action
                )

                $script:ReceivedAction = $Action

                return $Context

            }

            Register-DriverProvider `
                -Name "Test" `
                -Handler "Invoke-TestDriverProvider"

            $script:Action.Provider = "Test"

            $null = Invoke-Driver `
                -Context $script:Context `
                -Action $script:Action

            $script:ReceivedAction.Source |
                Should -Be $script:DriverPath

        }

    }

    # ==================================================
    # Invoke-DismDriver
    # ==================================================

    Context "Invoke-DismDriver" {

        It "Utilise le chemin de montage WIM" {

            $null = Invoke-DismDriver `
                -Context $script:Context `
                -Action $script:Action

            Should -Invoke Add-DismDriver -Times 1 -Exactly `
                -ParameterFilter {

                    $MountPath -eq $script:MountPath

                }

        }

        It "Utilise la source des pilotes de l'action" {

            $null = Invoke-DismDriver `
                -Context $script:Context `
                -Action $script:Action

            Should -Invoke Add-DismDriver -Times 1 -Exactly `
                -ParameterFilter {

                    $DriverPath -eq $script:DriverPath

                }

        }

        It "Transmet Recurse" {

            $script:Action.Recurse = $true

            $null = Invoke-DismDriver `
                -Context $script:Context `
                -Action $script:Action

            Should -Invoke Add-DismDriver -Times 1 -Exactly `
                -ParameterFilter {

                    $Recurse -eq $true

                }

        }

        It "Transmet ForceUnsigned" {

            $script:Action.ForceUnsigned = $true

            $null = Invoke-DismDriver `
                -Context $script:Context `
                -Action $script:Action

            Should -Invoke Add-DismDriver -Times 1 -Exactly `
                -ParameterFilter {

                    $ForceUnsigned -eq $true

                }

        }

        It "Retourne le contexte de build" {

            $Result = Invoke-DismDriver `
                -Context $script:Context `
                -Action $script:Action

            $Result |
                Should -Be $script:Context

        }

        It "Refuse un contexte sans WIM" {

            $Context = [pscustomobject]@{}

            {

                Invoke-DismDriver `
                    -Context $Context `
                    -Action $script:Action

            } |
                Should -Throw "*section WIM*"

        }

        It "Refuse un contexte sans WIM" {

            $Context = [pscustomobject]@{}

            {

                Invoke-DismDriver `
                    -Context $Context `
                    -Action $script:Action

            } |
                Should -Throw "*section WIM*"

        }

        It "Refuse un contexte sans chemin de montage" {

            $Context = [pscustomobject]@{

                WIM = [pscustomobject]@{

                    Mount = [pscustomobject]@{

                        Path = $null

                    }

                }

            }

            {

                Invoke-DismDriver `
                    -Context $Context `
                    -Action $script:Action

            } |
                Should -Throw "*chemin de montage WIM*"

        }

        It "Refuse un nom de pilote absent" {

            $script:Action.Name = $null

            {

                Invoke-DismDriver `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw "*nom du pilote est obligatoire*"

        }

        It "Refuse une source absente" {

            $script:Action.Source = $null

            {

                Invoke-DismDriver `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw "*source du pilote est obligatoire*"

        }

        It "Refuse un montage WIM inexistant" {

            $script:Context.WIM.Mount.Path =
                Join-Path $TestDrive "MissingMount"

            {

                Invoke-DismDriver `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw "*dossier de montage WIM est introuvable*"

        }

        It "Enrichit les erreurs DISM avec le nom du pilote" {

            Mock Add-DismDriver {

                throw "Erreur DISM de test"

            }

            {

                Invoke-DismDriver `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw "*TestDriver*"

        }

    }

    # ==================================================
    # Register-DriverProvider
    # ==================================================

    Context "Register-DriverProvider" {

        It "Enregistre un nouveau provider" {

            Register-DriverProvider `
                -Name "Test" `
                -Handler "Invoke-TestDriverProvider"

            @(
                Get-DriverProviders
            ) |
                Should -Contain "Test"

        }

        It "Refuse un handler inexistant" {

            {

                Register-DriverProvider `
                    -Name "Broken" `
                    -Handler "Invoke-UnknownDriverHandler"

            } |
                Should -Throw

        }

    }

    # ==================================================
    # Reset-DriverProviders
    # ==================================================

    Context "Reset-DriverProviders" {

        It "Réinitialise les providers par défaut" {

            Register-DriverProvider `
                -Name "Test" `
                -Handler "Invoke-TestDriverProvider"

            Get-DriverProviders |
                Should -Contain "Test"

            Reset-DriverProviders

            Get-DriverProviders |
                Should -Contain "DISM"

            Get-DriverProviders |
                Should -Contain "PNP"

            Get-DriverProviders |
                Should -Not -Contain "Test"

        }

    }

}
