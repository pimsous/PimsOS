# ==========================================
# Tests : PostInstall Unattend
# Projet : PimsOS Builder
# ==========================================

$ProjectRoot = (
    Resolve-Path "$PSScriptRoot\..\..\..\.."
).Path


Describe "PostInstall Unattend" {

    BeforeEach {

        $TestProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..\..").Path

        . "$TestProjectRoot\Modules\PostInstall\FirstBoot.ps1"
        . "$TestProjectRoot\Modules\PostInstall\Unattend.ps1"

        $script:BootstrapPath =
            "C:\ProgramData\PimsOS\PostInstall\Bootstrap.ps1"

        $script:Configuration =
            New-PimsOSFirstBootConfiguration `
                -BootstrapPath $script:BootstrapPath

    }

    # ==================================================
    # New-PimsOSUnattendDocument
    # ==================================================

    Context "New-PimsOSUnattendDocument" {

        It "Construit un document XML valide" {

            $Document =
                New-PimsOSUnattendDocument `
                    -FirstBootConfiguration $script:Configuration

            $Document |
                Should -Not -BeNullOrEmpty

            $Document.DocumentElement.Name |
                Should -Be "unattend"

        }

        It "Utilise le namespace unattend Microsoft" {

            $Document =
                New-PimsOSUnattendDocument `
                    -FirstBootConfiguration $script:Configuration

            $Document.DocumentElement.NamespaceURI |
                Should -Be "urn:schemas-microsoft-com:unattend"

        }

        It "Crée le passage oobeSystem" {

            $Document =
                New-PimsOSUnattendDocument `
                    -FirstBootConfiguration $script:Configuration

            $Settings =
                $Document.SelectSingleNode(
                    "/*[local-name()='unattend']/*[local-name()='settings']"
                )

            $Settings |
                Should -Not -BeNullOrEmpty

            $Settings.GetAttribute("pass") |
                Should -Be "oobeSystem"

        }

        It "Crée le composant Shell-Setup" {

            $Document =
                New-PimsOSUnattendDocument `
                    -FirstBootConfiguration $script:Configuration

            $Component =
                $Document.SelectSingleNode(
                    "//*[local-name()='component']"
                )

            $Component |
                Should -Not -BeNullOrEmpty

            $Component.GetAttribute("name") |
                Should -Be "Microsoft-Windows-Shell-Setup"

        }

        It "Crée FirstLogonCommands" {

            $Document =
                New-PimsOSUnattendDocument `
                    -FirstBootConfiguration $script:Configuration

            $FirstLogonCommands =
                $Document.SelectSingleNode(
                    "//*[local-name()='FirstLogonCommands']"
                )

            $FirstLogonCommands |
                Should -Not -BeNullOrEmpty

        }

        It "Crée une commande SynchronousCommand" {

            $Document =
                New-PimsOSUnattendDocument `
                    -FirstBootConfiguration $script:Configuration

            $Command =
                $Document.SelectSingleNode(
                    "//*[local-name()='SynchronousCommand']"
                )

            $Command |
                Should -Not -BeNullOrEmpty

        }

        It "Transmet l'ordre de la commande" {

            $Document =
                New-PimsOSUnattendDocument `
                    -FirstBootConfiguration $script:Configuration

            $Order =
                $Document.SelectSingleNode(
                    "//*[local-name()='Order']"
                )

            $Order.InnerText |
                Should -Be "1"

        }

        It "Transmet la ligne de commande Bootstrap" {

            $Document =
                New-PimsOSUnattendDocument `
                    -FirstBootConfiguration $script:Configuration

            $CommandLine =
                $Document.SelectSingleNode(
                    "//*[local-name()='CommandLine']"
                )

            $CommandLine.InnerText |
                Should -Match "Bootstrap.ps1"

        }

        It "Transmet la description de la commande" {

            $Document =
                New-PimsOSUnattendDocument `
                    -FirstBootConfiguration $script:Configuration

            $Description =
                $Document.SelectSingleNode(
                    "//*[local-name()='Description']"
                )

            $Description.InnerText |
                Should -Be "Lancement du PostInstall PimsOS"

        }

        It "Refuse une configuration null" {

            {

                New-PimsOSUnattendDocument `
                    -FirstBootConfiguration $null

            } |
                Should -Throw "*Cannot bind argument to parameter 'FirstBootConfiguration'*"

        }
		
		It "Déclare le namespace WCM Microsoft" {

            $Document =
                New-PimsOSUnattendDocument `
                    -FirstBootConfiguration $script:Configuration

            $NamespaceManager =
                New-Object System.Xml.XmlNamespaceManager(
                    $Document.NameTable
                )

            $NamespaceManager.AddNamespace(
                "wcm",
                "http://schemas.microsoft.com/WMIConfig/2002/State"
            )

            $Root =
                $Document.DocumentElement

            $Root.GetAttribute(
                "wcm",
                "http://www.w3.org/2000/xmlns/"
            ) |
                Should -Be "http://schemas.microsoft.com/WMIConfig/2002/State"

        }

        It "Ajoute wcm:action='add' aux commandes" {

            $Document =
                New-PimsOSUnattendDocument `
                    -FirstBootConfiguration $script:Configuration

            $Command =
                $Document.SelectSingleNode(
                    "//*[local-name()='SynchronousCommand']"
                )

            $Command |
                Should -Not -BeNullOrEmpty

            $Command.GetAttribute(
                "action",
                "http://schemas.microsoft.com/WMIConfig/2002/State"
            ) |
                Should -Be "add"

        }
    }

    # ==================================================
    # Export-PimsOSUnattendDocument
    # ==================================================

    Context "Export-PimsOSUnattendDocument" {

        It "Crée le fichier unattend.xml" {

            $Path = Join-Path `
                $TestDrive `
                "unattend.xml"

            Export-PimsOSUnattendDocument `
                -FirstBootConfiguration $script:Configuration `
                -Path $Path |
                Out-Null

            Test-Path `
                -LiteralPath $Path `
                -PathType Leaf |
                Should -BeTrue

        }

        It "Crée les dossiers parents" {

            $Path = Join-Path `
                $TestDrive `
                "Nested\Windows\unattend.xml"

            Export-PimsOSUnattendDocument `
                -FirstBootConfiguration $script:Configuration `
                -Path $Path |
                Out-Null

            Test-Path `
                -LiteralPath $Path `
                -PathType Leaf |
                Should -BeTrue

        }

        It "Produit un XML lisible" {

            $Path = Join-Path `
                $TestDrive `
                "unattend.xml"

            Export-PimsOSUnattendDocument `
                -FirstBootConfiguration $script:Configuration `
                -Path $Path |
                Out-Null

            {

                [xml](
                    Get-Content `
                        -LiteralPath $Path `
                        -Raw `
                        -Encoding UTF8
                )

            } |
                Should -Not -Throw

        }

        It "Refuse un chemin vide" {

            {

                Export-PimsOSUnattendDocument `
                    -FirstBootConfiguration $script:Configuration `
                    -Path ""

            } |
                Should -Throw "*Cannot bind argument to parameter 'Path'*"

        }

    }

}
