# ==========================================
# Tests : Check
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"
    . "$ProjectRoot\Modules\Infrastructure\Check.ps1"
}

Describe "Check" {

    # ==================================================
    # Test-PowerShellVersion
    # ==================================================

    Context "Test-PowerShellVersion" {

        It "Retourne True lorsque la version PowerShell est suffisante" {

            $Context = [pscustomobject]@{

                Project = [pscustomobject]@{

                    Config = [pscustomobject]@{

                        Requirements = [pscustomobject]@{

                            PowerShellMajor = 5

                        }

                    }

                }

            }

            Test-PowerShellVersion `
                -Context $Context |
                Should -BeTrue
        }

        It "Retourne False lorsque la version PowerShell est insuffisante" {

            $Context = [pscustomobject]@{

                Project = [pscustomobject]@{

                    Config = [pscustomobject]@{

                        Requirements = [pscustomobject]@{

                            PowerShellMajor = 99

                        }

                    }

                }

            }

            Test-PowerShellVersion `
                -Context $Context |
                Should -BeFalse
        }
    }

    # ==================================================
    # Test-Administrator
    # ==================================================

    Context "Test-Administrator" {

        It "Retourne une valeur booléenne" {

            $Result = Test-Administrator

            $Result |
                Should -BeOfType Boolean
        }
    }

    # ==================================================
    # Get-FreeDiskSpaceGB
    # ==================================================

    Context "Get-FreeDiskSpaceGB" {

        It "Retourne un nombre positif ou nul" {

            $Context = [pscustomobject]@{

                Project = [pscustomobject]@{

                    Root = $ProjectRoot

                }

            }

            $FreeSpace = Get-FreeDiskSpaceGB `
                -Context $Context

            $FreeSpace |
                Should -BeGreaterOrEqual 0
        }
    }

    # ==================================================
    # Invoke-EnvironmentChecks
    # ==================================================

    Context "Invoke-EnvironmentChecks" {

        BeforeEach {

            $script:Context = [pscustomobject]@{

                Project = [pscustomobject]@{

                    Root = $ProjectRoot

                    Config = [pscustomobject]@{

                        Requirements = [pscustomobject]@{

                            PowerShellMajor =
                                $PSVersionTable.PSVersion.Major

                            MinimumFreeSpaceGB = 0

                        }

                    }

                }

                # --------------------------------------------------
                # Rapport d'environnement
                # --------------------------------------------------

                EnvironmentChecks = @()

                # --------------------------------------------------
                # Etat du Build
                # --------------------------------------------------

                BuildState = [pscustomobject]@{

                    Status = ""

                    Environment = [pscustomobject]@{

                        Checked       = $false
                        PowerShell    = $false
                        Administrator = $false
                        Git           = $false
                        Dism          = $false
                        Iso           = $false
                        DiskSpace     = $false

                    }

                }

            }

            # ==================================================
            # Mocks des dépendances
            # ==================================================

            function global:Start-BuildPhase {

                param(
                    [psobject]$Context,
                    [string]$Name
                )

                $Context.BuildState.Status = "Starting$Name"

                return $Context
            }

            function global:Set-EnvironmentReport {

                param(
                    [psobject]$Context,
                    [object[]]$Checks
                )

                if (
                    $Context.PSObject.Properties.Name -contains
                    "EnvironmentChecks"
                ) {

                    $Context.EnvironmentChecks = $Checks

                }
                else {

                    $Context |
                        Add-Member `
                            -MemberType NoteProperty `
                            -Name "EnvironmentChecks" `
                            -Value $Checks
                }

                return $Context
            }

            function global:Complete-BuildPhase {

                param(
                    [psobject]$Context
                )

                return $Context
            }

            function global:Get-IsoFile {

                param(
                    [psobject]$Context
                )

                return [pscustomobject]@{

                    Name = "Win11_25H2_French_x64.iso"

                }
            }
        }

        # ==================================================
        # Tests
        # ==================================================

        It "Exécute les vérifications d'environnement" {

            $Context = Invoke-EnvironmentChecks `
                -Context $script:Context

            $Context |
                Should -Not -BeNullOrEmpty
        }

        It "Passe le BuildState à EnvironmentChecked" {

            $Context = Invoke-EnvironmentChecks `
                -Context $script:Context

            $Context.BuildState.Status |
                Should -Be "EnvironmentChecked"
        }

        It "Marque l'environnement comme vérifié" {

            $Context = Invoke-EnvironmentChecks `
                -Context $script:Context

            $Context.BuildState.Environment.Checked |
                Should -BeTrue
        }

        It "Détecte PowerShell" {

            $Context = Invoke-EnvironmentChecks `
                -Context $script:Context

            $Context.BuildState.Environment.PowerShell |
                Should -BeTrue
        }

        It "Détecte Git lorsqu'il est disponible" {

            $Context = Invoke-EnvironmentChecks `
                -Context $script:Context

            $Context.BuildState.Environment.Git |
                Should -BeTrue
        }

        It "Détecte l'ISO" {

            $Context = Invoke-EnvironmentChecks `
                -Context $script:Context

            $Context.BuildState.Environment.Iso |
                Should -BeTrue
        }

        It "Détecte l'espace disque disponible" {

            $Context = Invoke-EnvironmentChecks `
                -Context $script:Context

            $Context.BuildState.Environment.DiskSpace |
                Should -BeTrue
        }

        It "Crée un rapport contenant les vérifications" {

            $Context = Invoke-EnvironmentChecks `
                -Context $script:Context

            $Context.EnvironmentChecks |
                Should -Not -BeNullOrEmpty

            $Context.EnvironmentChecks.Count |
                Should -Be 6
        }
    }
}