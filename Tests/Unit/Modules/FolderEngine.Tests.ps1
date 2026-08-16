# ==========================================
# Tests : FolderEngine
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"

    # --------------------------------------------------
    # Dépendance du Manager
    # --------------------------------------------------

    function global:Invoke-Folder {

        param(
            [psobject]$Context,
            [psobject]$Action
        )

        return $Context

    }

    . "$ProjectRoot\Modules\Actions\FolderEngine.ps1"

}

Describe "FolderEngine" {

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

                FoldersProcessed = 0

            }

        }

        # ==========================================
        # Action
        # ==========================================

        $script:Action = [pscustomobject]@{

            Id = "Folder.Test"

            Path = "C:\Test\Folder"

            Success = $false

            Duration = [timespan]::Zero

            Error = $null

        }

    }


    # ==================================================
    # Invoke-FolderAction
    # ==================================================

    Context "Invoke-FolderAction" {

        It "Traite un dossier valide" {

            $Result = Invoke-FolderAction `
                -Context $script:Context `
                -Action $script:Action

            $Result |
                Should -Be $script:Context

            $script:Action.Success |
                Should -BeTrue

        }


        It "Passe le BuildState à FolderApplied" {

            $null = Invoke-FolderAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Context.BuildState.Status |
                Should -Be "FolderApplied"

        }


        It "Incrémente FoldersProcessed" {

            $null = Invoke-FolderAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Context.Statistics.FoldersProcessed |
                Should -Be 1

        }


        It "Positionne Duration" {

            $null = Invoke-FolderAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Action.Duration |
                Should -BeOfType ([TimeSpan])

        }


        It "Réinitialise Error après une réussite" {

            $script:Action.Error = "Ancienne erreur"

            $null = Invoke-FolderAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Action.Error |
                Should -BeNullOrEmpty

        }


        It "Lève une exception si Path est absent" {

            $script:Action.Path = $null

            {

                Invoke-FolderAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Passe le BuildState à FolderFailed en cas d'erreur" {

            function global:Invoke-Folder {

                throw "Erreur de test"

            }

            {

                Invoke-FolderAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

            $script:Context.BuildState.Status |
                Should -Be "FolderFailed"

        }


        It "Positionne Success à False en cas d'erreur" {

            function global:Invoke-Folder {

                throw "Erreur de test"

            }

            {

                Invoke-FolderAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

            $script:Action.Success |
                Should -BeFalse

        }


        It "Conserve le message d'erreur de l'action" {

            function global:Invoke-Folder {

                throw "Erreur dossier"

            }

            {

                Invoke-FolderAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

            $script:Action.Error |
                Should -Be "Erreur dossier"

        }


        It "Enrichit l'exception avec l'identifiant de l'action" {

            function global:Invoke-Folder {

                throw "Erreur dossier"

            }

            {

                Invoke-FolderAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw "*Folder.Test*"

        }

    }

}