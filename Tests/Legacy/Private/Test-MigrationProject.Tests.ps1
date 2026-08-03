# ==========================================
# Test-MigrationProject.Tests.ps1
# ==========================================

BeforeAll {

    $ProjectRoot = Resolve-Path (
        Join-Path $PSScriptRoot "..\..\.."
    )

    Import-Module `
        (Join-Path $ProjectRoot "Tools\Migration\Modules\Common.psm1") `
        -Force

    . (Join-Path $ProjectRoot "Tools\Migration\Private\Test-MigrationProject.ps1")

}

Describe "Test-MigrationProject" {

    Context "Projet valide" {

        It "Retourne True lorsque tous les dossiers existent" {

            $Context = New-MigrationContext

            $Context.ProjectRoot   = $ProjectRoot
            $Context.ToolsPath     = Join-Path $ProjectRoot "Tools"
            $Context.MigrationPath = Join-Path $ProjectRoot "Tools\Migration"
            $Context.ModulesPath   = Join-Path $ProjectRoot "Tools\Migration\Modules"
            $Context.TestsPath     = Join-Path $ProjectRoot "Tests"

            Test-MigrationProject -Context $Context |
                Should -BeTrue

        }

    }

    Context "ProjectRoot" {

        It "Retourne False si ProjectRoot est absent" {

            $Context = New-MigrationContext

            $Context.ProjectRoot   = "C:\Inexistant"
            $Context.ToolsPath     = Join-Path $ProjectRoot "Tools"
            $Context.MigrationPath = Join-Path $ProjectRoot "Tools\Migration"
            $Context.ModulesPath   = Join-Path $ProjectRoot "Tools\Migration\Modules"
            $Context.TestsPath     = Join-Path $ProjectRoot "Tests"

            Test-MigrationProject -Context $Context |
                Should -BeFalse

        }

    }

    Context "ToolsPath" {

        It "Retourne False si ToolsPath est absent" {

            $Context = New-MigrationContext

            $Context.ProjectRoot   = $ProjectRoot
            $Context.ToolsPath     = Join-Path $ProjectRoot "Inexistant"
            $Context.MigrationPath = Join-Path $ProjectRoot "Tools\Migration"
            $Context.ModulesPath   = Join-Path $ProjectRoot "Tools\Migration\Modules"
            $Context.TestsPath     = Join-Path $ProjectRoot "Tests"

            Test-MigrationProject -Context $Context |
                Should -BeFalse

        }

    }

    Context "MigrationPath" {

        It "Retourne False si MigrationPath est absent" {

            $Context = New-MigrationContext

            $Context.ProjectRoot   = $ProjectRoot
            $Context.ToolsPath     = Join-Path $ProjectRoot "Tools"
            $Context.MigrationPath = Join-Path $ProjectRoot "Tools\Inexistant"
            $Context.ModulesPath   = Join-Path $ProjectRoot "Tools\Migration\Modules"
            $Context.TestsPath     = Join-Path $ProjectRoot "Tests"

            Test-MigrationProject -Context $Context |
                Should -BeFalse

        }

    }

    Context "ModulesPath" {

        It "Retourne False si ModulesPath est absent" {

            $Context = New-MigrationContext

            $Context.ProjectRoot   = $ProjectRoot
            $Context.ToolsPath     = Join-Path $ProjectRoot "Tools"
            $Context.MigrationPath = Join-Path $ProjectRoot "Tools\Migration"
            $Context.ModulesPath   = Join-Path $ProjectRoot "Tools\Migration\Inexistant"
            $Context.TestsPath     = Join-Path $ProjectRoot "Tests"

            Test-MigrationProject -Context $Context |
                Should -BeFalse

        }

    }

    Context "TestsPath" {

        It "Retourne False si TestsPath est absent" {

            $Context = New-MigrationContext

            $Context.ProjectRoot   = $ProjectRoot
            $Context.ToolsPath     = Join-Path $ProjectRoot "Tools"
            $Context.MigrationPath = Join-Path $ProjectRoot "Tools\Migration"
            $Context.ModulesPath   = Join-Path $ProjectRoot "Tools\Migration\Modules"
            $Context.TestsPath     = Join-Path $ProjectRoot "Inexistant"

            Test-MigrationProject -Context $Context |
                Should -BeFalse

        }

    }

}