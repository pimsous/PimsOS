# ==========================================
# MigrationResult.Tests.ps1
# ==========================================

BeforeAll {

    $ProjectRoot = Resolve-Path (
        Join-Path $PSScriptRoot "..\..\.."
    )

    Import-Module `
        (Join-Path $ProjectRoot "Tools\Migration\Modules\Common.psm1") `
        -Force

}

Describe "New-MigrationResult" {

    Context "Création" {

        It "Peut être créé" {

            $Result = New-MigrationResult

            $Result |
                Should -Not -BeNullOrEmpty

        }

        It "Retourne un objet MigrationResult" {

            $Result = New-MigrationResult

            $Result.ObjectType |
                Should -Be "MigrationResult"

        }

    }

    Context "Initialisation" {

        BeforeEach {

            $Result = New-MigrationResult

        }

        It "Initialise Modified à False" {

            $Result.Modified |
                Should -BeFalse

        }

        It "Initialise File vide" {

            $Result.File |
                Should -BeNullOrEmpty

        }

        It "Initialise Rule vide" {

            $Result.Rule |
                Should -BeNullOrEmpty

        }

        It "Initialise Message vide" {

            $Result.Message |
                Should -Be ""

        }

    }

    Context "Propriétés" {

        BeforeEach {

            $Result = New-MigrationResult

        }

        It "Peut stocker Rule" {

            $Result.Rule = "Logger"

            $Result.Rule |
                Should -Be "Logger"

        }

        It "Peut stocker File" {

            $Result.File = "C:\Projets\PimsOS\Modules\Logger.psm1"

            $Result.File |
                Should -Be "C:\Projets\PimsOS\Modules\Logger.psm1"

        }

        It "Peut modifier Modified" {

            $Result.Modified = $true

            $Result.Modified |
                Should -BeTrue

        }

        It "Peut modifier Message" {

            $Result.Message = "Migration réussie"

            $Result.Message |
                Should -Be "Migration réussie"

        }

    }

    Context "Constructeur avec paramètres" {

        It "Crée un résultat complet" {

            $Result = New-MigrationResult `
                -File "Test.ps1" `
                -Rule "Rule001" `
                -Modified $true `
                -Message "OK"

            $Result.ObjectType |
                Should -Be "MigrationResult"

            $Result.File |
                Should -Be "Test.ps1"

            $Result.Rule |
                Should -Be "Rule001"

            $Result.Modified |
                Should -BeTrue

            $Result.Message |
                Should -Be "OK"

        }

    }

}