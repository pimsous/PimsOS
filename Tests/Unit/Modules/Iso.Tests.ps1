# ==========================================
# Tests : Iso
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Core\Core.ps1"
    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"
	. "$ProjectRoot\Modules\Infrastructure\Prerequisites.ps1"
    . "$ProjectRoot\Modules\Image\Iso.ps1"

}

Describe "Iso" {

    BeforeEach {

        Reset-Core
        Reset-Logger

        $script:Context = [pscustomobject]@{}

        # --------------------------------------------------
        # Environnement ISO de test
        # --------------------------------------------------

        $script:IsoFolder = Join-Path $TestDrive "ISO"

        New-Item `
            -ItemType Directory `
            -Path $script:IsoFolder `
            -Force |
            Out-Null

        # Get-IsoFile utilise Get-ProjectPath ISO.
        # On redirige donc le chemin ISO vers TestDrive.
        Mock Get-ProjectPath {

            param(
                [string]$Name
            )

            if ($Name -eq "ISO") {

                return $script:IsoFolder

            }

            throw "Get-ProjectPath non prévu dans ce test : $Name"
        }

    }

    Context "New-IsoMountState" {

        It "Retourne un objet IsoMountState" {

            $State = New-IsoMountState

            $State.ObjectType |
                Should -Be "IsoMountState"

        }

        It "Initialise Exists à False" {

            (New-IsoMountState).Exists |
                Should -BeFalse

        }

        It "Initialise Mounted à False" {

            (New-IsoMountState).Mounted |
                Should -BeFalse

        }

    }

    Context "Get-IsoFile" {

        It "Retourne les informations de l'ISO" {

            $IsoPath = Join-Path `
                $script:IsoFolder `
                "Win11_25H2_French_x64.iso"

            New-Item `
                -ItemType File `
                -Path $IsoPath `
                -Force |
                Out-Null

            $Iso = Get-IsoFile `
                -Context $script:Context

            $Iso |
                Should -Not -BeNullOrEmpty

            $Iso.Name |
                Should -Be "Win11_25H2_French_x64.iso"

            $Iso.FullName |
                Should -Be $IsoPath

        }

    }

    Context "Test-IsoFile" {

        It "Retourne un résultat de validation" {

            Mock Get-IsoFile {

                return [PSCustomObject]@{
                    Name      = "Test.iso"
                    FullName  = "C:\Test\Test.iso"
                    SizeGB    = 5.0
                    LastWrite = Get-Date
                }

            }

            $Result = Test-IsoFile `
                -Context $script:Context

            $Result |
                Should -Not -BeNullOrEmpty

            $Result.Success |
                Should -BeTrue

            $Result.Message |
                Should -Be "ISO valide."

        }

    }

    Context "Get-IsoInformation" {

        It "Retourne les informations principales" {

            $LastWrite = Get-Date

            Mock Get-IsoFile {

                return [PSCustomObject]@{
                    Name      = "Test.iso"
                    FullName  = "C:\Test\Test.iso"
                    SizeGB    = 5.0
                    LastWrite = $LastWrite
                }

            }

            $Info = Get-IsoInformation `
                -Context $script:Context

            $Info |
                Should -Not -BeNullOrEmpty

            $Info.Name |
                Should -Be "Test.iso"

            $Info.SizeGB |
                Should -Be 5.0

            $Info.LastWrite |
                Should -Be $LastWrite

        }

    }

    Context "Copy-IsoToWorkspace" {

        It "Retourne le chemin de destination" {

            Mock Write-Log {}

            Mock Get-Config {

                return [PSCustomObject]@{
                    Workspace = [PSCustomObject]@{
                        ISO = "Workspace\ISO"
                    }
                }

            }

            Mock Get-ProjectRoot {
                return $TestDrive
            }

            $IsoPath = Join-Path `
                $script:IsoFolder `
                "Win11_25H2_French_x64.iso"

            Set-Content `
                -Path $IsoPath `
                -Value "ISO TEST" `
                -Encoding UTF8

            $Destination = Copy-IsoToWorkspace `
                -Context $script:Context

            $ExpectedDestination = Join-Path `
                $TestDrive `
                "Workspace\ISO\Win11_25H2_French_x64.iso"

            $Destination |
                Should -Be $ExpectedDestination

            Test-Path $Destination |
                Should -BeTrue

            Get-Content $Destination |
                Should -Be "ISO TEST"

        }

    }

	# ==================================================
    # New-PimsOSIso
    # ==================================================

    Context "New-PimsOSIso" {

        BeforeEach {

            $script:IsoSource =
                Join-Path `
                    $TestDrive `
                    "ISOSource"

            $script:OutputPath =
                Join-Path `
                    $TestDrive `
                    "Output"

            New-Item `
                -ItemType Directory `
                -Path $script:IsoSource `
                -Force |
                Out-Null

            New-Item `
                -ItemType Directory `
                -Path $script:OutputPath `
                -Force |
                Out-Null

            # --------------------------------------------------
            # Arborescence de démarrage minimale
            # --------------------------------------------------

            $BootDirectory =
                Join-Path `
                    $script:IsoSource `
                    "boot"

            $EfiDirectory =
                Join-Path `
                    $script:IsoSource `
                    "efi\microsoft\boot"

            New-Item `
                -ItemType Directory `
                -Path $BootDirectory `
                -Force |
                Out-Null

            New-Item `
                -ItemType Directory `
                -Path $EfiDirectory `
                -Force |
                Out-Null

            Set-Content `
                -Path (
                    Join-Path `
                        $BootDirectory `
                        "etfsboot.com"
                ) `
                -Value "BIOS TEST" `
                -Encoding UTF8

            Set-Content `
                -Path (
                    Join-Path `
                        $EfiDirectory `
                        "efisys.bin"
                ) `
                -Value "UEFI TEST" `
                -Encoding UTF8

            # --------------------------------------------------
            # Contexte
            # --------------------------------------------------

            $script:Context = [pscustomobject]@{

                Project = [pscustomobject]@{
                    Version = "0.1.0"

                    Paths = [pscustomobject]@{
                        Output = $script:OutputPath
                    }
                }

                ISO = [pscustomobject]@{
                    OutputPath = $null
                    OutputName = $null
                    OutputSizeGB = $null
                }

            }

            Mock Write-Log {
            }

            Mock Get-ProjectRoot {
                return $TestDrive
            }

            Mock Get-Config {

                return [pscustomobject]@{

                    Workspace = [pscustomobject]@{
                        ISOSource = "ISOSource"
                    }

                }

            }

            Mock Get-PimsOSOsCdImgPath {

                return (
                    Join-Path `
                        $TestDrive `
                        "oscdimg.exe"
                )

            }

            # Faux oscdimg
            New-Item `
                -ItemType File `
                -Path (
                    Join-Path `
                        $TestDrive `
                        "oscdimg.exe"
                ) `
                -Force |
                Out-Null

        }


        It "Utilise Workspace.ISOSource comme source ISO" {

            Mock Get-PimsOSOsCdImgPath {

                return (
                    Join-Path `
                        $TestDrive `
                        "oscdimg.exe"
                )

            }

            Mock Get-Config {

                return [pscustomobject]@{

                    Workspace = [pscustomobject]@{
                        ISOSource = "ISOSource"
                    }

                }

            }

            $script:ReceivedArguments = $null

            # Remplace l'exécutable par un wrapper PowerShell
            $FakeOsCdImg =
                Join-Path `
                    $TestDrive `
                    "fake-oscdimg.ps1"

            @'
param(
    [Parameter(ValueFromRemainingArguments)]
    [string[]]$Arguments
)

$OutputPath = $Arguments[-1]

[System.IO.File]::WriteAllText(
    $OutputPath,
    "PimsOS ISO TEST"
)

exit 0
'@ |
                Set-Content `
                    -Path $FakeOsCdImg `
                    -Encoding UTF8

            Mock Get-PimsOSOsCdImgPath {
                return $FakeOsCdImg
            }

            $Result =
                New-PimsOSIso `
                    -Context $script:Context

            $Result |
                Should -Not -BeNullOrEmpty

            $Result.ISO.OutputPath |
                Should -Not -BeNullOrEmpty

            Test-Path `
                -LiteralPath $Result.ISO.OutputPath `
                -PathType Leaf |
                Should -BeTrue

        }


        It "Crée une ISO non vide lorsque oscdimg réussit" {

            $FakeOsCdImg =
                Join-Path `
                    $TestDrive `
                    "fake-oscdimg.ps1"

            @'
param(
    [Parameter(ValueFromRemainingArguments)]
    [string[]]$Arguments
)

$OutputPath = $Arguments[-1]

[System.IO.File]::WriteAllText(
    $OutputPath,
    "PimsOS ISO TEST"
)

exit 0
'@ |
                Set-Content `
                    -Path $FakeOsCdImg `
                    -Encoding UTF8

            Mock Get-PimsOSOsCdImgPath {
                return $FakeOsCdImg
            }

            $Result =
                New-PimsOSIso `
                    -Context $script:Context

            Test-Path `
                -LiteralPath $Result.ISO.OutputPath `
                -PathType Leaf |
                Should -BeTrue

            $File =
                Get-Item `
                    -LiteralPath $Result.ISO.OutputPath

            $File.Length |
                Should -BeGreaterThan 0

        }


        It "Refuse oscdimg introuvable" {

            Mock Get-PimsOSOsCdImgPath {

                return (
                    Join-Path `
                        $TestDrive `
                        "Missing\oscdimg.exe"
                )

            }

            {

                New-PimsOSIso `
                    -Context $script:Context

            } |
                Should -Throw "*oscdimg.exe est introuvable*"

        }


        It "Refuse une source ISO inexistante" {

            Mock Get-Config {

                return [pscustomobject]@{

                    Workspace = [pscustomobject]@{
                        ISOSource = "MissingISOSource"
                    }

                }

            }

            {

                New-PimsOSIso `
                    -Context $script:Context

            } |
                Should -Throw "*contenu source de l'ISO est introuvable*"

        }


        It "Refuse le fichier de démarrage BIOS absent" {

            Remove-Item `
                -LiteralPath (
                    Join-Path `
                        $script:IsoSource `
                        "boot\etfsboot.com"
                ) `
                -Force

            {

                New-PimsOSIso `
                    -Context $script:Context

            } |
                Should -Throw "*Fichier de démarrage BIOS introuvable*"

        }


        It "Refuse le fichier de démarrage UEFI absent" {

            Remove-Item `
                -LiteralPath (
                    Join-Path `
                        $script:IsoSource `
                        "efi\microsoft\boot\efisys.bin"
                ) `
                -Force

            {

                New-PimsOSIso `
                    -Context $script:Context

            } |
                Should -Throw "*Fichier de démarrage UEFI introuvable*"

        }


        It "Refuse un code retour oscdimg différent de zéro" {

            $FakeOsCdImg =
                Join-Path `
                    $TestDrive `
                    "fake-oscdimg.ps1"

            @'
exit 1
'@ |
                Set-Content `
                    -Path $FakeOsCdImg `
                    -Encoding UTF8

            Mock Get-PimsOSOsCdImgPath {
                return $FakeOsCdImg
            }

            {

                New-PimsOSIso `
                    -Context $script:Context

            } |
                Should -Throw "*oscdimg a échoué avec le code retour*"

        }


        It "Met à jour les informations ISO du contexte" {

            $FakeOsCdImg =
                Join-Path `
                    $TestDrive `
                    "fake-oscdimg.ps1"

            @'
param(
    [Parameter(ValueFromRemainingArguments)]
    [string[]]$Arguments
)

$OutputPath = $Arguments[-1]

[System.IO.File]::WriteAllText(
    $OutputPath,
    "PimsOS ISO TEST"
)

exit 0
'@ |
                Set-Content `
                    -Path $FakeOsCdImg `
                    -Encoding UTF8

            Mock Get-PimsOSOsCdImgPath {
                return $FakeOsCdImg
            }

            $Result =
                New-PimsOSIso `
                    -Context $script:Context

            $Result.ISO.OutputPath |
                Should -Be $script:Context.ISO.OutputPath

            $Result.ISO.OutputName |
                Should -Not -BeNullOrEmpty

            $Result.ISO.OutputSizeGB |
                Should -BeGreaterOrEqual 0

        }

    }

}
