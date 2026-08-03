<#
.SYNOPSIS
    Tests unitaires du module Common.

.DESCRIPTION
    Vérifie les fonctions utilitaires du framework de migration.

.NOTES

    Projet : PimsOS
    Module : Common.Tests
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

}

Describe "Module Common" {

    Context "Chargement du module" {

        It "Le module est chargé" {

            Get-Module Common |
                Should -Not -BeNullOrEmpty

        }

    }

    Context "Informations du framework" {

        It "Retourne le répertoire du projet" {

            $Result = Get-ProjectRoot

            $Result |
                Should -Not -BeNullOrEmpty

            Test-Path $Result |
                Should -BeTrue

        }

        It "Retourne le répertoire Migration" {

            $Result = Get-MigrationRoot

            $Result |
                Should -Not -BeNullOrEmpty

            Test-Path $Result |
                Should -BeTrue

        }

        It "Retourne le nom du framework" {

            Get-FrameworkName |
                Should -Be "PimsOS Migration Framework"

        }

        It "Retourne la version du framework" {

            Get-FrameworkVersion |
                Should -Be "1.1.0"

        }

        It "Retourne les extensions du projet" {

            $Extensions = Get-ProjectExtensions

            $Extensions |
                Should -Contain "*.ps1"

            $Extensions |
                Should -Contain "*.psm1"

            $Extensions |
                Should -Contain "*.psd1"

        }

        It "Retourne les dossiers exclus" {

            $Folders = Get-ExcludedFolders

            $Folders |
                Should -Contain ".git"

            $Folders |
                Should -Contain ".github"

            $Folders |
                Should -Contain ".vscode"

        }

    }

    Context "Version de PowerShell" {

        It "PowerShell 7.6 est supporté" {

            Test-PowerShellVersion |
                Should -BeTrue

        }

        It "Une version très élevée est refusée" {

            Test-PowerShellVersion `
                -MinimumVersion 99.0 |
                Should -BeFalse

        }

    }

    Context "Gestion des chemins" {

        It "Valide un chemin existant" {

            Test-MigrationPath `
                -Path $env:TEMP |
                Should -BeTrue

        }

        It "Refuse un chemin inexistant" {

            Test-MigrationPath `
                -Path "C:\___Impossible___\ABC" |
                Should -BeFalse

        }

        It "Calcule un chemin relatif" {

            $Base = "C:\Temp"
            $Target = "C:\Temp\Test\File.ps1"

            $Result = Get-RelativePath `
                -BasePath $Base `
                -Path $Target

            $Result |
                Should -Be "Test\File.ps1"

        }

    }

    Context "Objets métier" {

        It "Crée une règle de migration" {

            $Rule = New-MigrationRule

            $Rule.ObjectType |
                Should -Be "MigrationRule"

            $Rule.Name |
                Should -Be ""

            $Rule.Description |
                Should -Be ""

            $Rule.Enabled |
                Should -BeTrue

            $Rule.Priority |
                Should -Be 100

            $Rule.Script |
                Should -BeNullOrEmpty

        }

        It "Crée un contexte de migration" {

            $Context = New-MigrationContext

            $Context.ObjectType |
                Should -Be "MigrationContext"

            $Context.ProjectName |
                Should -Be ""

            $Context.ProjectRoot |
                Should -Be ""

            $Context.Rule |
                Should -Be ""

            $Context.AnalyzeOnly |
                Should -BeFalse

            $Context.ExecuteAll |
                Should -BeFalse

            ($null -eq $Context.Results) |
				Should -BeFalse

			$Context.Results.Count |
				Should -Be 0

        }

    }

    Context "Objets résultat" {

        It "Crée un résultat vide" {

            $Result = New-MigrationResult

            $Result.ObjectType |
                Should -Be "MigrationResult"

            $Result.Modified |
                Should -BeFalse

            $Result.File |
                Should -BeNullOrEmpty

            $Result.Rule |
                Should -BeNullOrEmpty

            $Result.Message |
                Should -Be ""

        }

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

        It "Crée une erreur de migration" {

            $Error = New-MigrationError `
                -File "Test.ps1" `
                -Rule "Rule001" `
                -Message "Erreur"

            $Error.ObjectType |
                Should -Be "MigrationError"

            $Error.File |
                Should -Be "Test.ps1"

            $Error.Rule |
                Should -Be "Rule001"

            $Error.Message |
                Should -Be "Erreur"

        }

    }

    Context "Chronomètre" {

        It "Crée un chronomètre" {

            $Stopwatch = New-Stopwatch

            $Stopwatch |
                Should -BeOfType ([System.Diagnostics.Stopwatch])

            $Stopwatch.IsRunning |
                Should -BeTrue

        }

        It "Retourne un temps écoulé" {

            $Stopwatch = New-Stopwatch

            Start-Sleep -Milliseconds 100

            $Elapsed = Get-ElapsedTime `
                -Stopwatch $Stopwatch

            $Elapsed |
                Should -BeOfType ([TimeSpan])

            $Elapsed.TotalMilliseconds |
                Should -BeGreaterThan 50

        }

    }

    Context "Fonctions d'affichage" {

        InModuleScope Common {

            BeforeEach {

                Mock Write-Host {}

            }

            It "Write-Blank appelle Write-Host" {

                Write-Blank

                Should -Invoke Write-Host -Times 1

            }

            It "Write-Banner affiche le bandeau" {

                Write-Banner

                Should -Invoke Write-Host -Times 6

            }

            It "Write-Section affiche une section" {

                Write-Section -Title "Migration"

                Should -Invoke Write-Host -Times 2

            }

            It "Write-Info affiche un message" {

                Write-Info -Message "Information"

                Should -Invoke Write-Host -Times 1

            }

            It "Write-Success affiche un succès" {

                Write-Success -Message "Succès"

                Should -Invoke Write-Host -Times 1

            }

            It "Write-WarningMessage affiche un avertissement" {

                Write-WarningMessage -Message "Attention"

                Should -Invoke Write-Host -Times 1

            }

            It "Write-ErrorMessage affiche une erreur" {

                Write-ErrorMessage -Message "Erreur"

                Should -Invoke Write-Host -Times 1

            }

        }

    }

    Context "Exports du module" {

        It "Exporte toutes les fonctions attendues" {

            $Module = Get-Module Common

            $Expected = @(
                "Get-ProjectRoot",
                "Get-MigrationRoot",
                "Get-FrameworkName",
                "Get-FrameworkVersion",
                "Get-ProjectExtensions",
                "Get-ExcludedFolders",
                "Test-PowerShellVersion",
                "Test-MigrationPath",
                "Get-RelativePath",
                "New-Stopwatch",
                "Get-ElapsedTime",
                "New-MigrationRule",
                "New-MigrationContext",
                "New-MigrationResult",
                "New-MigrationError",
                "Write-Blank",
                "Write-Banner",
                "Write-Section",
                "Write-Info",
                "Write-Success",
                "Write-WarningMessage",
                "Write-ErrorMessage"
            )

            foreach ($Function in $Expected) {

                $Module.ExportedFunctions.Keys |
                    Should -Contain $Function

            }

        }

    }

}