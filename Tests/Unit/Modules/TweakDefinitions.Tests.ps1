# ==========================================
# Tests : TweakDefinitions
# Projet : PimsOS Builder
# Version : 3.0.0
# ==========================================

BeforeAll {
    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    $Expected = @{
        "Explorer.ShowSecondsInSystemClock" = @{
            Path = "Tweaks\Explorer\ShowSecondsInSystemClock.json"
            Hive = "DEFAULT"
            Key = "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            Name = "ShowSecondsInSystemClock"
            Value = 1
            DataType = "DWord"
        }
        "Search.DisableSearchHighlights" = @{
            Path = "Tweaks\Search\DisableSearchHighlights.json"
            Hive = "SOFTWARE"
            Key = "Policies\Microsoft\Windows\Windows Search"
            Name = "EnableDynamicContentInWSB"
            Value = 0
            DataType = "DWord"
        }
        "Start.HideRecommendedPersonalizedSites" = @{
            Path = "Tweaks\Start\HideRecommendedPersonalizedSites.json"
            Hive = "SOFTWARE"
            Key = "Policies\Microsoft\Windows\Explorer"
            Name = "HideRecommendedPersonalizedSites"
            Value = 1
            DataType = "DWord"
        }
        "Start.HideRecommendedSection" = @{
            Path = "Tweaks\Start\HideRecommendedSection.json"
            Hive = "SOFTWARE"
            Key = "Policies\Microsoft\Windows\Explorer"
            Name = "HideRecommendedSection"
            Value = 1
            DataType = "DWord"
        }
        "Privacy.DisableTailoredExperiences" = @{
            Path = "Tweaks\Privacy\DisableTailoredExperiences.json"
            Hive = "DEFAULT"
            Key = "Software\Policies\Microsoft\Windows\CloudContent"
            Name = "DisableTailoredExperiencesWithDiagnosticData"
            Value = 1
            DataType = "DWord"
        }
        "Privacy.DisableThirdPartySpotlightSuggestions" = @{
            Path = "Tweaks\Privacy\DisableThirdPartySpotlightSuggestions.json"
            Hive = "DEFAULT"
            Key = "Software\Policies\Microsoft\Windows\CloudContent"
            Name = "DisableThirdPartySuggestions"
            Value = 1
            DataType = "DWord"
        }
        "WindowsAI.DisableRecallSnapshots" = @{
            Path = "Tweaks\WindowsAI\DisableRecallSnapshots.json"
            Hive = "SOFTWARE"
            Key = "Policies\Microsoft\Windows\WindowsAI"
            Name = "DisableAIDataAnalysis"
            Value = 1
            DataType = "DWord"
        }
        "WindowsAI.DisableRecall" = @{
            Path = "Tweaks\WindowsAI\DisableRecall.json"
            Hive = "SOFTWARE"
            Key = "Policies\Microsoft\Windows\WindowsAI"
            Name = "AllowRecallEnablement"
            Value = 0
            DataType = "DWord"
        }
    }
}

Describe "Catalogue des nouveaux Tweaks PimsOS" {

    It "contient tous les nouveaux Tweaks validés" {
        foreach ($Id in $Expected.Keys) {
            $Definition = Join-Path $ProjectRoot $Expected[$Id].Path
            Test-Path -LiteralPath $Definition |
                Should -BeTrue -Because "le fichier du tweak $Id doit exister"
        }
    }

    It "respecte la définition registre attendue" {
        foreach ($Id in $Expected.Keys) {

            $DefinitionPath = Join-Path $ProjectRoot $Expected[$Id].Path
            $Definition = Get-Content -LiteralPath $DefinitionPath -Raw |
                ConvertFrom-Json

            $Definition.Id |
                Should -Be $Id

            $Definition.Actions.Count |
                Should -Be 1

            $Action = $Definition.Actions[0]

            $Action.Type |
                Should -Be "Registry"

            $Action.Hive |
                Should -Be $Expected[$Id].Hive

            $Action.Key |
                Should -Be $Expected[$Id].Key

            $Action.Name |
                Should -Be $Expected[$Id].Name

            $Action.Value |
                Should -Be $Expected[$Id].Value

            $Action.DataType |
                Should -Be $Expected[$Id].DataType

            $Definition.Reversible |
                Should -BeTrue

            $Definition.Description |
                Should -Not -BeNullOrEmpty

            $Definition.Help |
                Should -Not -BeNullOrEmpty

            $Definition.Impact |
                Should -Not -BeNullOrEmpty
        }
    }

    It "ne recommande pas par défaut les réglages potentiellement intrusifs" {

        foreach ($Id in @(
            "Explorer.ShowSecondsInSystemClock",
            "Start.HideRecommendedSection",
            "WindowsAI.DisableRecall",
            "WindowsAI.DisableRecallSnapshots"
        )) {

            $DefinitionPath = Join-Path $ProjectRoot $Expected[$Id].Path
            $Definition = Get-Content -LiteralPath $DefinitionPath -Raw |
                ConvertFrom-Json

            $Definition.Default |
                Should -BeFalse
        }
    }
}

Describe "Documentation Explorer" {

    It "explique la différence entre fichiers cachés et fichiers système protégés" {

        $Hidden = Get-Content `
            -LiteralPath (Join-Path $ProjectRoot "Tweaks\Explorer\ShowHiddenFiles.json") `
            -Raw |
            ConvertFrom-Json

        $Protected = Get-Content `
            -LiteralPath (Join-Path $ProjectRoot "Tweaks\Explorer\ShowProtectedSystemFiles.json") `
            -Raw |
            ConvertFrom-Json

        $Hidden.Impact |
            Should -Match "fichiers système protégés"

        $Protected.Impact |
            Should -Match "pagefile\.sys"

        $Protected.Impact |
            Should -Match "desktop\.ini"
    }
}
