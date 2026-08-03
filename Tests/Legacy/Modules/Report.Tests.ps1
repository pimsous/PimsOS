<#
.SYNOPSIS
    Tests unitaires du module Report.

.DESCRIPTION
    Vérifie le gestionnaire de rapports du framework de migration PimsOS.

.NOTES

    Projet : PimsOS
    Module : Report.Tests
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
        (Join-Path $ModuleRoot "Replace.psm1") `
        -Force

    Import-Module `
        (Join-Path $ModuleRoot "Report.psm1") `
        -Force

}

Describe "Module Report" {

    Context "New-Report" {
		
		BeforeEach {

            $Report = New-Report

        }

        It "Crée un rapport valide" {

            $Report |
                Should -Not -BeNullOrEmpty

        }

        It "Possède un ReportId" {

            $Report.ReportId |
                Should -Not -BeNullOrEmpty

        }

        It "Initialise StartTime" {

            $Report.StartTime |
                Should -Not -BeNullOrEmpty

        }

        It "Initialise EndTime à null" {

            $Report.EndTime |
                Should -BeNullOrEmpty

        }

        It "Initialise Duration à zéro" {

            $Report.Duration |
                Should -Be ([TimeSpan]::Zero)

        }

        It "Initialise les collections" {

            $Report.Files.Count |
                Should -Be 0

            $Report.Replacements.Count |
                Should -Be 0

            $Report.Messages.Count |
                Should -Be 0

            $Report.Warnings.Count |
                Should -Be 0

            $Report.Errors.Count |
                Should -Be 0

        }

    }

    Context "Test-Report" {

			BeforeEach {

				$Report = New-Report

			}

			It "Retourne True pour un rapport valide" {

				Test-Report `
					-Report $Report |
					Should -BeTrue

			}


        It "Retourne False si une propriété est absente" {

            $Invalid = [PSCustomObject]@{

                ReportId = [guid]::NewGuid()

            }

            Test-Report `
                -Report $Invalid |
                Should -BeFalse

        }

        It "Retourne False avec un objet vide" {

            Test-Report `
                -Report ([PSCustomObject]@{}) |
                Should -BeFalse

        }

    }

    Context "Clear-Report" {

        BeforeEach {

            $Report = New-Report

            Add-ReportMessage `
                -Report $Report `
                -Text "Message"

            Add-ReportWarning `
                -Report $Report `
                -Text "Warning"

            Add-ReportError `
                -Report $Report `
                -Text "Error"

            Add-ReportFile `
                -Report $Report `
                -Path "C:\Temp\Test.txt"

            $Replacement = New-Replacement `
                -Start 0 `
                -End 5 `
                -Original "Hello" `
                -Replacement "Bonjour"

            Add-ReportReplacement `
                -Report $Report `
                -Replacement $Replacement

            Complete-Report `
                -Report $Report

        }

        It "Vide toutes les collections" {

            Clear-Report `
                -Report $Report

            $Report.Files.Count |
                Should -Be 0

            $Report.Replacements.Count |
                Should -Be 0

            $Report.Messages.Count |
                Should -Be 0

            $Report.Warnings.Count |
                Should -Be 0

            $Report.Errors.Count |
                Should -Be 0

        }

        It "Réinitialise EndTime" {

            Clear-Report `
                -Report $Report

            $Report.EndTime |
                Should -BeNullOrEmpty

        }

        It "Réinitialise Duration" {

            Clear-Report `
                -Report $Report

            $Report.Duration |
                Should -Be ([TimeSpan]::Zero)

        }

        It "Lève une exception avec un rapport invalide" {

            {

                Clear-Report `
                    -Report ([PSCustomObject]@{})

            } |
            Should -Throw

        }

    }

    Context "New-ReportEntry" {

        It "Crée un message" {

            $Entry = New-ReportEntry `
                -Type Message `
                -Text "Bonjour"

            $Entry |
                Should -Not -BeNullOrEmpty

        }

        It "Initialise correctement les propriétés" {

            $Entry = New-ReportEntry `
                -Type Warning `
                -Text "Attention"

            $Entry.Type |
                Should -Be "Warning"

            $Entry.Text |
                Should -Be "Attention"

            $Entry.Time |
                Should -Not -BeNullOrEmpty

        }

        It "Accepte le type Error" {

            {

                New-ReportEntry `
                    -Type Error `
                    -Text "Erreur"

            } |
            Should -Not -Throw

        }

        It "Refuse un type invalide" {

            {

                New-ReportEntry `
                    -Type "Invalid" `
                    -Text "Test"

            } |
            Should -Throw

        }

    }
	    Context "Add-ReportMessage" {

        BeforeEach {

            $Report = New-Report

        }

        It "Ajoute un message" {

            Add-ReportMessage `
                -Report $Report `
                -Text "Premier message"

            $Report.Messages.Count |
                Should -Be 1

        }

        It "Ajoute le bon texte" {

            Add-ReportMessage `
                -Report $Report `
                -Text "Bonjour"

            $Report.Messages[0].Text |
                Should -Be "Bonjour"

        }

        It "Lève une exception avec un rapport invalide" {

            {

                Add-ReportMessage `
                    -Report ([PSCustomObject]@{}) `
                    -Text "Test"

            } |
            Should -Throw

        }

    }

    Context "Add-ReportWarning" {

        BeforeEach {

            $Report = New-Report

        }

        It "Ajoute un avertissement" {

            Add-ReportWarning `
                -Report $Report `
                -Text "Attention"

            $Report.Warnings.Count |
                Should -Be 1

        }

        It "Crée une entrée de type Warning" {

            Add-ReportWarning `
                -Report $Report `
                -Text "Attention"

            $Report.Warnings[0].Type |
                Should -Be "Warning"

        }

        It "Lève une exception avec un rapport invalide" {

            {

                Add-ReportWarning `
                    -Report ([PSCustomObject]@{}) `
                    -Text "Test"

            } |
            Should -Throw

        }

    }

    Context "Add-ReportError" {

        BeforeEach {

            $Report = New-Report

        }

        It "Ajoute une erreur" {

            Add-ReportError `
                -Report $Report `
                -Text "Erreur"

            $Report.Errors.Count |
                Should -Be 1

        }

        It "Crée une entrée de type Error" {

            Add-ReportError `
                -Report $Report `
                -Text "Erreur"

            $Report.Errors[0].Type |
                Should -Be "Error"

        }

        It "Lève une exception avec un rapport invalide" {

            {

                Add-ReportError `
                    -Report ([PSCustomObject]@{}) `
                    -Text "Test"

            } |
            Should -Throw

        }

    }

    Context "New-ReportFile" {

        It "Crée une entrée de fichier" {

            $File = New-ReportFile `
                -Path "C:\Temp\Test.txt"

            $File |
                Should -Not -BeNullOrEmpty

        }

        It "Initialise correctement les propriétés" {

            $File = New-ReportFile `
                -Path "C:\Temp\Test.txt"

            $File.Path |
                Should -Be "C:\Temp\Test.txt"

            $File.Time |
                Should -Not -BeNullOrEmpty

        }

        It "Positionne Exists à False pour un fichier absent" {

            $File = New-ReportFile `
                -Path "C:\Temp\Inexistant.txt"

            $File.Exists |
                Should -BeFalse

        }

    }

    Context "Add-ReportFile" {

        BeforeEach {

            $Report = New-Report

        }

        It "Ajoute un fichier" {

            Add-ReportFile `
                -Report $Report `
                -Path "C:\Temp\Test.txt"

            $Report.Files.Count |
                Should -Be 1

        }

        It "Conserve le chemin" {

            Add-ReportFile `
                -Report $Report `
                -Path "C:\Temp\Test.txt"

            $Report.Files[0].Path |
                Should -Be "C:\Temp\Test.txt"

        }

        It "Lève une exception avec un rapport invalide" {

            {

                Add-ReportFile `
                    -Report ([PSCustomObject]@{}) `
                    -Path "C:\Temp\Test.txt"

            } |
            Should -Throw

        }

    }

    Context "Add-ReportReplacement" {

        BeforeEach {

            $Report = New-Report

        }

        It "Ajoute un remplacement" {

            $Replacement = New-Replacement `
                -Start 0 `
                -End 5 `
                -Original "Hello" `
                -Replacement "Bonjour"

            Add-ReportReplacement `
                -Report $Report `
                -Replacement $Replacement

            $Report.Replacements.Count |
                Should -Be 1

        }

        It "Conserve le même objet" {

            $Replacement = New-Replacement `
                -Start 0 `
                -End 5 `
                -Original "Hello" `
                -Replacement "Bonjour"

            Add-ReportReplacement `
                -Report $Report `
                -Replacement $Replacement

            $Report.Replacements[0] |
                Should -Be $Replacement

        }

        It "Lève une exception avec un remplacement invalide" {

            {

                Add-ReportReplacement `
                    -Report $Report `
                    -Replacement ([PSCustomObject]@{})

            } |
            Should -Throw

        }

        It "Lève une exception avec un rapport invalide" {

            $Replacement = New-Replacement `
                -Start 0 `
                -End 5 `
                -Original "Hello" `
                -Replacement "Bonjour"

            {

                Add-ReportReplacement `
                    -Report ([PSCustomObject]@{}) `
                    -Replacement $Replacement

            } |
            Should -Throw

        }

    }
	    Context "Get-ReportMessages" {

        BeforeEach {

            $Report = New-Report

            Add-ReportMessage `
                -Report $Report `
                -Text "Premier"

            Add-ReportMessage `
                -Report $Report `
                -Text "Second"

        }

        It "Retourne tous les messages" {

            $Messages = Get-ReportMessages `
                -Report $Report

            $Messages.Count |
                Should -Be 2

        }

        It "Retourne les messages dans l'ordre d'ajout" {

            $Messages = Get-ReportMessages `
                -Report $Report

            $Messages[0].Text |
                Should -Be "Premier"

            $Messages[1].Text |
                Should -Be "Second"

        }

    }

    Context "Get-ReportWarnings" {

        BeforeEach {

            $Report = New-Report

            Add-ReportWarning `
                -Report $Report `
                -Text "Attention"

        }

        It "Retourne les avertissements" {

            $Warnings = Get-ReportWarnings `
                -Report $Report

            $Warnings.Count |
                Should -Be 1

        }

        It "Retourne le bon type" {

            $Warnings = Get-ReportWarnings `
                -Report $Report

            $Warnings[0].Type |
                Should -Be "Warning"

        }

    }

    Context "Get-ReportErrors" {

        BeforeEach {

            $Report = New-Report

            Add-ReportError `
                -Report $Report `
                -Text "Erreur"

        }

        It "Retourne les erreurs" {

            $Errors = Get-ReportErrors `
                -Report $Report

            $Errors.Count |
                Should -Be 1

        }

        It "Retourne le bon type" {

            $Errors = Get-ReportErrors `
                -Report $Report

            $Errors[0].Type |
                Should -Be "Error"

        }

    }

    Context "Get-ReportFiles" {

        BeforeEach {

            $Report = New-Report

            Add-ReportFile `
                -Report $Report `
                -Path "C:\Temp\Test.txt"

        }

        It "Retourne les fichiers" {

            $Files = Get-ReportFiles `
                -Report $Report

            $Files.Count |
                Should -Be 1

        }

        It "Retourne le bon chemin" {

            $Files = Get-ReportFiles `
                -Report $Report

            $Files[0].Path |
                Should -Be "C:\Temp\Test.txt"

        }

    }

    Context "Get-ReportReplacements" {

        BeforeEach {

            $Report = New-Report

            $Replacement = New-Replacement `
                -Start 0 `
                -End 5 `
                -Original "Hello" `
                -Replacement "Bonjour"

            Add-ReportReplacement `
                -Report $Report `
                -Replacement $Replacement

        }

        It "Retourne les remplacements" {

            $Replacements = Get-ReportReplacements `
                -Report $Report

            $Replacements.Count |
                Should -Be 1

        }

        It "Retourne le même objet" {

            $Replacements = Get-ReportReplacements `
                -Report $Report

            $Replacements[0].Original |
                Should -Be "Hello"

        }

    }

    Context "Complete-Report" {

        BeforeEach {

            $Report = New-Report

        }

        It "Renseigne EndTime" {

            Complete-Report `
                -Report $Report

            $Report.EndTime |
                Should -Not -BeNullOrEmpty

        }

        It "Calcule une durée positive" {

            Start-Sleep -Milliseconds 100

            Complete-Report `
                -Report $Report

            $Report.Duration.TotalMilliseconds |
                Should -BeGreaterThan 0

        }

        It "Empêche de terminer deux fois le rapport" {

            Complete-Report `
                -Report $Report

            {

                Complete-Report `
                    -Report $Report

            } |
            Should -Throw

        }

    }

    Context "Get-ReportDuration" {

        It "Retourne une durée pendant l'exécution" {

            $Report = New-Report

            Start-Sleep -Milliseconds 100

            $Duration = Get-ReportDuration `
                -Report $Report

            $Duration.TotalMilliseconds |
                Should -BeGreaterThan 0

        }

        It "Retourne la durée finale après Complete-Report" {

            $Report = New-Report

            Start-Sleep -Milliseconds 100

            Complete-Report `
                -Report $Report

            $Duration = Get-ReportDuration `
                -Report $Report

            $Duration |
                Should -Be $Report.Duration

        }

    }

    Context "Get-ReportStatistics" {

        BeforeEach {

            $Report = New-Report

            Add-ReportMessage `
                -Report $Report `
                -Text "Message"

            Add-ReportWarning `
                -Report $Report `
                -Text "Warning"

            Add-ReportError `
                -Report $Report `
                -Text "Error"

            Add-ReportFile `
                -Report $Report `
                -Path "C:\Temp\Test.txt"

            $Replacement = New-Replacement `
                -Start 0 `
                -End 5 `
                -Original "Hello" `
                -Replacement "Bonjour"

            Add-ReportReplacement `
                -Report $Report `
                -Replacement $Replacement

        }

        It "Retourne les bonnes statistiques" {

            $Stats = Get-ReportStatistics `
                -Report $Report

            $Stats.Files |
                Should -Be 1

            $Stats.Replacements |
                Should -Be 1

            $Stats.Messages |
                Should -Be 1

            $Stats.Warnings |
                Should -Be 1

            $Stats.Errors |
                Should -Be 1

        }

        It "Indique que le rapport n'est pas terminé" {

            $Stats = Get-ReportStatistics `
                -Report $Report

            $Stats.Completed |
                Should -BeFalse

        }

        It "Indique que le rapport est terminé" {

            Complete-Report `
                -Report $Report

            $Stats = Get-ReportStatistics `
                -Report $Report

            $Stats.Completed |
                Should -BeTrue

        }

    }
	    Context "Export-ReportJson" {

        BeforeEach {

            $Report = New-Report

            Add-ReportMessage `
                -Report $Report `
                -Text "Message de test"

            $OutputFile = Join-Path `
                $TestDrive `
                "Report.json"

        }

        It "Crée le fichier JSON" {

            Export-ReportJson `
                -Report $Report `
                -File ([System.IO.FileInfo]::new($OutputFile))

            Test-Path `
                -LiteralPath $OutputFile |
                Should -BeTrue

        }

        It "Produit un JSON valide" {

            Export-ReportJson `
                -Report $Report `
                -File ([System.IO.FileInfo]::new($OutputFile))

            {

                Get-Content `
                    -LiteralPath $OutputFile `
                    -Raw |
                    ConvertFrom-Json

            } |
            Should -Not -Throw

        }

        It "Contient les propriétés attendues" {

            Export-ReportJson `
                -Report $Report `
                -File ([System.IO.FileInfo]::new($OutputFile))

            $Json = Get-Content `
                -LiteralPath $OutputFile `
                -Raw |
                ConvertFrom-Json

            $Json.ReportId |
                Should -Not -BeNullOrEmpty

            $Json.Messages.Count |
                Should -Be 1

        }

        It "Lève une exception avec un rapport invalide" {

            {

                Export-ReportJson `
                    -Report ([PSCustomObject]@{}) `
                    -File ([System.IO.FileInfo]::new($OutputFile))

            } |
            Should -Throw

        }

    }

    Context "Export-ReportText" {

        BeforeEach {

            $Report = New-Report

            Add-ReportMessage `
                -Report $Report `
                -Text "Message"

            Add-ReportWarning `
                -Report $Report `
                -Text "Attention"

            Add-ReportError `
                -Report $Report `
                -Text "Erreur"

            $OutputFile = Join-Path `
                $TestDrive `
                "Report.txt"

        }

        It "Crée le fichier texte" {

            Export-ReportText `
                -Report $Report `
                -File ([System.IO.FileInfo]::new($OutputFile))

            Test-Path `
                -LiteralPath $OutputFile |
                Should -BeTrue

        }

        It "Contient le titre du rapport" {

            Export-ReportText `
                -Report $Report `
                -File ([System.IO.FileInfo]::new($OutputFile))

            $Content = Get-Content `
                -LiteralPath $OutputFile `
                -Raw

            $Content |
                Should -Match "Rapport de migration PimsOS"

        }

        It "Contient les messages" {

            Export-ReportText `
                -Report $Report `
                -File ([System.IO.FileInfo]::new($OutputFile))

            $Content = Get-Content `
                -LiteralPath $OutputFile `
                -Raw

            $Content |
                Should -Match "Message"

            $Content |
                Should -Match "Attention"

            $Content |
                Should -Match "Erreur"

        }

        It "Lève une exception avec un rapport invalide" {

            {

                Export-ReportText `
                    -Report ([PSCustomObject]@{}) `
                    -File ([System.IO.FileInfo]::new($OutputFile))

            } |
            Should -Throw

        }

    }

    Context "Exports du module" {

        It "Exporte toutes les fonctions attendues" {

            $Module = Get-Module Report

            $Expected = @(

                "New-Report",
                "Test-Report",
                "Clear-Report",
                "New-ReportEntry",
                "Add-ReportMessage",
                "Add-ReportWarning",
                "Add-ReportError",
                "New-ReportFile",
                "Add-ReportFile",
                "Add-ReportReplacement",
                "Get-ReportMessages",
                "Get-ReportWarnings",
                "Get-ReportErrors",
                "Get-ReportFiles",
                "Get-ReportReplacements",
                "Complete-Report",
                "Get-ReportDuration",
                "Get-ReportStatistics",
                "Export-ReportJson",
                "Export-ReportText"

            )

            foreach ($Function in $Expected)
            {
                $Module.ExportedFunctions.Keys |
                    Should -Contain $Function
            }

        }

    }

}