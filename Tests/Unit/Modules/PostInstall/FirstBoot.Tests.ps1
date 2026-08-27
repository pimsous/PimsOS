# ==========================================
# Tests : PostInstall FirstBoot
# Projet : PimsOS Builder
# ==========================================

$ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..\..").Path

Describe "PostInstall FirstBoot" {

    BeforeEach {

        $TestProjectRoot = (
            Resolve-Path "$PSScriptRoot\..\..\..\.."
        ).Path

        . "$TestProjectRoot\Modules\PostInstall\FirstBoot.ps1"

        $script:BootstrapPath = `
            "C:\ProgramData\PimsOS\PostInstall\Bootstrap.ps1"

    }

    # ==================================================
    # New-PimsOSFirstLogonCommand
    # ==================================================

    Context "New-PimsOSFirstLogonCommand" {

        It "Construit une commande FirstLogon valide" {

            $Command = New-PimsOSFirstLogonCommand `
                -BootstrapPath $script:BootstrapPath

            $Command.Order |
                Should -Be 1

            $Command.Description |
                Should -Be "Lancement du PostInstall PimsOS"

            $Command.CommandLine |
                Should -Match "powershell.exe"

            $Command.CommandLine |
                Should -Match "Bootstrap.ps1"

        }

        It "Respecte l'ordre fourni" {

            $Command = New-PimsOSFirstLogonCommand `
                -BootstrapPath $script:BootstrapPath `
                -Order 5

            $Command.Order |
                Should -Be 5

        }

        It "Utilise le chemin complet du Bootstrap" {

            $Command = New-PimsOSFirstLogonCommand `
                -BootstrapPath $script:BootstrapPath

            $Command.CommandLine |
                Should -Be (
                    'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\ProgramData\PimsOS\PostInstall\Bootstrap.ps1"'
                )

        }

        It "Refuse un chemin Bootstrap vide" {

			{

				New-PimsOSFirstLogonCommand `
					-BootstrapPath ""

			} |
				Should -Throw "*Cannot bind argument to parameter 'BootstrapPath'*"

		}

        It "Refuse un ordre inférieur à 1" {

            {

                New-PimsOSFirstLogonCommand `
                    -BootstrapPath $script:BootstrapPath `
                    -Order 0

            } |
                Should -Throw "*ordre FirstBoot doit être supérieur ou égal à 1*"

        }

    }

    # ==================================================
    # New-PimsOSFirstBootConfiguration
    # ==================================================

    Context "New-PimsOSFirstBootConfiguration" {

        It "Construit une configuration FirstBoot" {

            $Configuration =
                New-PimsOSFirstBootConfiguration `
                    -BootstrapPath $script:BootstrapPath

            $Configuration.ObjectType |
                Should -Be "PimsOSFirstBootConfiguration"

            $Configuration.Version |
                Should -Be "1.0.0"

            $Configuration.BootstrapPath |
                Should -Be $script:BootstrapPath

            @(
                $Configuration.FirstLogonCommands
            ).Count |
                Should -Be 1

        }

        It "Crée une première commande ordonnée" {

            $Configuration =
                New-PimsOSFirstBootConfiguration `
                    -BootstrapPath $script:BootstrapPath

            $Command = @(
                $Configuration.FirstLogonCommands
            )[0]

            $Command.Order |
                Should -Be 1

        }

        It "Refuse un Bootstrap vide" {

			{

				New-PimsOSFirstBootConfiguration `
					-BootstrapPath ""

			} |
				Should -Throw "*Cannot bind argument to parameter 'BootstrapPath'*"

		}

    }

    # ==================================================
    # Test-PimsOSFirstBootConfiguration
    # ==================================================

    Context "Test-PimsOSFirstBootConfiguration" {

        It "Valide une configuration correcte" {

            $Configuration =
                New-PimsOSFirstBootConfiguration `
                    -BootstrapPath $script:BootstrapPath

            Test-PimsOSFirstBootConfiguration `
                -Configuration $Configuration |
                Should -BeTrue

        }

        It "Refuse une configuration null" {

			{

				Test-PimsOSFirstBootConfiguration `
					-Configuration $null

			} |
				Should -Throw "*Cannot bind argument to parameter 'Configuration'*"

		}

        It "Refuse une configuration sans FirstLogonCommands" {

            $Configuration = [PSCustomObject]@{

                ObjectType = "PimsOSFirstBootConfiguration"

                Version = "1.0.0"

            }

            {

                Test-PimsOSFirstBootConfiguration `
                    -Configuration $Configuration

            } |
                Should -Throw "*FirstLogonCommands*"

        }

        It "Refuse une configuration sans commande" {

            $Configuration = [PSCustomObject]@{

                ObjectType = "PimsOSFirstBootConfiguration"

                Version = "1.0.0"

                FirstLogonCommands = @()

            }

            {

                Test-PimsOSFirstBootConfiguration `
                    -Configuration $Configuration

            } |
                Should -Throw "*aucune commande*"

        }

        It "Refuse une commande sans ligne de commande" {

            $Configuration = [PSCustomObject]@{

                ObjectType = "PimsOSFirstBootConfiguration"

                Version = "1.0.0"

                FirstLogonCommands = @(
                    [PSCustomObject]@{
                        Order = 1
                    }
                )

            }

            {

                Test-PimsOSFirstBootConfiguration `
                    -Configuration $Configuration

            } |
                Should -Throw "*ne contient pas de propriété CommandLine*"

        }

        It "Refuse une ligne de commande vide" {

            $Configuration = [PSCustomObject]@{

                ObjectType = "PimsOSFirstBootConfiguration"

                Version = "1.0.0"

                FirstLogonCommands = @(
                    [PSCustomObject]@{
                        Order       = 1
                        CommandLine = ""
                    }
                )

            }

            {

                Test-PimsOSFirstBootConfiguration `
                    -Configuration $Configuration

            } |
                Should -Throw "*ligne de commande vide*"

        }

    }

}