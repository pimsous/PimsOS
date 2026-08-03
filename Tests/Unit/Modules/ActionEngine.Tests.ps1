
# ==========================================
# Tests : ActionEngine
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"
	. "$ProjectRoot\Modules\Core\ActionRegistry.ps1"
	. "$ProjectRoot\Modules\Actions\ActionEngine.ps1"

}

Describe "ActionEngine" {

    BeforeEach {

        Reset-ActionRegistry

    }

    Context "Invoke-Action" {

        BeforeEach {

            function Invoke-TestAction {

				param(
					[psobject]$Context,
					[psobject]$Action
				)

				$Context.Executed = $true

				return $Context

			}

            Register-ActionHandler `
                -Type "Test" `
                -Handler "Invoke-TestAction"

            $script:Context = [pscustomobject]@{
                Executed   = $false

                Statistics = [pscustomobject]@{
					ActionsProcessed = 0
					Errors           = 0
				}

                BuildState = [pscustomobject]@{
                    Status = ""
                }
            }

            $script:Action = [pscustomobject]@{
                Id      = "TestAction"
                Type    = "Test"
                Enabled = $true
            }

        }

        It "Exécute le moteur associé au type" {

            Invoke-Action `
                -Context $script:Context `
                -Action $script:Action

            $script:Context.Executed | Should -BeTrue

        }

        It "Incrémente le compteur ActionsProcessed" {

            Invoke-Action `
                -Context $script:Context `
                -Action $script:Action

            $script:Context.Statistics.ActionsProcessed |
				Should -Be 1

        }

        It "Passe le BuildState à ActionApplied" {

            Invoke-Action `
                -Context $script:Context `
                -Action $script:Action

            $script:Context.BuildState.Status |
                Should -Be "ActionApplied"

        }

        It "Lève une exception lorsqu'aucun moteur n'est enregistré" {

            $script:Action.Type = "Unknown"

            {
                Invoke-Action `
                    -Context $script:Context `
                    -Action $script:Action
            } | Should -Throw

        }

    }

}

