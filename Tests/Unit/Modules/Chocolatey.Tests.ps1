# ==========================================
# Tests : Chocolatey provider
# Projet : PimsOS Builder
# ==========================================

BeforeAll {
    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"
    . "$ProjectRoot\Modules\Package\Chocolatey.ps1"
}

Describe "Chocolatey provider" {

    BeforeEach {
        Reset-Logger
        Mock Write-Log {}
    }

    It "Retourne le cache PackagesChocolatey du contexte" {
        $Cache = Join-Path $TestDrive "Chocolatey"
        $Context = [pscustomobject]@{
            Workspace = [pscustomobject]@{
                PackagesChocolatey = $Cache
            }
        }

        $Result = Get-ChocolateyCachePath -Context $Context

        $Result | Should -Be (Resolve-Path $Cache).Path
        Test-Path $Cache | Should -BeTrue
    }

    It "Utilise Workspace.Cache\Chocolatey comme repli" {
        $Cache = Join-Path $TestDrive "Cache"
        $Context = [pscustomobject]@{
            Workspace = [pscustomobject]@{
                Cache = $Cache
            }
        }

        $Result = Get-ChocolateyCachePath -Context $Context

        $Result | Should -Be (Resolve-Path (Join-Path $Cache "Chocolatey")).Path
    }

    It "Détecte un package déjà présent dans le cache" {
        $Cache = Join-Path $TestDrive "Chocolatey"
        New-Item -ItemType Directory -Path $Cache -Force | Out-Null
        New-Item -ItemType File -Path (Join-Path $Cache "firefox.1.0.0.nupkg") | Out-Null

        $Result = Find-ChocolateyCachedPackage `
            -CachePath $Cache `
            -Name "firefox" `
            -Version "1.0.0"

        $Result.Name | Should -Be "firefox.1.0.0.nupkg"
    }

    It "Construit une installation séquentielle avec cache persistant" {
        Mock Test-ChocolateyAvailable { $true }
        Mock Get-Command {
            [pscustomobject]@{ Source = "choco.exe" }
        } -ParameterFilter { $Name -eq "choco.exe" }
        Mock Invoke-ChocolateyCli {
            [pscustomobject]@{ ExitCode = 0 }
        }

        $Cache = Join-Path $TestDrive "Chocolatey"
        $Context = [pscustomobject]@{
            Workspace = [pscustomobject]@{
                PackagesChocolatey = $Cache
            }
        }
        $Action = [pscustomobject]@{
            Name = "firefox"
        }

        $Result = Invoke-ChocolateyPackage -Context $Context -Action $Action

        $Result | Should -Be $Context
        Should -Invoke Invoke-ChocolateyCli -Times 1 -Exactly -ParameterFilter {
            $Arguments -contains "install" -and
            $Arguments -contains "firefox" -and
            ($Arguments -match "--cache-location=") -and
            ($Arguments -match "--source=")
        }
    }

    It "Transmet la version demandée" {
        Mock Test-ChocolateyAvailable { $true }
        Mock Get-Command {
            [pscustomobject]@{ Source = "choco.exe" }
        } -ParameterFilter { $Name -eq "choco.exe" }
        Mock Invoke-ChocolateyCli {
            [pscustomobject]@{ ExitCode = 0 }
        }

        $Context = [pscustomobject]@{
            Workspace = [pscustomobject]@{
                PackagesChocolatey = (Join-Path $TestDrive "Chocolatey")
            }
        }
        $Action = [pscustomobject]@{
            Name = "firefox"
            Version = "1.0.0"
        }

        $null = Invoke-ChocolateyPackage -Context $Context -Action $Action

        Should -Invoke Invoke-ChocolateyCli -Times 1 -Exactly -ParameterFilter {
            $Arguments -contains "--version=1.0.0"
        }
    }

    It "Accepte les codes de succès avec redémarrage" {
        Mock Test-ChocolateyAvailable { $true }
        Mock Get-Command {
            [pscustomobject]@{ Source = "choco.exe" }
        } -ParameterFilter { $Name -eq "choco.exe" }
        Mock Invoke-ChocolateyCli {
            [pscustomobject]@{ ExitCode = 3010 }
        }

        $Context = [pscustomobject]@{
            Workspace = [pscustomobject]@{
                PackagesChocolatey = (Join-Path $TestDrive "Chocolatey")
            }
        }
        $Action = [pscustomobject]@{ Name = "test-package" }

        { Invoke-ChocolateyPackage -Context $Context -Action $Action } | Should -Not -Throw
    }

    It "Refuse un code de sortie Chocolatey en erreur" {
        Mock Test-ChocolateyAvailable { $true }
        Mock Get-Command {
            [pscustomobject]@{ Source = "choco.exe" }
        } -ParameterFilter { $Name -eq "choco.exe" }
        Mock Invoke-ChocolateyCli {
            [pscustomobject]@{ ExitCode = 1 }
        }

        $Context = [pscustomobject]@{
            Workspace = [pscustomobject]@{
                PackagesChocolatey = (Join-Path $TestDrive "Chocolatey")
            }
        }
        $Action = [pscustomobject]@{ Name = "test-package" }

        { Invoke-ChocolateyPackage -Context $Context -Action $Action } |
            Should -Throw "*code de sortie 1*"
    }

    It "Refuse Chocolatey absent" {
        Mock Test-ChocolateyAvailable { $false }

        $Context = [pscustomobject]@{
            Workspace = [pscustomobject]@{
                PackagesChocolatey = (Join-Path $TestDrive "Chocolatey")
            }
        }
        $Action = [pscustomobject]@{ Name = "firefox" }

        { Invoke-ChocolateyPackage -Context $Context -Action $Action } |
            Should -Throw "*choco.exe*introuvable*"
    }
}
