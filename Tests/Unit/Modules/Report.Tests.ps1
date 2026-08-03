# ==========================================
# Tests : Report
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Core\Report.ps1"

}

Describe "Report" {

    BeforeEach {

        $script:Context = [pscustomobject]@{

            Report = [pscustomobject]@{

                Environment  = $null
                Informations = @()
                Warnings      = @()
                Errors        = @()

            }

        }

        $script:Checks = @(
            [pscustomobject]@{
                Name    = "PowerShell"
                Success = $true
            },
            [pscustomobject]@{
                Name    = "Git"
                Success = $true
            }
        )

    }

    Context "New-EnvironmentReport" {

        It "Construit un rapport valide" {

            $Report = New-EnvironmentReport `
                -Checks $script:Checks

            $Report.Success |
                Should -BeTrue

            $Report.Checks.Count |
                Should -Be 2

        }

        It "Retourne Success à False si un contrôle échoue" {

            $Checks = @(
                [pscustomobject]@{
                    Name    = "Git"
                    Success = $false
                }
            )

            $Report = New-EnvironmentReport `
                -Checks $Checks

            $Report.Success |
                Should -BeFalse

        }

    }

    Context "Set-EnvironmentReport" {

        It "Ajoute le rapport au contexte" {

            $Context = Set-EnvironmentReport `
                -Context $script:Context `
                -Checks $script:Checks

            $Context.Report.Environment |
                Should -Not -BeNullOrEmpty

        }

    }

    Context "Add-ReportInformation" {

        It "Ajoute une information" {

            $Context = Add-ReportInformation `
                -Context $script:Context `
                -Message "Information"

            $Context.Report.Informations.Count |
                Should -Be 1

        }

        It "Ignore les doublons" {

            $Context = Add-ReportInformation `
                -Context $script:Context `
                -Message "Information"

            $Context = Add-ReportInformation `
                -Context $Context `
                -Message "Information"

            $Context.Report.Informations.Count |
                Should -Be 1

        }

    }

    Context "Add-ReportWarning" {

        It "Ajoute un avertissement" {

            $Context = Add-ReportWarning `
                -Context $script:Context `
                -Message "Warning"

            $Context.Report.Warnings.Count |
                Should -Be 1

        }

        It "Ignore les doublons" {

            $Context = Add-ReportWarning `
                -Context $script:Context `
                -Message "Warning"

            $Context = Add-ReportWarning `
                -Context $Context `
                -Message "Warning"

            $Context.Report.Warnings.Count |
                Should -Be 1

        }

    }

    Context "Add-ReportError" {

        It "Ajoute une erreur" {

            $Context = Add-ReportError `
                -Context $script:Context `
                -Message "Erreur"

            $Context.Report.Errors.Count |
                Should -Be 1

        }

        It "Ignore les doublons" {

            $Context = Add-ReportError `
                -Context $script:Context `
                -Message "Erreur"

            $Context = Add-ReportError `
                -Context $Context `
                -Message "Erreur"

            $Context.Report.Errors.Count |
                Should -Be 1

        }

    }

}