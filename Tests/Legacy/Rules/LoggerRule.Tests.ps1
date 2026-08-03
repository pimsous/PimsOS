using module "..\..\..\Tools\Migration\Migration.psd1"

<#
.SYNOPSIS
    Tests unitaires de la règle Logger.

.DESCRIPTION
    Vérifie que la règle Logger est correctement construite
    et respecte le contrat d'une MigrationRule.

.NOTES
    Projet : PimsOS
    Auteur : Pims
#>

Describe "Rules\Logger.ps1" {

    BeforeAll {

		$ProjectRoot = Resolve-Path (
			Join-Path $PSScriptRoot "..\..\.."
		)

		$Rule = . (
			Join-Path $ProjectRoot "Tools\Migration\Rules\Logger.ps1"
		)

	}

    Context "Construction de la règle" {

        It "Retourne un objet MigrationRule" {

			$Rule.ObjectType |
				Should -Be "MigrationRule"

		}

        It "Possède le nom 'Logger'" {

            $Rule.Name | Should -Be "Logger"

        }

        It "Possède une description" {

            $Rule.Description | Should -Not -BeNullOrEmpty

        }

        It "Est activée" {

            $Rule.Enabled | Should -BeTrue

        }

        It "Possède une priorité" {

            $Rule.Priority | Should -BeGreaterThan 0

        }

        It "Possède un ScriptBlock" {

            $Rule.Script | Should -BeOfType ScriptBlock

        }

    }

}