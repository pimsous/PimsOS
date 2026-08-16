# ==========================================
# Tests : FileEngine
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"

    # --------------------------------------------------
    # Dépendance du Manager
    # --------------------------------------------------

    function global:Invoke-File {

        param(
            [psobject]$Context,
            [psobject]$Action
        )

        return $Context

    }

    . "$ProjectRoot\Modules\Actions\FileEngine.ps1"

}

Describe "FileEngine" {

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

                FilesProcessed = 0

            }

        }

        # ==========================================
        # Action
        # ==========================================

        $script:Action = [pscustomobject]@{

            Id = "File.Test"

            Source = "C:\Source\Test.txt"

            Success = $false

            Duration = [timespan]::Zero

            Error = $null

        }

    }


    # ==================================================
    # Invoke-FileAction
    # ==================================================

    Context "Invoke-FileAction" {

        It "Traite un fichier valide" {

            $Result = Invoke-FileAction `
                -Context $script:Context `
                -Action $script:Action

            $Result |
                Should -Be $script:Context

            $script:Action.Success |
                Should -BeTrue

        }


        It "Passe le BuildState à FileApplied" {

            $null = Invoke-FileAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Context.BuildState.Status |
                Should -Be "FileApplied"

        }


        It "Incrémente FilesProcessed" {

            $null = Invoke-FileAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Context.Statistics.FilesProcessed |
                Should -Be 1

        }


        It "Positionne Duration" {

            $null = Invoke-FileAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Action.Duration |
                Should -BeOfType ([TimeSpan])

        }


        It "Réinitialise Error après une réussite" {

            $script:Action.Error = "Ancienne erreur"

            $null = Invoke-FileAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Action.Error |
                Should -BeNullOrEmpty

        }


        It "Lève une exception si Source est absente" {

            $script:Action.Source = $null

            {

                Invoke-FileAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Passe le BuildState à FileFailed en cas d'erreur" {

            function global:Invoke-File {

                throw "Erreur de test"

            }

            {

                Invoke-FileAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

            $script:Context.BuildState.Status |
                Should -Be "FileFailed"

        }


        It "Positionne Success à False en cas d'erreur" {

            function global:Invoke-File {

                throw "Erreur de test"

            }

            {

                Invoke-FileAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

            $script:Action.Success |
                Should -BeFalse

        }


        It "Conserve le message d'erreur de l'action" {

            function global:Invoke-File {

                throw "Erreur fichier"

            }

            {

                Invoke-FileAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

            $script:Action.Error |
                Should -Be "Erreur fichier"

        }


        It "Enrichit l'exception avec l'identifiant de l'action" {

            function global:Invoke-File {

                throw "Erreur fichier"

            }

            {

                Invoke-FileAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw "*File.Test*"

        }

    }

}