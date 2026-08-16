# ==========================================
# Tests : FileManager
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"

    # --------------------------------------------------
    # Provider par défaut
    # --------------------------------------------------

    function global:Invoke-NativeFile {

        param(
            [psobject]$Context,
            [psobject]$Action
        )

        return $Context

    }

    # --------------------------------------------------
    # Provider de test
    # --------------------------------------------------

    function global:Invoke-TestFileProvider {

        param(
            [psobject]$Context,
            [psobject]$Action
        )

        return $Context

    }

    . "$ProjectRoot\Modules\Managers\FileManager.ps1"

}

Describe "FileManager" {

    BeforeEach {

        Reset-Logger

        Mock Write-Log {}

        Reset-FileProviders

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

            Source      = "C:\Source\Test.txt"

            Destination = "C:\Destination\Test.txt"

        }

    }


    # ==================================================
    # Get-FileProviders
    # ==================================================

    Context "Get-FileProviders" {

        It "Retourne Native par défaut" {

            $Providers = @(
                Get-FileProviders
            )

            $Providers |
                Should -Contain "Native"

        }


        It "Retourne les providers triés" {

            Register-FileProvider `
                -Name "AAA" `
                -Handler "Invoke-TestFileProvider"

            $Providers = @(
                Get-FileProviders
            )

            $Sorted = @(
                $Providers | Sort-Object
            )

            $Providers |
                Should -Be $Sorted

        }

    }


    # ==================================================
    # Invoke-File
    # ==================================================

    Context "Invoke-File" {

        It "Applique une opération fichier avec Native" {

            $Result = Invoke-File `
                -Context $script:Context `
                -Action $script:Action

            $Result |
                Should -Be $script:Context

        }


        It "Refuse un provider absent" {

            $script:Action.Provider = $null

            {

                Invoke-File `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Refuse une source absente" {

            $script:Action.Source = $null

            {

                Invoke-File `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Refuse une destination absente" {

            $script:Action.Destination = $null

            {

                Invoke-File `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Refuse un provider inconnu" {

            $script:Action.Provider = "Unknown"

            {

                Invoke-File `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Appelle le handler du provider" {

            $script:ReceivedAction = $null

            function global:Invoke-TestFileProvider {

                param(
                    [psobject]$Context,
                    [psobject]$Action
                )

                $script:ReceivedAction = $Action

                return $Context

            }

            Register-FileProvider `
                -Name "Test" `
                -Handler "Invoke-TestFileProvider"

            $script:Action.Provider = "Test"

            $null = Invoke-File `
                -Context $script:Context `
                -Action $script:Action

            $script:ReceivedAction.Source |
                Should -Be "C:\Source\Test.txt"

            $script:ReceivedAction.Destination |
                Should -Be "C:\Destination\Test.txt"

        }

    }


    # ==================================================
    # Register-FileProvider
    # ==================================================

    Context "Register-FileProvider" {

        It "Enregistre un nouveau provider" {

            Register-FileProvider `
                -Name "Test" `
                -Handler "Invoke-TestFileProvider"

            @(
                Get-FileProviders
            ) |
                Should -Contain "Test"

        }


        It "Refuse un handler inexistant" {

            {

                Register-FileProvider `
                    -Name "Broken" `
                    -Handler "Invoke-UnknownFileHandler"

            } |
                Should -Throw

        }

    }


    # ==================================================
    # Reset-FileProviders
    # ==================================================

    Context "Reset-FileProviders" {

        It "Réinitialise le provider Native" {

            Register-FileProvider `
                -Name "Test" `
                -Handler "Invoke-TestFileProvider"

            Get-FileProviders |
                Should -Contain "Test"

            Reset-FileProviders

            Get-FileProviders |
                Should -Contain "Native"

            Get-FileProviders |
                Should -Not -Contain "Test"

        }

    }

}