# ==========================================
# Tests : Registry
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"

    function global:Assert-Administrator {
        return
    }

    . "$ProjectRoot\Modules\Windows\Registry.ps1"

}

Describe "Registry" {

    BeforeEach {

        Reset-Logger

        Mock Write-Log {}

    }


    # ==================================================
    # Resolve-RegistryHive
    # ==================================================

    Context "Resolve-RegistryHive" {

        It "Retourne le chemin SOFTWARE" {

            Resolve-RegistryHive `
                -Hive "SOFTWARE" |
                Should -Be "HKLM:\PimsOS_SOFTWARE"

        }

        It "Retourne le chemin SYSTEM" {

            Resolve-RegistryHive `
                -Hive "SYSTEM" |
                Should -Be "HKLM:\PimsOS_SYSTEM"

        }

        It "Retourne le chemin DEFAULT" {

            Resolve-RegistryHive `
                -Hive "DEFAULT" |
                Should -Be "HKLM:\PimsOS_DEFAULT"

        }

        It "Retourne le chemin NTUSER" {

            Resolve-RegistryHive `
                -Hive "NTUSER" |
                Should -Be "HKLM:\PimsOS_NTUSER"

        }

        It "Retourne le chemin SAM" {

            Resolve-RegistryHive `
                -Hive "SAM" |
                Should -Be "HKLM:\PimsOS_SAM"

        }

        It "Retourne le chemin SECURITY" {

            Resolve-RegistryHive `
                -Hive "SECURITY" |
                Should -Be "HKLM:\PimsOS_SECURITY"

        }

        It "Retourne le chemin COMPONENTS" {

            Resolve-RegistryHive `
                -Hive "COMPONENTS" |
                Should -Be "HKLM:\PimsOS_COMPONENTS"

        }

        It "Refuse une ruche inconnue" {

            {
                Resolve-RegistryHive `
                    -Hive "UNKNOWN"
            } |
                Should -Throw

        }

    }


    # ==================================================
    # ConvertTo-RegistryType
    # ==================================================

    Context "ConvertTo-RegistryType" {

        It "Convertit String" {

            ConvertTo-RegistryType `
                -DataType "String" |
                Should -Be "String"

        }

        It "Convertit ExpandString" {

            ConvertTo-RegistryType `
                -DataType "ExpandString" |
                Should -Be "ExpandString"

        }

        It "Convertit MultiString" {

            ConvertTo-RegistryType `
                -DataType "MultiString" |
                Should -Be "MultiString"

        }

        It "Convertit Binary" {

            ConvertTo-RegistryType `
                -DataType "Binary" |
                Should -Be "Binary"

        }

        It "Convertit DWord" {

            ConvertTo-RegistryType `
                -DataType "DWord" |
                Should -Be "DWord"

        }

        It "Convertit QWord" {

            ConvertTo-RegistryType `
                -DataType "QWord" |
                Should -Be "QWord"

        }

        It "Refuse un type inconnu" {

            {
                ConvertTo-RegistryType `
                    -DataType "Unknown"
            } |
                Should -Throw

        }

    }


    # ==================================================
    # Test-RegistryHive
    # ==================================================

    Context "Test-RegistryHive" {

        It "Retourne True lorsque la ruche existe" {

            Mock Test-Path {
                return $true
            }

            Test-RegistryHive `
                -Hive "SOFTWARE" |
                Should -BeTrue

        }

        It "Retourne False lorsque la ruche n'existe pas" {

            Mock Test-Path {
                return $false
            }

            Test-RegistryHive `
                -Hive "SOFTWARE" |
                Should -BeFalse

        }

    }


    # ==================================================
    # New-RegistryKey
    # ==================================================

    Context "New-RegistryKey" {

        BeforeEach {

			$script:RegistryKeyCreated = $false

			Mock Test-RegistryHive {
				return $true
			}

			Mock Test-Path {
				param($Path)

				if ($Path -eq "HKLM:\PimsOS_SOFTWARE\Test") {

					return $script:RegistryKeyCreated

				}

				return $true
			}

			Mock New-Item {

				$script:RegistryKeyCreated = $true

			}

		}

        It "Crée une clé de registre" {

            $Path = New-RegistryKey `
                -Hive "SOFTWARE" `
                -Key "Test"

            $Path |
                Should -Be "HKLM:\PimsOS_SOFTWARE\Test"

        }

        It "Appelle New-Item pour créer la clé" {

            $null = New-RegistryKey `
                -Hive "SOFTWARE" `
                -Key "Test"

            Should -Invoke `
                -CommandName New-Item `
                -Times 1 `
                -Exactly

        }

        It "Retourne directement une clé existante" {

            Mock Test-Path {
                return $true
            }

            $Path = New-RegistryKey `
                -Hive "SOFTWARE" `
                -Key "Test"

            $Path |
                Should -Be "HKLM:\PimsOS_SOFTWARE\Test"

            Should -Invoke `
                -CommandName New-Item `
                -Times 0 `
                -Exactly

        }

        It "Refuse une ruche non montée" {

            Mock Test-RegistryHive {
                return $false
            }

            {
                New-RegistryKey `
                    -Hive "SOFTWARE" `
                    -Key "Test"
            } |
                Should -Throw

        }

    }


    # ==================================================
    # Get-OfflineRegistryPath
    # ==================================================

    Context "Get-OfflineRegistryPath" {

        BeforeEach {

            $script:Context = [pscustomobject]@{

                BuildState = [pscustomobject]@{

                    Image = [pscustomobject]@{

                        WimMounted = $true

                    }

                }

                WIM = [pscustomobject]@{

                    Mount = [pscustomobject]@{

                        Path = "C:\Test\Mount"

                    }

                }

            }

        }

        It "Retourne le chemin de SOFTWARE" {

            Mock Test-Path {
                return $true
            }

            $Path = Get-OfflineRegistryPath `
                -Context $script:Context `
                -Hive "SOFTWARE"

            $Path |
                Should -Be "C:\Test\Mount\Windows\System32\Config\SOFTWARE"

        }

        It "Retourne le chemin de SYSTEM" {

            Mock Test-Path {
                return $true
            }

            $Path = Get-OfflineRegistryPath `
                -Context $script:Context `
                -Hive "SYSTEM"

            $Path |
                Should -Be "C:\Test\Mount\Windows\System32\Config\SYSTEM"

        }

        It "Refuse une image non montée" {

            $script:Context.BuildState.Image.WimMounted = $false

            {
                Get-OfflineRegistryPath `
                    -Context $script:Context `
                    -Hive "SOFTWARE"
            } |
                Should -Throw

        }

        It "Refuse une ruche absente" {

            Mock Test-Path {
                return $false
            }

            {
                Get-OfflineRegistryPath `
                    -Context $script:Context `
                    -Hive "SOFTWARE"
            } |
                Should -Throw

        }

    }


    # ==================================================
    # Set-RegistryValue
    # ==================================================

    Context "Set-RegistryValue" {

        BeforeEach {

            $script:Context = [pscustomobject]@{

                Registry = [pscustomobject]@{

                    Mounted = @(
                        "SOFTWARE"
                    )

                }

            }

            $script:Action = [pscustomobject]@{

                Hive = "SOFTWARE"

                Key = "Test"

                Name = "Enabled"

                Value = 1

                DataType = "DWord"

            }

            Mock Test-RegistryHive {
                return $true
            }

            Mock New-RegistryKey {
                return "HKLM:\PimsOS_SOFTWARE\Test"
            }

            Mock New-ItemProperty {}

        }

        It "Retourne le contexte" {

            $Result = Set-RegistryValue `
                -Context $script:Context `
                -Action $script:Action

            $Result |
                Should -Be $script:Context

        }

        It "Appelle New-RegistryKey" {

            Set-RegistryValue `
                -Context $script:Context `
                -Action $script:Action |
                Out-Null

            Should -Invoke `
                -CommandName New-RegistryKey `
                -Times 1 `
                -Exactly

        }

        It "Appelle New-ItemProperty" {

            Set-RegistryValue `
                -Context $script:Context `
                -Action $script:Action |
                Out-Null

            Should -Invoke `
                -CommandName New-ItemProperty `
                -Times 1 `
                -Exactly

        }

        It "Refuse une ruche non montée dans le contexte" {

            $script:Context.Registry.Mounted = @()

            {
                Set-RegistryValue `
                    -Context $script:Context `
                    -Action $script:Action
            } |
                Should -Throw

        }

    }


    # ==================================================
    # Get-RegistryValue
    # ==================================================

    Context "Get-RegistryValue" {

        BeforeEach {

            $script:Context = [pscustomobject]@{

                Registry = [pscustomobject]@{

                    Mounted = @(
                        "SOFTWARE"
                    )

                }

            }

            Mock Test-Path {
                return $true
            }

        }

        It "Retourne une valeur existante" {

            Mock Get-ItemPropertyValue {
                return 42
            }

            $Value = Get-RegistryValue `
                -Context $script:Context `
                -Hive "SOFTWARE" `
                -Key "Test" `
                -Name "Value"

            $Value |
                Should -Be 42

        }

        It "Appelle Get-ItemPropertyValue" {

            Mock Get-ItemPropertyValue {
                return 42
            }

            Get-RegistryValue `
                -Context $script:Context `
                -Hive "SOFTWARE" `
                -Key "Test" `
                -Name "Value" |
                Out-Null

            Should -Invoke `
                -CommandName Get-ItemPropertyValue `
                -Times 1 `
                -Exactly

        }

        It "Refuse une ruche non montée" {

            $script:Context.Registry.Mounted = @()

            {
                Get-RegistryValue `
                    -Context $script:Context `
                    -Hive "SOFTWARE" `
                    -Key "Test" `
                    -Name "Value"
            } |
                Should -Throw

        }

        It "Refuse une clé inexistante" {

            Mock Test-Path {
                return $false
            }

            {
                Get-RegistryValue `
                    -Context $script:Context `
                    -Hive "SOFTWARE" `
                    -Key "Test" `
                    -Name "Value"
            } |
                Should -Throw

        }

        It "Lève une exception lorsque la valeur n'existe pas" {

            Mock Get-ItemPropertyValue {
                throw "Valeur absente"
            }

            {
                Get-RegistryValue `
                    -Context $script:Context `
                    -Hive "SOFTWARE" `
                    -Key "Test" `
                    -Name "Value"
            } |
                Should -Throw

        }

    }


    # ==================================================
    # Mount-RegistryHive
    # ==================================================

    Context "Mount-RegistryHive" {

        BeforeEach {

            $script:Context = [pscustomobject]@{

                Registry = [pscustomobject]@{

                    Mounted = @()

                }

                BuildState = [pscustomobject]@{

                    Status = "Idle"

                    Image = [pscustomobject]@{

                        WimMounted = $true
                        RegistryLoaded = $false
                        CurrentRegistryHive = $null

                    }

                }

                WIM = [pscustomobject]@{

                    Mount = [pscustomobject]@{

                        Path = "C:\Test\Mount"

                    }

                }

            }

            Mock Assert-Administrator {}

            Mock Get-OfflineRegistryPath {
                return "C:\Test\Mount\Windows\System32\Config\SOFTWARE"
            }

            Mock Test-Path {
                return $false
            }

        }

        It "Refuse une image non montée" {

            $script:Context.BuildState.Image.WimMounted = $false

            {
                Mount-RegistryHive `
                    -Context $script:Context `
                    -Hive "SOFTWARE"
            } |
                Should -Throw

        }

        It "Refuse une ruche inexistante" {

            Mock Get-OfflineRegistryPath {
                throw "Ruche introuvable"
            }

            {
                Mount-RegistryHive `
                    -Context $script:Context `
                    -Hive "SOFTWARE"
            } |
                Should -Throw

        }

    }


    # ==================================================
    # Dismount-RegistryHive
    # ==================================================

    Context "Dismount-RegistryHive" {

        BeforeEach {

            $script:Context = [pscustomobject]@{

                Registry = [pscustomobject]@{

                    Mounted = @(
                        "SOFTWARE"
                    )

                }

                BuildState = [pscustomobject]@{

                    Status = "RegistryMounted"

                    Image = [pscustomobject]@{

                        RegistryLoaded = $true
                        CurrentRegistryHive = "SOFTWARE"

                    }

                }

            }

            Mock Assert-Administrator {}

        }

        It "Retourne le contexte si la ruche n'est pas montée" {

            Mock Test-Path {
                return $false
            }

            $Result = Dismount-RegistryHive `
                -Context $script:Context `
                -Hive "SOFTWARE"

            $Result |
                Should -Be $script:Context

            $Result.BuildState.Status |
                Should -Be "RegistryUnmounted"

        }

        It "Ne modifie pas Mounted si la ruche n'est pas montée" {

            Mock Test-Path {
                return $false
            }

            $null = Dismount-RegistryHive `
                -Context $script:Context `
                -Hive "SOFTWARE"

            @($script:Context.Registry.Mounted).Count |
                Should -Be 1

        }

    }

}