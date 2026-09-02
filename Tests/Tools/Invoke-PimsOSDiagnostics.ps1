#requires -Version 7.0
<#
.SYNOPSIS
    Diagnostic statique et sécurisé du dépôt PimsOS.

.DESCRIPTION
    Analyse les tests Pester avant exécution afin de distinguer :
      SAFE           : test ne présentant pas d'appel build réel détectable.
      BUILD-CAPABLE  : appel à une opération de build potentiellement réelle.
      UNKNOWN        : analyse statique insuffisante -> jamais exécuté automatiquement.

    IMPORTANT :
      - -InventoryOnly n'exécute aucun test.
      - En mode -Unit, les BUILD-CAPABLE et UNKNOWN sont exclus.
      - -BuildValidation exige explicitement -AllowBuild.
      - Le script ne lance jamais Initialize-PimsOS pendant l'inventaire.

.EXAMPLE
    .\Invoke-PimsOSDiagnostics.ps1 -Unit -InventoryOnly

.EXAMPLE
    .\Invoke-PimsOSDiagnostics.ps1 -Unit -ExplainFailures

.EXAMPLE
    .\Invoke-PimsOSDiagnostics.ps1 -Integration -InventoryOnly -ExplainFailures

.EXAMPLE
    .\Invoke-PimsOSDiagnostics.ps1 -BuildValidation -AllowBuild -InventoryOnly -ExplainFailures

.EXAMPLE
    .\Invoke-PimsOSDiagnostics.ps1 -BuildValidation -AllowBuild -ExplainFailures
#>

[CmdletBinding()]
param(
    [switch]$Unit,
    [switch]$Integration,
    [switch]$BuildValidation,
    [switch]$AllowBuild,
    [switch]$InventoryOnly,
    [switch]$ExplainFailures
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$TestsRoot   = Join-Path $ProjectRoot 'Tests'
$ReportsRoot = Join-Path $TestsRoot 'Reports\Diagnostics'

New-Item -ItemType Directory -Path $ReportsRoot -Force | Out-Null

if (-not ($Unit -or $Integration -or $BuildValidation)) {
    $Unit = $true
}

if (($Unit -and $Integration) -or ($BuildValidation -and ($Unit -or $Integration))) {
    throw 'Choisissez un seul mode : -Unit, -Integration ou -BuildValidation.'
}

if ($BuildValidation -and -not $AllowBuild) {
    throw 'Le mode -BuildValidation exige explicitement -AllowBuild.'
}

function Get-PesterVersion {
    $module = Get-Module -ListAvailable Pester |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if ($module) { return [string]$module.Version }
    return 'Non installé'
}

function Get-TestFiles {
    param([string]$Root)

    $files = [System.Collections.Generic.List[object]]::new()

    if ($Unit -or $BuildValidation) {
        $unitRoot = Join-Path $Root 'Unit'
        if (Test-Path $unitRoot) {
            Get-ChildItem $unitRoot -Recurse -Filter '*.Tests.ps1' -File |
                ForEach-Object { $files.Add($_) }
        }
    }

    if ($Integration -or $BuildValidation) {
        $integrationRoot = Join-Path $Root 'Integration'
        if (Test-Path $integrationRoot) {
            Get-ChildItem $integrationRoot -Recurse -Filter '*.Tests.ps1' -File |
                ForEach-Object { $files.Add($_) }
        }

        $rootIntegration = Join-Path $Root 'Integration.Tests.ps1'
        if (Test-Path $rootIntegration) {
            $files.Add((Get-Item $rootIntegration))
        }
    }

    return @($files | Sort-Object FullName -Unique)
}

function Get-FunctionBody {
    param(
        [string]$Text,
        [string]$Name
    )

    # Analyse approximative suffisante pour le classement de sécurité.
    # On extrait les blocs Mock associés au nom demandé.
    $escaped = [regex]::Escape($Name)
    $pattern = "(?is)Mock\s+$escaped\b.*?(?=(?:\r?\n\s*Mock\s+)|(?:\r?\n\s*It\s+)|(?:\r?\n\s*Context\s+)|\z)"
    return @([regex]::Matches($Text, $pattern) | ForEach-Object { $_.Value })
}

function Test-CommandActuallyMocked {
    param(
        [string]$Text,
        [string]$Name
    )

    $blocks = @(Get-FunctionBody -Text $text -Name $Name)
    return ($blocks.Count -gt 0)
}

function Test-ForcedDryRun {
    param([string]$Text)

    return (
        $Text -match '(?im)\bDryRun\s*=\s*\$true\b' -or
        $Text -match '(?im)\bCreateISO\s*=\s*\$false\b'
    )
}

function Get-BuildRisk {
    param(
        [System.IO.FileInfo]$File
    )

    $text = Get-Content -LiteralPath $File.FullName -Raw -ErrorAction Stop

    $dangerous = @(
        'Initialize-PimsOS',
        'Invoke-BuildPipeline',
        'Complete-Build',
        'Mount-Wim',
        'Mount-WindowsImage',
        'Dismount-Wim',
        'oscdimg'
    )

    $hits = [System.Collections.Generic.List[string]]::new()
    $unmocked = [System.Collections.Generic.List[string]]::new()

    foreach ($name in $dangerous) {

        $escaped = [regex]::Escape($name)

        if ($text -notmatch "(?im)\b$escaped\b") {
            continue
        }

        $hits.Add($name)

        # --------------------------------------------------
        # 1. Appel explicite
        # --------------------------------------------------

        # Détecte également les appels avec affectation :
        #   Initialize-PimsOS ...
        #   $Result = Initialize-PimsOS ...
        #   & Initialize-PimsOS ...
        $invokePattern = "(?im)^\s*(?:(?:\$[\w:.-]+|\$\{[^}]+\})\s*=\s*)?(?:&\s*)?$escaped\b"
        $isInvoked = $text -match $invokePattern

        if (-not $isInvoked) {
            continue
        }

        # --------------------------------------------------
        # 2. Mock Pester explicite
        # --------------------------------------------------

        $mocked = Test-CommandActuallyMocked `
            -Text $text `
            -Name $name

        # --------------------------------------------------
        # Fonction directement testée
        #
        # Un fichier X.Tests.ps1 peut naturellement invoquer
        # X sans que cela constitue un build réel.
        #
        # On analyse ensuite ses dépendances dangereuses,
        # mais on ne classe pas X lui-même comme dangereux.
        # --------------------------------------------------

        $functionUnderTest = $File.Name -match (
            '^{0}\.Tests\.ps1$' -f [regex]::Escape($name)
        )

        if ($functionUnderTest) {
            continue
        }

        # --------------------------------------------------
        # Initialize-PimsOS est une API de build.
        #
        # Un test d'intégration qui invoque réellement
        # Initialize-PimsOS est BUILD-CAPABLE.
        #
        # Un Mock Pester explicite neutralise cet appel.
        # --------------------------------------------------

        if ($name -eq 'Initialize-PimsOS') {

            if ($mocked) {
                continue
            }

            if ($File.FullName -match '\\Tests\\Integration(\\|\.Tests\.ps1$)') {
                $unmocked.Add($name)
                continue
            }
        }

        if ($mocked) {
            continue
        }

        # --------------------------------------------------
        # 3. Neutralisation par faux outil / TestDrive
        #
        # Exemple :
        #   oscdimg.exe créé dans $TestDrive
        #   PATH temporairement modifié
        # --------------------------------------------------

        $fakeTool = $false

        if (
            $name -eq 'oscdimg' -and
            $text -match '(?is)\$TestDrive' -and
            $text -match '(?im)oscdimg(?:\.exe)?' -and
            (
                $text -match '(?im)Set-Content.*oscdimg' -or
                $text -match '(?im)New-Item.*oscdimg' -or
                $text -match '(?im)Out-File.*oscdimg' -or
                $text -match '(?im)\$env:PATH.*\$TestDrive'
            )
        ) {
            $fakeTool = $true
        }

        if ($fakeTool) {
            continue
        }

        # --------------------------------------------------
        # 4. Appel neutralisé explicitement par DryRun
        # --------------------------------------------------

        if (Test-ForcedDryRun -Text $text) {
            continue
        }

        # --------------------------------------------------
        # 5. Appel réellement non neutralisé
        # --------------------------------------------------

        $unmocked.Add($name)
    }

    $dryRun = Test-ForcedDryRun -Text $text

    $relative = $File.FullName.Substring(
        $ProjectRoot.Length
    ).TrimStart('\')

    # ------------------------------------------------------
    # SAFE
    # ------------------------------------------------------

    if ($unmocked.Count -eq 0) {

        return [pscustomobject]@{
            File           = $File
            RelativePath   = $relative
            Classification = 'SAFE'
            Reasons        = @(
                'Aucun appel build non neutralisé détecté.'
            )
            Dangerous      = @($hits)
            Unmocked       = @()
        }
    }

    # ------------------------------------------------------
    # BUILD-CAPABLE
    #
    # Un appel réel à Initialize-PimsOS est suffisant.
    # ------------------------------------------------------

    if ($unmocked -contains 'Initialize-PimsOS') {

        return [pscustomobject]@{
            File           = $File
            RelativePath   = $relative
            Classification = 'BUILD-CAPABLE'
            Reasons        = @(
                "Appel réel non neutralisé : Initialize-PimsOS."
            )
            Dangerous      = @($hits)
            Unmocked       = @($unmocked)
        }
    }

    # ------------------------------------------------------
    # Les tests d'intégration appelant une opération build
    # non neutralisée restent BUILD-CAPABLE.
    # ------------------------------------------------------

    if (
        $unmocked.Count -gt 0 -and
        $File.FullName -match '\\Tests\\Integration(\\|\.Tests\.ps1$)'
    ) {

        return [pscustomobject]@{
            File           = $File
            RelativePath   = $relative
            Classification = 'BUILD-CAPABLE'
            Reasons        = @(
                "Appel(s) potentiellement réel(s) : $($unmocked -join ', ')."
            )
            Dangerous      = @($hits)
            Unmocked       = @($unmocked)
        }
    }

    # ------------------------------------------------------
    # UNKNOWN
    #
    # Cas où le scanner détecte une opération dangereuse
    # mais ne peut pas établir suffisamment clairement
    # si elle est neutralisée.
    # ------------------------------------------------------

    return [pscustomobject]@{
        File           = $File
        RelativePath   = $relative
        Classification = 'UNKNOWN'
        Reasons        = @(
            "Appel potentiellement dangereux détecté sans preuve suffisante de neutralisation : $($unmocked -join ', ')."
        )
        Dangerous      = @($hits)
        Unmocked       = @($unmocked)
    }
}

function Get-TestSelection {
    param([object[]]$Inventory)

    switch ($true) {
        $Unit {
            return @($Inventory | Where-Object Classification -eq 'SAFE')
        }

        $Integration {
            return @(
                $Inventory |
                    Where-Object {
                        $_.Classification -eq 'SAFE'
                    }
            )
        }

        $BuildValidation {
            return @(
                $Inventory |
                    Where-Object {
                        $_.Classification -eq 'BUILD-CAPABLE'
                    }
            )
        }

        default {
            return @()
        }
    }
}

function Get-PesterFailureDetails {
    param([object]$PesterResult)

    $failures = [System.Collections.Generic.List[object]]::new()

    if ($null -eq $PesterResult) {
        return @()
    }

    $failedItems = @()
    if ($PesterResult.PSObject.Properties['Failed']) {
        $failedItems = @($PesterResult.Failed)
    }

    foreach ($failure in $failedItems) {
        $name = $null
        foreach ($property in @('ExpandedName', 'Name', 'ParameterizedSuiteName')) {
            if ($failure.PSObject.Properties[$property] -and $failure.$property) {
                $name = [string]$failure.$property
                break
            }
        }
        if (-not $name) { $name = 'Test Pester sans nom' }

        $path = $null
        if ($failure.PSObject.Properties['ScriptBlock'] -and $failure.ScriptBlock) {
            try { $path = [string]$failure.ScriptBlock.File }
            catch { $path = $null }
        }
        if (-not $path -and $failure.PSObject.Properties['Block'] -and $failure.Block) {
            try {
                if ($failure.Block.PSObject.Properties['Path']) {
                    $path = [string]$failure.Block.Path
                }
            }
            catch { $path = $null }
        }

        $message = $null
        $line = $null
        $position = $null

        $errorRecord = $null
        foreach ($property in @('ErrorRecord', 'ErrorRecordException')) {
            if ($failure.PSObject.Properties[$property] -and $failure.$property) {
                $errorRecord = $failure.$property
                break
            }
        }

        if ($errorRecord) {
            try {
                if ($errorRecord.PSObject.Properties['Exception'] -and $errorRecord.Exception) {
                    $message = [string]$errorRecord.Exception.Message
                }
                elseif ($errorRecord.PSObject.Properties['Message']) {
                    $message = [string]$errorRecord.Message
                }
            }
            catch { }

            try {
                if ($errorRecord.PSObject.Properties['InvocationInfo'] -and $errorRecord.InvocationInfo) {
                    $invocation = $errorRecord.InvocationInfo
                    if ($invocation.PSObject.Properties['ScriptName'] -and $invocation.ScriptName) {
                        $path = [string]$invocation.ScriptName
                    }
                    if ($invocation.PSObject.Properties['ScriptLineNumber']) {
                        $line = [int]$invocation.ScriptLineNumber
                    }
                    if ($invocation.PSObject.Properties['PositionMessage']) {
                        $position = [string]$invocation.PositionMessage
                    }
                }
            }
            catch { }
        }

        if (-not $message -and $failure.PSObject.Properties['ErrorRecord']) {
            try { $message = [string]$failure.ErrorRecord }
            catch { }
        }
        if (-not $message -and $failure.PSObject.Properties['Result']) {
            try { $message = [string]$failure.Result }
            catch { }
        }
        if (-not $message) { $message = 'Erreur Pester non détaillée.' }

        if (-not $path) {
            try {
                if ($failure.PSObject.Properties['Container'] -and $failure.Container) {
                    if ($failure.Container.PSObject.Properties['Item']) {
                        $path = [string]$failure.Container.Item
                    }
                }
            }
            catch { }
        }

        $relativePath = $path
        if ($path -and $path.StartsWith($ProjectRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            $relativePath = $path.Substring($ProjectRoot.Length).TrimStart('\')
        }

        $failures.Add([ordered]@{
            Path          = $relativePath
            Name          = $name
            Message       = $message
            Line          = $line
            Position      = $position
        })
    }

    return @($failures)
}

function Write-Inventory {
    param([object[]]$Inventory)

    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host ' PimsOS DIAGNOSTICS' -ForegroundColor Cyan
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host "Projet       : $ProjectRoot"
    Write-Host "PowerShell   : $($PSVersionTable.PSVersion)"
    Write-Host "Pester       : $(Get-PesterVersion)"

    $mode = if ($BuildValidation) { 'BuildValidation' }
            elseif ($Integration) { 'Integration' }
            else { 'Unit' }

    Write-Host "Mode         : $mode"

    if ($BuildValidation) {
        Write-Host 'Build réel   : AUTORISÉ' -ForegroundColor Yellow
    }
    else {
        Write-Host 'Build réel   : INTERDIT' -ForegroundColor Green
    }

    $unitCount = @($Inventory | Where-Object RelativePath -like 'Tests\Unit\*').Count
    $intCount  = @($Inventory | Where-Object RelativePath -like 'Tests\Integration*').Count
    $buildCount = @($Inventory | Where-Object Classification -eq 'BUILD-CAPABLE').Count
    $unknownCount = @($Inventory | Where-Object Classification -eq 'UNKNOWN').Count

    Write-Host "Unit         : $unitCount"
    Write-Host "Integration  : $intCount"
    Write-Host "Build-capable: $buildCount"
    Write-Host "Unknown      : $unknownCount"

    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host ' INVENTAIRE' -ForegroundColor Cyan
    Write-Host '============================================================'

    foreach ($item in $Inventory) {
        $label = "[{0}] {1}" -f $item.Classification, $item.RelativePath

        switch ($item.Classification) {
            'SAFE' {
                Write-Host $label -ForegroundColor Green
            }
            'BUILD-CAPABLE' {
                Write-Host $label -ForegroundColor Yellow
            }
            'UNKNOWN' {
                Write-Host $label -ForegroundColor Red
            }
        }

        if ($ExplainFailures -and $item.Classification -ne 'SAFE') {
            foreach ($reason in $item.Reasons) {
                Write-Host "       -> $reason"
            }
        }
    }
}

$files = @(Get-TestFiles -Root $TestsRoot)
$inventory = @(
    foreach ($file in @($files)) {
        Get-BuildRisk -File $file
    }
)

Write-Inventory -Inventory $inventory

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$reportMd = Join-Path $ReportsRoot "Diagnostics-$timestamp.md"
$reportJson = Join-Path $ReportsRoot "Diagnostics-$timestamp.json"

$selected = @(
    foreach ($item in @(Get-TestSelection -Inventory $inventory)) {

        if ($null -eq $item) {
            continue
        }

        if (-not $item.PSObject.Properties['RelativePath']) {
            continue
        }

        $item
    }
)

$report = [ordered]@{
    Date             = (Get-Date).ToString('s')
    Project          = $ProjectRoot
    PowerShell       = [string]$PSVersionTable.PSVersion
    Pester           = Get-PesterVersion
    Mode             = if ($BuildValidation) { 'BuildValidation' } elseif ($Integration) { 'Integration' } else { 'Unit' }
    AllowBuild       = [bool]$AllowBuild
    InventoryOnly    = [bool]$InventoryOnly
    TotalFiles       = $inventory.Count
    Safe             = @($inventory | Where-Object Classification -eq 'SAFE').Count
    BuildCapable     = @($inventory | Where-Object Classification -eq 'BUILD-CAPABLE').Count
    Unknown          = @($inventory | Where-Object Classification -eq 'UNKNOWN').Count
    Selected         = @(
        foreach ($item in $selected) {
            [string]$item.RelativePath
        }
    )
    Failures         = @()
    Inventory        = @(
        $inventory | ForEach-Object {
            [ordered]@{
                Path           = $_.RelativePath
                Classification = $_.Classification
                Reasons        = @($_.Reasons)
                Dangerous      = @($_.Dangerous)
                Unmocked       = @($_.Unmocked)
            }
        }
    )
}

$failureDetails = @()

$md = [System.Text.StringBuilder]::new()
[void]$md.AppendLine('# PimsOS Diagnostics')
[void]$md.AppendLine('')
[void]$md.AppendLine("- Date : $($report.Date)")
[void]$md.AppendLine("- Mode : $($report.Mode)")
[void]$md.AppendLine("- Build réel autorisé : $($report.AllowBuild)")
[void]$md.AppendLine("- Fichiers analysés : $($report.TotalFiles)")
[void]$md.AppendLine("- SAFE : $($report.Safe)")
[void]$md.AppendLine("- BUILD-CAPABLE : $($report.BuildCapable)")
[void]$md.AppendLine("- UNKNOWN : $($report.Unknown)")
[void]$md.AppendLine('')
[void]$md.AppendLine('## Classification')
[void]$md.AppendLine('')

foreach ($item in $inventory) {
    [void]$md.AppendLine("- **$($item.Classification)** — $($item.RelativePath)")
    foreach ($reason in $item.Reasons) {
        [void]$md.AppendLine("  - $reason")
    }
}

if ($InventoryOnly) {
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host ' INVENTAIRE TERMINÉ' -ForegroundColor Cyan
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host 'Aucun test exécuté.'
    Write-Host 'Aucun build exécuté.'
}
else {
    if ($selected.Count -eq 0) {
        Write-Host ''
        Write-Host 'Aucun test sélectionné pour ce mode.' -ForegroundColor Yellow
    }
    else {
        Write-Host ''
        Write-Host '============================================================' -ForegroundColor Cyan
        Write-Host ' EXÉCUTION' -ForegroundColor Cyan
        Write-Host '============================================================'

        $paths = @(
            foreach ($item in $selected) {

                if (
                    $item.PSObject.Properties['File'] -and
                    $null -ne $item.File
                ) {
                    [string]$item.File.FullName
                }
            }
        )

        # BuildValidation ne sélectionne QUE les tests explicitement classés
        # BUILD-CAPABLE. Les UNKNOWN restent toujours bloqués.
        if ($BuildValidation) {
            Write-Host "Tests build-capable sélectionnés : $($paths.Count)" -ForegroundColor Yellow
        }
        else {
            Write-Host "Tests SAFE sélectionnés : $($paths.Count)" -ForegroundColor Green
        }

        $pesterResult = Invoke-Pester -Path $paths -PassThru -Output Detailed
        $failureDetails = @(Get-PesterFailureDetails -PesterResult $pesterResult)
        $report.Failures = @($failureDetails)

        [void]$md.AppendLine('')
        [void]$md.AppendLine('## Résultats')
        [void]$md.AppendLine('')
        [void]$md.AppendLine("| Total | Pass | Fail | Skip |")
        [void]$md.AppendLine("|---:|---:|---:|---:|")
        [void]$md.AppendLine("| $($pesterResult.TotalCount) | $($pesterResult.PassedCount) | $($pesterResult.FailedCount) | $($pesterResult.SkippedCount) |")

        if ($failureDetails.Count -gt 0) {
            [void]$md.AppendLine('')
            [void]$md.AppendLine('## Échecs détaillés')
            [void]$md.AppendLine('')
            foreach ($failure in $failureDetails) {
                [void]$md.AppendLine("### $($failure.Name)")
                if ($failure.Path) { [void]$md.AppendLine("- Fichier : $($failure.Path)") }
                if ($failure.Line) { [void]$md.AppendLine("- Ligne : $($failure.Line)") }
                [void]$md.AppendLine("- Message : $($failure.Message)")
                if ($failure.Position) {
                    [void]$md.AppendLine('')
                    [void]$md.AppendLine('```text')
                    [void]$md.AppendLine($failure.Position)
                    [void]$md.AppendLine('```')
                }
                [void]$md.AppendLine('')
            }
        }
    }
}

$report | ConvertTo-Json -Depth 10 |
    Set-Content -LiteralPath $reportJson -Encoding utf8NoBOM

$md.ToString() |
    Set-Content -LiteralPath $reportMd -Encoding utf8NoBOM

Write-Host ''
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host ' RAPPORTS' -ForegroundColor Cyan
Write-Host '============================================================'
Write-Host "Markdown : $reportMd"
Write-Host "JSON     : $reportJson"

if (-not $InventoryOnly -and $selected.Count -gt 0 -and $pesterResult.FailedCount -gt 0) {
    exit 1
}

$unknownItems = @(
    $inventory |
        Where-Object { $_.Classification -eq 'UNKNOWN' }
)

if ($unknownItems.Count -gt 0 -and $BuildValidation) {
    Write-Warning 'Des tests UNKNOWN existent : ils restent volontairement exclus.'
}
