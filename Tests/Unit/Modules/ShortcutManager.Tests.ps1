# ==========================================
# Tests : ShortcutManager
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"

    # --------------------------------------------------
    # Provider par défaut
    # --------------------------------------------------

    function global:Invoke-NativeShortcut {

        param(
            [psobject]$Context,
            [psobject]$Action
        )

        return $Context

    }

    # --------------------------------------------------
    # Provider de test
    # --------------------------------------------------

    function global:Invoke-TestShortcutProvider {

        param(
            [psobject]$Context,
            [psobject]$Action
        )

        return $Context

    }

    . "$ProjectRoot\Modules\Managers\ShortcutManager.ps1"

}

Describe "ShortcutManager" {

    BeforeEach {

        Reset-Logger

        Mock Write-Log {}

        Reset-ShortcutProviders

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

            Provider    = "Native"
            Target      = "C:\Test\Application.exe"
            Destination = "C:\Users\Test\Desktop\Test.lnk"

        }

    }


    # ==================================================
    # Get-ShortcutProviders
    # ==================================================

    Context "Get-ShortcutProviders" {

        It "Retourne Native par défaut" {

            $Providers = @(
                Get-ShortcutProviders
            )

            $Providers |
                Should -Contain "Native"

        }

        It "Retourne les providers triés" {

            Register-ShortcutProvider `
                -Name "AAA" `
                -Handler "Invoke-TestShortcutProvider"

            $Providers = @(
                Get-ShortcutProviders
            )

            $Sorted = @(
                $Providers | Sort-Object
            )

            $Providers |
                Should -Be $Sorted

        }

    }


    # ==================================================
    # Invoke-Shortcut
    # ==================================================

    Context "Invoke-Shortcut" {

        It "Applique un raccourci avec Native" {

            $Result = Invoke-Shortcut `
                -Context $script:Context `
                -Action $script:Action

            $Result |
                Should -Be $script:Context

        }

        It "Refuse un provider absent" {

            $script:Action.Provider = $null

            {

                Invoke-Shortcut `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }

        It "Refuse une cible absente" {

            $script:Action.Target = $null

            {

                Invoke-Shortcut `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }

        It "Refuse une destination absente" {

            $script:Action.Destination = $null

            {

                Invoke-Shortcut `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }

        It "Refuse un provider inconnu" {

            $script:Action.Provider = "Unknown"

            {

                Invoke-Shortcut `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }

        It "Appelle le handler du provider" {

            $script:ReceivedAction = $null

            function global:Invoke-TestShortcutProvider {

                param(
                    [psobject]$Context,
                    [psobject]$Action
                )

                $script:ReceivedAction = $Action

                return $Context

            }

            Register-ShortcutProvider `
                -Name "Test" `
                -Handler "Invoke-TestShortcutProvider"

            $script:Action.Provider = "Test"

            $null = Invoke-Shortcut `
                -Context $script:Context `
                -Action $script:Action

            $script:ReceivedAction.Target |
                Should -Be "C:\Test\Application.exe"

            $script:ReceivedAction.Destination |
                Should -Be "C:\Users\Test\Desktop\Test.lnk"

        }

    }


    # ==================================================
    # Register-ShortcutProvider
    # ==================================================

    Context "Register-ShortcutProvider" {

        It "Enregistre un nouveau provider" {

            Register-ShortcutProvider `
                -Name "Test" `
                -Handler "Invoke-TestShortcutProvider"

            @(
                Get-ShortcutProviders
            ) |
                Should -Contain "Test"

        }

        It "Refuse un handler inexistant" {

            {

                Register-ShortcutProvider `
                    -Name "Broken" `
                    -Handler "Invoke-UnknownShortcutHandler"

            } |
                Should -Throw

        }

    }


    # ==================================================
    # Reset-ShortcutProviders
    # ==================================================

    Context "Reset-ShortcutProviders" {

        It "Réinitialise le provider Native" {

            Register-ShortcutProvider `
                -Name "Test" `
                -Handler "Invoke-TestShortcutProvider"

            Get-ShortcutProviders |
                Should -Contain "Test"

            Reset-ShortcutProviders

            Get-ShortcutProviders |
                Should -Contain "Native"

            Get-ShortcutProviders |
                Should -Not -Contain "Test"

        }

    }

}