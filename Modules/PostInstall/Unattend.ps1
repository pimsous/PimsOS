# ==========================================
# Module : PostInstall Unattend
# Projet : PimsOS Builder
# Version : 1.0.2
# Compatible : PowerShell 7+
# ==========================================

Set-StrictMode -Version Latest

# --------------------------------------------------
# Namespaces Windows Unattend
# --------------------------------------------------

$script:UnattendNamespace =
    "urn:schemas-microsoft-com:unattend"

$script:WcmNamespace =
    "http://schemas.microsoft.com/WMIConfig/2002/State"

# --------------------------------------------------
# Construit un document XML unattend.xml
# contenant les FirstLogonCommands PimsOS
# --------------------------------------------------

function New-PimsOSUnattendDocument {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$FirstBootConfiguration

    )

    # --------------------------------------------------
    # Validation
    # --------------------------------------------------

    if ($null -eq $FirstBootConfiguration) {

        throw "La configuration FirstBoot est null."

    }

    $null = Test-PimsOSFirstBootConfiguration `
        -Configuration $FirstBootConfiguration

    # --------------------------------------------------
    # Création du document XML
    # --------------------------------------------------

    $XmlDocument = New-Object System.Xml.XmlDocument

    $Declaration = $XmlDocument.CreateXmlDeclaration(
        "1.0",
        "utf-8",
        $null
    )

    $null = $XmlDocument.AppendChild(
        $Declaration
    )

    # --------------------------------------------------
    # Élément racine
    # --------------------------------------------------

    $Unattend = $XmlDocument.CreateElement(
        "unattend",
        $script:UnattendNamespace
    )

    $Unattend.SetAttribute(
        "xmlns:wcm",
        $script:WcmNamespace
    )

    $null = $XmlDocument.AppendChild(
        $Unattend
    )

    # --------------------------------------------------
    # settings / oobeSystem
    # --------------------------------------------------

    $Settings = $XmlDocument.CreateElement(
        "settings",
        $script:UnattendNamespace
    )

    $Settings.SetAttribute(
        "pass",
        "oobeSystem"
    )

    $null = $Unattend.AppendChild(
        $Settings
    )

    # --------------------------------------------------
    # component
    # --------------------------------------------------

    $Component = $XmlDocument.CreateElement(
        "component",
        $script:UnattendNamespace
    )

    $Component.SetAttribute(
        "name",
        "Microsoft-Windows-Shell-Setup"
    )

    $Component.SetAttribute(
        "processorArchitecture",
        "amd64"
    )

    $Component.SetAttribute(
        "publicKeyToken",
        "31bf3856ad364e35"
    )

    $Component.SetAttribute(
        "language",
        "neutral"
    )

    $Component.SetAttribute(
        "versionScope",
        "nonSxS"
    )

    $null = $Settings.AppendChild(
        $Component
    )

    # --------------------------------------------------
    # FirstLogonCommands
    # --------------------------------------------------

    $FirstLogonCommands = $XmlDocument.CreateElement(
        "FirstLogonCommands",
        $script:UnattendNamespace
    )

    $null = $Component.AppendChild(
        $FirstLogonCommands
    )

    # --------------------------------------------------
    # Commandes
    # --------------------------------------------------

    $Commands = @(
        $FirstBootConfiguration.FirstLogonCommands |
            Sort-Object Order
    )

    foreach ($Command in $Commands) {

        $SyncCommand = $XmlDocument.CreateElement(
            "SynchronousCommand",
            $script:UnattendNamespace
        )

        # ----------------------------------------------
        # wcm:action
        # ----------------------------------------------

        $null = $SyncCommand.SetAttribute(
            "action",
            $script:WcmNamespace,
            "add"
        )

        # ----------------------------------------------
        # Order
        # ----------------------------------------------

        $Order = $XmlDocument.CreateElement(
            "Order",
            $script:UnattendNamespace
        )

        $Order.InnerText =
            [string]$Command.Order

        $null = $SyncCommand.AppendChild(
            $Order
        )

        # ----------------------------------------------
        # CommandLine
        # ----------------------------------------------

        $CommandLine = $XmlDocument.CreateElement(
            "CommandLine",
            $script:UnattendNamespace
        )

        $CommandLine.InnerText =
            [string]$Command.CommandLine

        $null = $SyncCommand.AppendChild(
            $CommandLine
        )

        # ----------------------------------------------
        # Description
        # ----------------------------------------------

        if (
            $Command.PSObject.Properties.Name -contains
            "Description"
        ) {

            $Description = $XmlDocument.CreateElement(
                "Description",
                $script:UnattendNamespace
            )

            $Description.InnerText =
                [string]$Command.Description

            $null = $SyncCommand.AppendChild(
                $Description
            )

        }

        $null = $FirstLogonCommands.AppendChild(
            $SyncCommand
        )

    }

    return $XmlDocument

}

# --------------------------------------------------
# Génère directement un fichier unattend.xml
# --------------------------------------------------

function Export-PimsOSUnattendDocument {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [psobject]$FirstBootConfiguration,

        [Parameter(Mandatory)]
        [string]$Path

    )

    if ([string]::IsNullOrWhiteSpace($Path)) {

        throw "Le chemin du fichier unattend.xml est vide."

    }

    $Document = New-PimsOSUnattendDocument `
        -FirstBootConfiguration $FirstBootConfiguration

    $Parent = Split-Path `
        -Path $Path `
        -Parent

    if (
        -not [string]::IsNullOrWhiteSpace($Parent) -and
        -not (Test-Path -LiteralPath $Parent)
    ) {

        New-Item `
            -ItemType Directory `
            -Path $Parent `
            -Force `
            -ErrorAction Stop |
            Out-Null

    }

    try {

        $Settings =
            New-Object System.Xml.XmlWriterSettings

        $Settings.Indent = $true

        $Settings.Encoding =
            New-Object System.Text.UTF8Encoding(
                $false
            )

        $Writer = [System.Xml.XmlWriter]::Create(
            $Path,
            $Settings
        )

        try {

            $Document.Save(
                $Writer
            )

        }
        finally {

            $Writer.Dispose()

        }

    }
    catch {

        throw (
            "Impossible d'écrire le fichier unattend.xml '{0}'.`r`n{1}" -f
            $Path,
            $_.Exception.Message
        )

    }

    return $Path

}
