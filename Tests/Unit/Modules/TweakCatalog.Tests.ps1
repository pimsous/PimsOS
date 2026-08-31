# ==========================================
# Tests : TweakCatalog
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot =
        (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"
	. "$ProjectRoot\Modules\Core\Core.ps1"
	. "$ProjectRoot\Modules\Configuration\TweakCatalog.ps1"

}

Describe "Get-TweakCatalog" {

    BeforeEach {

        Mock Get-ProjectRoot {
            return $TestDrive
        }

        $TweaksRoot =
            Join-Path `
                -Path $TestDrive `
                -ChildPath "Tweaks"

        if (Test-Path -LiteralPath $TweaksRoot) {

            Remove-Item `
                -LiteralPath $TweaksRoot `
                -Recurse `
                -Force

        }

        New-Item `
            -ItemType Directory `
            -Path $TweaksRoot `
            -Force |
            Out-Null

    }

    It "Charge les tweaks JSON du catalogue" {

        $Tweak = @'
{
    "Id": "Test.Example",
    "Name": "Exemple de tweak",
    "Description": "Description du tweak.",
    "CategoryId": "Test",
    "Group": "Examples",
    "Level": "Official",
    "Risk": "Safe",
    "Default": true,
    "Recommended": true,
    "Reversible": true,
    "RequiresRestart": false,
    "Actions": [
        {
            "Id": "Test.Example.Registry01",
            "Type": "Registry"
        }
    ]
}
'@

        Set-Content `
            -LiteralPath (
                Join-Path $TweaksRoot "Example.json"
            ) `
            -Value $Tweak `
            -Encoding UTF8

        $Result = Get-TweakCatalog

        $Result.Count |
            Should -Be 1

        $Result[0].Id |
            Should -Be "Test.Example"

    }

    It "Expose les informations nécessaires à l'affichage" {

        Set-Content `
            -LiteralPath (
                Join-Path $TweaksRoot "Example.json"
            ) `
            -Value @'
{
    "Id": "Test.Example",
    "Name": "Exemple",
    "Description": "Description",
    "Help": "Aide",
    "CategoryId": "Privacy",
    "Group": "Telemetry",
    "Level": "Official",
    "Risk": "Safe",
    "Default": true,
    "Recommended": true,
    "Reversible": true,
    "RequiresRestart": true,
    "Impact": "Impact de test",
    "Actions": [
        {
            "Id": "Action01"
        },
        {
            "Id": "Action02"
        }
    ]
}
'@ `
            -Encoding UTF8

        $Result = Get-TweakCatalog

        $Result[0].Name |
            Should -Be "Exemple"

        $Result[0].Description |
            Should -Be "Description"

        $Result[0].Help |
            Should -Be "Aide"

        $Result[0].CategoryId |
            Should -Be "Privacy"

        $Result[0].Group |
            Should -Be "Telemetry"

        $Result[0].Risk |
            Should -Be "Safe"

        $Result[0].Recommended |
            Should -BeTrue

        $Result[0].Reversible |
            Should -BeTrue

        $Result[0].RequiresRestart |
            Should -BeTrue

        $Result[0].Impact |
            Should -Be "Impact de test"

        $Result[0].ActionCount |
            Should -Be 2

    }

    It "Utilise des valeurs par défaut pour les propriétés optionnelles" {

        Set-Content `
            -LiteralPath (
                Join-Path $TweaksRoot "Example.json"
            ) `
            -Value @'
{
    "Id": "Test.Example",
    "Name": "Exemple"
}
'@ `
            -Encoding UTF8

        $Result = Get-TweakCatalog

        $Result[0].Description |
            Should -Be ""

        $Result[0].Default |
            Should -BeFalse

        $Result[0].Recommended |
            Should -BeFalse

        $Result[0].Reversible |
            Should -BeFalse

        $Result[0].RequiresRestart |
            Should -BeFalse

        $Result[0].ActionCount |
            Should -Be 0

    }

    It "Charge les fichiers dans les sous-dossiers" {

        $PrivacyRoot =
            Join-Path $TweaksRoot "Privacy"

        New-Item `
            -ItemType Directory `
            -Path $PrivacyRoot `
            -Force |
            Out-Null

        Set-Content `
            -LiteralPath (
                Join-Path $PrivacyRoot "Privacy.json"
            ) `
            -Value @'
{
    "Id": "Privacy.Test",
    "Name": "Test Privacy"
}
'@ `
            -Encoding UTF8

        $Result = Get-TweakCatalog

        $Result.Id |
            Should -Contain "Privacy.Test"

    }

    It "Refuse un tweak sans Id" {

        Set-Content `
            -LiteralPath (
                Join-Path $TweaksRoot "Invalid.json"
            ) `
            -Value @'
{
    "Name": "Tweak invalide"
}
'@ `
            -Encoding UTF8

        {
            Get-TweakCatalog
        } |
            Should -Throw "*ne possède pas d'Id*"

    }

    It "Refuse un tweak sans Name" {

        Set-Content `
            -LiteralPath (
                Join-Path $TweaksRoot "Invalid.json"
            ) `
            -Value @'
{
    "Id": "Test.Invalid"
}
'@ `
            -Encoding UTF8

        {
            Get-TweakCatalog
        } |
            Should -Throw "*ne possède pas de Name*"

    }

    It "Refuse un JSON invalide" {

        Set-Content `
            -LiteralPath (
                Join-Path $TweaksRoot "Invalid.json"
            ) `
            -Value "{ JSON INVALIDE" `
            -Encoding UTF8

        {
            Get-TweakCatalog
        } |
            Should -Throw "*fichier tweak est invalide*"

    }

    It "Trie le catalogue par catégorie, groupe puis nom" {

        Set-Content `
            -LiteralPath (
                Join-Path $TweaksRoot "B.json"
            ) `
            -Value @'
{
    "Id": "B",
    "Name": "Zeta",
    "CategoryId": "Privacy",
    "Group": "B"
}
'@ `
            -Encoding UTF8

        Set-Content `
            -LiteralPath (
                Join-Path $TweaksRoot "A.json"
            ) `
            -Value @'
{
    "Id": "A",
    "Name": "Alpha",
    "CategoryId": "Privacy",
    "Group": "A"
}
'@ `
            -Encoding UTF8

        $Result = @(Get-TweakCatalog)

        $Result[0].Id |
            Should -Be "A"

        $Result[1].Id |
            Should -Be "B"

    }

    It "Charge correctement le tweak Windows.EnableNumLock" {

        $RealTweakPath =
            Join-Path `
                $ProjectRoot `
                "Tweaks\Windows\EnableNumLock.json"

        if (-not (Test-Path -LiteralPath $RealTweakPath)) {
            throw "Le fichier Windows.EnableNumLock.json est introuvable."
        }

        $Result = & {
            $OriginalTestDrive = $TestDrive

            Mock Get-ProjectRoot {
                return $ProjectRoot
            }

            Get-TweakCatalog
        } |
            Where-Object Id -eq "Windows.EnableNumLock"

        $Result |
            Should -Not -BeNullOrEmpty

        $Result.Name |
            Should -Be "Activer le pavé numérique au démarrage"

        $Result.CategoryId |
            Should -Be "Windows"

        $Result.Group |
            Should -Be "Keyboard"

        $Result.Level |
            Should -Be "Official"

        $Result.Risk |
            Should -Be "Safe"

        $Result.Recommended |
            Should -BeTrue

        $Result.Reversible |
            Should -BeTrue

        $Result.RequiresRestart |
            Should -BeTrue

        $Result.ActionCount |
            Should -Be 1
    }
}

