# ==========================================
# Tests : Check
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Check.ps1"

}

Describe "Check" {

    BeforeEach {

        $script:Context = [pscustomobject]@{

            Project = [pscustomobject]@{

                Root = (Get-Location).Path

                Config = [pscustomobject]@{

                    Requirements = [pscustomobject]@{

                        PowerShellMajor   = 7
                        MinimumFreeSpaceGB = 1

                    }

                }

            }

        }

    }

    Context "Test-PowerShellVersion" {

        It "Retourne un booléen" {

            $Result = Test-PowerShellVersion `
                -Context $script:Context

            $Result |
                Should -BeOfType ([bool])

        }

    }

    Context "Test-Administrator" {

        It "Retourne un booléen" {

            $Result = Test-Administrator

            $Result |
                Should -BeOfType ([bool])

        }

    }

    Context "Get-FreeDiskSpaceGB" {

        It "Retourne un nombre" {

            $Result = Get-FreeDiskSpaceGB `
                -Context $script:Context

            $Result |
                Should -BeOfType ([double])

        }

        It "Retourne une valeur positive" {

            $Result = Get-FreeDiskSpaceGB `
                -Context $script:Context

            $Result |
                Should -BeGreaterOrEqual 0

        }

    }

}