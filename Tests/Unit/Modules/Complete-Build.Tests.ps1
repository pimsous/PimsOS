# ==========================================
# Tests : Complete-Build
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"

    # --------------------------------------------------
    # Mocks des opérations externes
    # --------------------------------------------------

    function global:Dismount-Wim {

        param(
            [psobject]$Context
        )

        return $Context
    }

    function global:Dismount-Iso {

        param(
            [psobject]$Context
        )

        if ($null -ne $Context.ISO) {

            if (
                $Context.ISO.PSObject.Properties.Name -contains "Mounted"
            ) {

                $Context.ISO.Mounted = $false
            }

        }

        return $Context
    }

    . "$ProjectRoot\Modules\Core\Complete-Build.ps1"
}

Describe "Complete-Build" {

    BeforeEach {

        Reset-Logger

        Mock Write-Log {}
        Mock Stop-Logger {}

        $script:Context = [pscustomobject]@{

            # ==========================================
            # BuildState
            # ==========================================

            BuildState = [pscustomobject]@{

                Status = "Pipeline"

                Completed = $false

                Success = $false

                Recovery = [pscustomobject]@{

                    Wim = "WimRecovery"

                    Iso = "IsoRecovery"

                    Registry = @(
                        "SOFTWARE"
                    )

                }

                Image = [pscustomobject]@{

                    IsoMounted = $true

                    WimMounted = $true

                    RegistryLoaded = $true

                    CurrentRegistryHive = "SOFTWARE"

                    ConfigLoaded = $true

                    ProfileLoaded = $true

                    ProfileMerged = $true

                    TweaksLoaded = $true

                    TweaksApplied = $true

                }

            }

            # ==========================================
            # Projet
            # ==========================================

            Project = [pscustomobject]@{

                StartTime = (Get-Date).AddSeconds(-10)

                EndTime = $null

                Duration = $null

            }

            # ==========================================
            # ISO
            # ==========================================

            ISO = [pscustomobject]@{

                Name = "Win11_25H2_French_x64.iso"

                FullName = "C:\Test\Win11_25H2_French_x64.iso"

                DriveLetter = "O:"

                Root = "O:\"

                SourcesPath = "O:\sources"

                Label = "CCCOMA_X64FRE_FR-FR_DV9"

                Mounted = $true

            }

            # ==========================================
            # WIM
            # ==========================================

            WIM = [pscustomobject]@{

                Type = "WIM"

                Name = "install.wim"

                FullName = "C:\Test\install.wim"

                SizeGB = 7.04

                Images = [System.Collections.Generic.List[object]]::new()

                Mount = [pscustomobject]@{

                    Path = "C:\Test\Mount"

                    ReadOnly = $false

                }

            }

            # ==========================================
            # Registry
            # ==========================================

            Registry = [pscustomobject]@{

                Mounted = @()

            }

        }

    }


    # ==================================================
    # Complete-Build
    # ==================================================

    Context "Complete-Build" {

        It "Marque le Build comme terminé avec un code retour 0" {

            $Context = Complete-Build `
                -Context $script:Context `
                -ExitCode 0

            $Context.BuildState.Completed |
                Should -BeTrue

            $Context.BuildState.Success |
                Should -BeTrue

            $Context.BuildState.Status |
                Should -Be "Completed"

        }

        It "Marque le Build comme échoué avec un code retour non nul" {

            $Context = Complete-Build `
                -Context $script:Context `
                -ExitCode 1

            $Context.BuildState.Completed |
                Should -BeTrue

            $Context.BuildState.Success |
                Should -BeFalse

            $Context.BuildState.Status |
                Should -Be "Failed"

        }

        It "Définit EndTime" {

            $Context = Complete-Build `
                -Context $script:Context `
                -ExitCode 0

            $Context.Project.EndTime |
                Should -Not -BeNullOrEmpty

        }

        It "Calcule la durée du Build" {

            $Context = Complete-Build `
                -Context $script:Context `
                -ExitCode 0

            $Context.Project.Duration |
                Should -BeOfType ([TimeSpan])

        }

        It "Réinitialise l'état Image" {

            $Context = Complete-Build `
                -Context $script:Context `
                -ExitCode 0

            $Context.BuildState.Image.IsoMounted |
                Should -BeFalse

            $Context.BuildState.Image.WimMounted |
                Should -BeFalse

            $Context.BuildState.Image.RegistryLoaded |
                Should -BeFalse

            $Context.BuildState.Image.CurrentRegistryHive |
                Should -BeNullOrEmpty

            $Context.BuildState.Image.ConfigLoaded |
                Should -BeFalse

            $Context.BuildState.Image.ProfileLoaded |
                Should -BeFalse

            $Context.BuildState.Image.ProfileMerged |
                Should -BeFalse

            $Context.BuildState.Image.TweaksLoaded |
                Should -BeFalse

            $Context.BuildState.Image.TweaksApplied |
                Should -BeFalse

        }

        It "Réinitialise l'état Recovery" {

            $Context = Complete-Build `
                -Context $script:Context `
                -ExitCode 0

            $Context.BuildState.Recovery.Wim |
                Should -BeNullOrEmpty

            $Context.BuildState.Recovery.Iso |
                Should -BeNullOrEmpty

            $Context.BuildState.Recovery.Registry.Count |
                Should -Be 0

        }

        It "Retourne le contexte fourni" {

            $Context = Complete-Build `
                -Context $script:Context `
                -ExitCode 0

            $Context |
                Should -Not -BeNullOrEmpty

        }

    }

}