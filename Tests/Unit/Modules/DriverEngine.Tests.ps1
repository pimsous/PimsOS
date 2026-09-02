# ==========================================
# Tests : DriverEngine
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"

    # --------------------------------------------------
    # Dépendance du Manager
    # --------------------------------------------------

    function global:Invoke-Driver {

        param(
            [psobject]$Context,
            [psobject]$Action
        )

        return $Context

    }

    . "$ProjectRoot\Modules\Actions\DriverEngine.ps1"

}

Describe "DriverEngine" {

    BeforeEach {

        Reset-Logger

        Mock Write-Log {}

        # ==========================================
        # Contexte
        # ==========================================

        $script:Context = [pscustomobject]@{

            BuildState = [pscustomobject]@{

                Status = "Idle"

            }

            Statistics = [pscustomobject]@{

                DriversProcessed = 0

            }

        }

        # ==========================================
        # Action
        # ==========================================

        $script:Action = [pscustomobject]@{

            Id = "Driver.Test"

            Name = "TestDriver"

            Success = $false

            Duration = [timespan]::Zero

            Error = $null

        }

    }


    # ==================================================
    # Invoke-DriverAction
    # ==================================================

    Context "Invoke-DriverAction" {

        It "Applique un pilote valide" {

            $Result = Invoke-DriverAction `
                -Context $script:Context `
                -Action $script:Action

            $Result |
                Should -Be $script:Context

            $script:Action.Success |
                Should -BeTrue

        }


        It "Passe le BuildState à DriverApplied" {

            $null = Invoke-DriverAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Context.BuildState.Status |
                Should -Be "DriverApplied"

        }


        It "Incrémente DriversProcessed" {

            $null = Invoke-DriverAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Context.Statistics.DriversProcessed |
                Should -Be 1

        }


        It "Positionne Duration" {

            $null = Invoke-DriverAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Action.Duration |
                Should -BeOfType ([TimeSpan])

        }


        It "Ajoute les propriétés de résultat à une action dynamique" {

            $DynamicAction = [pscustomobject]@{

                Id = "Driver.Dynamic"

                Name = "DynamicDriver"

            }

            $null = Invoke-DriverAction `
                -Context $script:Context `
                -Action $DynamicAction

            $DynamicAction.PSObject.Properties.Name |
                Should -Contain "Success"

            $DynamicAction.PSObject.Properties.Name |
                Should -Contain "Duration"

            $DynamicAction.PSObject.Properties.Name |
                Should -Contain "Error"

            $DynamicAction.Success |
                Should -BeTrue

        }


        It "Gère une erreur avec une action dynamique" {

			Mock Invoke-Driver {
				throw "Erreur dynamique"
			}

			$DynamicAction = [pscustomobject]@{

				Id = "Driver.DynamicError"

				Name = "DynamicDriver"

			}

			{

				Invoke-DriverAction `
					-Context $script:Context `
					-Action $DynamicAction

			} |
				Should -Throw

			$DynamicAction.Success |
				Should -BeFalse

			$DynamicAction.Error |
				Should -Be "Erreur dynamique"

		}


        It "Réinitialise Error après une réussite" {

            $script:Action.Error = "Ancienne erreur"

            $null = Invoke-DriverAction `
                -Context $script:Context `
                -Action $script:Action

            $script:Action.Error |
                Should -BeNullOrEmpty

        }


        It "Lève une exception si Name est absent" {

            $script:Action.Name = $null

            {

                Invoke-DriverAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

        }


        It "Passe le BuildState à DriverFailed en cas d'erreur" {

            function global:Invoke-Driver {

                throw "Erreur de test"

            }

            {

                Invoke-DriverAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

            $script:Context.BuildState.Status |
                Should -Be "DriverFailed"

        }


        It "Positionne Success à False en cas d'erreur" {

            function global:Invoke-Driver {

                throw "Erreur de test"

            }

            {

                Invoke-DriverAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

            $script:Action.Success |
                Should -BeFalse

        }


        It "Conserve le message d'erreur de l'action" {

            function global:Invoke-Driver {

                throw "Erreur pilote"

            }

            {

                Invoke-DriverAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw

            $script:Action.Error |
                Should -Be "Erreur pilote"

        }


        It "Enrichit l'exception avec l'identifiant du pilote" {

            function global:Invoke-Driver {

                throw "Erreur pilote"

            }

            {

                Invoke-DriverAction `
                    -Context $script:Context `
                    -Action $script:Action

            } |
                Should -Throw "*Driver.Test*"

        }

    }

}