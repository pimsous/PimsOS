# ==========================================
# MigrationContext.Tests.ps1
# ==========================================

BeforeAll {

    $ProjectRoot = Resolve-Path (
        Join-Path $PSScriptRoot "..\..\.."
    )

    Import-Module `
        (Join-Path $ProjectRoot "Tools\Migration\Modules\Common.psm1") `
        -Force

}

Describe "New-MigrationContext" {

    Context "Création" {

        It "Peut être créé" {

            $Context = New-MigrationContext

            $Context |
                Should -Not -BeNullOrEmpty

        }

        It "Retourne un objet MigrationContext" {

            $Context = New-MigrationContext

            $Context.ObjectType |
                Should -Be "MigrationContext"

        }

    }

    Context "Initialisation" {

        BeforeEach {

            $Context = New-MigrationContext

        }

        It "Initialise Results" {

			($null -eq $Context.Results) |
				Should -BeFalse

			$Context.Results.Count |
				Should -Be 0

			$Context.Results.GetType() |
				Should -Be ([System.Collections.Generic.List[object]])

		}

        It "Initialise AnalyzeOnly à False" {

            $Context.AnalyzeOnly |
                Should -BeFalse

        }

        It "Initialise ExecuteAll à False" {

            $Context.ExecuteAll |
                Should -BeFalse

        }

        It "Initialise ProjectName vide" {

            $Context.ProjectName |
                Should -Be ""

        }

        It "Initialise ProjectRoot vide" {

            $Context.ProjectRoot |
                Should -Be ""

        }

        It "Initialise Rule vide" {

            $Context.Rule |
                Should -Be ""

        }

    }

    Context "Propriétés" {

        BeforeEach {

            $Context = New-MigrationContext

        }

        It "Peut stocker ProjectName" {

            $Context.ProjectName = "PimsOS"

            $Context.ProjectName |
                Should -Be "PimsOS"

        }

        It "Peut stocker ProjectRoot" {

            $Context.ProjectRoot = "C:\Projets\PimsOS"

            $Context.ProjectRoot |
                Should -Be "C:\Projets\PimsOS"

        }

        It "Peut stocker ToolsPath" {

            $Context.ToolsPath = "C:\Projets\PimsOS\Tools"

            $Context.ToolsPath |
                Should -Be "C:\Projets\PimsOS\Tools"

        }

        It "Peut stocker MigrationPath" {

            $Context.MigrationPath = "C:\Projets\PimsOS\Tools\Migration"

            $Context.MigrationPath |
                Should -Be "C:\Projets\PimsOS\Tools\Migration"

        }

        It "Peut stocker ModulesPath" {

            $Context.ModulesPath = "C:\Projets\PimsOS\Tools\Migration\Modules"

            $Context.ModulesPath |
                Should -Be "C:\Projets\PimsOS\Tools\Migration\Modules"

        }

        It "Peut stocker TestsPath" {

            $Context.TestsPath = "C:\Projets\PimsOS\Tests"

            $Context.TestsPath |
                Should -Be "C:\Projets\PimsOS\Tests"

        }

        It "Peut stocker Rule" {

            $Context.Rule = "Logger"

            $Context.Rule |
                Should -Be "Logger"

        }

        It "Peut modifier AnalyzeOnly" {

            $Context.AnalyzeOnly = $true

            $Context.AnalyzeOnly |
                Should -BeTrue

        }

        It "Peut modifier ExecuteAll" {

            $Context.ExecuteAll = $true

            $Context.ExecuteAll |
                Should -BeTrue

        }

    }

    Context "Résultats" {

        BeforeEach {

            $Context = New-MigrationContext

        }

        It "Peut ajouter un résultat" {

            $Context.Results.Add("Test")

            $Context.Results.Count |
                Should -Be 1

        }

        It "Conserve le résultat ajouté" {

            $Context.Results.Add("Premier")

            $Context.Results[0] |
                Should -Be "Premier"

        }

    }

}