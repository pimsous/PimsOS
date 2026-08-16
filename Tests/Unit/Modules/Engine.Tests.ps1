# ==========================================
# Tests : Engine
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"
    . "$ProjectRoot\Modules\Configuration\Tweak.ps1"
    . "$ProjectRoot\Modules\Configuration\Categories.ps1"
    . "$ProjectRoot\Modules\Core\ActionRegistry.ps1"
    . "$ProjectRoot\Modules\Actions\ActionEngine.ps1"
    . "$ProjectRoot\Modules\Core\Engine.ps1"

}

Describe "Engine" {

    BeforeEach {

        Reset-Logger
        Reset-ActionRegistry

        Mock Write-Log {}

        # --------------------------------------------------
        # Handler de test
        # --------------------------------------------------

        function global:Invoke-TestAction {

            param(
                [psobject]$Context,
                [psobject]$Action
            )

            return $Context
        }

        Register-ActionHandler `
            -Type "Test" `
            -Handler "Invoke-TestAction"

        # --------------------------------------------------
        # Contexte minimal
        # --------------------------------------------------

        $script:Context = [pscustomobject]@{

            BuildState = [pscustomobject]@{

                Status = "Idle"

                Image = [pscustomobject]@{

                    TweaksApplied = $false

                }

            }

            Statistics = [pscustomobject]@{

                TweaksApplied = 0

            }

        }

        # --------------------------------------------------
        # Action de test
        # --------------------------------------------------

        $script:Action = [pscustomobject]@{

            Id = "TestAction"

            Type = "Test"

            Enabled = $true

            RequiresRestart = $false

            ContinueOnError = $false

            Executed = $false

            Success = $false

            Duration = [timespan]::Zero

            Error = $null

        }

        # --------------------------------------------------
        # Tweak de test
        # --------------------------------------------------

        $script:Tweak = [pscustomobject]@{

            Id = "TestTweak"

            Name = "Test Tweak"

            Enabled = $true

            Actions = @(
                $script:Action
            )

            Applied = $false

            Result = $null

            Duration = [timespan]::Zero

            Errors = @()

            Warnings = @()

            Statistics = [pscustomobject]@{

                Actions = 1

                Executed = 0

                Failed = 0

            }

        }

    }


    # ==================================================
    # Invoke-Tweak
    # ==================================================

    Context "Invoke-Tweak" {

        It "Applique un tweak actif" {

            $Context = Invoke-Tweak `
                -Context $script:Context `
                -Tweak $script:Tweak

            $script:Tweak.Applied |
                Should -BeTrue

        }

        It "Positionne le résultat à Success" {

            Invoke-Tweak `
                -Context $script:Context `
                -Tweak $script:Tweak |
                Out-Null

            $script:Tweak.Result |
                Should -Be "Success"

        }

        It "Incrémente Executed" {

            Invoke-Tweak `
                -Context $script:Context `
                -Tweak $script:Tweak |
                Out-Null

            $script:Tweak.Statistics.Executed |
                Should -Be 1

        }

        It "Incrémente TweaksApplied" {

            Invoke-Tweak `
                -Context $script:Context `
                -Tweak $script:Tweak |
                Out-Null

            $script:Context.Statistics.TweaksApplied |
                Should -Be 1

        }

        It "Ignore une action désactivée" {

            $script:Tweak.Actions[0].Enabled = $false

            Invoke-Tweak `
                -Context $script:Context `
                -Tweak $script:Tweak |
                Out-Null

            $script:Tweak.Applied |
                Should -BeTrue

            $script:Tweak.Statistics.Executed |
                Should -Be 0

        }

        It "Ignore un tweak sans action" {

            $Tweak = [pscustomobject]@{

                Id = "EmptyTweak"

                Name = "Empty Tweak"

                Actions = @()

                Applied = $false

                Result = $null

                Duration = [timespan]::Zero

                Errors = @()

                Statistics = [pscustomobject]@{

                    Executed = 0
                    Failed = 0

                }

            }

            $Context = Invoke-Tweak `
                -Context $script:Context `
                -Tweak $Tweak

            $Tweak.Result |
                Should -Be "Skipped"

            $Context |
                Should -Not -BeNullOrEmpty

        }

        It "Lève une exception lorsqu'une action échoue" {

            function global:Invoke-TestAction {

                param(
                    [psobject]$Context,
                    [psobject]$Action
                )

                throw "Erreur de test"
            }

            {

                Invoke-Tweak `
                    -Context $script:Context `
                    -Tweak $script:Tweak

            } | Should -Throw

            $script:Tweak.Applied |
                Should -BeFalse

            $script:Tweak.Result |
                Should -Be "Failed"

            $script:Tweak.Statistics.Failed |
                Should -Be 1

        }

    }


    # ==================================================
    # Invoke-Configuration
    # ==================================================

    Context "Invoke-Configuration" {



        It "Applique un tweak actif" {

            $Context = Invoke-Configuration `
                -Context $script:Context `
                -Configuration @(
                    $script:Tweak
                )

            $script:Tweak.Applied |
                Should -BeTrue

            $Context.BuildState.Image.TweaksApplied |
                Should -BeTrue

        }

        It "Ignore un tweak désactivé" {

            $script:Tweak.Enabled = $false

            $Context = Invoke-Configuration `
                -Context $script:Context `
                -Configuration @(
                    $script:Tweak
                )

            $script:Tweak.Applied |
                Should -BeFalse

            $Context.BuildState.Image.TweaksApplied |
                Should -BeTrue

        }

        It "Positionne le statut à ConfigurationApplied" {

            $Context = Invoke-Configuration `
                -Context $script:Context `
                -Configuration @(
                    $script:Tweak
                )

            $Context.BuildState.Status |
                Should -Be "ConfigurationApplied"

        }

    }

}
