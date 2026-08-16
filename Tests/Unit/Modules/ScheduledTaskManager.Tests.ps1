# ==========================================
# Tests : ScheduledTaskManager
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"

    # --------------------------------------------------
    # Provider par défaut
    # --------------------------------------------------

    function global:Invoke-NativeScheduledTask {

        param(
            [psobject]$Context,
            [psobject]$Action
        )

        return $Context

    }

    # --------------------------------------------------
    # Provider de test
    # --------------------------------------------------

    function global:Invoke-TestScheduledTaskProvider {

        param(
            [psobject]$Context,
            [psobject]$Action
        )

        return $Context

    }

    . "$ProjectRoot\Modules\Managers\ScheduledTaskManager.ps1"

}

Describe "ScheduledTaskManager" {

    BeforeEach {

        Reset-Logger

        Mock Write-Log {}

        Reset-ScheduledTaskProviders

        # ==========================================
        # Contexte
        # ==========================================

        $script:Context = [pscustomobject]@{

            BuildState = [pscustomobject]@{

                Status = "Idle"

            }

        }

        # ==========================================
        # Action
        # ==========================================

        $script:Action = [pscustomobject]@{

            Provider = "Native"

            Name = "TestScheduledTask"

        }

    }


    # ==================================================
    # Get-ScheduledTaskProviders
    # ==================================================

    Context "Get-ScheduledTaskProviders" {

        It "Retourne Native par défaut" {

            $Providers = @(
                Get-ScheduledTaskProviders
            )

            $Providers |
                Should -Contain "Native"

        }


        It "Retourne les providers triés" {

            Register-ScheduledTaskProvider `
                -Name "AAA" `
                -Handler "Invoke-TestScheduledTaskProvider"

            $Providers = @(
                Get-ScheduledTaskProviders
            )

            $Sorted = @(
                $Providers | Sort-Object
            )

            $Providers |
                Should -Be $Sorted

        }

    }


    # ==================================================
    # Invoke-ScheduledTask
    # ==================================================

    Context "Invoke-ScheduledTask" {

        It "Applique une tâche avec Native" {

            $Result = Invoke-ScheduledTask `
                -Context $script:Context `
                -Action $script:Action

            $Result |
                Should -Be $script:Context

        }


        It "Refuse un provider absent" {

            $script:Action.Provider = $null

            {

                Invoke-ScheduledTask `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Refuse un nom absent" {

            $script:Action.Name = $null

            {

                Invoke-ScheduledTask `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Refuse un provider inconnu" {

            $script:Action.Provider = "Unknown"

            {

                Invoke-ScheduledTask `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Appelle le handler du provider" {

            $script:ReceivedAction = $null

            function global:Invoke-TestScheduledTaskProvider {

                param(
                    [psobject]$Context,
                    [psobject]$Action
                )

                $script:ReceivedAction = $Action

                return $Context

            }

            Register-ScheduledTaskProvider `
                -Name "Test" `
                -Handler "Invoke-TestScheduledTaskProvider"

            $script:Action.Provider = "Test"

            $null = Invoke-ScheduledTask `
                -Context $script:Context `
                -Action $script:Action

            $script:ReceivedAction.Name |
                Should -Be "TestScheduledTask"

        }

    }


    # ==================================================
    # Register-ScheduledTaskProvider
    # ==================================================

    Context "Register-ScheduledTaskProvider" {

        It "Enregistre un nouveau provider" {

            Register-ScheduledTaskProvider `
                -Name "Test" `
                -Handler "Invoke-TestScheduledTaskProvider"

            @(
                Get-ScheduledTaskProviders
            ) |
                Should -Contain "Test"

        }


        It "Refuse un handler inexistant" {

            {

                Register-ScheduledTaskProvider `
                    -Name "Broken" `
                    -Handler "Invoke-UnknownScheduledTaskHandler"

            } |
                Should -Throw

        }

    }


    # ==================================================
    # Reset-ScheduledTaskProviders
    # ==================================================

    Context "Reset-ScheduledTaskProviders" {

        It "Réinitialise le provider Native" {

            Register-ScheduledTaskProvider `
                -Name "Test" `
                -Handler "Invoke-TestScheduledTaskProvider"

            Get-ScheduledTaskProviders |
                Should -Contain "Test"

            Reset-ScheduledTaskProviders

            Get-ScheduledTaskProviders |
                Should -Contain "Native"

            Get-ScheduledTaskProviders |
                Should -Not -Contain "Test"

        }

    }

}