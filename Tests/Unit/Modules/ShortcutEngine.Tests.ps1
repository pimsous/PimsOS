# ==========================================
# Tests : ShortcutEngine
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"

    # --------------------------------------------------
    # Dépendance du Manager
    # --------------------------------------------------

    function global:Invoke-Shortcut {

        param(
            [psobject]$Context,
            [psobject]$Action
        )

        return $Context

    }

    . "$ProjectRoot\Modules\Actions\ShortcutEngine.ps1"

}

Describe "ShortcutEngine" {

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

                ShortcutsProcessed = 0

            }

        }

        # ==========================================
        # Action
        # ==========================================

        $script:Action = [pscustomobject]@{

            Id = "Shortcut.Test"

            Target = "C:\Test\Test.lnk"

            Success = $false

            Duration = [timespan]::Zero

            Error = $null

        }

    }


    # ==================================================
    # Invoke-ShortcutAction
    # ==================================================

    Context "Invoke-ShortcutAction" {

        It "Traite un raccourci valide" {

            $Result = Invoke-ShortcutAction `
                -Context $script:Context `
                -Action $script:Action

            $Result |
                Should -Be $script:Context

            $script:Action.Success |
                Should -BeTrue

        }


        It "Passe le BuildState à ShortcutApplied" {

            $null = Invoke-ShortcutAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Context.BuildState.Status |
                Should -Be "ShortcutApplied"

        }


        It "Incrémente ShortcutsProcessed" {

            $null = Invoke-ShortcutAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Context.Statistics.ShortcutsProcessed |
                Should -Be 1

        }


        It "Positionne Duration" {

            $null = Invoke-ShortcutAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Action.Duration |
                Should -BeOfType ([TimeSpan])

        }


        It "Réinitialise Error après une réussite" {

            $script:Action.Error = "Ancienne erreur"

            $null = Invoke-ShortcutAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Action.Error |
                Should -BeNullOrEmpty

        }


        It "Lève une exception si Target est absent" {

            $script:Action.Target = $null

            {

                Invoke-ShortcutAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Passe le BuildState à ShortcutFailed en cas d'erreur" {

            function global:Invoke-Shortcut {

                throw "Erreur de test"

            }

            {

                Invoke-ShortcutAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

            $script:Context.BuildState.Status |
                Should -Be "ShortcutFailed"

        }


        It "Positionne Success à False en cas d'erreur" {

            function global:Invoke-Shortcut {

                throw "Erreur de test"

            }

            {

                Invoke-ShortcutAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

            $script:Action.Success |
                Should -BeFalse

        }


        It "Conserve le message d'erreur de l'action" {

            function global:Invoke-Shortcut {

                throw "Erreur raccourci"

            }

            {

                Invoke-ShortcutAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

            $script:Action.Error |
                Should -Be "Erreur raccourci"

        }


        It "Enrichit l'exception avec l'identifiant de l'action" {

            function global:Invoke-Shortcut {

                throw "Erreur raccourci"

            }

            {

                Invoke-ShortcutAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw "*Shortcut.Test*"

        }

    }

}