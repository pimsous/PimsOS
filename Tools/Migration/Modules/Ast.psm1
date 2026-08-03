<#
.SYNOPSIS
    Analyseur AST du framework de migration PimsOS.

.DESCRIPTION
    Ce module encapsule l'API AST de PowerShell afin de fournir
    une interface stable aux règles de migration.

.NOTES

    Projet : PimsOS
    Module : Ast
    Version : 1.1.0

#>

Set-StrictMode -Version Latest

#==============================================================================
# Analyse un script PowerShell
#==============================================================================

function Get-ScriptAst {

    [CmdletBinding()]
    [OutputType([hashtable])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.IO.FileInfo]
        $File

    )

    if (-not (Test-Path -LiteralPath $File.FullName -PathType Leaf))
    {
        throw "Le fichier '$($File.FullName)' est introuvable."
    }

    $Tokens = $null
    $Errors = $null

    $Ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $File.FullName,
        [ref]$Tokens,
        [ref]$Errors
    )

    return @{

        File   = $File
        Ast    = $Ast
        Tokens = @($Tokens)
        Errors = @($Errors)

    }

}

#==============================================================================
# Retourne les erreurs de parsing
#==============================================================================

function Get-ParseErrors {

    [CmdletBinding()]
    [OutputType([System.Management.Automation.Language.ParseError[]])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [hashtable]
        $Script

    )

    if ($null -eq $Script.Errors)
    {
        return @()
    }

    return @($Script.Errors)

}

#==============================================================================
# Vérifie si le script contient des erreurs
#==============================================================================

function Test-ParseErrors {

    [CmdletBinding()]
    [OutputType([bool])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [hashtable]
        $Script

    )

    return (@(Get-ParseErrors -Script $Script).Count -gt 0)

}

#==============================================================================
# Retourne les tokens
#==============================================================================

function Get-Tokens {

    [CmdletBinding()]
    [OutputType([System.Management.Automation.Language.Token[]])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [hashtable]
        $Script

    )

    if ($null -eq $Script.Tokens)
    {
        return @()
    }

    return @($Script.Tokens)

}

#==============================================================================
# Recherche des commandes
#==============================================================================

function Get-Commands {

    [CmdletBinding()]
    [OutputType([System.Management.Automation.Language.CommandAst[]])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [hashtable]
        $Script

    )

    return @(
        $Script.Ast.FindAll({

            param($Node)

            $Node -is [System.Management.Automation.Language.CommandAst]

        }, $true)
    )

}

#==============================================================================
# Recherche des commandes par nom
#==============================================================================

function Find-Commands {

    [CmdletBinding()]
    [OutputType([System.Management.Automation.Language.CommandAst[]])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [hashtable]
        $Script,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name

    )

    return @(
        $Script.Ast.FindAll({

            param($Node)

            $Node -is [System.Management.Automation.Language.CommandAst] -and
            $Node.GetCommandName() -eq $Name

        }, $true)
    )

}

#==============================================================================
# Retourne le nom d'une commande
#==============================================================================

function Get-CommandName {

    [CmdletBinding()]
    [OutputType([string])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Management.Automation.Language.CommandAst]
        $Command

    )

    return $Command.GetCommandName()

}

#==============================================================================
# Retourne les éléments d'une commande
#==============================================================================

function Get-CommandElements {

    [CmdletBinding()]
    [OutputType([System.Management.Automation.Language.CommandElementAst[]])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Management.Automation.Language.CommandAst]
        $Command

    )

    if ($null -eq $Command.CommandElements)
    {
        return @()
    }

    return @($Command.CommandElements)

}

#==============================================================================
# Retourne les arguments d'une commande
#==============================================================================

function Get-CommandArguments {

    [CmdletBinding()]
    [OutputType([System.Management.Automation.Language.CommandElementAst[]])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Management.Automation.Language.CommandAst]
        $Command

    )

    $Elements = @(Get-CommandElements -Command $Command)

    if ($Elements.Count -le 1)
    {
        return @()
    }

    return @(
        $Elements |
            Select-Object -Skip 1
    )

}

#==============================================================================
# Retourne le texte exact d'un argument
#==============================================================================

function Get-ArgumentText {

    [CmdletBinding()]
    [OutputType([string])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Management.Automation.Language.CommandElementAst]
        $Argument

    )

    if ($Argument -is [System.Management.Automation.Language.VariableExpressionAst]) {
        return '$' + $Argument.VariablePath.UserPath
    }

    return $Argument.Extent.Text

}

#==============================================================================
# Retourne tous les textes des arguments
#==============================================================================

function Get-ArgumentTexts {

    [CmdletBinding()]
    [OutputType([string[]])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Management.Automation.Language.CommandAst]
        $Command

    )

    $Arguments = foreach ($Argument in (Get-CommandArguments -Command $Command) )
    {
        Get-ArgumentText -Argument $Argument
    }

    return ,([string[]]$Arguments)

}

#==============================================================================
# Recherche des fonctions PowerShell
#==============================================================================

function Get-Functions {

    [CmdletBinding()]
    [OutputType([System.Management.Automation.Language.FunctionDefinitionAst[]])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [hashtable]
        $Script

    )

    return @(
        $Script.Ast.FindAll({

            param($Node)

            $Node -is [System.Management.Automation.Language.FunctionDefinitionAst]

        }, $true)
    )

}

#==============================================================================
# Recherche une fonction par son nom
#==============================================================================

function Find-Functions {

    [CmdletBinding()]
    [OutputType([System.Management.Automation.Language.FunctionDefinitionAst[]])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [hashtable]
        $Script,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name

    )

    return @(
        $Script.Ast.FindAll({

            param($Node)

            $Node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
            $Node.Name -eq $Name

        }, $true)
    )

}

#==============================================================================
# Retourne le nom d'une fonction
#==============================================================================

function Get-FunctionName {

    [CmdletBinding()]
    [OutputType([string])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Management.Automation.Language.FunctionDefinitionAst]
        $Function

    )

    return $Function.Name

}

#==============================================================================
# Recherche des classes
#==============================================================================

function Get-Classes {

    [CmdletBinding()]
    [OutputType([System.Management.Automation.Language.TypeDefinitionAst[]])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [hashtable]
        $Script

    )

    return @(
        $Script.Ast.FindAll({

            param($Node)

            $Node -is [System.Management.Automation.Language.TypeDefinitionAst]

        }, $true)
    )

}

#==============================================================================
# Recherche une classe par son nom
#==============================================================================

function Find-Classes {

    [CmdletBinding()]
    [OutputType([System.Management.Automation.Language.TypeDefinitionAst[]])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [hashtable]
        $Script,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name

    )

    return @(
        $Script.Ast.FindAll({

            param($Node)

            $Node -is [System.Management.Automation.Language.TypeDefinitionAst] -and
            $Node.Name -eq $Name

        }, $true)
    )

}

#==============================================================================
# Retourne le nom d'une classe
#==============================================================================

function Get-ClassName {

    [CmdletBinding()]
    [OutputType([string])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Management.Automation.Language.TypeDefinitionAst]
        $Class

    )

    return $Class.Name

}

#==============================================================================
# Recherche toutes les variables
#==============================================================================

function Get-Variables {

    [CmdletBinding()]
    [OutputType([System.Management.Automation.Language.VariableExpressionAst[]])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [hashtable]
        $Script

    )

    return @(
        $Script.Ast.FindAll({

            param($Node)

            $Node -is [System.Management.Automation.Language.VariableExpressionAst]

        }, $true)
    )

}

#==============================================================================
# Recherche une variable
#==============================================================================

function Find-Variables {

    [CmdletBinding()]
    [OutputType([System.Management.Automation.Language.VariableExpressionAst[]])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [hashtable]
        $Script,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name

    )

    return @(
        $Script.Ast.FindAll({

            param($Node)

            $Node -is [System.Management.Automation.Language.VariableExpressionAst] -and
            $Node.VariablePath.UserPath -eq $Name

        }, $true)
    )

}

#==============================================================================
# Retourne le nom d'une variable
#==============================================================================

function Get-VariableName {

    [CmdletBinding()]
    [OutputType([string])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Management.Automation.Language.VariableExpressionAst]
        $Variable

    )

    return $Variable.VariablePath.UserPath

}

#==============================================================================
# Recherche les blocs Param()
#==============================================================================

function Get-ParameterBlocks {

    [CmdletBinding()]
    [OutputType([System.Management.Automation.Language.ParamBlockAst[]])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [hashtable]
        $Script

    )

    return @(
        $Script.Ast.FindAll({

            param($Node)

            $Node -is [System.Management.Automation.Language.ParamBlockAst]

        }, $true)
    )

}

#==============================================================================
# Retourne tous les paramètres
#==============================================================================

function Get-Parameters {

    [CmdletBinding()]
    [OutputType([System.Management.Automation.Language.ParameterAst[]])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [hashtable]
        $Script

    )

    return @(
        foreach ($Block in (Get-ParameterBlocks -Script $Script))
        {
            if ($null -ne $Block.Parameters)
            {
                $Block.Parameters
            }
        }
    )

}

#==============================================================================
# Recherche un paramètre
#==============================================================================

function Find-Parameters {

    [CmdletBinding()]
    [OutputType([System.Management.Automation.Language.ParameterAst[]])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [hashtable]
        $Script,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name

    )

    return @(
        Get-Parameters -Script $Script |
            Where-Object {

                $_.Name.VariablePath.UserPath -eq $Name

            }
    )

}

#==============================================================================
# Retourne le nom d'un paramètre
#==============================================================================

function Get-ParameterName {

    [CmdletBinding()]
    [OutputType([string])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Management.Automation.Language.ParameterAst]
        $Parameter

    )

    return $Parameter.Name.VariablePath.UserPath

}

#==============================================================================
# Retourne l'Extent d'un nœud AST
#==============================================================================

function Get-Extent {

    [CmdletBinding()]
    [OutputType([System.Management.Automation.Language.IScriptExtent])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Management.Automation.Language.Ast]
        $Node

    )

    return $Node.Extent

}

#==============================================================================
# Retourne la position de début
#==============================================================================

function Get-StartOffset {

    [CmdletBinding()]
    [OutputType([int])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Management.Automation.Language.Ast]
        $Node

    )

    return (Get-Extent -Node $Node).StartOffset

}

#==============================================================================
# Retourne la position de fin
#==============================================================================

function Get-EndOffset {

    [CmdletBinding()]
    [OutputType([int])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Management.Automation.Language.Ast]
        $Node

    )

    return (Get-Extent -Node $Node).EndOffset

}

#==============================================================================
# Retourne le texte exact d'un nœud
#==============================================================================

function Get-Text {

    [CmdletBinding()]
    [OutputType([string])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Management.Automation.Language.Ast]
        $Node

    )

    return (Get-Extent -Node $Node).Text

}

#==============================================================================
# Retourne la longueur du texte
#==============================================================================

function Get-TextLength {

    [CmdletBinding()]
    [OutputType([int])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Management.Automation.Language.Ast]
        $Node

    )

    return (
        (Get-EndOffset -Node $Node) -
        (Get-StartOffset -Node $Node)
    )

}

#==============================================================================
# Retourne le type .NET d'un nœud
#==============================================================================

function Get-NodeType {

    [CmdletBinding()]
    [OutputType([System.Type])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Management.Automation.Language.Ast]
        $Node

    )

    return $Node.GetType()

}

#==============================================================================
# Indique si un nœud possède des enfants
#==============================================================================

function Test-HasChildren {

    [CmdletBinding()]
    [OutputType([bool])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Management.Automation.Language.Ast]
        $Node

    )

    return (@($Node.FindAll({ $true }, $false)).Count -gt 0)

}

#==============================================================================
# Retourne tous les enfants directs d'un nœud
#==============================================================================

function Get-ChildNodes {

    [CmdletBinding()]
    [OutputType([System.Management.Automation.Language.Ast[]])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Management.Automation.Language.Ast]
        $Node

    )

    return @(
        $Node.FindAll({ $true }, $false)
    )

}

#==============================================================================
# Recherche des nœuds d'un type donné
#==============================================================================

function Find-Nodes {

    [CmdletBinding()]
    [OutputType([System.Management.Automation.Language.Ast[]])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [hashtable]
        $Script,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [Type]
        $NodeType

    )

    return @(
        $Script.Ast.FindAll({

            param($Node)

            $Node.GetType() -eq $NodeType

        }, $true)
    )

}

#==============================================================================
# Retourne des statistiques sur l'AST
#==============================================================================

function Get-AstStatistics {

    [CmdletBinding()]
    [OutputType([pscustomobject])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [hashtable]
        $Script

    )

    return [PSCustomObject]@{

        Commands   = @(Get-Commands -Script $Script).Count
        Functions  = @(Get-Functions -Script $Script).Count
        Classes    = @(Get-Classes -Script $Script).Count
        Variables  = @(Get-Variables -Script $Script).Count
        Parameters = @(Get-Parameters -Script $Script).Count
        Errors     = @(Get-ParseErrors -Script $Script).Count
        Tokens     = @(Get-Tokens -Script $Script).Count

    }

}

#==============================================================================
# Export
#==============================================================================

Export-ModuleMember `
    -Function `
        Get-ScriptAst,
        Get-ParseErrors,
        Test-ParseErrors,
        Get-Tokens,
        Get-Commands,
        Find-Commands,
        Get-CommandName,
        Get-CommandElements,
        Get-CommandArguments,
        Get-ArgumentText,
        Get-ArgumentTexts,
        Get-Functions,
        Find-Functions,
        Get-FunctionName,
        Get-Classes,
        Find-Classes,
        Get-ClassName,
        Get-Variables,
        Find-Variables,
        Get-VariableName,
        Get-ParameterBlocks,
        Get-Parameters,
        Find-Parameters,
        Get-ParameterName,
        Get-Extent,
        Get-StartOffset,
        Get-EndOffset,
        Get-Text,
        Get-TextLength,
        Get-NodeType,
        Test-HasChildren,
        Get-ChildNodes,
        Find-Nodes,
        Get-AstStatistics