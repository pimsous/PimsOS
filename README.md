# PimsOS Builder

> Framework PowerShell permettant de construire automatiquement une image Windows personnalisée à partir d'une ISO officielle Microsoft.

![CI](https://github.com/pimsous/PimsOS/actions/workflows/pester.yml/badge.svg)
![CodeQL](https://github.com/pimsous/PimsOS/actions/workflows/codeql.yml/badge.svg)
![License](https://img.shields.io/github/license/pimsous/PimsOS)
![Release](https://img.shields.io/github/v/release/pimsous/PimsOS)
![PowerShell](https://img.shields.io/badge/PowerShell-7.6+-5391FE)
![Windows](https://img.shields.io/badge/Windows-11%2024H2%20%7C%2025H2-0078D4)
![Status](https://img.shields.io/badge/status-Development-orange)

---

# Présentation

**PimsOS Builder** est un framework PowerShell permettant de créer automatiquement une image Windows personnalisée à partir d'une image officielle Microsoft.

Contrairement aux scripts de personnalisation classiques, PimsOS Builder repose sur une architecture modulaire composée d'un moteur de build, d'un pipeline d'exécution, d'un système de profils et d'un ensemble d'Engines spécialisés.

Le projet ne modifie jamais l'ISO d'origine. Toutes les opérations sont réalisées dans un Workspace dédié avant la génération d'une nouvelle image ISO.

---

# Pourquoi PimsOS Builder ?

L'installation et la personnalisation d'une image Windows impliquent généralement
de nombreuses opérations manuelles, difficiles à reproduire et à maintenir.

PimsOS Builder automatise l'ensemble du processus en séparant clairement :

- les définitions des personnalisations (Tweaks) ;
- les profils utilisateur ;
- la configuration générée ;
- le moteur d'exécution.

Cette approche permet de construire des images Windows reproductibles,
documentées et facilement maintenables.

# Objectifs

- Construire automatiquement une image Windows personnalisée
- Supporter plusieurs versions officielles de Windows
- Décrire les personnalisations dans des fichiers JSON
- Séparer les définitions, les profils et le moteur d'exécution
- Fournir une architecture modulaire, documentée et testable

---

# Statut du projet

Le projet est en développement actif.

Architecture : ✅ Stable

Documentation : ✅ Complète

Pipeline : 🚧 En cours

Première ISO : 🚧 En développement

# Fonctionnalités actuelles

## Build

- ✔ Recovery automatique
- ✔ Vérification de l'environnement
- ✔ Montage de l'ISO
- ✔ Détection du WIM
- ✔ Copie du WIM dans le Workspace
- ✔ Lecture des éditions Windows
- ✔ Sélection automatique ou interactive de l'édition
- ✔ Montage du WIM
- ✔ Montage des ruches du registre
- ✔ Chargement des Tweaks
- ✔ Validation de la configuration
- ✔ Chargement des profils
- ✔ Fusion Profil → Configuration
- ✔ Application des actions Registry
- ✔ Commit automatique du WIM
- ✔ Nettoyage complet des ressources

---

## Configuration

Le Builder distingue désormais trois niveaux :

```text
Tweaks JSON
        │
        ▼
Profils
        │
        ▼
Configuration
        │
        ▼
Pipeline
        │
        ▼
Engines
```

Les définitions des Tweaks restent immuables.

Le moteur applique uniquement la Configuration générée à partir du profil sélectionné.

---

## Support Windows

Le projet est conçu pour prendre en charge plusieurs versions de Windows.

Les informations de version sont centralisées dans :

```text
version.json
```

Exemple :

```json
"Windows": {
    "Release": "11 25H2",
    "Build": "26100"
}
```

À terme, plusieurs versions officielles de Windows pourront être personnalisées sans modifier le moteur de build.

---

# Architecture

Le Builder repose sur plusieurs couches.

```text
Build

    │

    ▼

Workflow

    │

    ▼

Pipeline

    │

    ▼

Engine

    │

    ▼

ActionEngine

    ├── RegistryEngine
    ├── ServiceEngine
    ├── FeatureEngine
    ├── PackageEngine
    ├── CommandEngine
    ├── DriverEngine
    ├── FileEngine
    ├── FolderEngine
    ├── EnvironmentEngine
    ├── ScheduledTaskEngine
    └── ShortcutEngine
```

Le Pipeline orchestre uniquement les différentes étapes.

Toute la logique métier est déléguée aux Engines spécialisés.

---

# BuildContext

Toutes les informations transitent par un BuildContext unique.

Il centralise notamment :

- les informations du projet ;
- les paramètres du build ;
- la version de Windows ;
- les chemins du Workspace ;
- la configuration ;
- les profils ;
- le BuildState ;
- les statistiques ;
- le rapport final.

Aucune variable globale n'est utilisée.

---

# BuildState

Le BuildState représente l'état courant du moteur.

Il permet notamment de suivre :

- l'initialisation ;
- le Recovery ;
- le Pipeline ;
- les montages ;
- les ruches du registre ;
- le chargement des profils ;
- l'application des personnalisations ;
- la réussite globale du build.

---

# Structure du projet

```text
Build/
Config/
Documentation/
ISO/
Logs/
Modules/
Output/
Packages/
Profiles/
Resources/
Tests/
Tweaks/
Workspace/
```

La description complète est disponible dans :

```
Documentation/ProjectStructure.md
```

---

# Technologies

- PowerShell 7.6+
- DISM
- Windows ADK
- JSON
- Pester

Les gestionnaires suivants seront pris en charge :

- Chocolatey
- Winget

---

# Installation

```powershell
git clone https://github.com/pimsous/PimsOS.git

cd PimsOS
```

Pour une installation complète et la préparation de l'environnement de développement, consulter :

- Documentation/GettingStarted.md

# Démarrage rapide

```powershell
Import-Module .\Modules\PimsOS.psd1

Initialize-PimsOS

.\Build\Build-PimsOS.ps1
```

Pour plus d'informations, consulter :

- Documentation/GettingStarted.md

# Documentation

Toute la documentation technique est disponible dans le dossier :

```
Documentation/
```

Elle comprend notamment :

-Architecture
-Architecture Rules
-BuildContext
-Developer Guide
-Module Guide
-Coding Standards
-API
-Testing
-Roadmap
-Milestones
-Release Notes
-Technical Decisions
-ADR

---

# État actuel

Version actuelle :

**v0.4.0**

Statut :

🚧 Développement actif

Les éléments suivants sont désormais opérationnels :

- Recovery
- BuildContext
- BuildState
- Pipeline
- Configuration
- Profils
- Validation
- Registry Engine

Les prochains développements concerneront principalement :

- Service Engine
- Feature Engine
- Package Engine
- Driver Engine
- File Engine
- Folder Engine
- ScheduledTask Engine
- Shortcut Engine

---

# Philosophie

PimsOS Builder repose sur quelques principes fondamentaux :

- simplicité ;
- modularité ;
- reproductibilité ;
- automatisation ;
- testabilité ;
- maintenabilité.

L'objectif du projet n'est pas uniquement de générer une image Windows personnalisée.

Il vise également à fournir un framework PowerShell robuste, documenté et facilement extensible.

# Roadmap

## v0.4

- ✔ Pipeline
- ✔ Recovery
- ✔ BuildContext
- ✔ BuildState
- ✔ Configuration
- ✔ Profils
- ✔ Registry Engine

## v0.5

- Service Engine
- Feature Engine
- Package Engine
- Validation avancée

## v0.6

- Driver Engine
- ScheduledTask Engine
- File Engine
- Folder Engine
- Environment Engine
- Shortcut Engine

## v1.0

Première version stable de PimsOS Builder.

---

# Support

Besoin d'aide ?

Consulter :

- Documentation/GettingStarted.md
- Documentation/DeveloperGuide.md
- Documentation/API.md
- SUPPORT.md

# Contribution

Avant toute contribution, consulter :

- Documentation/GettingStarted.md
- Documentation/DeveloperGuide.md
- Documentation/CodingStandards.md
- Documentation/Architecture.md

Chaque contribution doit :

- respecter l'architecture ;
- conserver un BuildContext unique ;
- utiliser le BuildState ;
- être documentée ;
- être accompagnée de tests.

---


## Licence

PimsOS Builder est distribué sous licence **GNU General Public License v3.0 (GPL-3.0)**.

Vous êtes libre d'utiliser, d'étudier, de modifier et de redistribuer ce projet dans le respect des conditions de cette licence.

Consultez le fichier [LICENSE](LICENSE) pour le texte complet de la licence.