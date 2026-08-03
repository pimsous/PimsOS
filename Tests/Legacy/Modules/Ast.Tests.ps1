<#
.SYNOPSIS
    Tests unitaires du module Ast.

.DESCRIPTION
    Vérifie les fonctions d'analyse AST du framework de migration.

.NOTES

    Projet : PimsOS
    Module : Ast.Tests
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
        (Join-Path $ModuleRoot "Scanner.psm1") `
        -Force

    Import-Module `
        (Join-Path $ModuleRoot "Ast.psm1") `
        -Force

}

Describe "Module Ast" {

    BeforeEach {

        $TestFile = Join-Path $TestDrive "Test.ps1"

        @'
param(
    [string]$Name
)

class DemoClass {

    [string] GetName() {

        return "Demo"

    }

}

function Test-Function {

    param(
        [string]$Value
    )

    $Variable = "Hello"

    Write-Host $Variable

    Get-Date

}
'@ | Set-Content `
        -LiteralPath $TestFile `
        -Encoding UTF8

        $Script = Get-ScriptAst `
            -File (Get-Item $TestFile)

    }


    Context "Chargement du module" {

        It "Le module est chargé" {

            Get-Module Ast |
                Should -Not -BeNullOrEmpty

        }

    }

    Context "Get-ScriptAst" {


    It "Retourne une hashtable" {

        $Script |
            Should -BeOfType ([hashtable])

    }

        It "Contient les clés attendues" {

            $Script.Keys |
                Should -Contain "File"

            $Script.Keys |
                Should -Contain "Ast"

            $Script.Keys |
                Should -Contain "Tokens"

            $Script.Keys |
                Should -Contain "Errors"

        }

        It "Retourne un AST valide" {

            $Script.Ast |
                Should -Not -BeNullOrEmpty

        }

        It "Lève une exception si le fichier est absent" {

            {

                Get-ScriptAst `
                    -File ([System.IO.FileInfo]::new("C:\Impossible\Test.ps1"))

            } |
            Should -Throw

        }

    }

    Context "Erreurs de parsing" {

        It "Ne contient aucune erreur" {

			Get-ParseErrors `
				-Script $Script |
				Should -BeNullOrEmpty

		}

        It "Test-ParseErrors retourne False" {

            Test-ParseErrors `
                -Script $Script |
                Should -BeFalse

        }

    }

    Context "Tokens" {

        It "Retourne une collection" {

            $Tokens = Get-Tokens `
                -Script $Script

            $Tokens |
                Should -Not -BeNullOrEmpty

        }

        It "Retourne plusieurs tokens" {

            (Get-Tokens `
                -Script $Script).Count |
                Should -BeGreaterThan 10

        }

    }

    Context "Commandes" {

        It "Retourne plusieurs commandes" {

            $Commands = Get-Commands `
                -Script $Script

            $Commands.Count |
                Should -BeGreaterThan 1

        }

        It "Trouve Write-Host" {

            $Commands = Find-Commands `
                -Script $Script `
                -Name "Write-Host"

            $Commands.Count |
                Should -Be 1

        }

        It "Trouve Get-Date" {

            $Commands = Find-Commands `
                -Script $Script `
                -Name "Get-Date"

            $Commands.Count |
                Should -Be 1

        }

        It "Ne trouve pas une commande inexistante" {

			$Commands = Find-Commands `
				-Script $Script `
				-Name "CommandeInexistante"

			$Commands |
				Should -BeNullOrEmpty

		}

    }
	    Context "Informations sur les commandes" {

        It "Retourne le nom d'une commande" {

            $Command = (
                Find-Commands `
                    -Script $Script `
                    -Name "Write-Host"
            )[0]

            Get-CommandName `
                -Command $Command |
                Should -Be "Write-Host"

        }

        It "Retourne les éléments d'une commande" {

            $Command = (
                Find-Commands `
                    -Script $Script `
                    -Name "Write-Host"
            )[0]

            $Elements = Get-CommandElements `
                -Command $Command

            $Elements.Count |
                Should -BeGreaterThan 1

        }

        It "Retourne les arguments d'une commande" {

            $Command = (
                Find-Commands `
                    -Script $Script `
                    -Name "Write-Host"
            )[0]

            $Arguments = Get-CommandArguments `
                -Command $Command

            $Arguments.Count |
                Should -Be 1

        }

        It "Retourne le texte exact d'un argument" {

            $Command = (
                Find-Commands `
                    -Script $Script `
                    -Name "Write-Host"
            )[0]

            $Argument = (
                Get-CommandArguments `
                    -Command $Command
            )[0]

            Get-ArgumentText `
                -Argument $Argument |
                Should -Be '$Variable'

        }

        It "Retourne tous les textes des arguments" {

            $Command = (
                Find-Commands `
                    -Script $Script `
                    -Name "Write-Host"
            )[0]

            $Arguments = Get-ArgumentTexts `
                -Command $Command

            $Arguments.Count |
                Should -Be 1

            $Arguments[0] |
                Should -Be '$Variable'

        }

    }

    Context "Fonctions" {

        It "Retourne toutes les fonctions" {

			$Functions = Get-Functions `
				-Script $Script

			$Functions.Count |
				Should -Be 2

		}

        It "Trouve Test-Function" {

            $Functions = Find-Functions `
                -Script $Script `
                -Name "Test-Function"

            $Functions.Count |
                Should -Be 1

        }

        It "Ne trouve pas une fonction inexistante" {

			$Functions = Find-Functions `
				-Script $Script `
				-Name "FonctionImpossible"

			$Functions |
				Should -BeNullOrEmpty

		}

        It "Retourne le nom de la fonction" {

            $Function = (
                Find-Functions `
                    -Script $Script `
                    -Name "Test-Function"
            )[0]

            Get-FunctionName `
                -Function $Function |
                Should -Be "Test-Function"

        }

    }
	    Context "Classes" {

        It "Retourne toutes les classes" {

            $Classes = Get-Classes `
                -Script $Script

            $Classes.Count |
                Should -Be 1

        }

        It "Trouve DemoClass" {

            $Classes = Find-Classes `
                -Script $Script `
                -Name "DemoClass"

            $Classes.Count |
                Should -Be 1

        }

        It "Ne trouve pas une classe inexistante" {

			$Classes = Find-Classes `
				-Script $Script `
				-Name "ClasseImpossible"

			$Classes |
				Should -BeNullOrEmpty

		}

        It "Retourne le nom de la classe" {

            $Class = (
                Find-Classes `
                    -Script $Script `
                    -Name "DemoClass"
            )[0]

            Get-ClassName `
                -Class $Class |
                Should -Be "DemoClass"

        }

    }

    Context "Variables" {

        It "Retourne toutes les variables" {

            $Variables = Get-Variables `
                -Script $Script

            $Variables.Count |
                Should -BeGreaterThan 2

        }

        It "Trouve la variable Variable" {

			$Variables = Find-Variables `
				-Script $Script `
				-Name "Variable"

			$Variables.Count |
				Should -Be 2

		}

        It "Trouve la variable Name" {

            $Variables = Find-Variables `
                -Script $Script `
                -Name "Name"

            $Variables.Count |
                Should -BeGreaterThan 0

        }

        It "Ne trouve pas une variable inexistante" {

			$Variables = Find-Variables `
				-Script $Script `
				-Name "Impossible"

			$Variables |
				Should -BeNullOrEmpty

		}

        It "Retourne le nom d'une variable" {

            $Variable = (
                Find-Variables `
                    -Script $Script `
                    -Name "Variable"
            )[0]

            Get-VariableName `
                -Variable $Variable |
                Should -Be "Variable"

        }

    }

    Context "Paramètres" {

        It "Retourne les blocs Param()" {

            $Blocks = Get-ParameterBlocks `
                -Script $Script

            $Blocks.Count |
                Should -BeGreaterThan 0

        }

        It "Retourne tous les paramètres" {

            $Parameters = Get-Parameters `
                -Script $Script

            $Parameters.Count |
                Should -Be 2

        }

        It "Trouve le paramètre Name" {

            $Parameter = Find-Parameters `
                -Script $Script `
                -Name "Name"

            $Parameter.Count |
                Should -Be 1

        }

        It "Trouve le paramètre Value" {

            $Parameter = Find-Parameters `
                -Script $Script `
                -Name "Value"

            $Parameter.Count |
                Should -Be 1

        }

        It "Ne trouve pas un paramètre inexistant" {

			$Parameter = Find-Parameters `
				-Script $Script `
				-Name "Impossible"

			$Parameter |
				Should -BeNullOrEmpty

		}

        It "Retourne le nom d'un paramètre" {

            $Parameter = (
                Find-Parameters `
                    -Script $Script `
                    -Name "Value"
            )[0]

            Get-ParameterName `
                -Parameter $Parameter |
                Should -Be "Value"

        }

    }
	    Context "Informations sur les nœuds AST" {

        It "Retourne l'Extent d'un nœud" {

            $Function = (
                Find-Functions `
                    -Script $Script `
                    -Name "Test-Function"
            )[0]

            $Extent = Get-Extent `
                -Node $Function

            $Extent |
                Should -Not -BeNullOrEmpty

        }

        It "Retourne un offset de début valide" {

			$Function = (
				Find-Functions `
					-Script $Script `
					-Name "Test-Function"
			)[0]

			Get-StartOffset `
				-Node $Function |
				Should -BeGreaterOrEqual 0

		}

        It "Retourne un offset de fin valide" {

            $Function = (
                Find-Functions `
                    -Script $Script `
                    -Name "Test-Function"
            )[0]

            Get-EndOffset `
                -Node $Function |
                Should -BeGreaterThan (
                    Get-StartOffset -Node $Function
                )

        }

        It "Retourne le texte exact du nœud" {

            $Function = (
                Find-Functions `
                    -Script $Script `
                    -Name "Test-Function"
            )[0]

            Get-Text `
                -Node $Function |
                Should -Match "function Test-Function"

        }

        It "Retourne une longueur valide" {

            $Function = (
                Find-Functions `
                    -Script $Script `
                    -Name "Test-Function"
            )[0]

            Get-TextLength `
                -Node $Function |
                Should -BeGreaterThan 0

        }

        It "Retourne le type .NET du nœud" {

            $Function = (
                Find-Functions `
                    -Script $Script `
                    -Name "Test-Function"
            )[0]

            Get-NodeType `
                -Node $Function |
                Should -Be ([System.Management.Automation.Language.FunctionDefinitionAst])

        }

        It "Indique que le nœud possède des enfants" {

            $Function = (
                Find-Functions `
                    -Script $Script `
                    -Name "Test-Function"
            )[0]

            Test-HasChildren `
                -Node $Function |
                Should -BeTrue

        }

        It "Retourne les enfants directs" {

            $Function = (
                Find-Functions `
                    -Script $Script `
                    -Name "Test-Function"
            )[0]

            (Get-ChildNodes `
                -Node $Function).Count |
                Should -BeGreaterThan 0

        }

        It "Recherche les nœuds d'un type donné" {

            $Nodes = Find-Nodes `
                -Script $Script `
                -NodeType ([System.Management.Automation.Language.CommandAst])

            $Nodes.Count |
                Should -BeGreaterThan 1

        }

    }

    Context "Statistiques AST" {

        It "Retourne un objet" {

            $Statistics = Get-AstStatistics `
                -Script $Script

            $Statistics |
                Should -Not -BeNullOrEmpty

        }

        It "Retourne le nombre de commandes" {

            $Statistics = Get-AstStatistics `
                -Script $Script

            $Statistics.Commands |
                Should -BeGreaterThan 1

        }

        It "Retourne le nombre de fonctions" {

			$Statistics = Get-AstStatistics `
				-Script $Script

			$Statistics.Functions |
				Should -Be 2

		}

        It "Retourne le nombre de classes" {

            $Statistics = Get-AstStatistics `
                -Script $Script

            $Statistics.Classes |
                Should -Be 1

        }

        It "Retourne le nombre de paramètres" {

            $Statistics = Get-AstStatistics `
                -Script $Script

            $Statistics.Parameters |
                Should -Be 2

        }

        It "Retourne zéro erreur" {

			$Statistics = Get-AstStatistics `
				-Script $Script

			$Statistics.Errors |
				Should -Be 0

		}

        It "Retourne plusieurs tokens" {

			$Statistics = Get-AstStatistics `
				-Script $Script

			$Statistics.Tokens |
				Should -BeGreaterThan 10

		}

    }

    Context "Exports du module" {

        It "Exporte toutes les fonctions attendues" {

            $Module = Get-Module Ast

            $Expected = @(

                "Get-ScriptAst",
                "Get-ParseErrors",
                "Test-ParseErrors",
                "Get-Tokens",

                "Get-Commands",
                "Find-Commands",
                "Get-CommandName",
                "Get-CommandElements",
                "Get-CommandArguments",
                "Get-ArgumentText",
                "Get-ArgumentTexts",

                "Get-Functions",
                "Find-Functions",
                "Get-FunctionName",

                "Get-Classes",
                "Find-Classes",
                "Get-ClassName",

                "Get-Variables",
                "Find-Variables",
                "Get-VariableName",

                "Get-ParameterBlocks",
                "Get-Parameters",
                "Find-Parameters",
                "Get-ParameterName",

                "Get-Extent",
                "Get-StartOffset",
                "Get-EndOffset",
                "Get-Text",
                "Get-TextLength",
                "Get-NodeType",
                "Test-HasChildren",
                "Get-ChildNodes",
                "Find-Nodes",

                "Get-AstStatistics"

            )

            foreach ($Function in $Expected)
            {
                $Module.ExportedFunctions.Keys |
                    Should -Contain $Function
            }

        }

    }

}