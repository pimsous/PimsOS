# ==========================================
# Test Pester : Mount-Wim
# Projet : PimsOS Builder
# ==========================================

#Requires -Version 7.0

Set-StrictMode -Version Latest

# --------------------------------------------------
# Racine du projet
# --------------------------------------------------

$ProjectRoot = Split-Path `
    (Split-Path $PSScriptRoot -Parent) `
    -Parent

Set-Location $ProjectRoot

# --------------------------------------------------
# Chargement des modules
# --------------------------------------------------

. "$ProjectRoot\Modules\Infrastructure\Logger.ps1"
. "$ProjectRoot\Modules\Core\Core.ps1"
. "$ProjectRoot\Modules\Core\BuildContext.ps1"
. "$ProjectRoot\Modules\Configuration\Configuration.ps1"
. "$ProjectRoot\Modules\Image\Iso.ps1"
. "$ProjectRoot\Modules\Image\Dism.ps1"
. "$ProjectRoot\Modules\Image\Wim.ps1"

# --------------------------------------------------
# Tests
# --------------------------------------------------

Describe "Montage WIM" {

    It "doit pouvoir initialiser un BuildContext" {

        $Context = New-BuildContext

        $Context | Should -Not -BeNullOrEmpty

        $Context.PSObject.Properties.Name |
            Should -Contain "WIM"

        $Context.PSObject.Properties.Name |
            Should -Contain "BuildState"
    }

    It "doit initialiser l'état de montage WIM" {

        $State = New-WimMountState

        $State | Should -Not -BeNullOrEmpty

        $State.ObjectType |
            Should -Be "WimMountState"

        $State.Exists |
            Should -BeFalse

        $State.Valid |
            Should -BeFalse

        $State.CanReuse |
            Should -BeFalse

        $State.MountPath |
            Should -BeNullOrEmpty
    }

    It "doit vérifier qu'un contexte WIM est valide" {

        $Context = New-BuildContext

        {
            Test-WimContext -Context $Context
        } |
            Should -Not -Throw
    }

}