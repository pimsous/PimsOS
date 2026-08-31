# ==========================================
# Module : TweakCatalog
# Projet : PimsOS Builder
# Version : 1.0.0
# ==========================================

Set-StrictMode -Version Latest

function Get-TweakCatalog {

    [CmdletBinding()]
    param()

    $ProjectRoot = Get-ProjectRoot

    $TweaksRoot = Join-Path `
        -Path $ProjectRoot `
        -ChildPath "Tweaks"

    if (-not (Test-Path `
        -LiteralPath $TweaksRoot `
        -PathType Container)) {

        throw (
            "Le dossier Tweaks est introuvable : {0}" -f
            $TweaksRoot
        )

    }

    $Files = Get-ChildItem `
        -LiteralPath $TweaksRoot `
        -Recurse `
        -File `
        -Filter "*.json" `
        -ErrorAction Stop

    $Catalog = [System.Collections.Generic.List[object]]::new()

    foreach ($File in $Files) {

        if ($File.Length -eq 0) {
            continue
        }


        try {

            $Tweak =
                Get-Content `
                    -LiteralPath $File.FullName `
                    -Raw `
                    -Encoding UTF8 |
                ConvertFrom-Json `
                    -ErrorAction Stop

        }
        catch {

            throw (
                "Le fichier tweak est invalide : {0}. {1}" -f
                $File.FullName,
                $_.Exception.Message
            )

        }

        if (
            $null -eq $Tweak.PSObject.Properties["Id"] -or
            [string]::IsNullOrWhiteSpace([string]$Tweak.Id)
        ) {

            throw (
                "Le tweak ne possède pas d'Id : {0}" -f
                $File.FullName
            )

        }

        if (
            $null -eq $Tweak.PSObject.Properties["Name"] -or
            [string]::IsNullOrWhiteSpace([string]$Tweak.Name)
        ) {

            throw (
                "Le tweak '{0}' ne possède pas de Name." -f
                $Tweak.Id
            )

        }

        $Catalog.Add(
            [PSCustomObject]@{

                Id =
                    [string]$Tweak.Id

                Name =
                    [string]$Tweak.Name

                Description =
                    if ($Tweak.PSObject.Properties["Description"]) {
                        [string]$Tweak.Description
                    }
                    else {
                        ""
                    }

                Help =
                    if ($Tweak.PSObject.Properties["Help"]) {
                        [string]$Tweak.Help
                    }
                    else {
                        ""
                    }

                CategoryId =
                    if ($Tweak.PSObject.Properties["CategoryId"]) {
                        [string]$Tweak.CategoryId
                    }
                    else {
                        ""
                    }

                Group =
                    if ($Tweak.PSObject.Properties["Group"]) {
                        [string]$Tweak.Group
                    }
                    else {
                        ""
                    }

                Level =
                    if ($Tweak.PSObject.Properties["Level"]) {
                        [string]$Tweak.Level
                    }
                    else {
                        ""
                    }

                Risk =
                    if ($Tweak.PSObject.Properties["Risk"]) {
                        [string]$Tweak.Risk
                    }
                    else {
                        ""
                    }

                Default =
                    if ($Tweak.PSObject.Properties["Default"]) {
                        [bool]$Tweak.Default
                    }
                    else {
                        $false
                    }

                Recommended =
                    if ($Tweak.PSObject.Properties["Recommended"]) {
                        [bool]$Tweak.Recommended
                    }
                    else {
                        $false
                    }

                Reversible =
                    if ($Tweak.PSObject.Properties["Reversible"]) {
                        [bool]$Tweak.Reversible
                    }
                    else {
                        $false
                    }

                RequiresRestart =
                    if ($Tweak.PSObject.Properties["RequiresRestart"]) {
                        [bool]$Tweak.RequiresRestart
                    }
                    else {
                        $false
                    }

                Impact =
                    if ($Tweak.PSObject.Properties["Impact"]) {
                        [string]$Tweak.Impact
                    }
                    else {
                        ""
                    }


                ActionCount =
                    if ($Tweak.PSObject.Properties["Actions"]) {
                        @($Tweak.Actions).Count
                    }
                    else {
                        0
                    }

                SourcePath =
                    $File.FullName

                RelativePath =
                    $File.FullName.Substring(
                        $TweaksRoot.Length
                    ).TrimStart(
                        "\"
                    )

            }
        )

    }

    return @(
        $Catalog |
            Sort-Object `
                CategoryId,
                Group,
                Name
    )

}

