# ==========================================
# Tests : ServiceEngine
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"
    . "$ProjectRoot\Modules\Actions\ServiceEngine.ps1"

    # --------------------------------------------------
    # Fonctions externes utilisées par ServiceEngine
    # --------------------------------------------------

    function global:Test-ServiceExists {
        param(
            [string]$Name
        )

        return $true
    }

    function global:Set-ServiceStartupType {
        param(
            [psobject]$Context,
            [psobject]$Action
        )

        $Context.ServiceConfigured = $true

        return $Context
    }

    function global:Stop-ServiceSafe {
        param(
            [psobject]$Context,
            [psobject]$Action
        )

        $Context.ServiceStopped = $true

        return $Context
    }
}

Describe "ServiceEngine" {

    BeforeEach {

        $script:Context = [pscustomobject]@{

            ServiceConfigured = $false
            ServiceStopped    = $false

            BuildState = [pscustomobject]@{
                Status = ""
            }
        }

        $script:Action = [pscustomobject]@{

			Id          = "DisableDiagTrack"
			Type        = "Service"
			Name        = "DiagTrack"
			StartupType = "Disabled"
			Stop        = $false

			Success     = $false
			Duration    = $null
			Error       = $null
		}

        Mock Test-ServiceExists {
            param(
                [string]$Name
            )

            return $true
        }

        Mock Set-ServiceStartupType {
            param(
                [psobject]$Context,
                [psobject]$Action
            )

            $Context.ServiceConfigured = $true

            return $Context
        }

        Mock Stop-ServiceSafe {
            param(
                [psobject]$Context,
                [psobject]$Action
            )

            $Context.ServiceStopped = $true

            return $Context
        }
    }

    Context "Invoke-ServiceAction" {

        It "Configure le StartupType du service" {

            $Context = Invoke-ServiceAction `
                -Context $script:Context `
                -Action $script:Action

            $Context.ServiceConfigured |
                Should -BeTrue
        }

        It "Passe le BuildState à ServiceApplied" {

            $Context = Invoke-ServiceAction `
                -Context $script:Context `
                -Action $script:Action

            $Context.BuildState.Status |
                Should -Be "ServiceApplied"
        }

        It "Arrête le service lorsque Stop est vrai" {

            $script:Action.Stop = $true

            $Context = Invoke-ServiceAction `
                -Context $script:Context `
                -Action $script:Action

            $Context.ServiceStopped |
                Should -BeTrue
        }

        It "Lève une exception si le service n'existe pas" {

            Mock Test-ServiceExists {
                param(
                    [string]$Name
                )

                return $false
            }

            {

                Invoke-ServiceAction `
                    -Context $script:Context `
                    -Action $script:Action

            } | Should -Throw

            $script:Context.BuildState.Status |
                Should -Be "ServiceFailed"
        }
    }
}