<#
.SYNOPSIS
    Tests unitaires du module Backup.

.DESCRIPTION
    Vérifie le gestionnaire de sauvegardes du framework PimsOS.

.NOTES

    Projet : PimsOS
    Module : Backup.Tests
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
        (Join-Path $ModuleRoot "Backup.psm1") `
        -Force


    #
    # Création d'un faux projet
    #

    $FakeProject = Join-Path `
        $TestDrive `
        "Project"

    New-Item `
        -ItemType Directory `
        -Path $FakeProject `
        -Force | Out-Null

    $Folder = Join-Path `
        $FakeProject `
        "Source"

    New-Item `
        -ItemType Directory `
        -Path $Folder `
        -Force | Out-Null

    $TestFile = Join-Path `
        $Folder `
        "Sample.txt"

    "Hello Backup" |
        Set-Content `
            -LiteralPath $TestFile `
            -Encoding UTF8

    #
    # Simulation des fonctions du module Common
    #

        Mock Get-ProjectRoot -ModuleName Backup {

        $FakeProject

    }

    Mock Get-MigrationRoot -ModuleName Backup {

        Join-Path `
            $TestDrive `
            "Migration"

    }

}

Describe "Module Backup" {

    Context "Get-BackupRoot" {

        It "Retourne le dossier Backups" {

            $Root = Get-BackupRoot

            $Root |
                Should -Match "Backups$"

        }

    }

    Context "Get-RelativeProjectPath" {

        It "Retourne le chemin relatif" {
			
			(Get-ProjectRoot) | Write-Host
			$TestFile | Write-Host

            $Relative = Get-RelativeProjectPath `
                -File (Get-Item $TestFile)

            $Relative |
                Should -Be "Source\Sample.txt"

        }

        It "Lève une exception si le fichier n'appartient pas au projet" {

            $Outside = Join-Path `
                $TestDrive `
                "Outside.txt"

            "Test" |
                Set-Content `
                    -LiteralPath $Outside

            {

                Get-RelativeProjectPath `
                    -File (Get-Item $Outside)

            } |
            Should -Throw

        }

    }

        Context "Get-BackupPath" {

        BeforeEach {

            $Session = New-BackupSession

        }

        It "Retourne le dossier de la session" {

            Get-BackupPath `
                -Session $Session |
                Should -Be $Session.BackupRoot

        }

    }

    Context "Get-BackupFile" {

        BeforeEach {

            $Session = New-BackupSession

        }

        It "Construit le chemin de sauvegarde" {

            $BackupFile = Get-BackupFile `
                -File (Get-Item $TestFile) `
                -Session $Session

            $BackupFile |
                Should -Match "Sample.txt$"

        }

        It "Place la sauvegarde dans le dossier de session" {

            $BackupFile = Get-BackupFile `
                -File (Get-Item $TestFile) `
                -Session $Session

            $BackupFile.StartsWith(
                $Session.BackupRoot,
                [System.StringComparison]::OrdinalIgnoreCase
            ) |
            Should -BeTrue

        }

    }


	            Context "Test-BackupSession" {

        BeforeEach {

            $Session = New-BackupSession

        }

        It "Retourne True pour une session valide" {

            Test-BackupSession `
                -Session $Session |
                Should -BeTrue

        }

        It "Retourne False pour une session vide" {

            Test-BackupSession `
                -Session @{} |
                Should -BeFalse

        }

        It "Retourne False si le dossier n'existe plus" {

            Remove-Item `
                -LiteralPath $Session.BackupRoot `
                -Recurse `
                -Force

            Test-BackupSession `
                -Session $Session |
                Should -BeFalse

            $Session = New-BackupSession

        }

    }

    Context "New-BackupSession" {

        It "Crée une nouvelle session" {

            $NewSession = New-BackupSession

            $NewSession |
                Should -Not -BeNullOrEmpty

        }

        It "Contient les propriétés attendues" {

            $NewSession = New-BackupSession

            $NewSession.Id |
                Should -Not -BeNullOrEmpty

            $NewSession.Started |
                Should -Not -BeNullOrEmpty

            $NewSession.BackupRoot |
                Should -Not -BeNullOrEmpty

        }

        It "Crée le dossier de sauvegarde" {

            $NewSession = New-BackupSession

            Test-Path `
                -LiteralPath $NewSession.BackupRoot `
                -PathType Container |
                Should -BeTrue

        }

    }

    Context "Get-BackupFiles" {

        BeforeEach {

            $Session = New-BackupSession

        }

        It "Retourne une collection vide au départ" {

            (Get-BackupFiles `
                -Session $Session).Count |
                Should -Be 0

        }

        It "Retourne les fichiers sauvegardés" {

            New-Backup `
                -File (Get-Item $TestFile) `
                -Session $Session

            $Files = Get-BackupFiles `
                -Session $Session

            $Files.Count |
                Should -Be 1

        }

        It "Lève une exception avec une session invalide" {

            {

                Get-BackupFiles `
                    -Session @{}

            } |
            Should -Throw

        }

    }

    Context "New-Backup" {

        BeforeEach {

            $Session = New-BackupSession

        }

        It "Crée une sauvegarde" {

            New-Backup `
                -File (Get-Item $TestFile) `
                -Session $Session

            Test-Backup `
                -File (Get-Item $TestFile) `
                -Session $Session |
                Should -BeTrue

        }

        It "Copie le contenu du fichier" {

            New-Backup `
                -File (Get-Item $TestFile) `
                -Session $Session

            $BackupFile = Get-BackupFile `
                -File (Get-Item $TestFile) `
                -Session $Session

            Get-Content `
                -LiteralPath $BackupFile `
                -Raw |
                Should -Be "Hello Backup`r`n"

        }

        It "Lève une exception si le fichier n'existe pas" {

            $Missing = Join-Path `
                $TestDrive `
                "Missing.txt"

            {

                New-Backup `
                    -File ([System.IO.FileInfo]::new($Missing)) `
                    -Session $Session

            } |
            Should -Throw

        }

        It "Lève une exception avec une session invalide" {

            {

                New-Backup `
                    -File (Get-Item $TestFile) `
                    -Session @{}

            } |
            Should -Throw

        }

    }
	    Context "Restore-Backup" {

        BeforeEach {

            $Session = New-BackupSession

            "Version originale" |
                Set-Content `
                    -LiteralPath $TestFile `
                    -Encoding UTF8

            New-Backup `
                -File (Get-Item $TestFile) `
                -Session $Session
        }

        It "Restaure le contenu sauvegardé" {

            "Version modifiée" |
                Set-Content `
                    -LiteralPath $TestFile `
                    -Encoding UTF8

            Restore-Backup `
                -File (Get-Item $TestFile) `
                -Session $Session `
                -Confirm:$false | Out-Null

            Get-Content `
                -LiteralPath $TestFile `
                -Raw |
                Should -Be "Version originale`r`n"

        }

        It "Retourne le fichier restauré" {

            $Result = Restore-Backup `
                -File (Get-Item $TestFile) `
                -Session $Session `
                -Confirm:$false

            $Result |
                Should -BeOfType ([System.IO.FileInfo])

        }

        It "Lève une exception lorsqu'aucune sauvegarde n'existe" {

            $OtherSession = New-BackupSession

            {

                Restore-Backup `
                    -File (Get-Item $TestFile) `
                    -Session $OtherSession `
                    -Confirm:$false

            } |
            Should -Throw

        }

    }

    Context "Remove-Backup" {

        BeforeEach {

            $Session = New-BackupSession

            New-Backup `
                -File (Get-Item $TestFile) `
                -Session $Session

        }

        It "Supprime la sauvegarde" {

            Remove-Backup `
                -File (Get-Item $TestFile) `
                -Session $Session `
                -Confirm:$false

            Test-Backup `
                -File (Get-Item $TestFile) `
                -Session $Session |
                Should -BeFalse

        }

        It "Ne lève pas d'exception si la sauvegarde est absente" {

            Remove-Backup `
                -File (Get-Item $TestFile) `
                -Session $Session `
                -Confirm:$false

            {

                Remove-Backup `
                    -File (Get-Item $TestFile) `
                    -Session $Session `
                    -Confirm:$false

            } |
            Should -Not -Throw

        }

    }

    Context "Test-Backup" {

        It "Retourne False lorsqu'aucune sauvegarde n'existe" {

            $Session = New-BackupSession

            Test-Backup `
                -File (Get-Item $TestFile) `
                -Session $Session |
                Should -BeFalse

        }

        It "Retourne True lorsqu'une sauvegarde existe" {

            $Session = New-BackupSession

            New-Backup `
                -File (Get-Item $TestFile) `
                -Session $Session

            Test-Backup `
                -File (Get-Item $TestFile) `
                -Session $Session |
                Should -BeTrue

        }

        It "Retourne False pour une session invalide" {

            Test-Backup `
                -File (Get-Item $TestFile) `
                -Session @{} |
                Should -BeFalse

        }

    }

    Context "Get-BackupStatistics" {

        BeforeEach {

            $Session = New-BackupSession

            New-Backup `
                -File (Get-Item $TestFile) `
                -Session $Session

        }

        It "Retourne un objet de statistiques" {

            $Statistics = Get-BackupStatistics `
                -Session $Session

            $Statistics |
                Should -Not -BeNullOrEmpty

        }

        It "Retourne le nombre correct de fichiers" {

            $Statistics = Get-BackupStatistics `
                -Session $Session

            $Statistics.Files |
                Should -Be 1

        }

        It "Retourne une taille supérieure à zéro" {

            $Statistics = Get-BackupStatistics `
                -Session $Session

            $Statistics.Size |
                Should -BeGreaterThan 0

        }

        It "Retourne l'identifiant de session" {

            $Statistics = Get-BackupStatistics `
                -Session $Session

            $Statistics.Session |
                Should -Be $Session.Id

        }

        It "Lève une exception avec une session invalide" {

            {

                Get-BackupStatistics `
                    -Session @{}

            } |
            Should -Throw

        }

    }
	    Context "Get-BackupSessions" {

        BeforeEach {

            $null = New-BackupSession
            Start-Sleep -Milliseconds 25
            $null = New-BackupSession

        }

        It "Retourne une collection" {

            $Sessions = Get-BackupSessions

            $Sessions |
                Should -Not -BeNullOrEmpty

        }

        It "Retourne des dossiers" {

            $Sessions = Get-BackupSessions

            foreach ($SessionFolder in $Sessions)
            {
                $SessionFolder |
                    Should -BeOfType ([System.IO.DirectoryInfo])
            }

        }

        It "Trie les sessions par ordre décroissant" {

            $Sessions = Get-BackupSessions

            if ($Sessions.Count -ge 2)
            {
                $Sessions[0].Name.CompareTo(
                    $Sessions[1].Name
                ) |
                Should -BeGreaterThan 0
            }

        }

    }

    Context "Remove-BackupSession" {

        It "Supprime une session complète" {

            $Session = New-BackupSession

            New-Backup `
                -File (Get-Item $TestFile) `
                -Session $Session

            Remove-BackupSession `
                -Session $Session `
                -Confirm:$false

            Test-Path `
                -LiteralPath $Session.BackupRoot |
                Should -BeFalse

        }

        It "Lève une exception avec une session invalide" {

            {

                Remove-BackupSession `
                    -Session @{} `
                    -Confirm:$false

            } |
            Should -Throw

        }

    }

    Context "Clear-Backups" {

        BeforeEach {

            1..5 | ForEach-Object {

                $null = New-BackupSession

                Start-Sleep -Milliseconds 25

            }

        }

        It "Conserve le nombre demandé de sessions" {

            Clear-Backups `
                -Keep 2 `
                -Confirm:$false

            (Get-BackupSessions).Count |
                Should -BeLessOrEqual 2

        }

        It "Ne supprime rien si le nombre est inférieur à Keep" {

            $Before = (Get-BackupSessions).Count

            Clear-Backups `
                -Keep 100 `
                -Confirm:$false

            (Get-BackupSessions).Count |
                Should -Be $Before

        }

    }

    Context "Exports du module" {

        It "Exporte toutes les fonctions attendues" {

            $Module = Get-Module Backup

            $Expected = @(

                "Get-BackupRoot",
                "Get-RelativeProjectPath",
                "Get-BackupPath",
                "Get-BackupFile",
                "Test-BackupSession",
                "New-BackupSession",
                "Get-BackupFiles",
                "New-Backup",
                "Restore-Backup",
                "Remove-Backup",
                "Test-Backup",
                "Get-BackupStatistics",
                "Get-BackupSessions",
                "Remove-BackupSession",
                "Clear-Backups"

            )

            foreach ($Function in $Expected)
            {
                $Module.ExportedFunctions.Keys |
                    Should -Contain $Function
            }

        }

    }

}