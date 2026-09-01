# PimsOS Builder - Structure du projet

> Version technique : 3.0.0
>
> Statut : Développement / architecture stabilisée
>
> Dernière mise à jour : 2026-09-01

---

# Objectif

Ce document décrit l'organisation réelle du projet **PimsOS Builder**.

Le projet est structuré autour d'un module PowerShell unique :

```text
Modules\PimsOS.psm1
```

Le module centralise le chargement des composants internes et l'exposition de l'API publique du framework.

---

# Structure générale

```text
PimsOS
│
├── Build
├── Config
├── Documentation
├── ISO
├── Logs
├── Modules
├── Output
├── Packages
├── Tests
├── Workspace
├── version.json
└── README.md
```

Le projet est organisé de manière à séparer clairement :

- le code du framework ;
- la configuration ;
- les ressources de Build ;
- les tests ;
- la documentation ;
- les artefacts et espaces de travail.

---

# Modules

Le code du framework se trouve dans :

```text
Modules\
```

La structure principale est :

```text
Modules
│
├── Actions
├── Configuration
├── Core
├── Image
├── Infrastructure
├── Managers
├── Package
├── PostInstall
├── Windows
├── PimsOS.psd1
└── PimsOS.psm1
```

Les composants internes appartiennent au module PowerShell unique **PimsOS**.

Ils ne constituent pas des modules PowerShell indépendants.

---

# PostInstall

Le projet contient désormais un sous-système dédié à l'exécution après l'installation de Windows :

```text
Modules\PostInstall\
```

Ce dossier contient le runtime PostInstall embarqué dans l'image Windows.

Les composants actuellement présents comprennent notamment :

```text
Bootstrap.ps1
FirstBoot.ps1
Installer.ps1
Network.ps1
PostInstall.ps1
State.ps1
UI.ps1
Unattend.ps1
```

Le runtime est préparé pendant le Build puis installé dans l'image Windows sous :

```text
C:\ProgramData\PimsOS\PostInstall\
```

Le sous-système PostInstall prend notamment en charge :

- l'initialisation du runtime ;
- la persistance de l'état ;
- la détection du réseau ;
- la détection de l'accès Internet ;
- l'attente de la disponibilité réseau ;
- l'interface console du premier démarrage ;
- la préparation FirstBoot ;
- la génération de `unattend.xml`.

Le PostInstall reste séparé de la logique du Build exécutée hors ligne.

---

# Diagnostic avant tests

Avant une campagne Pester, utiliser `Tests\Tools\Invoke-PimsOSDiagnostics.ps1` pour vérifier que les fichiers sélectionnés ne sont pas susceptibles de lancer un Build réel. Les validations `BUILD-CAPABLE` nécessitent explicitement `-BuildValidation -AllowBuild`.

# Tests

Les tests du framework sont organisés dans :

```text
Tests\
```

La structure comprend notamment :

```text
Tests
│
├── Unit
├── Integration
├── Acceptance
└── Legacy
```

Les tests Legacy sont conservés séparément et ne participent pas à la validation officielle du framework actif.

---

# Tests PostInstall

Les tests dédiés au sous-système PostInstall sont regroupés dans :

```text
Tests\Unit\Modules\PostInstall\
```

Ils couvrent notamment :

```text
Bootstrap.Tests.ps1
FirstBoot.Tests.ps1
Installer.Tests.ps1
Network.Tests.ps1
PostInstall.Tests.ps1
State.Tests.ps1
UI.Tests.ps1
Unattend.Tests.ps1
```

Les tests PostInstall vérifient les composants individuellement ainsi que leurs contrats fonctionnels.

L'intégration du PostInstall dans le pipeline est également couverte par les tests d'intégration du BuildPipeline.

---

# Architecture des dépendances

Le framework suit une architecture en couches.

Le flux principal est :

```text
Infrastructure
        │
        ▼
Core
        │
        ▼
Configuration
        │
        ▼
Workflow
        │
        ▼
Pipeline
        │
        ▼
ActionEngine
        │
        ▼
ActionRegistry
        │
        ▼
Engine spécialisé
        │
        ▼
Manager
        │
        ▼
Module technique
        │
        ▼
Windows
```

Le PostInstall constitue un sous-système runtime distinct du chemin d'exécution principal du Build.

Sa préparation est intégrée au Pipeline :

```text
MountWim
    │
    ▼
ApplyDrivers
    │
    ▼
PreparePostInstall
    │
    ▼
MountSoftwareHive
```

---

# Build

Le dossier :

```text
Build\
```

contient les scripts utilisés pour lancer et orchestrer le processus de Build.

Le lanceur principal est :

```text
Build\Build-PimsOS.ps1
```

Le Build prépare notamment :

- l'environnement ;
- les ressources ISO et WIM ;
- les drivers ;
- le runtime PostInstall ;
- FirstBoot ;
- la configuration ;
- les personnalisations ;
- le nettoyage ;
- la finalisation.

---

# Configuration

La configuration du Builder se trouve dans :

```text
Config\
```

Elle contient notamment :

```text
Categories.json
Profiles\
Tweaks\
```

Les profils sélectionnent les personnalisations et les Tweaks définissent les Actions à exécuter.

La configuration reste séparée du code PowerShell.

---

# Documentation

La documentation technique se trouve dans :

```text
Documentation\
```

Elle comprend notamment :

```text
API.md
Architecture.md
ArchitectureRules.md
BuildContext.md
DeveloperGuide.md
GettingStarted.md
Legacy.md
Lifecycle.md
Milestones.md
ModuleGuide.md
PostInstall.md
Prerequisites.md
ProjectStatus.md
ProjectStructure.md
ReleaseNotes.md
Roadmap.md
Schema.md
TechnicalDecisions.md
Testing.md
```

Les décisions d'architecture sont documentées dans :

```text
Documentation\ADR\
```

---

# ISO

Le dossier :

```text
ISO\
```

contient les ressources et éléments nécessaires aux opérations liées aux médias Windows et à la génération de l'image.

---

# Logs

Le dossier :

```text
Logs\
```

contient les journaux générés pendant les opérations du Builder.

---

# Output

Le dossier :

```text
Output\
```

est destiné aux artefacts produits par le Build.

---

# Workspace

Le dossier :

```text
Workspace\
```

contient les ressources de travail temporaires utilisées pendant les opérations du Builder.

Il peut notamment contenir :

- les copies de travail ;
- les montages WIM ;
- les fichiers temporaires ;
- les ressources intermédiaires.

---

# Packages

Le dossier :

```text
Packages\
```

contient les ressources liées aux packages ou aux fournisseurs utilisés par le projet.

---

# Classes

Le dossier historique :

```text
Classes\
```

n'est plus utilisé comme couche de classes métier du Builder.

Les composants actifs suivent désormais l'architecture modulaire du framework.

---

# Legacy

Les composants historiques peuvent être conservés dans :

```text
Tools\
Tests\Legacy\
```

Ils ne sont pas chargés par :

```text
Modules\PimsOS.psm1
```

et ne participent pas au fonctionnement normal du Builder.

Aucune nouvelle fonctionnalité ne doit être développée dans ces emplacements.

---

# Point d'entrée

Le point d'entrée du framework est :

```text
Modules\PimsOS.psm1
```

L'API publique est centralisée dans ce module.

La fonction publique principale actuellement définie est :

```powershell
Initialize-PimsOS
```

---

# Principe général

L'organisation du projet doit préserver la séparation entre :

```text
Configuration
    ↓
Framework
    ↓
Build
    ↓
Runtime PostInstall
    ↓
Windows installé
```

Le Build prépare l'image.

Le runtime PostInstall s'exécute ensuite dans Windows installé.

Cette séparation permet de maintenir une architecture claire, testable et évolutive.

---

# Références

Consulter également :

- `Architecture.md`
- `ArchitectureRules.md`
- `BuildContext.md`
- `DeveloperGuide.md`
- `ModuleGuide.md`
- `PostInstall.md`
- `Testing.md`
- `Legacy.md`
