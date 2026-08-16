@{

# ==========================================
# Informations générales
# ==========================================

RootModule = 'PimsOS.psm1'

ModuleVersion = '3.0.0'

GUID = 'A8C82474-5A75-4D1C-8E72-25A5BDE89C61'

Author = 'Pims'

CompanyName = 'Pims'

Copyright = '(c) 2026 Pims. Tous droits réservés.'

Description = 'PimsOS Builder - Framework de personnalisation Windows 11.'

PowerShellVersion = '7.0'

CompatiblePSEditions = @(
    'Core'
)

# ==========================================
# Fonctions exportées
# ==========================================

FunctionsToExport = @(
    'Initialize-PimsOS'
)

CmdletsToExport = @()

VariablesToExport = @()

AliasesToExport = @()

# ==========================================
# Assemblies
# ==========================================

RequiredAssemblies = @()

TypesToProcess = @()

FormatsToProcess = @()

ScriptsToProcess = @()

RequiredModules = @()

NestedModules = @()

ModuleList = @()

FileList = @(
    'PimsOS.psm1'
)

# ==========================================
# Données privées
# ==========================================

PrivateData = @{

    PSData = @{

        Tags = @(
            'Windows'
            'Windows11'
            'DISM'
            'ISO'
            'Deployment'
            'PowerShell'
            'PimsOS'
        )

        LicenseUri = ''

        ProjectUri = ''

        IconUri = ''

        ReleaseNotes = @'

Version 3.0.0

- Architecture PimsOS unifiée autour du module PowerShell unique
- BuildContext centralisé
- Workflow et Pipeline stabilisés
- ActionRegistry et routage des Actions
- Engines spécialisés
- Managers spécialisés
- Amélioration de la couverture de tests Pester
- Stabilisation de la gestion des images WIM et ISO
- Stabilisation de la configuration et du cycle de Build

Statut :
Développement / architecture stabilisée
Release complète : non finalisée

'@

    }

}

# ==========================================
# Signature
# ==========================================

HelpInfoURI = ''

DefaultCommandPrefix = ''

}