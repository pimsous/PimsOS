# ==========================================
# Tests : PostInstall Bootstrap
# Projet : PimsOS Builder
# ==========================================

BeforeAll {
    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path
    . "$ProjectRoot\Modules\PostInstall\DeploymentValidation.ps1"
}

Describe "PostInstall deployment validation" {

    It "Exige que Bootstrap charge DriverCheck et Chocolatey" {
        $Runtime = Join-Path $TestDrive "PostInstall"
        New-Item -ItemType Directory -Path $Runtime -Force | Out-Null
        @(
            'DriverCheck.ps1'
            'Chocolatey.ps1'
            'Bootstrap.ps1'
            'Logger.ps1'
            'Network.ps1'
            'UI.ps1'
            'PostInstall.ps1'
            'State.ps1'
            'Finalize.ps1'
        ) | ForEach-Object { New-Item -ItemType File -Path (Join-Path $Runtime $_) -Force | Out-Null }

        Set-Content -LiteralPath (Join-Path $Runtime 'Bootstrap.ps1') -Value @'
. "$PSScriptRoot\DriverCheck.ps1"
. "$PSScriptRoot\Chocolatey.ps1"
. "$PSScriptRoot\Finalize.ps1"
'@ -Encoding utf8

        $Unattend = Join-Path $TestDrive 'unattend.xml'
        Set-Content -LiteralPath $Unattend -Value @'
<unattend xmlns="urn:schemas-microsoft-com:unattend"><settings pass="oobeSystem"><component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"><FirstLogonCommands><SynchronousCommand xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" wcm:action="add"><Order>1</Order><CommandLine>powershell.exe -File "C:\ProgramData\PimsOS\PostInstall\Bootstrap.ps1"</CommandLine></SynchronousCommand></FirstLogonCommands></component></settings></unattend>
'@ -Encoding utf8

        $Result = Test-PostInstallDeployment -PostInstallPath $Runtime -UnattendPath $Unattend

        $Result.Success | Should -BeTrue
        $Result.BootstrapLoadsDriverCheck | Should -BeTrue
        $Result.BootstrapLoadsChocolatey | Should -BeTrue
        $Result.BootstrapLoadsFinalize | Should -BeTrue
    }
}
