BeforeAll {
    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path
    Import-Module "$ProjectRoot\Modules\PimsOS.psd1" -Force
    . "$ProjectRoot\Modules\Package\ChocolateyCatalog.ps1"
}

Describe "Chocolatey Catalog" {
    BeforeEach {
        $Root = Join-Path $TestDrive 'PimsOS'
        New-Item -ItemType Directory -Path (Join-Path $Root 'Config\Packages') -Force | Out-Null
        $Catalog = [ordered]@{
            Provider='Chocolatey'; Version='1.0'; Description='Test'
            Packages=@(
                [ordered]@{Id='chocolatey';Enabled=$true;Category='Chocolatey';Mode='Offline';Version=$null},
                [ordered]@{Id='vlc';Enabled=$true;Category='Media';Mode='Online';Version='3.0.23'}
            )
        }
        $Catalog | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $Root 'Config\Packages\Chocolatey.json') -Encoding utf8
        Mock Write-Log {}
        $Context = [pscustomobject]@{ Project = [pscustomobject]@{ Root = $Root } }
    }

    It "ajoute un package Online" {
        Add-ChocolateyCatalogPackage -Context $Context -Id '7zip' -Version '25.01' -Mode Online -Category 'Tools' | Out-Null
        (Read-ChocolateyCatalog -Context $Context).Packages.Id | Should -Contain '7zip'
    }

    It "ajoute un package Offline" {
        Add-ChocolateyCatalogPackage -Context $Context -Id 'keepass.install' -Mode Offline | Out-Null
        $p = @((Read-ChocolateyCatalog -Context $Context).Packages | Where-Object Id -eq 'keepass.install')[0]
        $p.Mode | Should -Be 'Offline'
        $p.Enabled | Should -BeTrue
    }

    It "refuse un doublon" {
        { Add-ChocolateyCatalogPackage -Context $Context -Id 'vlc' } | Should -Throw '*existe déjà*'
    }

    It "refuse de supprimer chocolatey" {
        { Remove-ChocolateyCatalogPackage -Context $Context -Id 'chocolatey' } | Should -Throw '*obligatoire*'
    }

    It "supprime un package existant" {
        Remove-ChocolateyCatalogPackage -Context $Context -Id 'vlc' | Should -BeTrue
        (Read-ChocolateyCatalog -Context $Context).Packages.Id | Should -Not -Contain 'vlc'
    }

    It "refuse un identifiant invalide" {
        { Add-ChocolateyCatalogPackage -Context $Context -Id 'Bad Package!' } | Should -Throw '*invalide*'
    }
}
