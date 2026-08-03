# ==========================================
# Module : Workflow
# Projet : PimsOS Builder
# Version : 1.0.0
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Démarre une phase du Build
# --------------------------------------------------

function Start-BuildPhase {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context,

        [Parameter(Mandatory)]
        [string]$Name

    )

    Write-Log "===== Phase : $Name ====="

    $Context.BuildState.Status = "Running-$Name"

    $Phase = [PSCustomObject]@{

        Id        = $Name.Replace(" ","")

        Name      = $Name

        StartTime = Get-Date

        EndTime   = $null

        Duration  = $null

        Success   = $true

        Steps     = @()

        Errors    = @()

    }

    $Context.Report.CurrentPhase = $Phase

    $Context.Report.Phases += $Phase

    return $Context

}

# --------------------------------------------------
# Termine la phase courante
# --------------------------------------------------

function Complete-BuildPhase {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context

    )

    if (-not $Context.Report.CurrentPhase) {

        return $Context

    }

    $Phase = $Context.Report.CurrentPhase

    $Phase.EndTime = Get-Date

    $Phase.Duration = $Phase.EndTime - $Phase.StartTime

    if ($Phase.Errors.Count -gt 0) {

        $Phase.Success = $false

    }

    if ($Phase.Success) {

        Write-Log (
            "Phase '$($Phase.Name)' terminée en $($Phase.Duration)"
        ) SUCCESS

    }
    else {

        Write-Log (
            "Phase '$($Phase.Name)' terminée avec erreur."
        ) WARNING

    }

    $Context.BuildState.Status = "Idle"

    $Context.Report.CurrentPhase = $null

    return $Context

}

# --------------------------------------------------
# Affiche le résumé du Build
# --------------------------------------------------

function Show-BuildSummary {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Context

    )

    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "              Résumé du Build" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host ""

    foreach ($Phase in $Context.Report.Phases) {

        if ($Phase.Success) {

            $PhaseIcon = "[OK]"

        }
        else {

            $PhaseIcon = "[ERREUR]"

        }

        Write-Host "$PhaseIcon $($Phase.Name)" -ForegroundColor Yellow

        foreach ($Step in $Phase.Steps) {

            $StepIcon = if ($Step.Success) { "[OK]" } else { "[ERREUR]" }

            Write-Host (
                "    {0} {1,-35} {2}" -f
                $StepIcon,
                $Step.Name,
                $Step.Duration
            )

        }

        if ($Phase.Errors.Count -gt 0) {

            Write-Host ""
            Write-Host "    Erreurs :" -ForegroundColor Red

            foreach ($ErrorMessage in $Phase.Errors) {

                Write-Host "      • $ErrorMessage" -ForegroundColor Red

            }

        }

        Write-Host ""

    }

    Write-Host "==================================================" -ForegroundColor Cyan

    Write-Host ("Tweaks appliqués : {0}" -f $Context.Statistics.TweaksApplied)

    Write-Host ("Packages         : {0}" -f $Context.Statistics.PackagesProcessed)

    Write-Host ("Drivers          : {0}" -f $Context.Statistics.DriversProcessed)

    Write-Host ("Erreurs          : {0}" -f $Context.Statistics.Errors)

    Write-Host ("Avertissements   : {0}" -f $Context.Statistics.Warnings)

    Write-Host ("Durée totale     : {0}" -f $Context.Project.Duration)

    Write-Host "==================================================" -ForegroundColor Cyan

}