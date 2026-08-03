# ==========================================
# Import-MigrationRules.Tests.ps1
# ==========================================

BeforeAll {

    $ProjectRoot = Resolve-Path (
        Join-Path $PSScriptRoot "..\..\.."
    )

    Import-Module `
        (Join-Path $ProjectRoot "Tools\Migration\Modules\Common.psm1") `
        -Force

    . (Join-Path $ProjectRoot "Tools\Migration\Private\Import-MigrationRules.ps1")

}

Describe "Import-MigrationRules" {

    Context "Dossier Rules valide" {

        It "Retourne True lorsque le dossier Rules existe" {

            $Context = New-MigrationContext

            $Context.ProjectRoot   = $ProjectRoot
            $Context.MigrationPath = Join-Path $ProjectRoot "Tools\Migration"

            Import-MigrationRules -Context $Context |
                Should -BeTrue

        }

    }

    Context "Dossier Rules absent" {

        It "Retourne False lorsque le dossier Rules est introuvable" {

            $Context = New-MigrationContext

            $Context.ProjectRoot   = $ProjectRoot
            $Context.MigrationPath = Join-Path $ProjectRoot "Inexistant"

            Import-MigrationRules -Context $Context |
                Should -BeFalse

        }

    }

    Context "Type de retour" {

        It "Retourne un booléen" {

            $Context = New-MigrationContext

            $Context.ProjectRoot   = $ProjectRoot
            $Context.MigrationPath = Join-Path $ProjectRoot "Tools\Migration"

            $Result = Import-MigrationRules -Context $Context

            $Result |
                Should -BeOfType ([System.Boolean])

        }

    }

}