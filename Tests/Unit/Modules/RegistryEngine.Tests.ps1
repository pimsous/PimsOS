# ==========================================
# Tests : RegistryEngine
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"
    . "$ProjectRoot\Modules\Windows\Registry.ps1"
    . "$ProjectRoot\Modules\Actions\RegistryEngine.ps1"

}

Describe "RegistryEngine" {

    BeforeEach {

        function Set-RegistryValue {

            param(
                [psobject]$Context,
                [psobject]$Action
            )

            $Context.RegistryApplied = $true

            return $Context

        }

        $script:Context = [pscustomobject]@{

            RegistryApplied = $false

            BuildState = [pscustomobject]@{

                Status = ""

            }

        }

        $script:Action = [pscustomobject]@{

            Id = "RegistryTest"

        }

    }

    Context "Invoke-RegistryAction" {

        It "Exécute le moteur Registry" {

            $Context = Invoke-RegistryAction `
                -Context $script:Context `
                -Action $script:Action

            $Context.RegistryApplied | Should -BeTrue

        }

        It "Passe le BuildState à RegistryApplied" {

            $Context = Invoke-RegistryAction `
                -Context $script:Context `
                -Action $script:Action

            $Context.BuildState.Status |
                Should -Be "RegistryApplied"

        }

        It "Passe le BuildState à RegistryFailed lorsqu'une erreur survient" {

            function Set-RegistryValue {

                throw "Erreur"

            }

            {

                Invoke-RegistryAction `
                    -Context $script:Context `
                    -Action $script:Action

            } | Should -Throw

            $script:Context.BuildState.Status |
                Should -Be "RegistryFailed"

        }

    }

}