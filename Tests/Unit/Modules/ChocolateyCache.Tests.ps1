# ==========================================
# Tests : Chocolatey cache
# Projet : PimsOS Builder
# ==========================================

BeforeAll {
    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"
    . "$ProjectRoot\Modules\Package\Chocolatey.ps1"
    . "$ProjectRoot\Modules\Package\ChocolateyCache.ps1"
}

Describe "Chocolatey cache" {

    BeforeEach {
        Reset-Logger
        Mock Write-Log {}
    }

    It "Charge uniquement les packages activés" {
        $Catalog = Join-Path $TestDrive "Chocolatey.json"

        @{
            Provider = 'Chocolatey'
            Version = '1.0'
            Packages = @(
                @{ Id = 'firefox'; Enabled = $true }
                @{ Id = 'vlc'; Enabled = $false }
            )
        } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $Catalog -Encoding utf8

        $Result = @(Get-ChocolateyPackageDefinitions -Path $Catalog)

        $Result.Count | Should -Be 1
        $Result[0].Id | Should -Be 'firefox'
    }

    It "Refuse une entrée activée sans Id" {
        $Catalog = Join-Path $TestDrive "Chocolatey.json"

        @{
            Packages = @(
                @{ Enabled = $true }
            )
        } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $Catalog -Encoding utf8

        { Get-ChocolateyPackageDefinitions -Path $Catalog } |
            Should -Throw "*ne possède pas d'Id*"
    }

    It "Détecte un package déjà présent et ne le télécharge pas" {
        $Cache = Join-Path $TestDrive "Chocolatey"
        New-Item -ItemType Directory -Path $Cache -Force | Out-Null
        $Existing = Join-Path $Cache "cached-firefox.1.0.0.nupkg"
        New-Item -ItemType File -Path $Existing -Force | Out-Null

        Mock Invoke-WebRequest { throw 'Le téléchargement ne doit pas être appelé.' }

        $Package = [pscustomobject]@{
            Id = 'cached-firefox'
			Enabled = $true
			Version = '1.0.0'
        }

        $Result = Save-ChocolateyPackageToCache `
            -Package $Package `
            -CachePath $Cache

        $Result.Status | Should -Be 'Cached'
        $Result.Downloaded | Should -BeFalse
        $Result.Path | Should -Be $Existing
        Should -Invoke Invoke-WebRequest -Times 0 -Exactly
    }


    It "Télécharge un package absent dans le cache" {
        $Cache = Join-Path $TestDrive "Chocolatey"
        $Package = [pscustomobject]@{
            Id = 'download-firefox'
			Enabled = $true
			Version = '1.0.0'
        }

        Mock Invoke-WebRequest {
            New-Item -ItemType File -Path $OutFile -Force | Out-Null
        }

        $Result = Save-ChocolateyPackageToCache `
            -Package $Package `
            -CachePath $Cache `
            -Source 'https://example.test/api/v2/package'

        $Result.Status | Should -Be 'Downloaded'
        $Result.Downloaded | Should -BeTrue
        Test-Path $Result.Path | Should -BeTrue

        Should -Invoke Invoke-WebRequest -Times 1 -Exactly -ParameterFilter {
            $Uri -eq 'https://example.test/api/v2/package/download-firefox/1.0.0'
        }
    }

    It "Prépare tout le catalogue et réutilise le cache" {
        $Catalog = Join-Path $TestDrive "Chocolatey.json"
        $Cache = Join-Path $TestDrive "Chocolatey"

        @{
            Packages = @(
                @{ Id = 'cache-firefox'; Enabled = $true; Version = '1.0.0' }
				@{ Id = 'cache-vlc';     Enabled = $true; Version = '2.0.0' }
            )
        } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $Catalog -Encoding utf8

        $Context = [pscustomobject]@{
            Workspace = [pscustomobject]@{
                PackagesChocolatey = $Cache
            }
        }

        Mock Invoke-WebRequest {
            New-Item -ItemType File -Path $OutFile -Force | Out-Null
        }

        $Result = Initialize-ChocolateyCache `
            -Context $Context `
            -CatalogPath $Catalog

        $Result.Total | Should -Be 2
        $Result.Downloaded | Should -Be 2
        $Result.AlreadyCached | Should -Be 0
        Should -Invoke Invoke-WebRequest -Times 2 -Exactly
    }

    It "Ne retélécharge pas un package déjà en cache lors d'une seconde préparation" {
        $Catalog = Join-Path $TestDrive "Chocolatey.json"
        $Cache = Join-Path $TestDrive "Chocolatey"

        @{
            Packages = @(
                @{ Id = 'cache-second-firefox'; Enabled = $true; Version = '1.0.0' }
            )
        } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $Catalog -Encoding utf8

        $Context = [pscustomobject]@{
            Workspace = [pscustomobject]@{
                PackagesChocolatey = $Cache
            }
        }

        Mock Invoke-WebRequest {
            New-Item -ItemType File -Path $OutFile -Force | Out-Null
        }

        $First = Initialize-ChocolateyCache -Context $Context -CatalogPath $Catalog
        $Second = Initialize-ChocolateyCache -Context $Context -CatalogPath $Catalog

        $First.Downloaded | Should -Be 1
        $Second.Downloaded | Should -Be 0
        $Second.AlreadyCached | Should -Be 1
        Should -Invoke Invoke-WebRequest -Times 1 -Exactly
    }
}
