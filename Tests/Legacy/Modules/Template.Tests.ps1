<#
.SYNOPSIS
    Gabarit des tests unitaires Pester pour PimsOS.

.DESCRIPTION
    Ce fichier sert de modèle pour tous les tests unitaires
    des modules du projet PimsOS.

.NOTES

    Projet   : PimsOS
    Framework: Pester 5
    Version  : 1.0.0

#>

#Requires -Modules Pester

BeforeAll {

    Set-StrictMode -Version Latest

    #--------------------------------------------------
    # Détermination des chemins
    #--------------------------------------------------

    $ProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

    $ModuleName = '<Module>'

    $ModulePath = Join-Path `
        $ProjectRoot `
        "Modules\$ModuleName.psm1"

    #--------------------------------------------------
    # Vérification du module
    #--------------------------------------------------

    if (-not (Test-Path -LiteralPath $ModulePath))
    {
        throw "Module introuvable : $ModulePath"
    }

    #--------------------------------------------------
    # Chargement du module
    #--------------------------------------------------

    Import-Module `
        -Name $ModulePath `
        -Force `
        -ErrorAction Stop

    #--------------------------------------------------
    # Données communes aux tests
    #--------------------------------------------------

    $TestData = @{

        # Ajouter ici les objets communs
        # Exemple :
        #
        # Report      = New-Report
        # Replacement = New-Replacement ...
        #

    }

}

AfterAll {

    Remove-Module `
        -Name $ModuleName `
        -ErrorAction SilentlyContinue

}

Describe $ModuleName {

    It 'Le module est chargé' {

        Get-Module -Name $ModuleName |
            Should -Not -BeNullOrEmpty

    }

    InModuleScope $ModuleName {

        Describe '<Nom de la fonction>' {

            Context 'Avec des paramètres valides' {

                It 'Exécute correctement le scénario attendu' {

                    #--------------------------------------------------
                    # Arrange
                    # Prépare les données de test
                    #--------------------------------------------------

                    #--------------------------------------------------
                    # Act
                    # Exécute la fonction
                    #--------------------------------------------------

                    #--------------------------------------------------
                    # Assert
                    # Vérifie le résultat
                    #--------------------------------------------------

                }

            }

            Context 'Avec des paramètres invalides' {

                It 'Lève une exception' {

                    {
                        # Appel de la fonction

                    } | Should -Throw

                }

            }

            Context 'Valeur retournée' {

                It 'Retourne le type attendu' {

                    # Arrange

                    # Act

                    # Assert

                }

            }

            Context 'Cas limites' {

                It 'Gère correctement les cas particuliers' {

                    # Arrange

                    # Act

                    # Assert

                }

            }

        }

    }

}