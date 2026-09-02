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

    It "Extrait correctement un bootstrap .nupkg sous PowerShell 5.1+" {
        $script:ChocolateyAvailabilityCalls = 0
        Mock Test-ChocolateyAvailable {
            $script:ChocolateyAvailabilityCalls++
            return ($script:ChocolateyAvailabilityCalls -ge 2)
        }
        Mock Write-Log {}

        $Source = Join-Path $TestDrive "ChocolateyBootstrap"
        $Tools = Join-Path $Source "tools"
        New-Item -ItemType Directory -Path $Tools -Force | Out-Null

        @'
# Test uniquement : prouve que le script contenu dans le .nupkg est extractible.
exit 0
'@ | Set-Content -LiteralPath (Join-Path $Tools "chocolateyInstall.ps1") -Encoding UTF8

        $Zip = Join-Path $TestDrive "chocolatey.zip"
        Compress-Archive -Path (Join-Path $Source "*") -DestinationPath $Zip -Force
        $Nupkg = Join-Path $TestDrive "chocolatey.nupkg"
        Move-Item -LiteralPath $Zip -Destination $Nupkg -Force

        { Install-ChocolateyBootstrap -BootstrapPackagePath $Nupkg } | Should -Not -Throw
        Should -Invoke Test-ChocolateyAvailable -Times 3 -Exactly
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
    It "Utilise uniquement le cache en mode Offline" {
        Mock Test-ChocolateyAvailable { $true }
        Mock Get-Command { [pscustomobject]@{ Source = "choco.exe" } } -ParameterFilter { $Name -eq "choco.exe" }
        Mock Invoke-ChocolateyCli { [pscustomobject]@{ ExitCode = 0 } }

        $Cache = Join-Path $TestDrive "Chocolatey"
        New-Item -ItemType Directory -Path $Cache -Force | Out-Null
        New-Item -ItemType File -Path (Join-Path $Cache "firefox.1.0.0.nupkg") -Force | Out-Null
        $Context = [pscustomobject]@{ Workspace = [pscustomobject]@{ PackagesChocolatey = $Cache } }
        $Action = [pscustomobject]@{ Name = "firefox"; Version = "1.0.0"; Mode = "Offline" }

        $null = Invoke-ChocolateyPackage -Context $Context -Action $Action
        Should -Invoke Invoke-ChocolateyCli -Times 1 -Exactly -ParameterFilter { $Arguments -match "--source=$([regex]::Escape($Cache))$" }
    }

    It "Utilise Community en mode Online" {
        Mock Test-ChocolateyAvailable { $true }
        Mock Get-Command { [pscustomobject]@{ Source = "choco.exe" } } -ParameterFilter { $Name -eq "choco.exe" }
        Mock Invoke-ChocolateyCli { [pscustomobject]@{ ExitCode = 0 } }

        $Context = [pscustomobject]@{ Workspace = [pscustomobject]@{ PackagesChocolatey = (Join-Path $TestDrive "Chocolatey") } }
        $Action = [pscustomobject]@{ Name = "firefox"; Version = "1.0.0"; Mode = "Online" }

        $null = Invoke-ChocolateyPackage -Context $Context -Action $Action
        Should -Invoke Invoke-ChocolateyCli -Times 1 -Exactly -ParameterFilter { $Arguments -match "--source=https://community\.chocolatey\.org/api/v2/" }
    }

    It "Continue sur un échec lorsque FailurePolicy vaut Continue" {
        $Cache = Join-Path $TestDrive "Chocolatey"
        $Context = [pscustomobject]@{
            Workspace = [pscustomobject]@{
                PackagesChocolatey = $Cache
            }
        }
        $Catalog = Join-Path $TestDrive "Chocolatey.json"
        @{
            Packages = @(
                @{ Id = 'broken-package'; Enabled = $true; Mode = 'Online'; FailurePolicy = 'Continue' }
                @{ Id = 'next-package'; Enabled = $true; Mode = 'Online'; FailurePolicy = 'Continue' }
            )
        } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $Catalog -Encoding utf8

        $script:Calls = 0
        Mock Invoke-ChocolateyPackage {
            $script:Calls++
            if ($Action.Name -eq 'broken-package') {
                throw "checksum mismatch"
            }
            $Context
        }

        $Result = @(Invoke-ChocolateyCatalog -Context $Context -CatalogPath $Catalog -RuntimeCachePath $Cache)

        $Result.Count | Should -Be 2
        $Result[0].Status | Should -Be 'Failed'
        $Result[0].FailurePolicy | Should -Be 'Continue'
        $Result[1].Status | Should -Be 'Installed'
        $script:Calls | Should -Be 2
    }

    It "Arrête le catalogue sur un échec lorsque FailurePolicy vaut Stop" {
        $Cache = Join-Path $TestDrive "Chocolatey"
        $Context = [pscustomobject]@{
            Workspace = [pscustomobject]@{
                PackagesChocolatey = $Cache
            }
        }
        $Catalog = Join-Path $TestDrive "Chocolatey.json"
        @{
            Packages = @(
                @{ Id = 'broken-package'; Enabled = $true; Mode = 'Online'; FailurePolicy = 'Stop' }
                @{ Id = 'next-package'; Enabled = $true; Mode = 'Online'; FailurePolicy = 'Continue' }
            )
        } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $Catalog -Encoding utf8

        Mock Invoke-ChocolateyPackage { throw "checksum mismatch" }

        { Invoke-ChocolateyCatalog -Context $Context -CatalogPath $Catalog -RuntimeCachePath $Cache } |
            Should -Throw "*checksum mismatch*"
    }

}
