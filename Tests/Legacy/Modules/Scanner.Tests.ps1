<#
.SYNOPSIS
    Tests unitaires du module Scanner.

.DESCRIPTION
    Vérifie les fonctions de découverte des fichiers du framework
    de migration PimsOS.

.NOTES

    Projet : PimsOS
    Module : Scanner.Tests
    Framework : Pester 5

#>

BeforeAll {

    $ProjectRoot = Resolve-Path (
		Join-Path $PSScriptRoot "..\..\.."
	)

	$ModuleRoot = Join-Path $ProjectRoot "Tools\Migration\Modules"

    Import-Module `
        (Join-Path $ModuleRoot "Common.psm1") `
        -Force

    Import-Module `
        (Join-Path $ModuleRoot "Scanner.psm1") `
        -Force

}

Describe "Module Scanner" {

    Context "Chargement du module" {

        It "Le module Scanner est chargé" {

            Get-Module Scanner |
                Should -Not -BeNullOrEmpty

        }

    }

    Context "Test-IsExcluded" {

        It "Retourne True pour un dossier exclu" {

            $File = [System.IO.FileInfo]::new(
                (Join-Path (Get-ProjectRoot) ".git\config")
            )

            Test-IsExcluded `
                -File $File |
                Should -BeTrue

        }

        It "Retourne False pour un fichier normal" {

            $File = [System.IO.FileInfo]::new(
                (Join-Path (Get-ProjectRoot) "README.md")
            )

            Test-IsExcluded `
                -File $File |
                Should -BeFalse

        }

    }

    Context "Get-ProjectFiles" {

        It "Retourne une collection" {

            $Files = Get-ProjectFiles

            $Files |
                Should -Not -BeNullOrEmpty

        }

        It "Retourne uniquement des FileInfo" {

            $Files = Get-ProjectFiles

            foreach ($File in $Files)
            {
                $File |
                    Should -BeOfType ([System.IO.FileInfo])
            }

        }

        It "Retourne des fichiers PowerShell" {

            $Files = Get-ProjectFiles

            foreach ($File in $Files)
            {
                $File.Extension |
                    Should -BeIn @(
                        ".ps1",
                        ".psm1",
                        ".psd1"
                    )
            }

        }

        It "Lève une exception sur un dossier inexistant" {

            {
                Get-ProjectFiles `
                    -Root "C:\___Impossible___"
            } |
            Should -Throw

        }

    }

    Context "Get-PowerShellFiles" {

        It "Retourne au moins un fichier" {

            $Files = Get-PowerShellFiles

            $Files.Count |
                Should -BeGreaterThan 0

        }

        It "Retourne uniquement des fichiers PowerShell" {

            $Files = Get-PowerShellFiles

            foreach ($File in $Files)
            {
                $File.Extension |
                    Should -BeIn @(
                        ".ps1",
                        ".psm1",
                        ".psd1"
                    )
            }

        }

    }

    Context "Get-MarkdownFiles" {

        It "Retourne une collection" {

            $Files = Get-MarkdownFiles

            @($Files).Count |
				Should -BeGreaterThan 0

        }

        It "Retourne uniquement des fichiers Markdown" {

            $Files = Get-MarkdownFiles

            foreach ($File in $Files)
            {
                $File.Extension |
                    Should -Be ".md"
            }

        }

        It "Retourne une collection vide si le dossier n'existe pas" {

            $Files = Get-MarkdownFiles `
                -Root "C:\___Impossible___"

            $Files.Count |
                Should -Be 0

        }

    }

    Context "Get-JsonFiles" {

        It "Retourne une collection" {

            $Files = Get-JsonFiles

            @($Files).Count |
				Should -BeGreaterThan 0

        }

        It "Retourne uniquement des fichiers JSON" {

            $Files = Get-JsonFiles

            foreach ($File in $Files)
            {
                $File.Extension |
                    Should -Be ".json"
            }

        }

        It "Retourne une collection vide si le dossier n'existe pas" {

            $Files = Get-JsonFiles `
                -Root "C:\___Impossible___"

            $Files.Count |
                Should -Be 0

        }

    }
	    Context "Get-MigrationFiles" {

        It "Retourne une collection" {

            $Files = Get-MigrationFiles

            $Files |
                Should -Not -BeNullOrEmpty

        }

        It "Ne retourne aucun fichier situé dans un dossier exclu" {

            $Files = Get-MigrationFiles

            foreach ($File in $Files)
            {
                Test-IsExcluded `
                    -File $File |
                    Should -BeFalse
            }

        }

    }

    Context "Get-RuleFiles" {

        It "Retourne une collection" {

            $Files = Get-RuleFiles

            @($Files).Count |
				Should -BeGreaterThan 0

        }

        It "Retourne uniquement des scripts PowerShell" {

            $Files = Get-RuleFiles

            foreach ($File in $Files)
            {
                $File.Extension |
                    Should -Be ".ps1"
            }

        }

    }

    Context "Get-ModuleFiles" {

        It "Retourne une collection" {

            $Files = Get-ModuleFiles

            @($Files).Count |
				Should -BeGreaterThan 0

        }

        It "Retourne uniquement des modules PowerShell" {

            $Files = Get-ModuleFiles

            foreach ($File in $Files)
            {
                $File.Extension |
                    Should -Be ".psm1"
            }

        }

    }

    Context "Get-ProjectInventory" {

        It "Retourne un objet" {

            $Inventory = Get-ProjectInventory

            $Inventory |
                Should -Not -BeNullOrEmpty

        }

        It "Contient toutes les propriétés attendues" {

            $Inventory = Get-ProjectInventory

            $Inventory.PowerShell |
                Should -Not -BeNullOrEmpty

            $Inventory.Markdown |
                Should -Not -BeNullOrEmpty

            $Inventory.Json |
                Should -Not -BeNullOrEmpty

            $Inventory.Migration |
                Should -Not -BeNullOrEmpty

            $Inventory.Rules |
                Should -Not -BeNullOrEmpty

            $Inventory.Modules |
                Should -Not -BeNullOrEmpty

        }

    }

    Context "Exports du module" {

        It "Exporte toutes les fonctions attendues" {

            $Module = Get-Module Scanner

            $Expected = @(
                "Test-IsExcluded",
                "Get-PowerShellFiles",
                "Get-MarkdownFiles",
                "Get-JsonFiles",
                "Get-ProjectFiles",
                "Get-MigrationFiles",
                "Get-RuleFiles",
                "Get-ModuleFiles",
                "Get-ProjectInventory"
            )

            foreach ($Function in $Expected)
            {
                $Module.ExportedFunctions.Keys |
                    Should -Contain $Function
            }

        }

    }

}