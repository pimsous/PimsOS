# ==========================================
# Tests : Service
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"
    . "$ProjectRoot\Modules\Infrastructure\Service.ps1"

}

Describe "Service" {

    Context "Test-ServiceExists" {

        It "Retourne True pour un service existant" {

            Test-ServiceExists `
                -Name "DiagTrack" |
                Should -BeTrue

        }

        It "Retourne False pour un service inexistant" {

            Test-ServiceExists `
                -Name "PimsOS-Service-Inexistant" |
                Should -BeFalse

        }

    }

    Context "Get-ServiceStartupType" {

        It "Retourne un StartupType valide" {

            $StartupType = Get-ServiceStartupType `
                -Name "DiagTrack"

            $StartupType | Should -Not -BeNullOrEmpty

        }

    }

}