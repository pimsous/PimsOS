# API Reference

## Objectif

Ce document décrit les interfaces publiques du framework **PimsOS Builder**.

Il documente exclusivement les fonctions destinées à être utilisées par :

- le script de build ;
- les futurs outils d'automatisation ;
- les tests ;
- les extensions du framework.

Les fonctions internes utilisées uniquement par les moteurs (Engine), les Managers ou les composants d'infrastructure ne font pas partie de cette API.

---

# Organisation

L'API est organisée par module.

Modules actuels :

- Core
- Configuration
- Image
- Actions
- Infrastructure

---

# Fonctions publiques

## Initialize-PimsOS

### Description

Point d'entrée principal du framework.

Initialise le BuildContext, prépare l'environnement, exécute l'ensemble de la Build Pipeline puis génère le rapport final.

---

### Syntaxe

```powershell
Initialize-PimsOS
```

---

### Paramètres

Aucun.

---

### Valeur retournée

```text
BuildContext
```

---

### Exceptions

Peut lever une exception si :

- l'environnement est invalide ;
- une étape critique du pipeline échoue ;
- une action obligatoire échoue.

---

### Exemple

```powershell
Import-Module .\Modules\PimsOS.psm1

$Context = Initialize-PimsOS
```

---

## Get-Configuration

### Description

Construit la configuration finale à appliquer.

Cette fonction :

- charge les définitions de tweaks ;
- valide les fichiers JSON ;
- charge le profil sélectionné ;
- fusionne le profil avec les tweaks ;
- retourne la configuration prête à être exécutée.

---

### Valeur retournée

```text
BuildContext
```

---

## Invoke-BuildPipeline

### Description

Exécute l'ensemble de la pipeline de construction.

Cette fonction orchestre toutes les étapes du build.

---

### Étapes actuelles

- Recovery
- Environment
- ISO Mount
- WIM Detection
- WIM Copy
- WIM Read
- Edition Selection
- WIM Mount
- Registry Mount
- Configuration Loading
- Configuration Execution
- Registry Unmount
- WIM Unmount
- ISO Unmount
- Build Completion

---

### Valeur retournée

```text
BuildContext
```

---

# Architecture actuelle

L'API publique repose sur plusieurs composants.

## Core

Responsable de :

- BuildContext
- Pipeline
- Workflow
- Engine
- Report
- Complete-Build

---

## Configuration

Responsable de :

- chargement des tweaks
- validation
- profils
- fusion de configuration

---

## Actions

Chaque type d'action possède désormais son propre moteur.

Actuellement :

- RegistryEngine
- ServiceEngine
- PackageEngine
- DriverEngine
- FeatureEngine
- CapabilityEngine
- CommandEngine
- FileEngine
- FolderEngine
- EnvironmentEngine
- ScheduledTaskEngine
- ShortcutEngine

---

## Managers

Les Managers encapsulent les opérations Windows spécialisées.

Modules disponibles :

- PackageManager
- DriverManager
- FeatureManager
- CapabilityManager
- CommandManager
- FileManager
- FolderManager
- EnvironmentManager
- ScheduledTaskManager
- ShortcutManager

---

## Infrastructure

L'infrastructure fournit les services communs :

- Logger
- Validation
- Recovery
- Security
- Service
- Converters

---

# Modèle d'exécution

Le framework suit le cycle suivant :

```
Initialize-PimsOS
        │
        ▼
Initialize BuildContext
        │
        ▼
Recovery
        │
        ▼
Environment Checks
        │
        ▼
Pipeline
        │
        ▼
Configuration
        │
        ▼
Action Engines
        │
        ▼
Complete-Build
        │
        ▼
Report
```

---

# Version actuelle

Documentation compatible avec :

```
PimsOS Builder 0.4.0
Architecture 2.x
PowerShell 7+
```

---

# Évolution

Toute nouvelle fonctionnalité publique devra :

- être documentée ici ;
- préciser ses paramètres ;
- préciser son type de retour ;
- documenter les exceptions possibles ;
- fournir un exemple d'utilisation.

Les fonctions internes (Engine, Manager, Infrastructure) ne doivent être documentées ici que lorsqu'elles deviennent officiellement publiques.