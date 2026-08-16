# ==========================================
# Tests : FolderManager
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"

    # --------------------------------------------------
    # Provider par défaut
    # --------------------------------------------------

    function global:Invoke-NativeFolder {

        param(
            [psobject]$Context,
            [psobject]$Action
        )

        return $Context

    }

    # --------------------------------------------------
    # Provider de test
    # --------------------------------------------------

    function global:Invoke-TestFolderProvider {

        param(
            [psobject]$Context,
            [psobject]$Action
        )

        return $Context

    }

    . "$ProjectRoot\Modules\Managers\FolderManager.ps1"

}

Describe "FolderManager" {

    BeforeEach {

        Reset-Logger

        Mock Write-Log {}

        Reset-FolderProviders

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
            Path        = "C:\Test\Folder"
            Destination = "C:\Destination\Folder"

        }

    }


    # ==================================================
    # Get-FolderProviders
    # ==================================================

    Context "Get-FolderProviders" {

        It "Retourne Native par défaut" {

            $Providers = @(
                Get-FolderProviders
            )

            $Providers |
                Should -Contain "Native"

        }


        It "Retourne les providers triés" {

            Register-FolderProvider `
                -Name "AAA" `
                -Handler "Invoke-TestFolderProvider"

            $Providers = @(
                Get-FolderProviders
            )

            $Sorted = @(
                $Providers | Sort-Object
            )

            $Providers |
                Should -Be $Sorted

        }

    }


    # ==================================================
    # Invoke-Folder
    # ==================================================

    Context "Invoke-Folder" {

        It "Applique une opération dossier avec Native" {

            $Result = Invoke-Folder `
                -Context $script:Context `
                -Action $script:Action

            $Result |
                Should -Be $script:Context

        }


        It "Refuse un provider absent" {

            $script:Action.Provider = $null

            {

                Invoke-Folder `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Refuse un chemin absent" {

            $script:Action.Path = $null

            {

                Invoke-Folder `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Refuse un provider inconnu" {

            $script:Action.Provider = "Unknown"

            {

                Invoke-Folder `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Appelle le handler du provider" {

            $script:ReceivedAction = $null

            function global:Invoke-TestFolderProvider {

                param(
                    [psobject]$Context,
                    [psobject]$Action
                )

                $script:ReceivedAction = $Action

                return $Context

            }

            Register-FolderProvider `
                -Name "Test" `
                -Handler "Invoke-TestFolderProvider"

            $script:Action.Provider = "Test"

            $null = Invoke-Folder `
                -Context $script:Context `
                -Action $script:Action

            $script:ReceivedAction.Path |
                Should -Be "C:\Test\Folder"

            $script:ReceivedAction.Destination |
                Should -Be "C:\Destination\Folder"

        }

    }


    # ==================================================
    # Register-FolderProvider
    # ==================================================

    Context "Register-FolderProvider" {

        It "Enregistre un nouveau provider" {

            Register-FolderProvider `
                -Name "Test" `
                -Handler "Invoke-TestFolderProvider"

            @(
                Get-FolderProviders
            ) |
                Should -Contain "Test"

        }


        It "Refuse un handler inexistant" {

            {

                Register-FolderProvider `
                    -Name "Broken" `
                    -Handler "Invoke-UnknownFolderHandler"

            } |
                Should -Throw

        }

    }


    # ==================================================
    # Reset-FolderProviders
    # ==================================================

    Context "Reset-FolderProviders" {

        It "Réinitialise le provider Native" {

            Register-FolderProvider `
                -Name "Test" `
                -Handler "Invoke-TestFolderProvider"

            Get-FolderProviders |
                Should -Contain "Test"

            Reset-FolderProviders

            Get-FolderProviders |
                Should -Contain "Native"

            Get-FolderProviders |
                Should -Not -Contain "Test"

        }

    }

}