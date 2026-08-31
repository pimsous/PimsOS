# ==========================================
# Tests : PostInstall DeploymentValidation
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..\..").Path

    . "$ProjectRoot\Modules\PostInstall\DeploymentValidation.ps1"

}

Describe "PostInstall DeploymentValidation" {

    BeforeEach {

        $script:PostInstallPath = Join-Path $TestDrive "PostInstall"
        $script:UnattendPath = Join-Path $TestDrive "unattend.xml"

        New-Item -ItemType Directory -Path $script:PostInstallPath -Force | Out-Null

        @(
			"Bootstrap.ps1"
			"Logger.ps1"
			"Network.ps1"
			"UI.ps1"
			"DriverCheck.ps1"
			"PostInstall.ps1"
			"State.ps1"
		) | ForEach-Object {

            New-Item -ItemType File -Path (Join-Path $script:PostInstallPath $_) -Force | Out-Null

        }

    }

    It "Valide un déploiement PostInstall complet" {

        $Xml = '<unattend xmlns="urn:schemas-microsoft-com:unattend"><settings pass="oobeSystem"><component name="Microsoft-Windows-Shell-Setup"><FirstLogonCommands><SynchronousCommand><Order>1</Order><CommandLine>powershell.exe -File "C:\ProgramData\PimsOS\PostInstall\Bootstrap.ps1"</CommandLine><Description>PimsOS Bootstrap</Description></SynchronousCommand></FirstLogonCommands></component></settings></unattend>'

        Set-Content -LiteralPath $script:UnattendPath -Value $Xml -Encoding UTF8

        $Result = Test-PostInstallDeployment -PostInstallPath $script:PostInstallPath -UnattendPath $script:UnattendPath

        $Result.Success | Should -BeTrue
        $Result.MissingFiles | Should -HaveCount 0
        $Result.UnattendExists | Should -BeTrue
        $Result.XmlValid | Should -BeTrue
        $Result.FirstLogonCommands | Should -BeTrue
        $Result.BootstrapReferenced | Should -BeTrue
        $Result.RunOnceReferenced | Should -BeFalse

    }

    It "Détecte un script PostInstall manquant" {

        Remove-Item -LiteralPath (Join-Path $script:PostInstallPath "DriverCheck.ps1")

        $Xml = '<unattend xmlns="urn:schemas-microsoft-com:unattend"><settings pass="oobeSystem"><component name="Microsoft-Windows-Shell-Setup"><FirstLogonCommands><SynchronousCommand><Order>1</Order><CommandLine>powershell.exe -File "C:\ProgramData\PimsOS\PostInstall\Bootstrap.ps1"</CommandLine></SynchronousCommand></FirstLogonCommands></component></settings></unattend>'

        Set-Content -LiteralPath $script:UnattendPath -Value $Xml -Encoding UTF8

        $Result = Test-PostInstallDeployment -PostInstallPath $script:PostInstallPath -UnattendPath $script:UnattendPath

        $Result.Success | Should -BeFalse
        $Result.MissingFiles | Should -Contain "DriverCheck.ps1"

    }

    It "Détecte un unattend.xml absent" {

		Remove-Item `
			-LiteralPath $script:UnattendPath `
			-Force `
			-ErrorAction SilentlyContinue

		$Result = Test-PostInstallDeployment `
			-PostInstallPath $script:PostInstallPath `
			-UnattendPath $script:UnattendPath

		$Result.Success |
			Should -BeFalse

		$Result.UnattendExists |
			Should -BeFalse

	}

    It "Détecte un XML invalide" {

        Set-Content -LiteralPath $script:UnattendPath -Value "<unattend>" -Encoding UTF8

        $Result = Test-PostInstallDeployment -PostInstallPath $script:PostInstallPath -UnattendPath $script:UnattendPath

        $Result.Success | Should -BeFalse
        $Result.XmlValid | Should -BeFalse

    }

    It "Détecte l'absence de FirstLogonCommands" {

        $Xml = '<unattend xmlns="urn:schemas-microsoft-com:unattend"><settings pass="oobeSystem"></settings></unattend>'

        Set-Content -LiteralPath $script:UnattendPath -Value $Xml -Encoding UTF8

        $Result = Test-PostInstallDeployment -PostInstallPath $script:PostInstallPath -UnattendPath $script:UnattendPath

        $Result.Success | Should -BeFalse
        $Result.FirstLogonCommands | Should -BeFalse

    }

}
