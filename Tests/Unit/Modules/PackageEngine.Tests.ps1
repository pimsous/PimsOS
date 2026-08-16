# ==========================================
# Tests : PackageEngine
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"

    # --------------------------------------------------
    # Dépendance du Manager
    # --------------------------------------------------

    function global:Invoke-Package {

        param(
            [psobject]$Context,
            [psobject]$Action
        )

        return $Context

    }

    . "$ProjectRoot\Modules\Actions\PackageEngine.ps1"

}

Describe "PackageEngine" {

    BeforeEach {

        Reset-Logger

        Mock Write-Log {}

        # ==========================================
        # Contexte
        # ==========================================

        $script:Context = [pscustomobject]@{

            BuildState = [pscustomobject]@{

                Status = "Idle"

            }

            Statistics = [pscustomobject]@{

                PackagesProcessed = 0

            }

        }

        # ==========================================
        # Action
        # ==========================================

        $script:Action = [pscustomobject]@{

            Id = "Package.Test"

            Name = "TestPackage"

            Success = $false

            Duration = [timespan]::Zero

            Error = $null

        }

    }


    # ==================================================
    # Invoke-PackageAction
    # ==================================================

    Context "Invoke-PackageAction" {

        It "Applique un package valide" {

            $Result = Invoke-PackageAction `
                -Context $script:Context `
                -Action $script:Action

            $Result |
                Should -Be $script:Context

            $script:Action.Success |
                Should -BeTrue

        }


        It "Passe le BuildState à PackageApplied" {

            $null = Invoke-PackageAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Context.BuildState.Status |
                Should -Be "PackageApplied"

        }


        It "Incrémente PackagesProcessed" {

            $null = Invoke-PackageAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Context.Statistics.PackagesProcessed |
                Should -Be 1

        }


        It "Positionne Duration" {

            $null = Invoke-PackageAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Action.Duration |
                Should -BeOfType ([TimeSpan])

        }


        It "Réinitialise Error après une réussite" {

            $script:Action.Error = "Ancienne erreur"

            $null = Invoke-PackageAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Action.Error |
                Should -BeNullOrEmpty

        }


        It "Lève une exception si Name est absent" {

            $script:Action.Name = $null

            {

                Invoke-PackageAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Passe le BuildState à PackageFailed en cas d'erreur" {

            function global:Invoke-Package {

                throw "Erreur de test"

            }

            {

                Invoke-PackageAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

            $script:Context.BuildState.Status |
                Should -Be "PackageFailed"

        }


        It "Positionne Success à False en cas d'erreur" {

            function global:Invoke-Package {

                throw "Erreur de test"

            }

            {

                Invoke-PackageAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

            $script:Action.Success |
                Should -BeFalse

        }


        It "Conserve le message d'erreur de l'action" {

            function global:Invoke-Package {

                throw "Erreur package"

            }

            {

                Invoke-PackageAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

            $script:Action.Error |
                Should -Be "Erreur package"

        }


        It "Enrichit l'exception avec l'identifiant du package" {

            function global:Invoke-Package {

                throw "Erreur package"

            }

            {

                Invoke-PackageAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw "*Package.Test*"

        }

    }

}