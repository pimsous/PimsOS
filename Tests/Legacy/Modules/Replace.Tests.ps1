<#
.SYNOPSIS
    Tests unitaires du module Replace.

.DESCRIPTION
    Vérifie le fonctionnement du moteur de remplacement
    utilisé par le framework de migration PimsOS.

.NOTES

    Projet   : PimsOS
    Module   : Replace
    Version  : 3.0.0
    Framework: Pester 5

#>

#Requires -Modules Pester

Set-StrictMode -Version Latest

#--------------------------------------------------
# Localisation du projet
#--------------------------------------------------

$ProjectRoot = Split-Path (
    Split-Path $PSScriptRoot -Parent
) -Parent

$ModulePath = Join-Path `
    $ProjectRoot `
    'Tools\Migration\Modules\Replace.psm1'

if (-not (Test-Path -LiteralPath $ModulePath))
{
    throw "Module introuvable : $ModulePath"
}

Import-Module `
    -Name $ModulePath `
    -Force `
    -ErrorAction Stop

BeforeAll {

}

AfterAll {

    Remove-Module `
        Replace `
        -ErrorAction SilentlyContinue

}

Describe 'Replace module' {

    It 'Le module est chargé' {

        Get-Module Replace |
            Should -Not -BeNullOrEmpty

    }

    InModuleScope Replace {

        #==================================================
        # New-ReplacementCollection
        #==================================================

        Describe 'New-ReplacementCollection' {

            It 'Retourne une collection vide' {

				$Collection = New-ReplacementCollection

				($null -eq $Collection) |
					Should -BeFalse

				$Collection.Count |
					Should -Be 0

			}

            

        }

        #==================================================
        # New-Replacement
        #==================================================

        Describe 'New-Replacement' {

            Context 'Création valide' {

                It 'Crée un remplacement standard' {

                    $Replacement = New-Replacement `
                        -Start 10 `
                        -End 20 `
                        -Original 'abcdefghij' `
                        -Replacement '0123456789' `
                        -Description 'Test'

                    $Replacement.Start |
                        Should -Be 10

                    $Replacement.End |
                        Should -Be 20

                    $Replacement.Length |
                        Should -Be 10

                    $Replacement.Original |
                        Should -BeExactly 'abcdefghij'

                    $Replacement.Replacement |
                        Should -BeExactly '0123456789'

                    $Replacement.Description |
                        Should -BeExactly 'Test'

                    $Replacement.Applied |
                        Should -BeFalse

                }

                It 'Accepte un Original vide (insertion)' {

                    $Replacement = New-Replacement `
                        -Start 5 `
                        -End 5 `
                        -Original '' `
                        -Replacement 'ABC'

                    $Replacement.Length |
                        Should -Be 0

                    $Replacement.Original |
                        Should -BeExactly ''

                }

                It 'Accepte un Replacement vide (suppression)' {

                    $Replacement = New-Replacement `
                        -Start 3 `
                        -End 8 `
                        -Original 'ABCDE' `
                        -Replacement ''

                    $Replacement.Length |
                        Should -Be 5

                    $Replacement.Replacement |
                        Should -BeExactly ''

                }

            }

            Context 'Validation' {

                It 'Refuse End inférieur à Start' {

                    {
                        New-Replacement `
                            -Start 20 `
                            -End 10 `
                            -Original 'ABC' `
                            -Replacement 'DEF'

                    } |
                        Should -Throw

                }

                It 'Refuse un Start négatif' {

                    {
                        New-Replacement `
                            -Start -1 `
                            -End 5 `
                            -Original 'ABC' `
                            -Replacement 'DEF'

                    } |
                        Should -Throw

                }

                It 'Refuse un End négatif' {

                    {
                        New-Replacement `
                            -Start 0 `
                            -End -1 `
                            -Original 'ABC' `
                            -Replacement 'DEF'

                    } |
                        Should -Throw

                }

            }

        }
		#==================================================
        # Add-Replacement
        #==================================================

        Describe 'Add-Replacement' {

            Context 'Ajout valide' {

                It 'Ajoute un remplacement dans la collection' {

                    $Collection = New-ReplacementCollection

					# Vérifications de diagnostic
					($null -eq $Collection) |
						Should -BeFalse

					$Collection.GetType().Name |
						Should -Be 'List`1'

					$Collection.Count |
						Should -Be 0

					$Replacement = New-Replacement `
						-Start 0 `
						-End 5 `
						-Original 'ABCDE' `
						-Replacement '12345'

					Add-Replacement `
						-Collection $Collection `
						-Replacement $Replacement

					$Collection.Count |
						Should -Be 1

					$Collection[0] |
						Should -Be $Replacement

                }

                It 'Ajoute plusieurs remplacements' {

                    $Collection = New-ReplacementCollection

                    foreach ($i in 0..9)
                    {
                        Add-Replacement `
                            -Collection $Collection `
                            -Replacement (
                                New-Replacement `
                                    -Start ($i * 10) `
                                    -End (($i * 10) + 5) `
                                    -Original 'AAAAA' `
                                    -Replacement 'BBBBB'
                            )
                    }

                    $Collection.Count |
                        Should -Be 10

                }

            }

            Context 'Validation' {

                It 'Refuse un remplacement invalide' {

                    $Collection = New-ReplacementCollection

                    $Replacement = [PSCustomObject]@{

                        Start = 0

                    }

                    {
                        Add-Replacement `
                            -Collection $Collection `
                            -Replacement $Replacement

                    } |
                        Should -Throw

                }

            }

        }

        #==================================================
        # Get-ReplacementCount
        #==================================================

        Describe 'Get-ReplacementCount' {

            It 'Retourne zéro pour une collection vide' {

                $Collection = New-ReplacementCollection

                Get-ReplacementCount `
                    -Collection $Collection |
                    Should -Be 0

            }

            It 'Retourne le nombre réel de remplacements' {

                $Collection = New-ReplacementCollection

                foreach ($i in 1..5)
                {
                    Add-Replacement `
                        -Collection $Collection `
                        -Replacement (
                            New-Replacement `
                                -Start ($i * 20) `
                                -End (($i * 20) + 5) `
                                -Original 'AAAAA' `
                                -Replacement 'BBBBB'
                        )
                }

                Get-ReplacementCount `
                    -Collection $Collection |
                    Should -Be 5

            }

        }

        #==================================================
        # Test-Replacement
        #==================================================

        Describe 'Test-Replacement' {

            Context 'Objet valide' {

                It 'Retourne True pour un remplacement valide' {

                    $Replacement = New-Replacement `
                        -Start 0 `
                        -End 5 `
                        -Original 'AAAAA' `
                        -Replacement 'BBBBB'

                    Test-Replacement `
                        -Replacement $Replacement |
                        Should -BeTrue

                }

            }

            Context 'Objet invalide' {

                It 'Retourne False si une propriété est absente' {

                    $Replacement = [PSCustomObject]@{

                        Start = 0
                        End = 5
                    }

                    Test-Replacement `
                        -Replacement $Replacement |
                        Should -BeFalse

                }

                It 'Retourne False si Length est incorrect' {

                    $Replacement = [PSCustomObject]@{

                        Start       = 0
                        End         = 10
                        Length      = 99
                        Original    = 'AAAAAAAAAA'
                        Replacement = 'BBBBBBBBBB'
                        Description = ''
                        Applied     = $false

                    }

                    Test-Replacement `
                        -Replacement $Replacement |
                        Should -BeFalse

                }

                It 'Retourne False si End est inférieur à Start' {

                    $Replacement = [PSCustomObject]@{

                        Start       = 10
                        End         = 5
                        Length      = -5
                        Original    = 'AAAAA'
                        Replacement = 'BBBBB'
                        Description = ''
                        Applied     = $false

                    }

                    Test-Replacement `
                        -Replacement $Replacement |
                        Should -BeFalse

                }

                It 'Retourne False si Start est négatif' {

                    $Replacement = [PSCustomObject]@{

                        Start       = -1
                        End         = 5
                        Length      = 6
                        Original    = 'AAAAAA'
                        Replacement = 'BBBBBB'
                        Description = ''
                        Applied     = $false

                    }

                    Test-Replacement `
                        -Replacement $Replacement |
                        Should -BeFalse

                }

                It 'Retourne False si Replacement vaut `$null' {

                    $Replacement = [PSCustomObject]@{

                        Start       = 0
                        End         = 5
                        Length      = 5
                        Original    = 'AAAAA'
                        Replacement = $null
                        Description = ''
                        Applied     = $false

                    }

                    Test-Replacement `
                        -Replacement $Replacement |
                        Should -BeFalse

                }

            }

        }
		#==================================================
        # Test-Replacements
        #==================================================

        Describe 'Test-Replacements' {

            Context 'Collection valide' {

                It 'Retourne True pour une collection vide' {

                    $Collection = New-ReplacementCollection

                    Test-Replacements `
                        -Collection $Collection |
                        Should -BeTrue

                }

                It 'Retourne True avec un remplacement' {

                    $Collection = New-ReplacementCollection

                    Add-Replacement `
                        -Collection $Collection `
                        -Replacement (
                            New-Replacement `
                                -Start 0 `
                                -End 5 `
                                -Original 'AAAAA' `
                                -Replacement 'BBBBB'
                        )

                    Test-Replacements `
                        -Collection $Collection |
                        Should -BeTrue

                }

                It 'Retourne True avec plusieurs remplacements' {

                    $Collection = New-ReplacementCollection

                    foreach ($i in 0..4)
                    {
                        Add-Replacement `
                            -Collection $Collection `
                            -Replacement (
                                New-Replacement `
                                    -Start ($i * 20) `
                                    -End (($i * 20) + 5) `
                                    -Original 'AAAAA' `
                                    -Replacement 'BBBBB'
                            )
                    }

                    Test-Replacements `
                        -Collection $Collection |
                        Should -BeTrue

                }

            }

            Context 'Chevauchements' {

                It 'Détecte deux remplacements qui se chevauchent' {

                    $Collection = New-ReplacementCollection

                    Add-Replacement `
                        -Collection $Collection `
                        -Replacement (
                            New-Replacement `
                                -Start 0 `
                                -End 10 `
                                -Original 'AAAAAAAAAA' `
                                -Replacement 'BBBBBBBBBB'
                        )

                    Add-Replacement `
                        -Collection $Collection `
                        -Replacement (
                            New-Replacement `
                                -Start 5 `
                                -End 15 `
                                -Original 'CCCCCCCCCC' `
                                -Replacement 'DDDDDDDDDD'
                        )

                    Test-Replacements `
                        -Collection $Collection |
                        Should -BeFalse

                }

                It 'Autorise deux remplacements adjacents' {

                    $Collection = New-ReplacementCollection

                    Add-Replacement `
                        -Collection $Collection `
                        -Replacement (
                            New-Replacement `
                                -Start 0 `
                                -End 5 `
                                -Original 'AAAAA' `
                                -Replacement 'BBBBB'
                        )

                    Add-Replacement `
                        -Collection $Collection `
                        -Replacement (
                            New-Replacement `
                                -Start 5 `
                                -End 10 `
                                -Original 'CCCCC' `
                                -Replacement 'DDDDD'
                        )

                    Test-Replacements `
                        -Collection $Collection |
                        Should -BeTrue

                }

            }

            Context 'Remplacement invalide' {

                It 'Retourne False si un élément est invalide' {

                    $Collection = New-ReplacementCollection

                    $Collection.Add(
                        [PSCustomObject]@{
                            Start = 0
                        }
                    )

                    Test-Replacements `
                        -Collection $Collection |
                        Should -BeFalse

                }

            }

        }

        #==================================================
        # Sort-Replacements
        #==================================================

        Describe 'Sort-Replacements' {

            It 'Retourne une collection vide si la collection est vide' {

                $Collection = New-ReplacementCollection

                $Sorted = Sort-Replacements `
                    -Collection $Collection

                @($Sorted).Count |
                    Should -Be 0

            }

            It 'Trie par Start décroissant' {

                $Collection = New-ReplacementCollection

                foreach ($Start in 10, 50, 20, 40, 30)
                {
                    Add-Replacement `
                        -Collection $Collection `
                        -Replacement (
                            New-Replacement `
                                -Start $Start `
                                -End ($Start + 5) `
                                -Original 'AAAAA' `
                                -Replacement 'BBBBB'
                        )
                }

                $Sorted = @(Sort-Replacements `
                    -Collection $Collection)

                $Sorted.Count |
                    Should -Be 5

                $Sorted[0].Start |
                    Should -Be 50

                $Sorted[1].Start |
                    Should -Be 40

                $Sorted[2].Start |
                    Should -Be 30

                $Sorted[3].Start |
                    Should -Be 20

                $Sorted[4].Start |
                    Should -Be 10

            }

            It 'Trie également sur End lorsque Start est identique' {

                $Collection = New-ReplacementCollection

                Add-Replacement `
                    -Collection $Collection `
                    -Replacement (
                        New-Replacement `
                            -Start 10 `
                            -End 20 `
                            -Original 'AAAAAAAAAA' `
                            -Replacement 'BBBBBBBBBB'
                    )

                Add-Replacement `
                    -Collection $Collection `
                    -Replacement (
                        New-Replacement `
                            -Start 10 `
                            -End 15 `
                            -Original 'AAAAA' `
                            -Replacement 'BBBBB'
                    )

                $Sorted = @(Sort-Replacements `
                    -Collection $Collection)

                $Sorted.Count |
                    Should -Be 2

                $Sorted[0].End |
                    Should -Be 20

                $Sorted[1].End |
                    Should -Be 15

            }

        }
		#==================================================
        # Convert-Replacements
        #==================================================

        Describe 'Convert-Replacements' {

            Context 'Collection vide' {

                It 'Retourne le contenu inchangé' {

                    $Collection = New-ReplacementCollection

                    $Result = Convert-Replacements `
                        -Content 'Hello World' `
                        -Collection $Collection

                    $Result |
                        Should -BeExactly 'Hello World'

                }

            }

            Context 'Un remplacement' {

                It 'Remplace correctement une chaîne' {

                    $Collection = New-ReplacementCollection

                    Add-Replacement `
                        -Collection $Collection `
                        -Replacement (
                            New-Replacement `
                                -Start 6 `
                                -End 11 `
                                -Original 'World' `
                                -Replacement 'Pims'
                        )

                    $Result = Convert-Replacements `
                        -Content 'Hello World' `
                        -Collection $Collection

                    $Result |
                        Should -BeExactly 'Hello Pims'

                }

            }

            Context 'Deux remplacements' {

                It 'Applique plusieurs remplacements' {

                    $Collection = New-ReplacementCollection

                    Add-Replacement `
                        -Collection $Collection `
                        -Replacement (
                            New-Replacement `
                                -Start 0 `
                                -End 5 `
                                -Original 'Hello' `
                                -Replacement 'Salut'
                        )

                    Add-Replacement `
                        -Collection $Collection `
                        -Replacement (
                            New-Replacement `
                                -Start 6 `
                                -End 11 `
                                -Original 'World' `
                                -Replacement 'Pims'
                        )

                    $Result = Convert-Replacements `
                        -Content 'Hello World' `
                        -Collection $Collection

                    $Result |
                        Should -BeExactly 'Salut Pims'

                }

            }

            Context 'Insertion' {

                It 'Insère du texte' {

                    $Collection = New-ReplacementCollection

                    Add-Replacement `
                        -Collection $Collection `
                        -Replacement (
                            New-Replacement `
                                -Start 5 `
                                -End 5 `
                                -Original '' `
                                -Replacement ' World'
                        )

                    $Result = Convert-Replacements `
                        -Content 'Hello' `
                        -Collection $Collection

                    $Result |
                        Should -BeExactly 'Hello World'

                }

            }

            Context 'Suppression' {

                It 'Supprime une portion du texte' {

                    $Collection = New-ReplacementCollection

                    Add-Replacement `
                        -Collection $Collection `
                        -Replacement (
                            New-Replacement `
                                -Start 5 `
                                -End 11 `
                                -Original ' World' `
                                -Replacement ''
                        )

                    $Result = Convert-Replacements `
                        -Content 'Hello World' `
                        -Collection $Collection

                    $Result |
                        Should -BeExactly 'Hello'

                }

            }

            Context 'Remplacement plus long' {

                It 'Accepte un texte de remplacement plus long' {

                    $Collection = New-ReplacementCollection

                    Add-Replacement `
                        -Collection $Collection `
                        -Replacement (
                            New-Replacement `
                                -Start 0 `
                                -End 2 `
                                -Original 'Hi' `
                                -Replacement 'Bonjour'
                        )

                    $Result = Convert-Replacements `
                        -Content 'Hi' `
                        -Collection $Collection

                    $Result |
                        Should -BeExactly 'Bonjour'

                }

            }

            Context 'Remplacement plus court' {

                It 'Accepte un texte de remplacement plus court' {

                    $Collection = New-ReplacementCollection

                    Add-Replacement `
                        -Collection $Collection `
                        -Replacement (
                            New-Replacement `
                                -Start 0 `
                                -End 7 `
                                -Original 'Bonjour' `
                                -Replacement 'Hi'
                        )

                    $Result = Convert-Replacements `
                        -Content 'Bonjour' `
                        -Collection $Collection

                    $Result |
                        Should -BeExactly 'Hi'

                }

            }

            Context 'Ordre des remplacements' {

                It 'Applique les remplacements du dernier vers le premier' {

                    $Collection = New-ReplacementCollection

                    Add-Replacement `
                        -Collection $Collection `
                        -Replacement (
                            New-Replacement `
                                -Start 8 `
                                -End 10 `
                                -Original '89' `
                                -Replacement 'AB'
                        )

                    Add-Replacement `
                        -Collection $Collection `
                        -Replacement (
                            New-Replacement `
                                -Start 2 `
                                -End 4 `
                                -Original '23' `
                                -Replacement 'CD'
                        )

                    $Result = Convert-Replacements `
                        -Content '0123456789' `
                        -Collection $Collection

                    $Result |
                        Should -BeExactly '01CD4567AB'

                }

            }

            Context 'Remplacements adjacents' {

                It 'Traite correctement deux remplacements côte à côte' {

                    $Collection = New-ReplacementCollection

                    Add-Replacement `
                        -Collection $Collection `
                        -Replacement (
                            New-Replacement `
                                -Start 0 `
                                -End 5 `
                                -Original 'Hello' `
                                -Replacement 'Salut'
                        )

                    Add-Replacement `
                        -Collection $Collection `
                        -Replacement (
                            New-Replacement `
                                -Start 5 `
                                -End 6 `
                                -Original ' ' `
                                -Replacement '-'
                        )

                    Add-Replacement `
                        -Collection $Collection `
                        -Replacement (
                            New-Replacement `
                                -Start 6 `
                                -End 11 `
                                -Original 'World' `
                                -Replacement 'Pims'
                        )

                    $Result = Convert-Replacements `
                        -Content 'Hello World' `
                        -Collection $Collection

                    $Result |
                        Should -BeExactly 'Salut-Pims'

                }

            }
			Context 'Collection non triée' {

			It 'Trie automatiquement les remplacements avant application' {

				$Collection = New-ReplacementCollection

				Add-Replacement `
					-Collection $Collection `
					-Replacement (
						New-Replacement `
							-Start 6 `
							-End 11 `
							-Original 'World' `
							-Replacement 'Pims'
					)

				Add-Replacement `
					-Collection $Collection `
					-Replacement (
						New-Replacement `
							-Start 0 `
							-End 5 `
							-Original 'Hello' `
							-Replacement 'Salut'
					)

				$Result = Convert-Replacements `
					-Content 'Hello World' `
					-Collection $Collection

				$Result |
					Should -BeExactly 'Salut Pims'

			}

		}
        }
		#==================================================
        # Convert-Replacements - Cas d'erreur
        #==================================================

        Describe 'Convert-Replacements - Validation' {

            Context 'Collection invalide' {

                It 'Lève une exception lorsqu''un remplacement est invalide' {

                    $Collection = New-ReplacementCollection

                    $Collection.Add(
                        [PSCustomObject]@{
                            Start = 0
                        }
                    )

                    {
                        Convert-Replacements `
                            -Content 'Hello' `
                            -Collection $Collection

                    } |
                        Should -Throw 'La collection de remplacements est invalide.'

                }

                It 'Lève une exception lorsqu''il existe un chevauchement' {

                    $Collection = New-ReplacementCollection

                    Add-Replacement `
                        -Collection $Collection `
                        -Replacement (
                            New-Replacement `
                                -Start 0 `
                                -End 5 `
                                -Original 'Hello' `
                                -Replacement 'Salut'
                        )

                    Add-Replacement `
                        -Collection $Collection `
                        -Replacement (
                            New-Replacement `
                                -Start 3 `
                                -End 8 `
                                -Original 'lo Wo' `
                                -Replacement 'XXXXX'
                        )

                    {
                        Convert-Replacements `
                            -Content 'Hello World' `
                            -Collection $Collection

                    } |
                        Should -Throw 'La collection de remplacements est invalide.'

                }

            }

            Context 'Position invalide' {

                It 'Lève une exception si End dépasse la taille du contenu' {

                    $Collection = New-ReplacementCollection

                    $Replacement = New-Replacement `
						-Start 8 `
						-End 20 `
						-Original '89ABCDEFGHI' `
						-Replacement 'TEST'

					Add-Replacement `
						-Collection $Collection `
						-Replacement $Replacement

                    {
                        Convert-Replacements `
                            -Content '0123456789' `
                            -Collection $Collection

                    } |
                        Should -Throw 'Le remplacement dépasse la taille du contenu.'

                }

            }

            Context 'Texte inattendu' {

                It 'Lève une exception si Original ne correspond pas' {

                    $Collection = New-ReplacementCollection

                    Add-Replacement `
                        -Collection $Collection `
                        -Replacement (
                            New-Replacement `
                                -Start 6 `
                                -End 11 `
                                -Original 'Earth' `
                                -Replacement 'Pims'
                        )

                    {
                        Convert-Replacements `
                            -Content 'Hello World' `
                            -Collection $Collection

                    } |
                        Should -Throw

                }

                It 'Le message contient la position' {

                    $Collection = New-ReplacementCollection

                    Add-Replacement `
                        -Collection $Collection `
                        -Replacement (
                            New-Replacement `
                                -Start 6 `
                                -End 11 `
                                -Original 'Earth' `
                                -Replacement 'Pims' `
                                -Description 'Test de validation'
                        )

                    try
                    {
                        Convert-Replacements `
                            -Content 'Hello World' `
                            -Collection $Collection

                        throw 'Aucune exception.'

                    }
                    catch
                    {
                        $_.Exception.Message |
                            Should -Match 'Position'

                        $_.Exception.Message |
                            Should -Match '6'

                        $_.Exception.Message |
                            Should -Match 'Earth'

                        $_.Exception.Message |
                            Should -Match 'World'
                    }

                }

            }

            Context 'Insertion en fin de chaîne' {

                It 'Autorise une insertion exactement à la fin' {

                    $Collection = New-ReplacementCollection

                    Add-Replacement `
                        -Collection $Collection `
                        -Replacement (
                            New-Replacement `
                                -Start 5 `
                                -End 5 `
                                -Original '' `
                                -Replacement ' World'
                        )

                    $Result = Convert-Replacements `
                        -Content 'Hello' `
                        -Collection $Collection

                    $Result |
                        Should -BeExactly 'Hello World'

                }

            }

            Context 'Suppression complète' {

                It 'Supprime tout le contenu' {

                    $Collection = New-ReplacementCollection

                    Add-Replacement `
                        -Collection $Collection `
                        -Replacement (
                            New-Replacement `
                                -Start 0 `
                                -End 5 `
                                -Original 'Hello' `
                                -Replacement ''
                        )

                    $Result = Convert-Replacements `
                        -Content 'Hello' `
                        -Collection $Collection

                    $Result |
                        Should -BeExactly ''

                }

            }

        }
		#==================================================
        # Invoke-Replacements
        #==================================================

        Describe 'Invoke-Replacements' {

            BeforeEach {

                $TestFile = Join-Path `
                    $TestDrive `
                    'Replace.txt'

            }

            Context 'Fichier inexistant' {

                It 'Lève une exception' {

                    $Collection = New-ReplacementCollection

                    $File = [System.IO.FileInfo]::new($TestFile)

                    {
                        Invoke-Replacements `
                            -File $File `
                            -Collection $Collection

                    } |
                        Should -Throw

                }

            }

            Context 'Application d''un remplacement' {

                It 'Modifie le contenu du fichier' {

                    Set-Content `
                        -LiteralPath $TestFile `
                        -Value 'Hello World' `
                        -Encoding UTF8

                    $File = Get-Item `
                        -LiteralPath $TestFile

                    $Collection = New-ReplacementCollection

                    Add-Replacement `
                        -Collection $Collection `
                        -Replacement (
                            New-Replacement `
                                -Start 6 `
                                -End 11 `
                                -Original 'World' `
                                -Replacement 'Pims'
                        )

                    Invoke-Replacements `
                        -File $File `
                        -Collection $Collection

                    $Content = Get-Content `
                        -LiteralPath $TestFile `
                        -Raw

                    $Content.TrimEnd("`r", "`n") |
						Should -BeExactly 'Hello Pims'

                }

            }

            Context 'Applied' {

                It 'Marque tous les remplacements comme appliqués' {

                    Set-Content `
                        -LiteralPath $TestFile `
                        -Value 'Hello World' `
                        -Encoding UTF8

                    $File = Get-Item `
                        -LiteralPath $TestFile

                    $Collection = New-ReplacementCollection

                    $Replacement = New-Replacement `
                        -Start 6 `
                        -End 11 `
                        -Original 'World' `
                        -Replacement 'Pims'

                    Add-Replacement `
                        -Collection $Collection `
                        -Replacement $Replacement

                    Invoke-Replacements `
                        -File $File `
                        -Collection $Collection

                    $Replacement.Applied |
                        Should -BeTrue

                }

            }

            Context 'Plusieurs remplacements' {

                It 'Applique correctement tous les remplacements' {

                    Set-Content `
                        -LiteralPath $TestFile `
                        -Value 'Hello World' `
                        -Encoding UTF8

                    $File = Get-Item `
                        -LiteralPath $TestFile

                    $Collection = New-ReplacementCollection

                    Add-Replacement `
                        -Collection $Collection `
                        -Replacement (
                            New-Replacement `
                                -Start 0 `
                                -End 5 `
                                -Original 'Hello' `
                                -Replacement 'Salut'
                        )

                    Add-Replacement `
                        -Collection $Collection `
                        -Replacement (
                            New-Replacement `
                                -Start 6 `
                                -End 11 `
                                -Original 'World' `
                                -Replacement 'Pims'
                        )

                    Invoke-Replacements `
                        -File $File `
                        -Collection $Collection

                    $Content = Get-Content `
						-LiteralPath $TestFile `
						-Raw

					$Content.TrimEnd("`r", "`n") |
						Should -BeExactly 'Salut Pims'

                }
				It 'Marque tous les remplacements de la collection comme appliqués' {

					Set-Content `
						-LiteralPath $TestFile `
						-Value 'Hello World' `
						-Encoding UTF8

					$File = Get-Item `
						-LiteralPath $TestFile

					$Collection = New-ReplacementCollection

					$Replacement1 = New-Replacement `
						-Start 0 `
						-End 5 `
						-Original 'Hello' `
						-Replacement 'Salut'

					$Replacement2 = New-Replacement `
						-Start 6 `
						-End 11 `
						-Original 'World' `
						-Replacement 'Pims'

					Add-Replacement `
						-Collection $Collection `
						-Replacement $Replacement1

					Add-Replacement `
						-Collection $Collection `
						-Replacement $Replacement2

					Invoke-Replacements `
						-File $File `
						-Collection $Collection

					foreach ($Replacement in $Collection)
					{
						$Replacement.Applied |
							Should -BeTrue
					}

				}
            }

        }

    }

}