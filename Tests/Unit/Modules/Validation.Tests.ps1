# ==========================================
# Tests : Validation
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    # --------------------------------------------------
    # Dépendance Logger
    # --------------------------------------------------

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"

    # --------------------------------------------------
    # Module testé
    # --------------------------------------------------

    . "$ProjectRoot\Modules\Infrastructure\Validation.ps1"
}


Describe "Validation" {

    # ==================================================
    # Dépendances de test
    # ==================================================

    BeforeEach {

        Reset-Logger

        # --------------------------------------------------
        # Mock Test-CategoryExists
        # --------------------------------------------------

        function global:Test-CategoryExists {

            param(
                [string]$Id
            )

            return $true
        }

        # --------------------------------------------------
        # Mock Get-CategoryLevels
        # --------------------------------------------------

        function global:Get-CategoryLevels {

            return @(
                "Low"
                "Medium"
                "High"
            )
        }

        # --------------------------------------------------
        # Mock Get-CategoryGroups
        # --------------------------------------------------

        function global:Get-CategoryGroups {

            param(
                [string]$Id
            )

            return @(
                "Privacy"
                "Performance"
                "Security"
            )
        }

        # --------------------------------------------------
        # Contexte minimal
        # --------------------------------------------------

        $script:Context = [pscustomobject]@{

            Project = [pscustomobject]@{

                Name = "PimsOS Builder"

            }

        }

        # --------------------------------------------------
        # Tweak valide de base
        # --------------------------------------------------

        $script:ValidTweak = [pscustomobject]@{

            SourceFile = "Tests\Tweak.json"

            Id = "TestTweak"

            Name = "Test Tweak"

            Description = "Tweak de test"

            Default = $false

            Recommended = $true

            CategoryId = "Privacy"

            Level = "Medium"

            Group = "Privacy"

            Tags = @(
                "Test"
                "Privacy"
            )

            Supported = [pscustomobject]@{

                MinBuild = 26100

                MaxBuild = 26199

            }

            Scores = [pscustomobject]@{

                Privacy = 5

                Performance = 3

                Memory = 3

                Compatibility = 5

            }

            Actions = @(
                [pscustomobject]@{

                    Id = "TestAction"

                    Type = "Registry"

                    Enabled = $true

                    Hive = "SOFTWARE"

                    Key = "Software\PimsOS\Test"

                    Name = "Enabled"

                    Value = 1

                    DataType = "DWord"

                }
            )
        }
    }


    # ==================================================
    # Test-IsInteger
    # ==================================================

    Context "Test-IsInteger" {

        It "Retourne True pour un Int32" {

            Test-IsInteger -Value ([int]42) |
                Should -BeTrue
        }

        It "Retourne True pour un Int64" {

            Test-IsInteger -Value ([int64]42) |
                Should -BeTrue
        }

        It "Retourne True pour un Int16" {

            Test-IsInteger -Value ([int16]42) |
                Should -BeTrue
        }

        It "Retourne True pour un Byte" {

            Test-IsInteger -Value ([byte]42) |
                Should -BeTrue
        }

        It "Retourne False pour une chaîne" {

            Test-IsInteger -Value "42" |
                Should -BeFalse
        }

        It "Retourne False pour un Double" {

            Test-IsInteger -Value 42.5 |
                Should -BeFalse
        }
    }


    # ==================================================
    # New-ValidationError
    # ==================================================

    Context "New-ValidationError" {

        It "Lève une exception" {

            {
                New-ValidationError `
                    -File "Tests\Tweak.json" `
                    -Tweak "TestTweak" `
                    -Message "Erreur de test"
            } |
                Should -Throw
        }

        It "Contient le nom du fichier dans l'exception" {

            $ErrorMessage = $null

            try {

                New-ValidationError `
                    -File "Tests\Tweak.json" `
                    -Tweak "TestTweak" `
                    -Message "Erreur de test"

            }
            catch {

                $ErrorMessage = $_.Exception.Message
            }

            $ErrorMessage |
                Should -Match "Tests\\Tweak\.json"
        }

        It "Contient l'identifiant du tweak dans l'exception" {

            $ErrorMessage = $null

            try {

                New-ValidationError `
                    -File "Tests\Tweak.json" `
                    -Tweak "TestTweak" `
                    -Message "Erreur de test"

            }
            catch {

                $ErrorMessage = $_.Exception.Message
            }

            $ErrorMessage |
                Should -Match "TestTweak"
        }

        It "Contient le message d'erreur" {

            $ErrorMessage = $null

            try {

                New-ValidationError `
                    -File "Tests\Tweak.json" `
                    -Tweak "TestTweak" `
                    -Message "Erreur de test"

            }
            catch {

                $ErrorMessage = $_.Exception.Message
            }

            $ErrorMessage |
                Should -Match "Erreur de test"
        }
    }


    # ==================================================
    # Test-TweakRequiredProperties
    # ==================================================

    Context "Test-TweakRequiredProperties" {

        It "Accepte un tweak complet" {

            {
                Test-TweakRequiredProperties `
                    -Context $script:Context `
                    -Tweaks @($script:ValidTweak)
            } |
                Should -Not -Throw
        }

        It "Refuse un tweak sans Id" {

            $Tweak = $script:ValidTweak.PSObject.Copy()

            $Tweak.PSObject.Properties.Remove("Id")

            {
                Test-TweakRequiredProperties `
                    -Context $script:Context `
                    -Tweaks @($Tweak)
            } |
                Should -Throw
        }

        It "Refuse un tweak sans Name" {

            $Tweak = $script:ValidTweak.PSObject.Copy()

            $Tweak.PSObject.Properties.Remove("Name")

            {
                Test-TweakRequiredProperties `
                    -Context $script:Context `
                    -Tweaks @($Tweak)
            } |
                Should -Throw
        }

        It "Refuse un tweak sans Actions" {

            $Tweak = $script:ValidTweak.PSObject.Copy()

            $Tweak.PSObject.Properties.Remove("Actions")

            {
                Test-TweakRequiredProperties `
                    -Context $script:Context `
                    -Tweaks @($Tweak)
            } |
                Should -Throw
        }
    }


    # ==================================================
    # Test-TweakIds
    # ==================================================

    Context "Test-TweakIds" {

        It "Accepte des identifiants uniques" {

            $Tweaks = @(
                $script:ValidTweak

                [pscustomobject]@{
                    SourceFile   = "Tests\Tweak2.json"
                    Id           = "AnotherTweak"
                    Name         = "Another"
                    Description  = "Autre"
                    Default      = $false
                    Recommended  = $false
                    Actions      = @()
                }
            )

            {
                Test-TweakIds `
                    -Context $script:Context `
                    -Tweaks $Tweaks
            } |
                Should -Not -Throw
        }

        It "Refuse deux identifiants identiques" {

            $Tweak2 = $script:ValidTweak.PSObject.Copy()

            $Tweaks = @(
                $script:ValidTweak
                $Tweak2
            )

            {
                Test-TweakIds `
                    -Context $script:Context `
                    -Tweaks $Tweaks
            } |
                Should -Throw
        }
    }


    # ==================================================
    # Test-TweakCategory
    # ==================================================

    Context "Test-TweakCategory" {

        It "Accepte une catégorie existante" {

            {
                Test-TweakCategory `
                    -Context $script:Context `
                    -Tweaks @($script:ValidTweak)
            } |
                Should -Not -Throw
        }

        It "Refuse une catégorie inconnue" {

            function global:Test-CategoryExists {

                param(
                    [string]$Id
                )

                return $false
            }

            {
                Test-TweakCategory `
                    -Context $script:Context `
                    -Tweaks @($script:ValidTweak)
            } |
                Should -Throw
        }

        It "Refuse une propriété CategoryId absente" {

            $Tweak = $script:ValidTweak.PSObject.Copy()

            $Tweak.PSObject.Properties.Remove("CategoryId")

            {
                Test-TweakCategory `
                    -Context $script:Context `
                    -Tweaks @($Tweak)
            } |
                Should -Throw
        }
    }


    # ==================================================
    # Test-TweakLevel
    # ==================================================

    Context "Test-TweakLevel" {

        It "Accepte un niveau valide" {

            {
                Test-TweakLevel `
                    -Context $script:Context `
                    -Tweaks @($script:ValidTweak)
            } |
                Should -Not -Throw
        }

        It "Accepte un tweak sans niveau" {

            $Tweak = $script:ValidTweak.PSObject.Copy()

            $Tweak.PSObject.Properties.Remove("Level")

            {
                Test-TweakLevel `
                    -Context $script:Context `
                    -Tweaks @($Tweak)
            } |
                Should -Not -Throw
        }

        It "Refuse un niveau inconnu" {

            $Tweak = $script:ValidTweak.PSObject.Copy()

            $Tweak.Level = "Unknown"

            {
                Test-TweakLevel `
                    -Context $script:Context `
                    -Tweaks @($Tweak)
            } |
                Should -Throw
        }
    }


    # ==================================================
    # Test-TweakGroup
    # ==================================================

    Context "Test-TweakGroup" {

        It "Accepte un groupe valide" {

            {
                Test-TweakGroup `
                    -Context $script:Context `
                    -Tweaks @($script:ValidTweak)
            } |
                Should -Not -Throw
        }

        It "Accepte un tweak sans groupe" {

            $Tweak = $script:ValidTweak.PSObject.Copy()

            $Tweak.PSObject.Properties.Remove("Group")

            {
                Test-TweakGroup `
                    -Context $script:Context `
                    -Tweaks @($Tweak)
            } |
                Should -Not -Throw
        }

        It "Refuse un groupe invalide" {

            $Tweak = $script:ValidTweak.PSObject.Copy()

            $Tweak.Group = "InvalidGroup"

            {
                Test-TweakGroup `
                    -Context $script:Context `
                    -Tweaks @($Tweak)
            } |
                Should -Throw
        }
    }


    # ==================================================
    # Test-TweakTags
    # ==================================================

    Context "Test-TweakTags" {

        It "Accepte des tags valides" {

            {
                Test-TweakTags `
                    -Context $script:Context `
                    -Tweaks @($script:ValidTweak)
            } |
                Should -Not -Throw
        }

        It "Accepte l'absence de tags" {

            $Tweak = $script:ValidTweak.PSObject.Copy()

            $Tweak.PSObject.Properties.Remove("Tags")

            {
                Test-TweakTags `
                    -Context $script:Context `
                    -Tweaks @($Tweak)
            } |
                Should -Not -Throw
        }

        It "Refuse un tag vide" {

            $Tweak = $script:ValidTweak.PSObject.Copy()

            $Tweak.Tags = @(
                "Privacy"
                ""
            )

            {
                Test-TweakTags `
                    -Context $script:Context `
                    -Tweaks @($Tweak)
            } |
                Should -Throw
        }
    }


    # ==================================================
    # Test-TweakSupported
    # ==================================================

    Context "Test-TweakSupported" {

        It "Accepte une plage de builds valide" {

            {
                Test-TweakSupported `
                    -Context $script:Context `
                    -Tweaks @($script:ValidTweak)
            } |
                Should -Not -Throw
        }

        It "Accepte l'absence de Supported" {

            $Tweak = $script:ValidTweak.PSObject.Copy()

            $Tweak.PSObject.Properties.Remove("Supported")

            {
                Test-TweakSupported `
                    -Context $script:Context `
                    -Tweaks @($Tweak)
            } |
                Should -Not -Throw
        }

        It "Refuse MinBuild supérieur à MaxBuild" {

            $Tweak = $script:ValidTweak.PSObject.Copy()

            $Tweak.Supported.MinBuild = 26200
            $Tweak.Supported.MaxBuild = 26100

            {
                Test-TweakSupported `
                    -Context $script:Context `
                    -Tweaks @($Tweak)
            } |
                Should -Throw
        }

        It "Refuse un MinBuild non entier" {

            $Tweak = $script:ValidTweak.PSObject.Copy()

            $Tweak.Supported.MinBuild = "26100"

            {
                Test-TweakSupported `
                    -Context $script:Context `
                    -Tweaks @($Tweak)
            } |
                Should -Throw
        }

        It "Refuse l'absence de MinBuild" {

            $Tweak = $script:ValidTweak.PSObject.Copy()

            $Tweak.Supported.PSObject.Properties.Remove("MinBuild")

            {
                Test-TweakSupported `
                    -Context $script:Context `
                    -Tweaks @($Tweak)
            } |
                Should -Throw
        }

        It "Refuse l'absence de MaxBuild" {

            $Tweak = $script:ValidTweak.PSObject.Copy()

            $Tweak.Supported.PSObject.Properties.Remove("MaxBuild")

            {
                Test-TweakSupported `
                    -Context $script:Context `
                    -Tweaks @($Tweak)
            } |
                Should -Throw
        }
    }


    # ==================================================
    # Test-TweakScores
    # ==================================================

    Context "Test-TweakScores" {

        It "Accepte des scores valides" {

            {
                Test-TweakScores `
                    -Context $script:Context `
                    -Tweaks @($script:ValidTweak)
            } |
                Should -Not -Throw
        }

        It "Accepte l'absence de Scores" {

            $Tweak = $script:ValidTweak.PSObject.Copy()

            $Tweak.PSObject.Properties.Remove("Scores")

            {
                Test-TweakScores `
                    -Context $script:Context `
                    -Tweaks @($Tweak)
            } |
                Should -Not -Throw
        }

        It "Refuse un score supérieur à 5" {

            $Tweak = $script:ValidTweak.PSObject.Copy()

            $Tweak.Scores.Privacy = 6

            {
                Test-TweakScores `
                    -Context $script:Context `
                    -Tweaks @($Tweak)
            } |
                Should -Throw
        }

        It "Refuse un score inférieur à 0" {

            $Tweak = $script:ValidTweak.PSObject.Copy()

            $Tweak.Scores.Privacy = -1

            {
                Test-TweakScores `
                    -Context $script:Context `
                    -Tweaks @($Tweak)
            } |
                Should -Throw
        }

        It "Refuse un score non entier" {

            $Tweak = $script:ValidTweak.PSObject.Copy()

            $Tweak.Scores.Privacy = "5"

            {
                Test-TweakScores `
                    -Context $script:Context `
                    -Tweaks @($Tweak)
            } |
                Should -Throw
        }

        It "Refuse un score manquant" {

            $Tweak = $script:ValidTweak.PSObject.Copy()

            $Tweak.Scores.PSObject.Properties.Remove("Privacy")

            {
                Test-TweakScores `
                    -Context $script:Context `
                    -Tweaks @($Tweak)
            } |
                Should -Throw
        }
    }


    # ==================================================
    # Test-TweakActions
    # ==================================================

    Context "Test-TweakActions" {

        It "Accepte une action Registry valide" {

            {
                Test-TweakActions `
                    -Context $script:Context `
                    -Tweaks @($script:ValidTweak)
            } |
                Should -Not -Throw
        }

        It "Refuse un tweak sans actions" {

            $Tweak = $script:ValidTweak.PSObject.Copy()

            $Tweak.Actions = @()

            {
                Test-TweakActions `
                    -Context $script:Context `
                    -Tweaks @($Tweak)
            } |
                Should -Throw
        }

        It "Refuse un type d'action inconnu" {

            $Tweak = $script:ValidTweak.PSObject.Copy()

            $Tweak.Actions = @(
                [pscustomobject]@{
                    Id      = "UnknownAction"
                    Type    = "Unknown"
                    Enabled = $true
                }
            )

            {
                Test-TweakActions `
                    -Context $script:Context `
                    -Tweaks @($Tweak)
            } |
                Should -Throw
        }

        It "Refuse deux actions avec le même identifiant" {

            $Tweak = $script:ValidTweak.PSObject.Copy()

            $Tweak.Actions = @(
                [pscustomobject]@{
                    Id       = "Duplicate"
                    Type     = "Registry"
                    Enabled  = $true
                    Hive     = "SOFTWARE"
                    Key      = "Software\PimsOS"
                    Name     = "Test"
                    Value    = 1
                    DataType = "DWord"
                }

                [pscustomobject]@{
                    Id       = "Duplicate"
                    Type     = "Registry"
                    Enabled  = $true
                    Hive     = "SOFTWARE"
                    Key      = "Software\PimsOS"
                    Name     = "Test2"
                    Value    = 2
                    DataType = "DWord"
                }
            )

            {
                Test-TweakActions `
                    -Context $script:Context `
                    -Tweaks @($Tweak)
            } |
                Should -Throw
        }

        It "Refuse une action sans Id" {

            $Tweak = $script:ValidTweak.PSObject.Copy()

            $Tweak.Actions = @(
                [pscustomobject]@{
                    Type     = "Registry"
                    Enabled  = $true
                    Hive     = "SOFTWARE"
                    Key      = "Software\PimsOS"
                    Name     = "Test"
                    Value    = 1
                    DataType = "DWord"
                }
            )

            {
                Test-TweakActions `
                    -Context $script:Context `
                    -Tweaks @($Tweak)
            } |
                Should -Throw
        }

        It "Refuse une action Registry sans Hive" {

            $Tweak = $script:ValidTweak.PSObject.Copy()

            $Tweak.Actions = @(
                [pscustomobject]@{
                    Id       = "RegistryTest"
                    Type     = "Registry"
                    Enabled  = $true
                    Key      = "Software\PimsOS"
                    Name     = "Test"
                    Value    = 1
                    DataType = "DWord"
                }
            )

            {
                Test-TweakActions `
                    -Context $script:Context `
                    -Tweaks @($Tweak)
            } |
                Should -Throw
        }

        It "Refuse une ruche Registry inconnue" {

            $Tweak = $script:ValidTweak.PSObject.Copy()

            $Tweak.Actions = @(
                [pscustomobject]@{
                    Id       = "RegistryTest"
                    Type     = "Registry"
                    Enabled  = $true
                    Hive     = "INVALID"
                    Key      = "Software\PimsOS"
                    Name     = "Test"
                    Value    = 1
                    DataType = "DWord"
                }
            )

            {
                Test-TweakActions `
                    -Context $script:Context `
                    -Tweaks @($Tweak)
            } |
                Should -Throw
        }

        It "Refuse un DataType Registry inconnu" {

            $Tweak = $script:ValidTweak.PSObject.Copy()

            $Tweak.Actions = @(
                [pscustomobject]@{
                    Id       = "RegistryTest"
                    Type     = "Registry"
                    Enabled  = $true
                    Hive     = "SOFTWARE"
                    Key      = "Software\PimsOS"
                    Name     = "Test"
                    Value    = 1
                    DataType = "Invalid"
                }
            )

            {
                Test-TweakActions `
                    -Context $script:Context `
                    -Tweaks @($Tweak)
            } |
                Should -Throw
        }

        It "Accepte une action Service valide" {

            $Tweak = $script:ValidTweak.PSObject.Copy()

            $Tweak.Actions = @(
                [pscustomobject]@{
                    Id          = "ServiceTest"
                    Type        = "Service"
                    Enabled     = $true
                    Name        = "DiagTrack"
                    StartupType = "Disabled"
                    Stop        = $true
                }
            )

            {
                Test-TweakActions `
                    -Context $script:Context `
                    -Tweaks @($Tweak)
            } |
                Should -Not -Throw
        }

        It "Refuse un StartupType Service inconnu" {

            $Tweak = $script:ValidTweak.PSObject.Copy()

            $Tweak.Actions = @(
                [pscustomobject]@{
                    Id          = "ServiceTest"
                    Type        = "Service"
                    Enabled     = $true
                    Name        = "DiagTrack"
                    StartupType = "Invalid"
                    Stop        = $false
                }
            )

            {
                Test-TweakActions `
                    -Context $script:Context `
                    -Tweaks @($Tweak)
            } |
                Should -Throw
        }

        It "Refuse Stop lorsqu'il n'est pas booléen" {

            $Tweak = $script:ValidTweak.PSObject.Copy()

            $Tweak.Actions = @(
                [pscustomobject]@{
                    Id          = "ServiceTest"
                    Type        = "Service"
                    Enabled     = $true
                    Name        = "DiagTrack"
                    StartupType = "Disabled"
                    Stop        = "true"
                }
            )

            {
                Test-TweakActions `
                    -Context $script:Context `
                    -Tweaks @($Tweak)
            } |
                Should -Throw
        }
    }


    # ==================================================
    # Test-RegistryAction
    # ==================================================

    Context "Test-RegistryAction" {

        It "Accepte une action Registry complète" {

            {
                Test-RegistryAction `
                    -Context $script:Context `
                    -Tweak $script:ValidTweak `
                    -Action $script:ValidTweak.Actions[0]
            } |
                Should -Not -Throw
        }

        It "Refuse une ruche inconnue" {

            $Action = $script:ValidTweak.Actions[0].PSObject.Copy()

            $Action.Hive = "INVALID"

            {
                Test-RegistryAction `
                    -Context $script:Context `
                    -Tweak $script:ValidTweak `
                    -Action $Action
            } |
                Should -Throw
        }

        It "Refuse un type de données inconnu" {

            $Action = $script:ValidTweak.Actions[0].PSObject.Copy()

            $Action.DataType = "Invalid"

            {
                Test-RegistryAction `
                    -Context $script:Context `
                    -Tweak $script:ValidTweak `
                    -Action $Action
            } |
                Should -Throw
        }

        It "Refuse une propriété obligatoire absente" {

            $Action = $script:ValidTweak.Actions[0].PSObject.Copy()

            $Action.PSObject.Properties.Remove("Hive")

            {
                Test-RegistryAction `
                    -Context $script:Context `
                    -Tweak $script:ValidTweak `
                    -Action $Action
            } |
                Should -Throw
        }
    }


    # ==================================================
    # Test-ServiceAction
    # ==================================================

    Context "Test-ServiceAction" {

        It "Accepte une action Service complète" {

            $Action = [pscustomobject]@{

                Id          = "ServiceTest"

                Name        = "DiagTrack"

                StartupType = "Disabled"

                Stop        = $true
            }

            {
                Test-ServiceAction `
                    -Context $script:Context `
                    -Tweak $script:ValidTweak `
                    -Action $Action
            } |
                Should -Not -Throw
        }

        It "Refuse un StartupType inconnu" {

            $Action = [pscustomobject]@{

                Id          = "ServiceTest"

                Name        = "DiagTrack"

                StartupType = "Invalid"

                Stop        = $false
            }

            {
                Test-ServiceAction `
                    -Context $script:Context `
                    -Tweak $script:ValidTweak `
                    -Action $Action
            } |
                Should -Throw
        }

        It "Refuse un nom de service absent" {

            $Action = [pscustomobject]@{

                Id          = "ServiceTest"

                StartupType = "Disabled"

                Stop        = $false
            }

            {
                Test-ServiceAction `
                    -Context $script:Context `
                    -Tweak $script:ValidTweak `
                    -Action $Action
            } |
                Should -Throw
        }

        It "Refuse Stop lorsqu'il n'est pas booléen" {

            $Action = [pscustomobject]@{

                Id          = "ServiceTest"

                Name        = "DiagTrack"

                StartupType = "Disabled"

                Stop        = "false"
            }

            {
                Test-ServiceAction `
                    -Context $script:Context `
                    -Tweak $script:ValidTweak `
                    -Action $Action
            } |
                Should -Throw
        }
    }


    # ==================================================
    # Test-TweakDefinitions
    # ==================================================

    Context "Test-TweakDefinitions" {

        It "Accepte un tweak valide complet" {

            {
                Test-TweakDefinitions `
                    -Context $script:Context `
                    -Tweaks @($script:ValidTweak)
            } |
                Should -Not -Throw
        }


    }
}
