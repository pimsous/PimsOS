# ==========================================
# Module : PostInstall DeploymentValidation
# Projet : PimsOS Builder
# Version : 1.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

function Test-PostInstallDeployment {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]$PostInstallPath,

        [Parameter(Mandatory)]
        [string]$UnattendPath

    )

    $RequiredFiles = @(
		"Bootstrap.ps1"
		"Logger.ps1"
		"Network.ps1"
		"UI.ps1"
		"DriverCheck.ps1"
		"PostInstall.ps1"
		"State.ps1"
        "Chocolatey.ps1"
        "Finalize.ps1"
	)

    $MissingFiles = @()

    foreach ($File in $RequiredFiles) {

        $Path = Join-Path `
            -Path $PostInstallPath `
            -ChildPath $File

        if (-not (Test-Path `
            -LiteralPath $Path `
            -PathType Leaf)) {

            $MissingFiles += $File

        }

    }

    $UnattendExists = Test-Path `
        -LiteralPath $UnattendPath `
        -PathType Leaf

    $XmlValid = $false
    $FirstLogonCommands = $false
    $BootstrapReferenced = $false
    $RunOnceReferenced = $false
    $BootstrapLoadsDriverCheck = $false
    $BootstrapLoadsChocolatey = $false
    $BootstrapLoadsFinalize = $false

    if ($UnattendExists) {

        try {

            [xml]$Xml = Get-Content `
                -LiteralPath $UnattendPath `
                -Raw `
                -Encoding UTF8

            $XmlValid = $true

            $NamespaceManager =
                New-Object System.Xml.XmlNamespaceManager(
                    $Xml.NameTable
                )

            $NamespaceManager.AddNamespace(
                "u",
                "urn:schemas-microsoft-com:unattend"
            )

            $FirstLogonNode =
                $Xml.SelectNodes(
                    "//u:FirstLogonCommands",
                    $NamespaceManager
                )

            if ($FirstLogonNode.Count -gt 0) {

                $FirstLogonCommands = $true

            }

            $CommandNodes =
                $Xml.SelectNodes(
                    "//u:FirstLogonCommands/u:SynchronousCommand",
                    $NamespaceManager
                )

            foreach ($Command in $CommandNodes) {

                if (
                    $Command.CommandLine -match
                    "Bootstrap\.ps1"
                ) {

                    $BootstrapReferenced = $true

                }

            }

            $XmlText = $Xml.OuterXml

            if (
                $XmlText -match
                "CurrentVersion\\RunOnce"
            ) {

                $RunOnceReferenced = $true

            }

        }
        catch {

            $XmlValid = $false

        }

    }

    $BootstrapPath = Join-Path -Path $PostInstallPath -ChildPath "Bootstrap.ps1"

    if (Test-Path -LiteralPath $BootstrapPath -PathType Leaf) {

        try {

            $BootstrapText = Get-Content -LiteralPath $BootstrapPath -Raw -ErrorAction Stop
            $BootstrapLoadsDriverCheck = $BootstrapText -match '(?i)DriverCheck\.ps1'
            $BootstrapLoadsChocolatey = $BootstrapText -match '(?i)Chocolatey\.ps1'
            $BootstrapLoadsFinalize = $BootstrapText -match '(?i)Finalize\.ps1'

        }
        catch {

            $BootstrapLoadsDriverCheck = $false
            $BootstrapLoadsChocolatey = $false
            $BootstrapLoadsFinalize = $false

        }

    }

    $Success = (
        $MissingFiles.Count -eq 0 -and
        $UnattendExists -and
        $XmlValid -and
        $FirstLogonCommands -and
        $BootstrapReferenced -and
        -not $RunOnceReferenced -and
        $BootstrapLoadsDriverCheck -and
        $BootstrapLoadsChocolatey -and
        $BootstrapLoadsFinalize
    )

    return [pscustomobject]@{

        Success              = $Success
        MissingFiles         = @($MissingFiles)
        UnattendExists       = $UnattendExists
        XmlValid             = $XmlValid
        FirstLogonCommands   = $FirstLogonCommands
        BootstrapReferenced  = $BootstrapReferenced
        RunOnceReferenced      = $RunOnceReferenced
        BootstrapLoadsDriverCheck = $BootstrapLoadsDriverCheck
        BootstrapLoadsChocolatey  = $BootstrapLoadsChocolatey
        BootstrapLoadsFinalize    = $BootstrapLoadsFinalize

    }

}
