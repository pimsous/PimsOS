# ==========================================
# Tests : Profile Preset
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot =
        (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"
    . "$ProjectRoot\Modules\Configuration\Profile.ps1"

}

Describe "Resolve-ProfilePreset" {

    BeforeEach {

        $Tweaks = @(

            [PSCustomObject]@{
                Id      = "Privacy.DisableTelemetry"
                Name    = "Désactiver la télémétrie"
                Default = $true
            }

            [PSCustomObject]@{
                Id      = "Xbox.DisableGameBar"
                Name    = "Désactiver Xbox Game Bar"
                Default = $false
            }

            [PSCustomObject]@{
                Id      = "Explorer.ShowFileExtensions"
                Name    = "Afficher les extensions"
                Default = $false
            }

        )

    }

    It "Lit le format historique en tableau" {

        $Profile = [PSCustomObject]@{

            Name = "Default"

            Description = "Profil par défaut"

            Tweaks = @(
                [PSCustomObject]@{
                    Id      = "Privacy.DisableTelemetry"
                    Enabled = $true
                }
            )

        }

        $Result =
            Resolve-ProfilePreset `
                -Profile $Profile `
                -Tweaks $Tweaks

        $Result.Name |
            Should -Be "Default"

        $Result.SelectedIds |
            Should -Contain "Privacy.DisableTelemetry"

    }

    It "Lit le format objet utilisé par Gaming" {

        $Profile = [PSCustomObject]@{

            Name = "Gaming"

            Description = "Optimisations Gaming"

            Tweaks = [PSCustomObject]@{

                "Xbox.DisableGameBar" = $true
                "Explorer.ShowFileExtensions" = $true

            }

        }

        $Result =
            Resolve-ProfilePreset `
                -Profile $Profile `
                -Tweaks $Tweaks

        $Result.SelectedIds |
            Should -Contain "Xbox.DisableGameBar"

        $Result.SelectedIds |
            Should -Contain "Explorer.ShowFileExtensions"

    }

    It "Conserve les tweaks désactivés explicitement" {

        $Profile = [PSCustomObject]@{

            Name = "Test"

            Tweaks = [PSCustomObject]@{

                "Privacy.DisableTelemetry" = $false

            }

        }

        $Result =
            Resolve-ProfilePreset `
                -Profile $Profile `
                -Tweaks $Tweaks

        $Result.DisabledIds |
            Should -Contain "Privacy.DisableTelemetry"

        $Result.SelectedIds |
            Should -Not -Contain "Privacy.DisableTelemetry"

    }

    It "Ignore un tweak inconnu" {

        $Profile = [PSCustomObject]@{

            Name = "Test"

            Tweaks = [PSCustomObject]@{

                "Unknown.Tweak" = $true

            }

        }

        $Result =
            Resolve-ProfilePreset `
                -Profile $Profile `
                -Tweaks $Tweaks

        $Result.SelectedIds.Count |
            Should -Be 0

    }

    It "Peut sélectionner plusieurs tweaks" {

        $Profile = [PSCustomObject]@{

            Name = "Gaming"

            Tweaks = [PSCustomObject]@{

                "Xbox.DisableGameBar" = $true
                "Explorer.ShowFileExtensions" = $true
                "Privacy.DisableTelemetry" = $true

            }

        }

        $Result =
            Resolve-ProfilePreset `
                -Profile $Profile `
                -Tweaks $Tweaks

        $Result.SelectedIds.Count |
            Should -Be 3

    }

    It "Retourne une structure exploitable par Resolve-TweakSelection" {

        $Profile = [PSCustomObject]@{

            Name = "Gaming"

            Tweaks = [PSCustomObject]@{

                "Xbox.DisableGameBar" = $true

            }

        }

        $Preset =
            Resolve-ProfilePreset `
                -Profile $Profile `
                -Tweaks $Tweaks

        $Result =
            Resolve-TweakSelection `
                -Tweaks $Tweaks `
                -SelectedIds $Preset.SelectedIds `
                -DisabledIds $Preset.DisabledIds

        $Result.Id |
            Should -Contain "Xbox.DisableGameBar"

    }

}

Describe "Load-Profile" {

    BeforeEach {
        $Context = [pscustomobject]@{
            Project = [pscustomobject]@{ Root = $ProjectRoot }
            ConfigurationProfile = $null
            BuildState = [pscustomobject]@{
                Image = [pscustomobject]@{ ProfileLoaded = $false }
            }
        }

        Mock Write-Log {}
    }

    It "Charge un profil imbriqué sans extension" {
        $Result = Load-Profile -Context $Context -Name "Tests\Registry"
        $Result.Name | Should -Be "Registry"
        $Context.ConfigurationProfile | Should -Be "Tests\Registry"
    }

    It "Accepte aussi le nom avec extension .json" {
        $Result = Load-Profile -Context $Context -Name "Tests\Registry.json"
        $Result.Name | Should -Be "Registry"
    }
}
