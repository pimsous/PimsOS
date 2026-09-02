# ==========================================
# Tests : PostInstall Installer
# Projet : PimsOS Builder
# ==========================================

Describe "PostInstall Installer" {

    BeforeEach {

        $TestProjectRoot = (
            Resolve-Path "$PSScriptRoot\..\..\..\.."
        ).Path

        . "$TestProjectRoot\Modules\PostInstall\FirstBoot.ps1"
        . "$TestProjectRoot\Modules\PostInstall\Unattend.ps1"
        . "$TestProjectRoot\Modules\PostInstall\Installer.ps1"

        # --------------------------------------------------
        # Runtime source
        # --------------------------------------------------

        $script:SourcePath = Join-Path `
            $TestDrive `
            "Runtime"

        New-Item `
            -ItemType Directory `
            -Path $script:SourcePath `
            -Force |
            Out-Null

        foreach ($FileName in @(
            "Bootstrap.ps1"
			"Logger.ps1"
			"Network.ps1"
			"UI.ps1"
			"DriverCheck.ps1"
			"PostInstall.ps1"
            "Finalize.ps1"
			"State.ps1"
        )) {

            Set-Content `
                -Path (
                    Join-Path `
                        $script:SourcePath `
                        $FileName
                ) `
                -Value "# Test runtime" `
                -Encoding UTF8

        }

        # --------------------------------------------------
        # Provider Chocolatey simulé
        # --------------------------------------------------

        $script:ChocolateyProviderPath = Join-Path `
            $TestDrive `
            "Chocolatey.ps1"

        Set-Content `
            -LiteralPath $script:ChocolateyProviderPath `
            -Value "# Test Chocolatey provider" `
            -Encoding UTF8

        # --------------------------------------------------
        # Image montée simulée
        # --------------------------------------------------

        $script:MountPath = Join-Path `
            $TestDrive `
            "Mount"

        New-Item `
            -ItemType Directory `
            -Path $script:MountPath `
            -Force |
            Out-Null

    }

    # ==================================================
    # Install-PimsOSPostInstallRuntime
    # ==================================================

    Context "Install-PimsOSPostInstallRuntime" {

        It "Installe le runtime PostInstall dans ProgramData" {

            $Result =
                Install-PimsOSPostInstallRuntime `
                    -MountPath $script:MountPath `
                    -SourcePath $script:SourcePath `
                    -ChocolateyProviderPath $script:ChocolateyProviderPath

            $Destination = Join-Path `
                $script:MountPath `
                "ProgramData\PimsOS\PostInstall"

            Test-Path `
                -LiteralPath $Destination `
                -PathType Container |
                Should -BeTrue

            $Result.Installed |
                Should -BeTrue

        }


        It "Copie les neuf fichiers du runtime" {

            $null =
                Install-PimsOSPostInstallRuntime `
                    -MountPath $script:MountPath `
                    -SourcePath $script:SourcePath `
                    -ChocolateyProviderPath $script:ChocolateyProviderPath

            $Destination = Join-Path `
                $script:MountPath `
                "ProgramData\PimsOS\PostInstall"

            foreach ($FileName in @(
                "Bootstrap.ps1"
				"Logger.ps1"
				"Network.ps1"
				"UI.ps1"
				"DriverCheck.ps1"
                "Chocolatey.ps1"
                "PostInstall.ps1"
                "Finalize.ps1"
				"State.ps1"
            )) {

                $FilePath = Join-Path `
                    $Destination `
                    $FileName

                Test-Path `
                    -LiteralPath $FilePath `
                    -PathType Leaf |
                    Should -BeTrue

            }

        }


        It "Inclut Logger.ps1 dans le runtime" {

            $null =
                Install-PimsOSPostInstallRuntime `
                    -MountPath $script:MountPath `
                    -SourcePath $script:SourcePath `
                    -ChocolateyProviderPath $script:ChocolateyProviderPath

            $LoggerPath = Join-Path `
                $script:MountPath `
                "ProgramData\PimsOS\PostInstall\Logger.ps1"

            Test-Path `
                -LiteralPath $LoggerPath `
                -PathType Leaf |
                Should -BeTrue

        }


        It "Retourne le chemin de destination" {

            $Result =
                Install-PimsOSPostInstallRuntime `
                    -MountPath $script:MountPath `
                    -SourcePath $script:SourcePath `
                    -ChocolateyProviderPath $script:ChocolateyProviderPath

            $Expected = Join-Path `
                $script:MountPath `
                "ProgramData\PimsOS\PostInstall"

            $Result.DestinationPath |
                Should -Be $Expected

        }


        It "Refuse un montage inexistant" {

            {

                Install-PimsOSPostInstallRuntime `
                    -MountPath (
                        Join-Path `
                            $TestDrive `
                            "MissingMount"
                    ) `
                    -SourcePath $script:SourcePath

            } |
                Should -Throw "*chemin de montage Windows est introuvable*"

        }


        It "Refuse un runtime source inexistant" {

            {

                Install-PimsOSPostInstallRuntime `
                    -MountPath $script:MountPath `
                    -SourcePath (
                        Join-Path `
                            $TestDrive `
                            "MissingRuntime"
                    )

            } |
                Should -Throw "*runtime PostInstall source est introuvable*"

        }


        It "Refuse un runtime incomplet" {

            Remove-Item `
                -LiteralPath (
                    Join-Path `
                        $script:SourcePath `
                        "Network.ps1"
                ) `
                -Force

            {

                Install-PimsOSPostInstallRuntime `
                    -MountPath $script:MountPath `
                    -SourcePath $script:SourcePath

            } |
                Should -Throw "*Fichier PostInstall requis introuvable*"

        }

    }


    # ==================================================
    # Install-PimsOSFirstBoot
    # ==================================================

    Context "Install-PimsOSFirstBoot" {

        It "Crée unattend.xml dans Windows\Panther" {

            $BootstrapPath =
                "C:\ProgramData\PimsOS\PostInstall\Bootstrap.ps1"

            $Result =
                Install-PimsOSFirstBoot `
                    -MountPath $script:MountPath `
                    -BootstrapPath $BootstrapPath

            Test-Path `
                -LiteralPath $Result.UnattendPath `
                -PathType Leaf |
                Should -BeTrue

        }


        It "Crée le dossier Panther automatiquement" {

            $BootstrapPath =
                "C:\ProgramData\PimsOS\PostInstall\Bootstrap.ps1"

            $null =
                Install-PimsOSFirstBoot `
                    -MountPath $script:MountPath `
                    -BootstrapPath $BootstrapPath

            Test-Path `
                -LiteralPath (
                    Join-Path `
                        $script:MountPath `
                        "Windows\Panther"
                ) `
                -PathType Container |
                Should -BeTrue

        }


        It "Produit un XML FirstBoot valide" {

            $BootstrapPath =
                "C:\ProgramData\PimsOS\PostInstall\Bootstrap.ps1"

            $Result =
                Install-PimsOSFirstBoot `
                    -MountPath $script:MountPath `
                    -BootstrapPath $BootstrapPath

            {

                [xml](
                    Get-Content `
                        -LiteralPath $Result.UnattendPath `
                        -Raw `
                        -Encoding UTF8
                )

            } |
                Should -Not -Throw

        }


        It "Transmet le chemin du Bootstrap" {

            $BootstrapPath =
                "C:\ProgramData\PimsOS\PostInstall\Bootstrap.ps1"

            $Result =
                Install-PimsOSFirstBoot `
                    -MountPath $script:MountPath `
                    -BootstrapPath $BootstrapPath

            $Xml = [xml](
                Get-Content `
                    -LiteralPath $Result.UnattendPath `
                    -Raw `
                    -Encoding UTF8
            )

            $CommandLine =
                $Xml.SelectSingleNode(
                    '//*[local-name()="CommandLine"]'
                )

            $CommandLine.InnerText |
                Should -Match "Bootstrap.ps1"

        }


        It "Refuse un montage inexistant" {

            {

                Install-PimsOSFirstBoot `
                    -MountPath (
                        Join-Path `
                            $TestDrive `
                            "MissingMount"
                    ) `
                    -BootstrapPath `
                        "C:\ProgramData\PimsOS\PostInstall\Bootstrap.ps1"

            } |
                Should -Throw "*chemin de montage Windows est introuvable*"

        }


        It "Refuse un Bootstrap vide" {

            {

                Install-PimsOSFirstBoot `
                    -MountPath $script:MountPath `
                    -BootstrapPath ""

            } |
                Should -Throw "*Cannot bind argument to parameter 'BootstrapPath'*"

        }

    }


    # ==================================================
    # Get-PostInstallRuntimePath
    # ==================================================

    Context "Get-PostInstallRuntimePath" {

        It "Retourne le dossier Modules\PostInstall du projet" {

            $Result = Get-PostInstallRuntimePath

            $Expected = (
                Resolve-Path `
                    "$PSScriptRoot\..\..\..\..\Modules\PostInstall"
            ).Path

            $Result |
                Should -Be $Expected

        }


        It "Retourne un dossier existant" {

            $Result = Get-PostInstallRuntimePath

            Test-Path `
                -LiteralPath $Result `
                -PathType Container |
                Should -BeTrue

        }

    }

}
