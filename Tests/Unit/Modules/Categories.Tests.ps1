# ==========================================
# Tests : Categories
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"
    . "$ProjectRoot\Modules\Core\Core.ps1"
    . "$ProjectRoot\Modules\Configuration\Categories.ps1"

}

Describe "Categories" {

    BeforeEach {

        Reset-Logger

        # Force le chargement des définitions réelles
        # afin d'isoler les tests du cache précédent.
        $null = Get-CategoryDefinitions -Reload

    }


    # ==================================================
    # Get-CategoryDefinitions
    # ==================================================

    Context "Get-CategoryDefinitions" {

        It "Retourne les catégories" {

            $Categories = Get-CategoryDefinitions -Reload

            $Categories |
                Should -Not -BeNullOrEmpty

        }


        It "Retourne une collection contenant au moins une catégorie" {

            $Categories = @(
                Get-CategoryDefinitions -Reload
            )

            $Categories.Count |
                Should -BeGreaterThan 0

        }


        It "Chaque catégorie possède un identifiant" {

            $Categories = @(
                Get-CategoryDefinitions -Reload
            )

            foreach ($Category in $Categories) {

                $Category.Id |
                    Should -Not -BeNullOrEmpty

            }

        }


        It "Utilise le cache lorsqu'un rechargement n'est pas demandé" {

            $First = @(
                Get-CategoryDefinitions -Reload
            )

            $Second = @(
                Get-CategoryDefinitions
            )

            $Second.Count |
                Should -Be $First.Count

            for (
                $Index = 0;
                $Index -lt $First.Count;
                $Index++
            ) {

                $Second[$Index].Id |
                    Should -Be $First[$Index].Id

            }

        }


        It "Recharge les définitions avec Reload" {

            $First = @(
                Get-CategoryDefinitions -Reload
            )

            $Second = @(
                Get-CategoryDefinitions -Reload
            )

            $First |
                Should -Not -BeNullOrEmpty

            $Second |
                Should -Not -BeNullOrEmpty

            $Second.Count |
                Should -Be $First.Count

        }

    }


    # ==================================================
    # Get-CategoryDefinition
    # ==================================================

    Context "Get-CategoryDefinition" {

        It "Retourne une catégorie existante" {

            $Categories = @(
                Get-CategoryDefinitions -Reload
            )

            $Id = $Categories[0].Id

            $Category = Get-CategoryDefinition `
                -Id $Id

            $Category |
                Should -Not -BeNullOrEmpty

            $Category.Id |
                Should -Be $Id

        }


        It "Lève une exception pour une catégorie inconnue" {

            {

                Get-CategoryDefinition `
                    -Id "Category_That_Does_Not_Exist"

            } |
                Should -Throw

        }

    }


    # ==================================================
    # Get-CategoryGroups
    # ==================================================

    Context "Get-CategoryGroups" {

        It "Retourne les groupes d'une catégorie" {

            $Categories = @(
                Get-CategoryDefinitions -Reload
            )

            $CategoryWithGroups = $Categories |
                Where-Object {
                    $_.PSObject.Properties["Groups"] -and
                    $_.Groups
                } |
                Select-Object -First 1

            if ($null -eq $CategoryWithGroups) {

                Set-ItResult -Skipped `
                    -Because "Aucune catégorie avec groupes n'est présente dans Categories.json."

                return

            }

            $Groups = @(
                Get-CategoryGroups `
                    -Id $CategoryWithGroups.Id
            )

            $Groups |
                Should -Not -BeNull

        }


        It "Retourne une collection pour une catégorie sans groupes" {

            $Categories = @(
                Get-CategoryDefinitions -Reload
            )

            $CategoryWithoutGroups = $Categories |
                Where-Object {
                    -not $_.PSObject.Properties["Groups"] -or
                    -not $_.Groups
                } |
                Select-Object -First 1

            if ($null -eq $CategoryWithoutGroups) {

                Set-ItResult -Skipped `
                    -Because "Toutes les catégories actuelles possèdent des groupes."

                return

            }

            $Groups = @(
                Get-CategoryGroups `
                    -Id $CategoryWithoutGroups.Id
            )

            $Groups.Count |
                Should -Be 0

        }


        It "Lève une exception pour une catégorie inconnue" {

            {

                Get-CategoryGroups `
                    -Id "Category_That_Does_Not_Exist"

            } |
                Should -Throw

        }

    }


    # ==================================================
    # Get-CategoryLevels
    # ==================================================

    Context "Get-CategoryLevels" {

        It "Retourne les trois niveaux définis" {

            $Levels = @(
                Get-CategoryLevels
            )

            $Levels.Count |
                Should -Be 3

        }


        It "Contient Official" {

            @(
                Get-CategoryLevels
            ) |
                Should -Contain "Official"

        }


        It "Contient Advanced" {

            @(
                Get-CategoryLevels
            ) |
                Should -Contain "Advanced"

        }


        It "Contient Experimental" {

            @(
                Get-CategoryLevels
            ) |
                Should -Contain "Experimental"

        }

    }


    # ==================================================
    # Test-CategoryExists
    # ==================================================

    Context "Test-CategoryExists" {

        It "Retourne True pour une catégorie existante" {

            $Categories = @(
                Get-CategoryDefinitions -Reload
            )

            $Id = $Categories[0].Id

            Test-CategoryExists `
                -Id $Id |
                Should -BeTrue

        }


        It "Retourne False pour une catégorie inconnue" {

            Test-CategoryExists `
                -Id "Category_That_Does_Not_Exist" |
                Should -BeFalse

        }

    }

}