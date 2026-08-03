# ==========================================
# Tests : Logger
# Projet : PimsOS Builder
# ==========================================

BeforeAll {

    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path

    . "$ProjectRoot\Modules\Infrastructure\Logger.ps1"

}

Describe "Logger" {

    BeforeEach {

        Reset-Logger

        $script:LogFile = Join-Path $env:TEMP "PimsOS-Logger-Test.log"

        if (Test-Path $script:LogFile) {

            Remove-Item `
                -Path $script:LogFile `
                -Force

        }

    }

    Context "Start-Logger" {

        It "Initialise le logger" {

            Start-Logger `
                -Path $script:LogFile

            Get-LogFile |
                Should -Be $script:LogFile

        }

    }

    Context "Write-Log" {

        BeforeEach {

            Start-Logger `
                -Path $script:LogFile

        }

        It "Crée le fichier de log" {

            Test-Path $script:LogFile |
                Should -BeTrue

        }

        It "Écrit un message dans le fichier" {

            Write-Log "Test Logger"

            (Get-Content $script:LogFile -Raw) |
                Should -Match "Test Logger"

        }

        It "Écrit un message SUCCESS" {

            Write-Log `
                -Message "Succès" `
                -Level SUCCESS

            (Get-Content $script:LogFile -Raw) |
                Should -Match "SUCCESS"

        }

        It "Écrit un message ERROR" {

            Write-Log `
                -Message "Erreur" `
                -Level ERROR

            (Get-Content $script:LogFile -Raw) |
                Should -Match "ERROR"

        }

    }

    Context "Get-BuildDuration" {

        It "Retourne une durée" {

            Start-Logger `
                -Path $script:LogFile

            Get-BuildDuration |
                Should -BeOfType ([TimeSpan])

        }

    }

    Context "Reset-Logger" {

        It "Réinitialise le logger" {

            Start-Logger `
                -Path $script:LogFile

            Reset-Logger

            Get-LogFile |
                Should -BeNullOrEmpty

        }

    }

}