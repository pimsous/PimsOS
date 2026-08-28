# ==========================================
# Module : Prerequisites
# Projet : PimsOS Builder
# ==========================================

Set-StrictMode -Version Latest


# ==================================================
# Get-PimsOSOsCdImgPath
# ==================================================

function Get-PimsOSOsCdImgPath {

    [CmdletBinding()]
    param()

    $Candidates = @()

    $Command = Get-Command `
        oscdimg.exe `
        -ErrorAction SilentlyContinue

    if ($null -ne $Command) {

        $Candidates += $Command.Source

    }


    $WindowsKitsRoot = "${env:ProgramFiles(x86)}\Windows Kits"

    if (
        Test-Path `
            -LiteralPath $WindowsKitsRoot `
            -PathType Container
    ) {

        $Candidates += Get-ChildItem `
            -LiteralPath $WindowsKitsRoot `
            -Filter oscdimg.exe `
            -Recurse `
            -File `
            -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty FullName

    }


    foreach ($Candidate in $Candidates) {

        if (
            -not [string]::IsNullOrWhiteSpace($Candidate) -and
            (Test-Path -LiteralPath $Candidate -PathType Leaf)
        ) {

            return (
                Get-Item `
                    -LiteralPath $Candidate
            ).FullName

        }

    }

    return $null
}


# ==================================================
# Test-PimsOSWindowsADK
# ==================================================

function Test-PimsOSWindowsADK {

    [CmdletBinding()]
    param()

    $OsCdImgPath = Get-PimsOSOsCdImgPath

    [pscustomobject]@{

        Installed = (
            -not [string]::IsNullOrWhiteSpace(
                $OsCdImgPath
            )
        )

        OsCdImgPath = $OsCdImgPath

    }
}

# ==================================================
# Get-PimsOSADKSetupPath
# ==================================================

function Get-PimsOSADKSetupPath {

    [CmdletBinding()]
    param(
        [string]$SearchRoot
    )

    $Candidates = @()

    if (
        -not [string]::IsNullOrWhiteSpace($SearchRoot)
    ) {

        if (
            Test-Path `
                -LiteralPath $SearchRoot `
                -PathType Container
        ) {

            $Candidates += Get-ChildItem `
                -LiteralPath $SearchRoot `
                -Filter adksetup.exe `
                -Recurse `
                -File `
                -ErrorAction SilentlyContinue |
                Select-Object -ExpandProperty FullName

        }

    }

    $DefaultRoots = @(
        "$env:USERPROFILE\Downloads"
        "$env:TEMP"
        "C:\ADK"
        "C:\Temp"
    )

    foreach ($Root in $DefaultRoots) {

        if (
            Test-Path `
                -LiteralPath $Root `
                -PathType Container
        ) {

            $Candidates += Get-ChildItem `
                -LiteralPath $Root `
                -Filter adksetup.exe `
                -Recurse `
                -File `
                -ErrorAction SilentlyContinue |
                Select-Object -ExpandProperty FullName

        }

    }

    foreach ($Candidate in $Candidates) {

        if (
            Test-Path `
                -LiteralPath $Candidate `
                -PathType Leaf
        ) {

            return (
                Get-Item `
                    -LiteralPath $Candidate
            ).FullName

        }

    }

    return $null
}


# ==================================================
# Get-PimsOSWindowsADKInstaller
# ==================================================

function Get-PimsOSWindowsADKInstaller {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$Configuration,

        [Parameter(Mandatory)]
        [string]$DestinationPath

    )

    if ($null -eq $Configuration) {

        throw (
            "La configuration PimsOS est obligatoire."
        )

    }

    if (
        -not (
            $Configuration.PSObject.Properties.Name `
                -contains "Requirements"
        )
    ) {

        throw (
            "La configuration PimsOS ne contient pas " +
            "la section 'Requirements'."
        )

    }

    if ($null -eq $Configuration.Requirements) {

        throw (
            "La configuration PimsOS ne contient pas " +
            "la section 'Requirements'."
        )

    }

    $RequirementProperties =
        @(
            $Configuration.Requirements.PSObject.Properties |
            Select-Object -ExpandProperty Name
        )

    if (
        -not (
            $RequirementProperties -contains "WindowsADK"
        )
    ) {

        throw (
            "La configuration PimsOS ne contient pas " +
            "la configuration 'Requirements.WindowsADK'."
        )

    }

    $AdkConfiguration =
        $Configuration.Requirements.WindowsADK

    if (
        $null -eq $AdkConfiguration -or
        -not (
            $AdkConfiguration.PSObject.Properties.Name `
                -contains "DownloadUrl"
        ) -or
        [string]::IsNullOrWhiteSpace(
            $AdkConfiguration.DownloadUrl
        )
    ) {

        throw (
            "L'URL de téléchargement Windows ADK est absente."
        )

    }

    if (
        -not (
            Test-Path `
                -LiteralPath $DestinationPath `
                -PathType Container
        )
    ) {

        New-Item `
            -ItemType Directory `
            -Path $DestinationPath `
            -Force `
            -ErrorAction Stop |
            Out-Null

    }

    $DownloadFileName = "adksetup.exe"

    if (
        $AdkConfiguration.PSObject.Properties.Name `
            -contains "DownloadFileName" -and
        -not [string]::IsNullOrWhiteSpace(
            $AdkConfiguration.DownloadFileName
        )
    ) {

        $DownloadFileName =
            $AdkConfiguration.DownloadFileName

    }

    $InstallerPath =
        Join-Path `
            $DestinationPath `
            $DownloadFileName

    if (
        Test-Path `
            -LiteralPath $InstallerPath `
            -PathType Leaf
    ) {

        if (
            $AdkConfiguration.PSObject.Properties.Name `
                -contains "Sha256" -and
            -not [string]::IsNullOrWhiteSpace(
                $AdkConfiguration.Sha256
            )
        ) {

            $HashResult = Test-PimsOSFileHash `
                -Path $InstallerPath `
                -ExpectedHash $AdkConfiguration.Sha256

            if (-not $HashResult.Valid) {

                throw (
                    "La vérification SHA-256 de Windows ADK a échoué."
                )

            }

        }

        return $InstallerPath

    }

    Invoke-WebRequest `
        -Uri $AdkConfiguration.DownloadUrl `
        -OutFile $InstallerPath `
        -UseBasicParsing `
        -ErrorAction Stop

    if (
        -not (
            Test-Path `
                -LiteralPath $InstallerPath `
                -PathType Leaf
        )
    ) {

        throw (
            "Le téléchargement du programme d'installation " +
            "Windows ADK a échoué."
        )

    }

    if (
        $AdkConfiguration.PSObject.Properties.Name `
            -contains "Sha256" -and
        -not [string]::IsNullOrWhiteSpace(
            $AdkConfiguration.Sha256
        )
    ) {

        $HashResult = Test-PimsOSFileHash `
            -Path $InstallerPath `
            -ExpectedHash $AdkConfiguration.Sha256

        if (-not $HashResult.Valid) {

			Remove-Item `
				-LiteralPath $InstallerPath `
				-Force `
				-ErrorAction SilentlyContinue

			throw (
				"La vérification SHA-256 de Windows ADK a échoué."
			)

		}        

    }

    return $InstallerPath
}

# ==================================================
# Install-PimsOSWindowsADK
# ==================================================

function Install-PimsOSWindowsADK {

    [CmdletBinding()]
    param(

        [string]$SetupPath,

        [psobject]$Configuration,

        [string]$DestinationPath

    )


    # ------------------------------------------
    # Vérification d'une installation existante
    # ------------------------------------------

    $Existing = Test-PimsOSWindowsADK

    if ($Existing.Installed) {

        return $Existing

    }


    # ------------------------------------------
    # Lecture de la configuration ADK
    # ------------------------------------------

    $AdkConfiguration = $null

    if ($null -ne $Configuration) {

        if (
            $Configuration.PSObject.Properties.Name `
                -contains "Requirements"
        ) {

            if (
                $null -ne $Configuration.Requirements -and
                $Configuration.Requirements.PSObject.Properties.Name `
                    -contains "WindowsADK"
            ) {

                $AdkConfiguration =
                    $Configuration.Requirements.WindowsADK

            }

        }

    }


    # ------------------------------------------
    # Recherche du programme d'installation
    # ------------------------------------------

    if (
        [string]::IsNullOrWhiteSpace($SetupPath)
    ) {

        $SetupPath = Get-PimsOSADKSetupPath

    }


    # ------------------------------------------
    # Téléchargement si nécessaire
    # ------------------------------------------

    if (
        [string]::IsNullOrWhiteSpace($SetupPath)
    ) {

        if ($null -eq $Configuration) {

            throw (
                "Windows ADK introuvable. " +
                "La configuration PimsOS est nécessaire " +
                "pour télécharger automatiquement le programme."
            )

        }


        if ($null -eq $AdkConfiguration) {

            throw (
                "Windows ADK introuvable. " +
                "La configuration Requirements.WindowsADK " +
                "est obligatoire pour télécharger automatiquement " +
                "le programme."
            )

        }


        if (
			[string]::IsNullOrWhiteSpace($DestinationPath)
		) {

			if (
				$null -eq $Context -or
				-not $Context.PSObject.Properties["Workspace"] -or
				-not $Context.Workspace.PSObject.Properties["Temp"]
			) {

				throw (
					"Le chemin Workspace.Temp est obligatoire " +
					"pour télécharger le Windows ADK."
				)

			}

			$DestinationPath = Join-Path `
				$Context.Workspace.Temp `
				"ADK"

		}


        $SetupPath = Get-PimsOSWindowsADKInstaller `
            -Configuration $Configuration `
            -DestinationPath $DestinationPath

    }


    # ------------------------------------------
    # Vérification du programme d'installation
    # ------------------------------------------

    if (
        [string]::IsNullOrWhiteSpace($SetupPath)
    ) {

        throw (
            "Windows ADK introuvable. " +
            "Téléchargez l'ADK Microsoft 10.1.26100.2454 " +
            "et fournissez le chemin vers ADKSetup.exe."
        )

    }


    if (
        -not (
            Test-Path `
                -LiteralPath $SetupPath `
                -PathType Leaf
        )
    ) {

        throw (
            "ADKSetup.exe introuvable : '$SetupPath'."
        )

    }


    # ------------------------------------------
    # Paramètres d'installation
    # ------------------------------------------

    $InstallPath =
        "C:\Program Files (x86)\Windows Kits\10"

    $Feature =
        "OptionId.DeploymentTools"


    if ($null -ne $AdkConfiguration) {

        if (
            $AdkConfiguration.PSObject.Properties.Name `
                -contains "InstallPath" -and
            -not [string]::IsNullOrWhiteSpace(
                $AdkConfiguration.InstallPath
            )
        ) {

            $InstallPath =
                $AdkConfiguration.InstallPath

        }


        if (
            $AdkConfiguration.PSObject.Properties.Name `
                -contains "Feature" -and
            -not [string]::IsNullOrWhiteSpace(
                $AdkConfiguration.Feature
            )
        ) {

            $Feature =
                $AdkConfiguration.Feature

        }

    }


    # ------------------------------------------
    # Installation Deployment Tools
    # ------------------------------------------

    $Arguments = @(
        "/quiet"
        "/installpath"
        $InstallPath
        "/features"
        $Feature
    )


    $Process = Start-Process `
        -FilePath $SetupPath `
        -ArgumentList $Arguments `
        -Wait `
        -PassThru `
        -ErrorAction Stop


    if ($Process.ExitCode -ne 0) {

        throw (
            "L'installation des outils de déploiement Windows ADK " +
            "a échoué. Code retour : $($Process.ExitCode)."
        )

    }


    # ------------------------------------------
    # Vérification finale
    # ------------------------------------------

    $Result = Test-PimsOSWindowsADK

    if (-not $Result.Installed) {

        throw (
            "L'installation de l'ADK est terminée mais " +
            "oscdimg.exe reste introuvable."
        )

    }


    return $Result
}
# ==================================================
# Test-PimsOSFileHash
# ==================================================

function Test-PimsOSFileHash {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [string]$Path,

        [string]$ExpectedHash

    )


    # ------------------------------------------
    # Vérification du fichier
    # ------------------------------------------

    if (
        -not (
            Test-Path `
                -LiteralPath $Path `
                -PathType Leaf
        )
    ) {

        throw (
            "Fichier introuvable pour vérification SHA-256 : " +
            "'$Path'."
        )

    }


    # ------------------------------------------
    # Calcul du SHA-256
    # ------------------------------------------

    $Hash = (
        Get-FileHash `
            -LiteralPath $Path `
            -Algorithm SHA256 `
            -ErrorAction Stop
    ).Hash.ToUpperInvariant()


    # ------------------------------------------
    # Aucun hash attendu
    # ------------------------------------------

    if (
        [string]::IsNullOrWhiteSpace($ExpectedHash)
    ) {

        return [pscustomobject]@{

            Valid    = $true
            Verified = $false
            Hash     = $Hash
            Expected = $null
            Path     = $Path

        }

    }


    # ------------------------------------------
    # Normalisation du hash attendu
    # ------------------------------------------

    $NormalizedExpectedHash =
        $ExpectedHash.Trim().ToUpperInvariant()


    # ------------------------------------------
    # Validation du format SHA-256
    # ------------------------------------------

    if (
        $NormalizedExpectedHash -notmatch '^[A-F0-9]{64}$'
    ) {

        throw (
            "Le SHA-256 configuré est invalide : " +
            "'$ExpectedHash'."
        )

    }


    # ------------------------------------------
    # Comparaison
    # ------------------------------------------

    $Valid =
        $Hash -eq $NormalizedExpectedHash


    [pscustomobject]@{

        Valid    = $Valid
        Verified = $true
        Hash     = $Hash
        Expected = $NormalizedExpectedHash
        Path     = $Path

    }
}