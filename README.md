# PimsOS Builder

> Framework PowerShell permettant de construire et personnaliser des images Windows à partir de médias sources compatibles.

![CI](https://github.com/pimsous/PimsOS/actions/workflows/pester.yml/badge.svg)
![CodeQL](https://github.com/pimsous/PimsOS/actions/workflows/codeql.yml/badge.svg)
![License](https://img.shields.io/github/license/pimsous/PimsOS)
![Release](https://img.shields.io/github/v/release/pimsous/PimsOS)
![PowerShell](https://img.shields.io/badge/PowerShell-7.6+-5391FE)
![Windows](https://img.shields.io/badge/Windows-11%2025H2-0078D4)
![Status](https://img.shields.io/badge/status-Development-orange)

---

# Présentation

**PimsOS Builder** est un framework PowerShell permettant de construire et de personnaliser des images Windows à partir de médias sources compatibles.

Le projet automatise progressivement les différentes étapes du processus de Build tout en séparant :

- les définitions de personnalisation ;
- les profils ;
- la configuration générée ;
- l'exécution des Actions ;
- les opérations techniques Windows.

PimsOS repose sur une architecture modulaire interne organisée autour d'un **module PowerShell unique**.

Le projet ne constitue pas une collection de modules PowerShell indépendants. Les composants internes sont chargés par `Modules\PimsOS.psm1`.

Les opérations de modification sont réalisées dans un Workspace de travail afin de préserver les ressources sources lorsqu'une copie de travail est nécessaire.

---

# Pourquoi PimsOS Builder ?

La personnalisation d'une image Windows implique de nombreuses opérations techniques qui sont difficiles à reproduire manuellement et à maintenir dans le temps.

PimsOS Builder cherche à automatiser ce processus en séparant clairement :

- les définitions des Tweaks ;
- les profils utilisateur ;
- la configuration finale ;
- le moteur d'exécution ;
- les opérations techniques.

Cette séparation permet de construire un framework :

- reproductible ;
- documenté ;
- testable ;
- maintenable ;
- extensible.

---

# Objectifs

- Construire automatiquement des images Windows personnalisées.
- Supporter différentes versions compatibles de Windows.
- Décrire les personnalisations avec des données JSON.
- Séparer les définitions, les profils et la configuration d'exécution.
- Fournir une architecture modulaire au sein d'un module PowerShell unique.
- Permettre l'ajout de nouveaux types d'Actions sans modifier inutilement le moteur principal.
- Fournir une couverture de tests Pester adaptée aux composants critiques.
- Produire à terme des rapports et des artefacts de Build complets.

---

# Statut du projet

**Version technique : 3.0.0**

**Statut :** 🚧 Développement actif / architecture stabilisée

| Domaine | État |
|---------|------|
| Architecture | ✅ Stabilisée |
| Module PimsOS unique | ✅ Implémenté |
| BuildContext | ✅ Implémenté |
| BuildState | ✅ Implémenté |
| Workflow | ✅ Implémenté |
| Pipeline | ✅ Implémenté |
| Configuration | ✅ Implémentée |
| ActionRegistry | ✅ Implémenté |
| ActionEngine | ✅ Implémenté |
| Engines spécialisés | ✅ Implémentés |
| Managers | ✅ Implémentés |
| Registry | ✅ Implémenté |
| Image ISO / WIM | ✅ Implémentée |
| Tests Pester | ✅ Forte couverture / extension en cours |
| Reporting | 🟡 À enrichir |
| Génération ISO finale | 🟡 En cours de finalisation |
| Providers Chocolatey / Winget | 🟡 À finaliser |
| Converters | ⬜ À implémenter |

La version technique 3.0.0 ne constitue pas encore une release finale stable du produit.

---

# Fonctionnalités actuelles

## Build

Les principales étapes du Build sont actuellement implémentées :

- ✔ Recovery
- ✔ Vérification de l'environnement
- ✔ Préparation du Workspace
- ✔ Gestion de l'ISO
- ✔ Détection du WIM
- ✔ Copie du WIM
- ✔ Lecture des éditions Windows
- ✔ Sélection de l'édition
- ✔ Montage du WIM
- ✔ Gestion des ruches du registre
- ✔ Chargement des Tweaks
- ✔ Chargement des profils
- ✔ Validation de la configuration
- ✔ Fusion Profil + Tweaks
- ✔ Exécution des Actions
- ✔ Commit des modifications
- ✔ Démontage des ressources
- ✔ Nettoyage
- ✔ Finalisation du Build

La validation complète d'un scénario de Build de bout en bout et la génération finale de l'ISO restent en cours de finalisation.

---

# Configuration

Le Builder distingue clairement trois niveaux :

```text
Tweaks JSON
      │
      ▼
Profils
      │
      ▼
Configuration finale
      │
      ▼
Actions
      │
      ▼
Engines
```

Les définitions des Tweaks restent séparées de leur utilisation.

Les profils déterminent les personnalisations sélectionnées.

Le moteur de configuration construit ensuite une configuration destinée à l'exécution.

Les définitions sources des Tweaks ne sont pas modifiées lors de cette opération.

---

# Actions, Engines et Managers

Le traitement d'une Action suit le flux :

```text
Action
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

## Engines spécialisés

Les Engines actuellement intégrés comprennent :

- `RegistryEngine`
- `ServiceEngine`
- `PackageEngine`
- `DriverEngine`
- `FeatureEngine`
- `CapabilityEngine`
- `CommandEngine`
- `FileEngine`
- `FolderEngine`
- `EnvironmentEngine`
- `ScheduledTaskEngine`
- `ShortcutEngine`

## Managers

Les Managers actuellement intégrés comprennent :

- `PackageManager`
- `DriverManager`
- `FeatureManager`
- `CapabilityManager`
- `CommandManager`
- `FileManager`
- `FolderManager`
- `EnvironmentManager`
- `ScheduledTaskManager`
- `ShortcutManager`

Les Managers encapsulent les opérations techniques et les mécanismes de providers de leur domaine.

---

# BuildContext

Le `BuildContext` est le contrat central du Build.

Il est créé au démarrage puis enrichi progressivement pendant tout le cycle du Build.

Il centralise notamment :

- les informations du projet ;
- les paramètres du Build ;
- la version de Windows ciblée ;
- les chemins de travail ;
- le BuildState ;
- la configuration ;
- les ressources ;
- les résultats ;
- les statistiques ;
- les rapports.

Le même contexte est transmis aux composants concernés.

Les variables globales ne sont pas utilisées pour transporter l'état du Build.

---

# BuildState

Le `BuildState` représente l'état courant de l'exécution.

Il permet notamment de suivre :

- l'initialisation ;
- le Recovery ;
- les vérifications de l'environnement ;
- la progression du Pipeline ;
- l'état des ressources ;
- le chargement de la configuration ;
- l'application des personnalisations ;
- l'état final du Build.

Le BuildState est contenu dans le BuildContext.

---

# Support Windows

PimsOS Builder n'est pas conçu autour d'une seule version de Windows.

Les informations relatives à la cible doivent être découvertes depuis l'image traitée et/ou provenir du BuildContext et de la configuration.

L'environnement de référence actuel du projet est :

```text
Windows 11 25H2
Build 26100
```

Les métadonnées générales du projet sont centralisées dans :

```text
version.json
```

Exemple :

```json
{
    "Project": "PimsOS Builder",
    "Version": "3.0.0",
    "Windows": {
        "Release": "11 25H2",
        "Build": "26100"
    },
    "Author": "Pims",
    "Company": "PimsOS",
    "Repository": "https://github.com/Pims/PimsOS",
    "BuildDate": null
}
```

L'objectif est de pouvoir étendre le traitement à d'autres versions compatibles sans modifier l'architecture générale du moteur.

---

# Architecture

PimsOS Builder repose sur un **module PowerShell unique** :

```text
Modules\PimsOS.psd1
Modules\PimsOS.psm1
```

Les composants internes sont organisés par responsabilité :

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
├── Windows
├── PimsOS.psd1
└── PimsOS.psm1
```

Le flux logique principal est :

```text
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

Les composants internes ne sont pas des modules PowerShell indépendants.

---

# API publique

L'API publique du module est volontairement minimale.

L'entrée fonctionnelle actuelle est :

```powershell
Initialize-PimsOS
```

Exemple :

```powershell
Import-Module .\Modules\PimsOS.psd1

$Context = Initialize-PimsOS
```

Les Engines, Managers et autres composants internes restent internes au module sauf export explicite.

---

# Structure du projet

```text
PimsOS
│
├── Build
├── Config
├── Documentation
├── ISO
├── Logs
├── Modules
│   ├── Actions
│   ├── Configuration
│   ├── Core
│   ├── Image
│   ├── Infrastructure
│   ├── Managers
│   ├── Package
│   ├── Windows
│   ├── PimsOS.psd1
│   └── PimsOS.psm1
├── Output
├── Tests
├── Workspace
└── version.json
```

La description détaillée est disponible dans :

```text
Documentation/ProjectStructure.md
```

---

# Technologies

- PowerShell 7.6.x
- DISM
- Windows ADK pour les opérations de génération d'images qui le nécessitent
- JSON
- Pester 5.x
- Git
- Visual Studio Code recommandé

Les providers de packages prévus comprennent :

- Chocolatey
- Winget

---

# Installation

Cloner le dépôt :

```powershell
git clone https://github.com/pimsous/PimsOS.git

cd PimsOS
```

Pour préparer l'environnement de développement :

```powershell
Get-Content .\Documentation\GettingStarted.md
```

Consulter également :

```text
Documentation\Prerequisites.md
```

---

# Démarrage rapide

Charger le module :

```powershell
Import-Module .\Modules\PimsOS.psd1
```

Vérifier le point d'entrée :

```powershell
Get-Command Initialize-PimsOS
```

Lancer le Builder :

```powershell
.\Build\Build-PimsOS.ps1
```

Pour travailler directement avec l'API publique :

```powershell
$Context = Initialize-PimsOS
```

`Build-PimsOS.ps1` constitue le script de lancement du processus de Build ; `Initialize-PimsOS` constitue le point d'entrée public du module.

---

# Tests

Les tests utilisent Pester 5.x.

Exécuter tous les tests :

```powershell
Invoke-Pester -Path .\Tests\Unit
Invoke-Pester -Path .\Tests\Integration
```

Exécuter une suite ciblée :

```powershell
Invoke-Pester -Path .\Tests\Unit
```

Les nouveaux composants doivent être accompagnés de tests adaptés.

Les tests Legacy sont conservés séparément et ne constituent pas la validation courante du Builder.

---

# Documentation

La documentation technique est disponible dans :

```text
Documentation/
```

Elle comprend notamment :

- `Architecture.md`
- `ArchitectureRules.md`
- `API.md`
- `BuildContext.md`
- `CodingStandards.md`
- `DeveloperGuide.md`
- `GettingStarted.md`
- `Lifecycle.md`
- `ModuleGuide.md`
- `Prerequisites.md`
- `ProjectStatus.md`
- `ProjectStructure.md`
- `Schema.md`
- `Testing.md`
- `TechnicalDecisions.md`
- `Roadmap.md`
- `Milestones.md`
- `ReleaseNotes.md`
- `ChatGPT-Workflow.md`
- `Legacy.md`

Les décisions architecturales sont documentées dans :

```text
Documentation/ADR/
```

---

# Contribution

Avant toute contribution, consulter :

- `Documentation/GettingStarted.md`
- `Documentation/DeveloperGuide.md`
- `Documentation/CodingStandards.md`
- `Documentation/Architecture.md`
- `Documentation/ArchitectureRules.md`
- `Documentation/Testing.md`
- `Documentation/ADR/`

Chaque contribution doit :

- respecter l'architecture ;
- conserver un BuildContext unique ;
- utiliser le BuildState ;
- respecter le routage des Actions ;
- être accompagnée de tests ;
- mettre à jour la documentation lorsque nécessaire.

Les contributions sont détaillées dans :

```text
CONTRIBUTING.md
```

---

# Roadmap

## Prochaines priorités

- Finaliser la couverture des composants critiques.
- Renforcer les tests Recovery et Security.
- Finaliser les providers nécessaires.
- Enrichir le Reporting.
- Valider un scénario de Build complet de bout en bout.
- Finaliser la génération de l'ISO.

## À moyen terme

- automatisation complète de la génération d'image ;
- reporting complet ;
- extension du support Windows compatible ;
- préparation d'une release publique stable.

Consulter :

```text
Documentation/Roadmap.md
Documentation/Milestones.md
Documentation/Backlog.md
```

---

# Philosophie

PimsOS Builder repose sur les principes suivants :

- simplicité ;
- modularité ;
- reproductibilité ;
- automatisation ;
- testabilité ;
- maintenabilité ;
- extensibilité.

Le projet ne cherche pas uniquement à produire une image Windows personnalisée.

Il vise également à fournir un framework PowerShell robuste, documenté, testable et progressivement industrialisable.

---

# Licence

PimsOS Builder est distribué sous licence **GNU General Public License v3.0 (GPL-3.0)**.

Vous êtes libre d'utiliser, d'étudier, de modifier et de redistribuer ce projet dans le respect des conditions de cette licence.

Consultez le fichier [LICENSE](LICENSE) pour le texte complet de la licence.

---

# Support

Pour comprendre le fonctionnement du projet :

1. consulter `Documentation/GettingStarted.md` ;
2. consulter `Documentation/Architecture.md` ;
3. consulter `Documentation/DeveloperGuide.md` ;
4. consulter `Documentation/Testing.md` ;
5. consulter `Documentation/ADR/`.

Pour le suivi de l'état du projet :

```text
Documentation/ProjectStatus.md
```
