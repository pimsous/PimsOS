# ==========================================
# Tests : Profile Selection
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot =
        (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"
    . "$ProjectRoot\Modules\Configuration\Profile.ps1"

}

Describe "Resolve-TweakSelection" {

    BeforeEach {

        $Tweaks = @(

            [PSCustomObject]@{
                Id          = "Privacy.DisableTelemetry"
                Name        = "Désactiver la télémétrie"
                Default     = $true
                Description = "Désactive la télémétrie."
            }

            [PSCustomObject]@{
                Id          = "Xbox.DisableGameBar"
                Name        = "Désactiver Xbox Game Bar"
                Default     = $false
                Description = "Désactive Xbox Game Bar."
            }

            [PSCustomObject]@{
                Id          = "Explorer.ShowFileExtensions"
                Name        = "Afficher les extensions"
                Default     = $false
                Description = "Affiche les extensions."
            }

        )

    }

    It "Sélectionne les tweaks Default" {

        $Result =
            Resolve-TweakSelection `
                -Tweaks $Tweaks

        $Result.Id |
            Should -Contain "Privacy.DisableTelemetry"

        $Result.Id |
            Should -Not -Contain "Xbox.DisableGameBar"

    }

    It "Ajoute un tweak sélectionné explicitement" {

        $Result =
            Resolve-TweakSelection `
                -Tweaks $Tweaks `
                -SelectedIds @(
                    "Xbox.DisableGameBar"
                )

        $Result.Id |
            Should -Contain "Xbox.DisableGameBar"

    }

    It "Supprime un tweak désactivé explicitement" {

		$Result = @(
			Resolve-TweakSelection `
				-Tweaks $Tweaks `
				-DisabledIds @(
					"Privacy.DisableTelemetry"
				)
		)

		@(
			$Result |
				Where-Object {
					$_.Id -eq "Privacy.DisableTelemetry"
				}
		).Count |
			Should -Be 0

	}

    It "Autorise plusieurs tweaks simultanément" {

        $Result =
            Resolve-TweakSelection `
                -Tweaks $Tweaks `
                -SelectedIds @(
                    "Xbox.DisableGameBar",
                    "Explorer.ShowFileExtensions"
                )

        $Result.Id |
            Should -Contain "Privacy.DisableTelemetry"

        $Result.Id |
            Should -Contain "Xbox.DisableGameBar"

        $Result.Id |
            Should -Contain "Explorer.ShowFileExtensions"

    }

    It "La désactivation explicite est prioritaire" {

		$Result = @(
			Resolve-TweakSelection `
				-Tweaks $Tweaks `
				-SelectedIds @(
					"Privacy.DisableTelemetry"
				) `
				-DisabledIds @(
					"Privacy.DisableTelemetry"
				)
		)

		@(
			$Result |
				Where-Object {
					$_.Id -eq "Privacy.DisableTelemetry"
				}
		).Count |
			Should -Be 0

	}

    It "Ignore un identifiant inconnu" {

        {

            Resolve-TweakSelection `
                -Tweaks $Tweaks `
                -SelectedIds @(
                    "Unknown.Tweak"
                )

        } |
            Should -Not -Throw

    }

}