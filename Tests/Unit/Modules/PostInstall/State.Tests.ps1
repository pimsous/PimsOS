# ==========================================
# Tests : PostInstall State
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..\..").Path

    . "$ProjectRoot\Modules\PostInstall\State.ps1"

}

Describe "PostInstall State" {

    Context "New-PostInstallState" {

        It "Crée un état initial Pending" {

            $State = New-PostInstallState

            $State.Status |
                Should -Be "Pending"

            $State.Started |
                Should -BeFalse

            $State.Completed |
                Should -BeFalse

            $State.Failed |
                Should -BeFalse

            $State.WaitingForNetwork |
                Should -BeFalse

            $State.NetworkAvailable |
                Should -BeFalse

        }

        It "Utilise le chemin d'état fourni" {

            $StatePath = Join-Path `
                $TestDrive `
                "state.json"

            $State = New-PostInstallState `
                -StatePath $StatePath

            $State.StatePath |
                Should -Be $StatePath

        }

    }

    Context "Save-PostInstallState / Get-PostInstallState" {

        It "Sauvegarde et recharge l'état" {

            $StatePath = Join-Path `
                $TestDrive `
                "state.json"

            $State = New-PostInstallState `
                -StatePath $StatePath

            $State.CurrentPhase = "Local"

            $State.CompletedTasks = @(
                "Local"
            )

            Save-PostInstallState `
                -State $State |
                Out-Null

            Test-Path `
                -LiteralPath $StatePath `
                -PathType Leaf |
                Should -BeTrue

            $Loaded = Get-PostInstallState `
                -StatePath $StatePath

            $Loaded.Status |
                Should -Be "Pending"

            $Loaded.CurrentPhase |
                Should -Be "Local"

            $Loaded.CompletedTasks |
                Should -Contain "Local"

        }

        It "Crée le dossier de destination automatiquement" {

            $StatePath = Join-Path `
                $TestDrive `
                "Nested\State\state.json"

            $State = New-PostInstallState `
                -StatePath $StatePath

            Save-PostInstallState `
                -State $State |
                Out-Null

            Test-Path `
                -LiteralPath $StatePath `
                -PathType Leaf |
                Should -BeTrue

        }

        It "Retourne un nouvel état si le fichier est absent" {

            $StatePath = Join-Path `
                $TestDrive `
                "Missing\state.json"

            $State = Get-PostInstallState `
                -StatePath $StatePath

            $State.Status |
                Should -Be "Pending"

        }

    }

    Context "Set-PostInstallStatus" {

        BeforeEach {

            $script:State = New-PostInstallState

        }

        It "Passe à Running" {

            Set-PostInstallStatus `
                -State $script:State `
                -Status "Running" |
                Out-Null

            $script:State.Status |
                Should -Be "Running"

            $script:State.Started |
                Should -BeTrue

            $script:State.Completed |
                Should -BeFalse

            $script:State.Failed |
                Should -BeFalse

        }

        It "Passe à WaitingForNetwork" {

            Set-PostInstallStatus `
                -State $script:State `
                -Status "WaitingForNetwork" |
                Out-Null

            $script:State.Status |
                Should -Be "WaitingForNetwork"

            $script:State.WaitingForNetwork |
                Should -BeTrue

            $script:State.Completed |
                Should -BeFalse

            $script:State.Failed |
                Should -BeFalse

        }

        It "Passe à Completed" {

            Set-PostInstallStatus `
                -State $script:State `
                -Status "Completed" |
                Out-Null

            $script:State.Status |
                Should -Be "Completed"

            $script:State.Completed |
                Should -BeTrue

            $script:State.WaitingForNetwork |
                Should -BeFalse

            $script:State.Failed |
                Should -BeFalse

        }

        It "Passe à Failed" {

            Set-PostInstallStatus `
                -State $script:State `
                -Status "Failed" |
                Out-Null

            $script:State.Status |
                Should -Be "Failed"

            $script:State.Failed |
                Should -BeTrue

            $script:State.Completed |
                Should -BeFalse

            $script:State.WaitingForNetwork |
                Should -BeFalse

        }

    }

}
