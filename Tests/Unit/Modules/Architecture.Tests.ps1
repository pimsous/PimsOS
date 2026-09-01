# ==========================================
# Tests : Architecture PimsOS
# Projet : PimsOS Builder
# ==========================================

BeforeAll {
    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"
    . "$ProjectRoot\Modules\Core\Core.ps1"
    . "$ProjectRoot\Modules\Core\BuildContext.ps1"

    . "$ProjectRoot\Modules\Configuration\Categories.ps1"
    . "$ProjectRoot\Modules\Configuration\Tweak.ps1"
    . "$ProjectRoot\Modules\Configuration\TweakCatalog.ps1"
    . "$ProjectRoot\Modules\Configuration\Profile.ps1"
    . "$ProjectRoot\Modules\Configuration\Configuration.ps1"

    . "$ProjectRoot\Modules\UI\Wizard.ps1"
}

Describe "Architecture PimsOS" {

    It "Expose uniquement le point d'entrée public" {
        (Get-Module PimsOS).ExportedFunctions.Keys |
            Should -Be "Initialize-PimsOS"
    }

    It "Charge toutes les définitions de tweaks avec des actions valides" {

		$Context = [pscustomobject]@{
			Project = [pscustomobject]@{
				Root = $ProjectRoot
			}

			BuildState = [pscustomobject]@{
				Image = [pscustomobject]@{
					TweaksLoaded = $false
				}
			}
		}

		$Tweaks = @(Get-TweakDefinitions -Context $Context -Reload)

		$Tweaks.Count | Should -Be 27

		foreach ($Tweak in $Tweaks) {

			$Tweak.PSObject.Properties.Name |
				Should -Contain "Id"

			$Tweak.PSObject.Properties.Name |
				Should -Contain "Enabled"

			foreach ($Action in @($Tweak.Actions)) {

				$Action.PSObject.Properties.Name |
					Should -Contain "Id"

				$Action.PSObject.Properties.Name |
					Should -Contain "Type"

				$Action.PSObject.Properties.Name |
					Should -Contain "Enabled"
			}
		}
	}

    It "Conserve une configuration Custom plate dans Get-PimsOSTweakConfiguration" {

		$Context = [pscustomobject]@{
			Configuration = @(
				[pscustomobject]@{ Id="A"; Name="A"; Enabled=$true },
				[pscustomobject]@{ Id="B"; Name="B"; Enabled=$false }
			)
		}

		$Result = @(Get-PimsOSTweakConfiguration -Context $Context)

		$Result.Count | Should -Be 2
		$Result[0].Enabled | Should -BeTrue
		$Result[1].Enabled | Should -BeFalse
	}
}
