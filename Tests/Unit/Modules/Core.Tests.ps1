# ==========================================
# Tests : Core
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Core\Core.ps1"

}

Describe "Core" {

    BeforeEach {

        Reset-Core

    }

    Context "Get-ProjectRoot" {

        It "Retourne le dossier racine du projet" {

            $Root = Get-ProjectRoot

            $Root | Should -Not -BeNullOrEmpty
            (Test-Path $Root) | Should -BeTrue

        }

    }

    Context "Get-Config" {

        It "Charge la configuration" {

            $Config = Get-Config

            $Config | Should -Not -BeNullOrEmpty

        }

        It "Contient une section Build" {

			$Config = Get-Config

			$Config.Build |
				Should -Not -BeNullOrEmpty

		}

        It "Contient une section Paths" {

            $Config = Get-Config

            $Config.Paths | Should -Not -BeNullOrEmpty

        }

    }

    Context "Get-ProjectPath" {

        It "Retourne le dossier ISO" {

            $Path = Get-ProjectPath ISO

            $Path | Should -Not -BeNullOrEmpty

        }

        It "Retourne le dossier Logs" {

            $Path = Get-ProjectPath Logs

            $Path | Should -Not -BeNullOrEmpty

        }

    }

    Context "Get-ObjectProperty" {

        It "Retourne une propriété existante" {

            $Object = [pscustomobject]@{

                Value = 42

            }

            Get-ObjectProperty `
                -Object $Object `
                -Name "Value" |
                Should -Be 42

        }

        It "Retourne la valeur par défaut si la propriété est absente" {

            $Object = [pscustomobject]@{}

            Get-ObjectProperty `
                -Object $Object `
                -Name "Missing" `
                -Default "DefaultValue" |
                Should -Be "DefaultValue"

        }

    }

    Context "Reset-Core" {

        It "Réinitialise le module sans erreur" {

            {

                Reset-Core

            } | Should -Not -Throw

        }

    }

}