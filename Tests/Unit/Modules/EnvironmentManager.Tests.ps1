# ==========================================
# Tests : EnvironmentManager
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"

    # --------------------------------------------------
    # Provider par défaut
    # --------------------------------------------------

    function global:Invoke-NativeEnvironment {

        param(
            [psobject]$Context,
            [psobject]$Action
        )

        return $Context

    }

    # --------------------------------------------------
    # Provider de test
    # --------------------------------------------------

    function global:Invoke-TestEnvironmentProvider {

        param(
            [psobject]$Context,
            [psobject]$Action
        )

        return $Context

    }

    . "$ProjectRoot\Modules\Managers\EnvironmentManager.ps1"

}

Describe "EnvironmentManager" {

    BeforeEach {

        Reset-Logger

        Mock Write-Log {}

        Reset-EnvironmentProviders

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

            Name = "TEST_VARIABLE"

            Value = "TestValue"

        }

    }


    # ==================================================
    # Get-EnvironmentProviders
    # ==================================================

    Context "Get-EnvironmentProviders" {

        It "Retourne Native par défaut" {

            $Providers = @(
                Get-EnvironmentProviders
            )

            $Providers |
                Should -Contain "Native"

        }


        It "Retourne les providers triés" {

            Register-EnvironmentProvider `
                -Name "AAA" `
                -Handler "Invoke-TestEnvironmentProvider"

            $Providers = @(
                Get-EnvironmentProviders
            )

            $Sorted = @(
                $Providers | Sort-Object
            )

            $Providers |
                Should -Be $Sorted

        }

    }


    # ==================================================
    # Invoke-Environment
    # ==================================================

    Context "Invoke-Environment" {

        It "Applique une variable avec le provider Native" {

            $Result = Invoke-Environment `
                -Context $script:Context `
                -Action $script:Action

            $Result |
                Should -Be $script:Context

        }


        It "Refuse un provider absent" {

            $script:Action.Provider = $null

            {

                Invoke-Environment `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Refuse un nom absent" {

            $script:Action.Name = $null

            {

                Invoke-Environment `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Refuse un provider inconnu" {

            $script:Action.Provider = "Unknown"

            {

                Invoke-Environment `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Appelle le handler du provider" {

            $script:ReceivedAction = $null

            function global:Invoke-TestEnvironmentProvider {

                param(
                    [psobject]$Context,
                    [psobject]$Action
                )

                $script:ReceivedAction = $Action

                return $Context

            }

            Register-EnvironmentProvider `
                -Name "Test" `
                -Handler "Invoke-TestEnvironmentProvider"

            $script:Action.Provider = "Test"

            $null = Invoke-Environment `
                -Context $script:Context `
                -Action $script:Action

            $script:ReceivedAction.Name |
                Should -Be "TEST_VARIABLE"

            $script:ReceivedAction.Value |
                Should -Be "TestValue"

        }

    }


    # ==================================================
    # Register-EnvironmentProvider
    # ==================================================

    Context "Register-EnvironmentProvider" {

        It "Enregistre un nouveau provider" {

            Register-EnvironmentProvider `
                -Name "Test" `
                -Handler "Invoke-TestEnvironmentProvider"

            @(
                Get-EnvironmentProviders
            ) |
                Should -Contain "Test"

        }


        It "Refuse un handler inexistant" {

            {

                Register-EnvironmentProvider `
                    -Name "Broken" `
                    -Handler "Invoke-UnknownEnvironmentHandler"

            } |
                Should -Throw

        }

    }


    # ==================================================
    # Reset-EnvironmentProviders
    # ==================================================

    Context "Reset-EnvironmentProviders" {

        It "Réinitialise le provider Native" {

            Register-EnvironmentProvider `
                -Name "Test" `
                -Handler "Invoke-TestEnvironmentProvider"

            Get-EnvironmentProviders |
                Should -Contain "Test"

            Reset-EnvironmentProviders

            Get-EnvironmentProviders |
                Should -Contain "Native"

            Get-EnvironmentProviders |
                Should -Not -Contain "Test"

        }

    }

}