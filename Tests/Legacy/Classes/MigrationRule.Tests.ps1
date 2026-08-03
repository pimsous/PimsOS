# ==========================================
# MigrationRule.Tests.ps1
# ==========================================

BeforeAll {

    $ProjectRoot = Resolve-Path (
        Join-Path $PSScriptRoot "..\..\.."
    )

    Import-Module `
        (Join-Path $ProjectRoot "Tools\Migration\Modules\Common.psm1") `
        -Force

}

Describe "New-MigrationRule" {

    Context "Création" {

        It "Peut être créé" {

            $Rule = New-MigrationRule

            $Rule |
                Should -Not -BeNullOrEmpty

        }

        It "Retourne un objet MigrationRule" {

            $Rule = New-MigrationRule

            $Rule.ObjectType |
                Should -Be "MigrationRule"

        }

    }

    Context "Initialisation" {

        BeforeEach {

            $Rule = New-MigrationRule

        }

        It "Initialise Name vide" {

            $Rule.Name |
                Should -Be ""

        }

        It "Initialise Description vide" {

            $Rule.Description |
                Should -Be ""

        }

        It "Initialise Enabled à True" {

            $Rule.Enabled |
                Should -BeTrue

        }

        It "Initialise Priority à 100" {

            $Rule.Priority |
                Should -Be 100

        }

        It "Initialise Script à Null" {

            $Rule.Script |
                Should -BeNullOrEmpty

        }

    }

    Context "Propriétés" {

        BeforeEach {

            $Rule = New-MigrationRule

        }

        It "Peut stocker Name" {

            $Rule.Name = "Logger"

            $Rule.Name |
                Should -Be "Logger"

        }

        It "Peut stocker Description" {

            $Rule.Description = "Migration du module Logger"

            $Rule.Description |
                Should -Be "Migration du module Logger"

        }

        It "Peut modifier Enabled" {

            $Rule.Enabled = $false

            $Rule.Enabled |
                Should -BeFalse

        }

        It "Peut modifier Priority" {

            $Rule.Priority = 10

            $Rule.Priority |
                Should -Be 10

        }

        It "Peut stocker Script" {

            $Script = {

                "Hello"

            }

            $Rule.Script = $Script

            $Rule.Script |
                Should -Be $Script

        }

    }

}