@{

# ============================================================================
# PimsOS Migration Framework
# Module Manifest
# ============================================================================

# Script module associé au manifeste.
RootModule = 'Migration.psm1'

# Version du module.
ModuleVersion = '1.0.0'

# Identifiant unique du module (à remplacer par un GUID généré avec New-Guid).
GUID = 'f6f1e0af-5f84-4ef3-b07f-2d07dd2c96fa'

# Auteur.
Author = 'Pims'

# Société.
CompanyName = 'PimsOS'

# Copyright.
Copyright = '(c) Pims. Tous droits réservés.'

# Description.
Description = 'Framework de migration et de refactoring PowerShell pour PimsOS Builder.'

# Version minimale de PowerShell.
PowerShellVersion = '7.6'

# Éditions compatibles.
CompatiblePSEditions = @(
    'Core'
)

# Architecture processeur.
ProcessorArchitecture = 'None'

# Les sous-modules sont chargés dynamiquement par Migration.psm1.
NestedModules = @()

# Modules requis.
RequiredModules = @()

# Assemblies requises.
RequiredAssemblies = @()

# Scripts exécutés lors de l'import.
ScriptsToProcess = @()

# Formats personnalisés.
FormatsToProcess = @()

# Types personnalisés.
TypesToProcess = @()

# Fonctions exportées.
FunctionsToExport = @(
    'Invoke-Migration'
)

# Cmdlets exportées.
CmdletsToExport = @()

# Variables exportées.
VariablesToExport = @()

# Alias exportés.
AliasesToExport = @()

# Ressources DSC exportées.
DscResourcesToExport = @()

# Informations privées.
PrivateData = @{

    PSData = @{

        Tags = @(
            'PimsOS'
            'Migration'
            'Refactoring'
            'PowerShell'
            'Framework'
        )

        LicenseUri = ''

        ProjectUri = ''

        IconUri = ''

        ReleaseNotes = 'Version initiale du framework Migration.'

        Prerelease = ''

    }

}

# URI de l'aide en ligne.
HelpInfoURI = ''

# Préfixe par défaut des commandes.
DefaultCommandPrefix = ''

}