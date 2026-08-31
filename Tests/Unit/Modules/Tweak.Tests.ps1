# ==========================================
# Tests : Tweak
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"
    . "$ProjectRoot\Modules\Core\Core.ps1"
    . "$ProjectRoot\Modules\Configuration\Tweak.ps1"

}

Describe "New-Action" {

    It "Conserve les propriétés spécifiques d'un moteur" {

        $Definition = [pscustomobject]@{
            Id = "Package.Test"
            Type = "Package"
            Provider = "Chocolatey"
            Name = "7zip"
            Operation = "Install"
            Version = "24.0"
            Enabled = $true
        }

        $Action = New-Action -Definition $Definition

        $Action.Id |
            Should -Be "Package.Test"

        $Action.Provider |
            Should -Be "Chocolatey"

        $Action.Operation |
            Should -Be "Install"

        $Action.Version |
            Should -Be "24.0"

        $Action.Enabled |
            Should -BeTrue

    }

}

Describe "Tweak" {

    BeforeEach {

        Reset-Logger

    }


    # ==================================================
    # New-Action
    # ==================================================

    Context "New-Action" {

        It "Construit une action complète" {

            $Definition = [pscustomobject]@{

                Id = "Test.Action"
                Type = "Registry"
                Description = "Action de test"

                Enabled = $true
                RequiresRestart = $true
                ContinueOnError = $true

                Hive = "SOFTWARE"
                Key = "Test"
                Name = "TestValue"
                Value = 1
                DataType = "DWord"

                StartupType = "Disabled"
                Stop = $true

                Provider = "TestProvider"
                Command = "test"
                Version = "1.0"
                Source = "Source"
                Destination = "Destination"
                Target = "Target"
                Path = "C:\Test"
                Arguments = "-Test"
                WorkingDirectory = "C:\Test"
                Timeout = 30
                Wait = $false
                RunAs = $true
            }

            $Action = New-Action -Definition $Definition

            $Action |
                Should -Not -BeNullOrEmpty

            $Action.ObjectType |
                Should -Be "Action"

            $Action.Id |
                Should -Be "Test.Action"

            $Action.Type |
                Should -Be "Registry"

            $Action.Description |
                Should -Be "Action de test"
        }


        It "Utilise les valeurs par défaut" {

            $Definition = [pscustomobject]@{

                Id = "Test.Action"
                Type = "Registry"

            }

            $Action = New-Action -Definition $Definition

            $Action.Enabled |
                Should -BeTrue

            $Action.RequiresRestart |
                Should -BeFalse

            $Action.ContinueOnError |
                Should -BeFalse

            $Action.Stop |
                Should -BeFalse

            $Action.Wait |
                Should -BeTrue

            $Action.RunAs |
                Should -BeFalse
        }


        It "Initialise l'état d'exécution" {

            $Definition = [pscustomobject]@{

                Id = "Test.Action"
                Type = "Registry"

            }

            $Action = New-Action -Definition $Definition

            $Action.Executed |
                Should -BeFalse

            $Action.Success |
                Should -BeFalse

            $Action.Duration |
                Should -BeOfType ([TimeSpan])

            $Action.Error |
                Should -BeNullOrEmpty
        }


        It "Copie les propriétés spécifiques Registry" {

            $Definition = [pscustomobject]@{

                Id = "Registry.Test"
                Type = "Registry"

                Hive = "SOFTWARE"
                Key = "Policies\Test"
                Name = "Enabled"
                Value = 1
                DataType = "DWord"

            }

            $Action = New-Action -Definition $Definition

            $Action.Hive |
                Should -Be "SOFTWARE"

            $Action.Key |
                Should -Be "Policies\Test"

            $Action.Name |
                Should -Be "Enabled"

            $Action.Value |
                Should -Be 1

            $Action.DataType |
                Should -Be "DWord"
        }


        It "Copie les propriétés spécifiques Service" {

            $Definition = [pscustomobject]@{

                Id = "Service.Test"
                Type = "Service"

                Name = "DiagTrack"
                StartupType = "Disabled"
                Stop = $true

            }

            $Action = New-Action -Definition $Definition

            $Action.Name |
                Should -Be "DiagTrack"

            $Action.StartupType |
                Should -Be "Disabled"

            $Action.Stop |
                Should -BeTrue
        }


        It "Copie les propriétés générales des Managers" {

            $Definition = [pscustomobject]@{

                Id = "Package.Test"
                Type = "Package"

                Provider = "Winget"
                Command = "install"
                Version = "1.0"
                Source = "Source"
                Destination = "Destination"
                Target = "Target"
                Path = "C:\Test"
                Arguments = "--silent"
                WorkingDirectory = "C:\Test"
                Timeout = 60
                Wait = $false
                RunAs = $true

            }

            $Action = New-Action -Definition $Definition

            $Action.Provider |
                Should -Be "Winget"

            $Action.Command |
                Should -Be "install"

            $Action.Version |
                Should -Be "1.0"

            $Action.Source |
                Should -Be "Source"

            $Action.Destination |
                Should -Be "Destination"

            $Action.Target |
                Should -Be "Target"

            $Action.Path |
                Should -Be "C:\Test"

            $Action.Arguments |
                Should -Be "--silent"

            $Action.WorkingDirectory |
                Should -Be "C:\Test"

            $Action.Timeout |
                Should -Be 60

            $Action.Wait |
                Should -BeFalse

            $Action.RunAs |
                Should -BeTrue
        }

    }


    # ==================================================
    # New-Tweak
    # ==================================================

    Context "New-Tweak" {

        It "Construit un tweak complet" {

            $Definition = [pscustomobject]@{

                Id = "Test.Tweak"
                Name = "Tweak de test"
                Description = "Description de test"
                Risk = "Safe"
                Impact = "Impact de test"
                Actions = @(
                    [pscustomobject]@{
                        Id = "Test.Action"
                        Type = "Registry"
                        Enabled = $true
                        Hive = "SOFTWARE"
                        Key = "Test"
                        Name = "Value"
                        Value = 1
                        DataType = "DWord"
                    }
                )

                Help = "Aide"
                Group = "Test"
                Tags = @("Test")

                Default = $true
                Recommended = $true
                Level = "Official"

                Scores = [pscustomobject]@{
                    Performance = 5
                    Privacy = 4
                }

                Supported = [pscustomobject]@{
                    MinBuild = 26100
                    MaxBuild = 27000
                }

                Reversible = $true
                RequiresRestart = $false
            }

            $Tweak = New-Tweak `
                -Definition $Definition `
                -CategoryId "Test" `
                -SourceFile "Test.json"

            $Tweak |
                Should -Not -BeNullOrEmpty

            $Tweak.ObjectType |
                Should -Be "Tweak"

            $Tweak.Id |
                Should -Be "Test.Tweak"

            $Tweak.Name |
                Should -Be "Tweak de test"

            $Tweak.CategoryId |
                Should -Be "Test"

            $Tweak.SourceFile |
                Should -Be "Test.json"

            $Tweak.Risk |
                Should -Be "Safe"

            $Tweak.Impact |
                Should -Be "Impact de test"
        }


        It "Construit les actions du tweak" {

            $Definition = [pscustomobject]@{

                Id = "Test.Tweak"
                Name = "Tweak de test"
                Description = "Description de test"

                Actions = @(
                    [pscustomobject]@{
                        Id = "Action.One"
                        Type = "Registry"
                    },
                    [pscustomobject]@{
                        Id = "Action.Two"
                        Type = "Service"
                    }
                )

            }

            $Tweak = New-Tweak `
                -Definition $Definition `
                -CategoryId "Test" `
                -SourceFile "Test.json"

            $Tweak.Actions |
                Should -Not -BeNullOrEmpty

            $Tweak.Actions.Count |
                Should -Be 2

            $Tweak.Actions[0].Id |
                Should -Be "Action.One"

            $Tweak.Actions[1].Id |
                Should -Be "Action.Two"
        }


        It "Initialise les valeurs par défaut" {

            $Definition = [pscustomobject]@{

                Id = "Test.Tweak"
                Name = "Tweak de test"
                Description = "Description de test"
                Actions = @()

            }

            $Tweak = New-Tweak `
                -Definition $Definition `
                -CategoryId "Test" `
                -SourceFile "Test.json"

            $Tweak.Default |
                Should -BeFalse

            $Tweak.Recommended |
                Should -BeFalse

            $Tweak.Level |
                Should -Be "Official"

            $Tweak.Reversible |
                Should -BeTrue

            $Tweak.RequiresRestart |
                Should -BeFalse

            $Tweak.Enabled |
                Should -BeFalse

            $Tweak.Applied |
                Should -BeFalse

            $Tweak.Result |
                Should -BeNullOrEmpty

            $Tweak.Duration |
                Should -BeOfType ([TimeSpan])
        }


        It "Initialise les collections d'état" {

            $Definition = [pscustomobject]@{

                Id = "Test.Tweak"
                Name = "Tweak de test"
                Description = "Description de test"
                Actions = @()

            }

            $Tweak = New-Tweak `
                -Definition $Definition `
                -CategoryId "Test" `
                -SourceFile "Test.json"

            ($null -eq $Tweak.Actions) |
                Should -BeFalse

            ($null -eq $Tweak.Errors) |
                Should -BeFalse

            ($null -eq $Tweak.Warnings) |
                Should -BeFalse

            ($null -eq $Tweak.Statistics) |
                Should -BeFalse
        }


        It "Initialise les statistiques du tweak" {

            $Definition = [pscustomobject]@{

                Id = "Test.Tweak"
                Name = "Tweak de test"
                Description = "Description de test"

                Actions = @(
                    [pscustomobject]@{
                        Id = "One"
                        Type = "Registry"
                    },
                    [pscustomobject]@{
                        Id = "Two"
                        Type = "Service"
                    }
                )

            }

            $Tweak = New-Tweak `
                -Definition $Definition `
                -CategoryId "Test" `
                -SourceFile "Test.json"

            $Tweak.Statistics.Actions |
                Should -Be 2

            $Tweak.Statistics.Executed |
                Should -Be 0

            $Tweak.Statistics.Failed |
                Should -Be 0
        }


        It "Construit un tweak sans action" {

            $Definition = [pscustomobject]@{

                Id = "Test.Tweak"
                Name = "Tweak vide"
                Description = "Tweak sans action"
                Actions = @()

            }

            $Tweak = New-Tweak `
                -Definition $Definition `
                -CategoryId "Test" `
                -SourceFile "Test.json"

            $Tweak.Actions.Count |
                Should -Be 0

            $Tweak.Statistics.Actions |
                Should -Be 0
        }

    }

}