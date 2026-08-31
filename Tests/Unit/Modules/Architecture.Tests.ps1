# ==========================================
# Tests : Architecture PimsOS
# Projet : PimsOS Builder
# ==========================================

BeforeAll {
    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path
    Import-Module "$ProjectRoot\Modules\PimsOS.psd1" -Force
}

Describe "Architecture PimsOS" {

    It "Expose uniquement le point d'entrée public" {
        (Get-Module PimsOS).ExportedFunctions.Keys |
            Should -Be "Initialize-PimsOS"
    }

    It "Charge toutes les définitions de tweaks avec des actions valides" {
        InModuleScope PimsOS {
            $Context = [pscustomobject]@{
                Project = [pscustomobject]@{ Root = $ProjectRoot }
                BuildState = [pscustomobject]@{
                    Image = [pscustomobject]@{ TweaksLoaded = $false }
                }
            }

            $Tweaks = @(Get-TweakDefinitions -Context $Context -Reload)
            $Tweaks.Count | Should -BeGreaterThan 0

			foreach ($Tweak in $Tweaks) {
				$Tweak.PSObject.Properties.Name | Should -Contain "Id"
				$Tweak.PSObject.Properties.Name | Should -Contain "Enabled"

				foreach ($Action in @($Tweak.Actions)) {
					$Action.PSObject.Properties.Name | Should -Contain "Id"
					$Action.PSObject.Properties.Name | Should -Contain "Type"
					$Action.PSObject.Properties.Name | Should -Contain "Enabled"
				}
			}
        }
    }

    It "Conserve une configuration Custom plate dans Get-PimsOSTweakConfiguration" {
        InModuleScope PimsOS {
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
}
