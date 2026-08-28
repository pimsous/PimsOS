# ==========================================
# Tests : Infrastructure Prerequisites
# Projet : PimsOS Builder
# ==========================================

Describe "PimsOS Prerequisites" {

    BeforeAll {

        $ProjectRoot = (
            Resolve-Path "$PSScriptRoot\..\..\..\.."
        ).Path

        . "$ProjectRoot\Modules\Infrastructure\Prerequisites.ps1"

    }


    Context "Get-PimsOSOsCdImgPath" {

        It "Retourne null si oscdimg est absent" {

            Mock Get-Command {
                return $null
            }

            Mock Get-ChildItem {
                return @()
            }

            $Result = Get-PimsOSOsCdImgPath

            $Result |
                Should -BeNullOrEmpty

        }

    }


    Context "Test-PimsOSWindowsADK" {

        It "Indique que l'ADK est installé lorsque oscdimg existe" {

            Mock Get-PimsOSOsCdImgPath {
                return "C:\ADK\oscdimg.exe"
            }

            $Result = Test-PimsOSWindowsADK

            $Result.Installed |
                Should -BeTrue

            $Result.OsCdImgPath |
                Should -Be "C:\ADK\oscdimg.exe"

        }


        It "Indique que l'ADK est absent lorsque oscdimg est introuvable" {

            Mock Get-PimsOSOsCdImgPath {
                return $null
            }

            $Result = Test-PimsOSWindowsADK

            $Result.Installed |
                Should -BeFalse

            $Result.OsCdImgPath |
                Should -BeNullOrEmpty

        }

    }


    Context "Get-PimsOSADKSetupPath" {

        It "Retourne null si ADKSetup.exe est absent" {

            Mock Test-Path {
                return $false
            }

            $Result = Get-PimsOSADKSetupPath

            $Result |
                Should -BeNullOrEmpty

        }

    }


    Context "Install-PimsOSWindowsADK" {

        It "Ne réinstalle pas un ADK déjà disponible" {

            Mock Test-PimsOSWindowsADK {
                return [pscustomobject]@{
                    Installed   = $true
                    OsCdImgPath = "C:\ADK\oscdimg.exe"
                }
            }

            $Result = Install-PimsOSWindowsADK

            $Result.Installed |
                Should -BeTrue

            $Result.OsCdImgPath |
                Should -Be "C:\ADK\oscdimg.exe"

        }


        It "Refuse une installation sans ADKSetup.exe" {

            Mock Test-PimsOSWindowsADK {
                return [pscustomobject]@{
                    Installed   = $false
                    OsCdImgPath = $null
                }
            }

            Mock Get-PimsOSADKSetupPath {
                return $null
            }

            {

                Install-PimsOSWindowsADK

            } |
                Should -Throw "*Windows ADK introuvable*"

        }
		
		It "Utilise la configuration Windows ADK fournie" {

            $script:AdkCheckCount = 0

            Mock Test-PimsOSWindowsADK {

                $script:AdkCheckCount++

                if ($script:AdkCheckCount -eq 1) {

                    return [pscustomobject]@{
                        Installed   = $false
                        OsCdImgPath = $null
                    }

                }

                return [pscustomobject]@{
                    Installed   = $true
                    OsCdImgPath = "C:\PimsOS\ADK\oscdimg.exe"
                }

            }

            Mock Get-PimsOSADKSetupPath {
                return "C:\ADK\ADKSetup.exe"
            }

            Mock Test-Path {
                return $true
            }

            Mock Start-Process {
                return [pscustomobject]@{
                    ExitCode = 0
                }
            }


            $Configuration = [pscustomobject]@{

                Requirements = [pscustomobject]@{

                    WindowsADK = [pscustomobject]@{

                        Required         = $true
                        Version          = "10.1.26100.2454"
                        DownloadUrl      = "https://example.invalid/adksetup.exe"
                        InstallPath      = "C:\PimsOS\ADK"
                        Feature          = "OptionId.DeploymentTools"
                        DownloadFileName = "adksetup.exe"
                        Sha256           = $null

                    }

                }

            }


            $Result = Install-PimsOSWindowsADK `
                -Configuration $Configuration


            $Result.Installed |
                Should -BeTrue


            $Result.OsCdImgPath |
                Should -Be "C:\PimsOS\ADK\oscdimg.exe"


            Should -Invoke Start-Process `
                -Times 1 `
                -Exactly `
                -ParameterFilter {

                    $ArgumentList -contains "/quiet" -and
                    $ArgumentList -contains "/installpath" -and
                    $ArgumentList -contains "C:\PimsOS\ADK" -and
                    $ArgumentList -contains "/features" -and
                    $ArgumentList -contains "OptionId.DeploymentTools"

                }

        }
		
		It "Télécharge le programme d'installation lorsqu'il est absent" {

            Mock Test-PimsOSWindowsADK {

                return [pscustomobject]@{

                    Installed   = $false
                    OsCdImgPath = $null

                }

            }

            Mock Get-PimsOSADKSetupPath {

                return $null

            }

            Mock Get-PimsOSWindowsADKInstaller {

                return "C:\Temp\adksetup.exe"

            }

            # Install-PimsOSWindowsADK utilise le Workspace du contexte
            # lorsque DestinationPath n'est pas fourni.
            $Context = [pscustomobject]@{

                Workspace = [pscustomobject]@{

                    Temp = $TestDrive

                }

            }

            $Configuration = [pscustomobject]@{

                Requirements = [pscustomobject]@{

                    WindowsADK = [pscustomobject]@{

                        Required         = $true
                        Version          = "10.1.26100.2454"
                        DownloadUrl      = "https://example.invalid/adksetup.exe"
                        InstallPath      = "C:\PimsOS\ADK"
                        Feature          = "OptionId.DeploymentTools"
                        DownloadFileName = "adksetup.exe"
                        Sha256           = $null

                    }

                }

            }

            Mock Test-Path {

                return $true

            }

            Mock Start-Process {

                return [pscustomobject]@{

                    ExitCode = 0

                }

            }

            $script:AdkCheckCount = 0

            Mock Test-PimsOSWindowsADK {

                $script:AdkCheckCount++

                if ($script:AdkCheckCount -eq 1) {

                    return [pscustomobject]@{

                        Installed   = $false
                        OsCdImgPath = $null

                    }

                }

                return [pscustomobject]@{

                    Installed   = $true
                    OsCdImgPath = "C:\PimsOS\ADK\oscdimg.exe"

                }

            }

            $Result = Install-PimsOSWindowsADK `
                -Configuration $Configuration

            $Result.Installed |
                Should -BeTrue

            $Result.OsCdImgPath |
                Should -Be "C:\PimsOS\ADK\oscdimg.exe"

            Should -Invoke Get-PimsOSWindowsADKInstaller `
                -Times 1 `
                -Exactly

            Should -Invoke Start-Process `
                -Times 1 `
                -Exactly

        }
    }
	
	Context "Configuration Windows ADK" {

        It "Lit la configuration Windows ADK" {

            $Configuration = [pscustomobject]@{

                Requirements = [pscustomobject]@{

                    WindowsADK = [pscustomobject]@{

                        Required         = $true
                        Version          = "10.1.26100.2454"
                        DownloadUrl      = "https://example.invalid/adksetup.exe"
                        InstallPath      = "C:\Program Files (x86)\Windows Kits\10"
                        Feature          = "OptionId.DeploymentTools"
                        DownloadFileName = "adksetup.exe"
                        Sha256           = $null

                    }

                }

            }


            $Adk = $Configuration.Requirements.WindowsADK


            $Adk.Required |
                Should -BeTrue

            $Adk.Version |
                Should -Be "10.1.26100.2454"

            $Adk.Feature |
                Should -Be "OptionId.DeploymentTools"

        }

    }
	
	Context "Get-PimsOSWindowsADKInstaller" {

        It "Refuse une configuration null" {

            {

                Get-PimsOSWindowsADKInstaller `
                    -Configuration $null `
                    -DestinationPath $TestDrive

            } |
                Should -Throw "*Cannot bind argument to parameter 'Configuration'*"

        }


        It "Refuse une configuration sans WindowsADK" {

            $Configuration = [pscustomobject]@{

                Requirements = [pscustomobject]@{}

            }


            {

                Get-PimsOSWindowsADKInstaller `
                    -Configuration $Configuration `
                    -DestinationPath $TestDrive

            } |
                Should -Throw "*Requirements.WindowsADK*"

        }


        It "Refuse une URL de téléchargement absente" {

            $Configuration = [pscustomobject]@{

                Requirements = [pscustomobject]@{

                    WindowsADK = [pscustomobject]@{

                        DownloadUrl = $null

                    }

                }

            }


            {

                Get-PimsOSWindowsADKInstaller `
                    -Configuration $Configuration `
                    -DestinationPath $TestDrive

            } |
                Should -Throw "*URL de téléchargement Windows ADK*"

        }


        It "Crée le dossier destination" {

            $Configuration = [pscustomobject]@{

                Requirements = [pscustomobject]@{

                    WindowsADK = [pscustomobject]@{

                        DownloadUrl      = "https://example.invalid/adksetup.exe"
                        DownloadFileName = "adksetup.exe"

                    }

                }

            }


            $Destination =
                Join-Path `
                    $TestDrive `
                    "ADKDownload"


            Mock Invoke-WebRequest {

                New-Item `
                    -ItemType File `
                    -Path (
                        Join-Path `
                            $Destination `
                            "adksetup.exe"
                    ) `
                    -Force |
                    Out-Null

            }


            $Result =
                Get-PimsOSWindowsADKInstaller `
                    -Configuration $Configuration `
                    -DestinationPath $Destination


            Test-Path `
                -LiteralPath $Destination `
                -PathType Container |
                Should -BeTrue


            $Result |
                Should -Be (
                    Join-Path `
                        $Destination `
                        "adksetup.exe"
                )

        }


        It "Retourne le fichier déjà présent sans téléchargement" {

            $Configuration = [pscustomobject]@{

                Requirements = [pscustomobject]@{

                    WindowsADK = [pscustomobject]@{

                        DownloadUrl      = "https://example.invalid/adksetup.exe"
                        DownloadFileName = "adksetup.exe"

                    }

                }

            }


            $Destination =
                Join-Path `
                    $TestDrive `
                    "Existing"


            New-Item `
                -ItemType Directory `
                -Path $Destination `
                -Force |
                Out-Null


            $Installer =
                Join-Path `
                    $Destination `
                    "adksetup.exe"


            New-Item `
                -ItemType File `
                -Path $Installer `
                -Force |
                Out-Null


            Mock Invoke-WebRequest {

                throw "Invoke-WebRequest ne doit pas être appelé."

            }


            $Result =
                Get-PimsOSWindowsADKInstaller `
                    -Configuration $Configuration `
                    -DestinationPath $Destination


            $Result |
                Should -Be $Installer


            Should -Invoke Invoke-WebRequest `
                -Times 0 `
                -Exactly

        }
		
		It "Vérifie le SHA-256 du fichier téléchargé" {

            $Configuration = [pscustomobject]@{

                Requirements = [pscustomobject]@{

                    WindowsADK = [pscustomobject]@{

                        DownloadUrl      = "https://example.invalid/adksetup.exe"
                        DownloadFileName = "adksetup.exe"
                        Sha256           = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"

                    }

                }

            }


            $Destination =
                Join-Path `
                    $TestDrive `
                    "Downloaded"


            Mock Invoke-WebRequest {

                New-Item `
                    -ItemType File `
                    -Path (
                        Join-Path `
                            $Destination `
                            "adksetup.exe"
                    ) `
                    -Force |
                    Out-Null

            }


            Mock Test-PimsOSFileHash {

                return [pscustomobject]@{

                    Valid    = $true
                    Verified = $true
                    Hash     = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
                    Expected = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
                    Path     = (
                        Join-Path `
                            $Destination `
                            "adksetup.exe"
                    )

                }

            }


            $Result =
                Get-PimsOSWindowsADKInstaller `
                    -Configuration $Configuration `
                    -DestinationPath $Destination


            $Result |
                Should -Be (
                    Join-Path `
                        $Destination `
                        "adksetup.exe"
                )


            Should -Invoke Test-PimsOSFileHash `
                -Times 1 `
                -Exactly

        }


        It "Refuse un fichier téléchargé dont le SHA-256 est incorrect" {

            $Configuration = [pscustomobject]@{

                Requirements = [pscustomobject]@{

                    WindowsADK = [pscustomobject]@{

                        DownloadUrl      = "https://example.invalid/adksetup.exe"
                        DownloadFileName = "adksetup.exe"
                        Sha256           = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"

                    }

                }

            }


            $Destination =
                Join-Path `
                    $TestDrive `
                    "InvalidHash"


            Mock Invoke-WebRequest {

                New-Item `
                    -ItemType File `
                    -Path (
                        Join-Path `
                            $Destination `
                            "adksetup.exe"
                    ) `
                    -Force |
                    Out-Null

            }


            Mock Test-PimsOSFileHash {

                return [pscustomobject]@{

                    Valid    = $false
                    Verified = $true
                    Hash     = "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB"
                    Expected = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
                    Path     = (
                        Join-Path `
                            $Destination `
                            "adksetup.exe"
                    )

                }

            }


            {

                Get-PimsOSWindowsADKInstaller `
                    -Configuration $Configuration `
                    -DestinationPath $Destination

            } |
                Should -Throw "*vérification SHA-256 de Windows ADK a échoué*"


            Test-Path `
                -LiteralPath (
                    Join-Path `
                        $Destination `
                        "adksetup.exe"
                ) |
                Should -BeFalse

        }
    }
	
	Context "Test-PimsOSFileHash" {

        It "Refuse un fichier inexistant" {

            {

                Test-PimsOSFileHash `
                    -Path "$TestDrive\missing.exe"

            } |
                Should -Throw "*Fichier introuvable pour vérification SHA-256*"

        }


        It "Calcule le SHA-256 sans hash attendu" {

            $FilePath =
                Join-Path `
                    $TestDrive `
                    "test.bin"


            [System.IO.File]::WriteAllText(
                $FilePath,
                "PimsOS SHA256 test"
            )


            $Result =
                Test-PimsOSFileHash `
                    -Path $FilePath


            $Result.Valid |
                Should -BeTrue

            $Result.Verified |
                Should -BeFalse

            $Result.Hash |
                Should -Match '^[A-F0-9]{64}$'

            $Result.Expected |
                Should -BeNullOrEmpty

        }


        It "Valide un SHA-256 correct" {

            $FilePath =
                Join-Path `
                    $TestDrive `
                    "test.bin"


            [System.IO.File]::WriteAllText(
                $FilePath,
                "PimsOS SHA256 test"
            )


            $ActualHash =
                (
                    Get-FileHash `
                        -LiteralPath $FilePath `
                        -Algorithm SHA256
                ).Hash


            $Result =
                Test-PimsOSFileHash `
                    -Path $FilePath `
                    -ExpectedHash $ActualHash.ToLowerInvariant()


            $Result.Valid |
                Should -BeTrue

            $Result.Verified |
                Should -BeTrue

            $Result.Hash |
                Should -Be $ActualHash.ToUpperInvariant()

            $Result.Expected |
                Should -Be $ActualHash.ToUpperInvariant()

        }


        It "Détecte un SHA-256 incorrect" {

            $FilePath =
                Join-Path `
                    $TestDrive `
                    "test.bin"


            [System.IO.File]::WriteAllText(
                $FilePath,
                "PimsOS SHA256 test"
            )


            $WrongHash =
                "0000000000000000000000000000000000000000000000000000000000000000"


            $Result =
                Test-PimsOSFileHash `
                    -Path $FilePath `
                    -ExpectedHash $WrongHash


            $Result.Valid |
                Should -BeFalse

            $Result.Verified |
                Should -BeTrue

        }


        It "Refuse un SHA-256 configuré avec un format invalide" {

            $FilePath =
                Join-Path `
                    $TestDrive `
                    "test.bin"


            [System.IO.File]::WriteAllText(
                $FilePath,
                "PimsOS SHA256 test"
            )


            {

                Test-PimsOSFileHash `
                    -Path $FilePath `
                    -ExpectedHash "ABC123"

            } |
                Should -Throw "*SHA-256 configuré est invalide*"

        }

    }
}