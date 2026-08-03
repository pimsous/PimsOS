# ==========================================
# Tests : Wim
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Image\Wim.ps1"

}

Describe "Wim" {

    Context "New-WimMountState" {

        It "Retourne un objet WimMountState" {

            $State = New-WimMountState

            $State.ObjectType |
                Should -Be "WimMountState"

        }

        It "Initialise Exists à False" {

            (New-WimMountState).Exists |
                Should -BeFalse

        }

        It "Initialise Valid à False" {

            (New-WimMountState).Valid |
                Should -BeFalse

        }

        It "Initialise NeedsCleanup à False" {

            (New-WimMountState).NeedsCleanup |
                Should -BeFalse

        }

    }

    Context "Test-WimContext" {

        It "Accepte un contexte valide" {

            $Context = [pscustomobject]@{

                WIM = [pscustomobject]@{}

            }

            {

                Test-WimContext `
                    -Context $Context

            } | Should -Not -Throw

        }

        It "Refuse un contexte null" {

            {

                Test-WimContext `
                    -Context $null

            } | Should -Throw

        }

        It "Refuse un contexte sans section WIM" {

            $Context = [pscustomobject]@{}

            {

                Test-WimContext `
                    -Context $Context

            } | Should -Throw

        }

    }

    Context "Set-WimMountedState" {

        It "Positionne Mounted à True" {

            $Context = [pscustomobject]@{

                BuildState = [pscustomobject]@{

                    Image = [pscustomobject]@{

                        Mounted = $false
                        RegistryLoaded = $true
                        CurrentRegistryHive = "SOFTWARE"
                        ConfigLoaded = $true
                        TweaksLoaded = $true
                        TweaksApplied = $true

                    }

                }

            }

            $Context = Set-WimMountedState `
                -Context $Context `
                -Mounted $true

            $Context.BuildState.Image.Mounted |
                Should -BeTrue

        }

        It "Réinitialise l'état lorsque Mounted vaut False" {

            $Context = [pscustomobject]@{

                BuildState = [pscustomobject]@{

                    Image = [pscustomobject]@{

                        Mounted = $true
                        RegistryLoaded = $true
                        CurrentRegistryHive = "SOFTWARE"
                        ConfigLoaded = $true
                        TweaksLoaded = $true
                        TweaksApplied = $true

                    }

                }

            }

            $Context = Set-WimMountedState `
                -Context $Context `
                -Mounted $false

            $Context.BuildState.Image.Mounted |
                Should -BeFalse

            $Context.BuildState.Image.RegistryLoaded |
                Should -BeFalse

            $Context.BuildState.Image.CurrentRegistryHive |
                Should -BeNullOrEmpty

            $Context.BuildState.Image.ConfigLoaded |
                Should -BeFalse

            $Context.BuildState.Image.TweaksLoaded |
                Should -BeFalse

            $Context.BuildState.Image.TweaksApplied |
                Should -BeFalse

        }

    }

}