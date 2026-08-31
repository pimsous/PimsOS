# PimsOS Builder - BuildContext

> Version technique : 3.0.0
>
> Statut : Développement / architecture stabilisée
>
> Dernière mise à jour : 2026-08-31

---

# Présentation

Le **BuildContext** est le contrat central utilisé par les composants de **PimsOS Builder**.

Il est créé au démarrage du Builder puis enrichi progressivement tout au long du cycle de Build.

Le BuildContext permet de partager l'état et les données nécessaires entre les différents composants sans utiliser d'état global pour transporter les informations du Build.

Les Engines, Managers et autres composants reçoivent le contexte nécessaire à leur traitement et mettent à jour les informations relevant de leur responsabilité.

---

# Objectifs

Le BuildContext permet de :

- centraliser les données du Build ;
- partager un état commun entre les composants ;
- réduire les dépendances implicites ;
- faciliter les tests unitaires ;
- faciliter le diagnostic et le débogage ;
- maintenir une architecture modulaire ;
- conserver un contrat commun entre les différentes couches.

---

# Cycle de vie

Le cycle de vie général du BuildContext est :

```text
Initialize-PimsOS
        │
        ▼
New-BuildContext
        │
        ▼
Initialize-BuildContext
        │
        ▼
Recovery
        │
        ▼
Environment Checks
        │
        ▼
Workflow
        │
        ▼
Pipeline
        │
        ▼
Configuration
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
Complete-Build
```

Le même BuildContext est utilisé pendant toute l'exécution.

---

# Structure générale

```text
Context
│
├── Project
├── Build
├── BuildState
├── Configuration
├── ConfigurationProfile
├── ISO
├── WIM
├── Image
├── Workspace
├── Registry
├── Packages
├── Drivers
├── Tweaks
├── Services
├── Features
├── Report
├── Logger
└── Statistics
```

---

# Project

Contient toutes les informations relatives au projet.

```text
Project
│
├── Name
├── Version
├── Windows
│   ├── Release
│   └── Build
├── Author
├── Company
├── Repository
├── Root
├── Paths
├── Config
├── StartTime
├── EndTime
└── Duration
```

Ces informations proviennent principalement du fichier **version.json**.

Le BuildContext contient également les informations concernant la version de Windows ciblée.

Exemples :

- Release ;
- Build ;
- Édition sélectionnée.

Ces informations sont découvertes ou sélectionnées au moment du Build et ne sont pas figées dans le moteur.

---

# Build

Informations relatives au build courant.

Exemples :

- Build ID ;
- mode interactif ;
- génération ISO ;
- génération du rapport ;
- mode DryRun.

---

# BuildState

Le BuildState représente l'état courant du pipeline.

Il est mis à jour par chaque étape du Build.

Il contient notamment :

- état du Recovery ;
- état des vérifications ;
- état du Pipeline ;
- état des images montées ;
- état de la configuration ;
- état global du Build.

---

# Configuration

Contient la configuration fusionnée prête à être exécutée.

Elle est construite à partir :

- des fichiers JSON ;
- des catégories ;
- du profil sélectionné.

---

# ConfigurationProfile

Nom du profil actuellement utilisé.

Exemples :

- Default ;
- Gaming ;
- Privacy ;
- Minimal ;
- Workstation ;
- Tests\Registry.

---

# ISO

Informations concernant l'image ISO montée.

---

# WIM

Informations relatives au fichier install.wim.

Exemples :

- nom ;
- taille ;
- images disponibles ;
- chemin ;
- montage.

---

# Image

Informations sur l'édition Windows sélectionnée.

Exemples :

- Index ;
- Nom ;
- Description ;
- Taille ;
- État de modification.

Le Builder permet désormais de sélectionner dynamiquement l'édition Windows présente dans le WIM.

Il n'est plus limité à une version spécifique de Windows.

---

# Workspace

Répertoires temporaires utilisés pendant le Build.

Exemples :

- Sources ;
- Mount ;
- ISO ;
- Output ;
- Temp ;
- Extract.

---

# Registry

Informations concernant les ruches Windows actuellement montées.

---

# Packages

Liste des packages à installer.

Les packages sont indépendants du gestionnaire utilisé.

Le choix entre Chocolatey, Winget ou un autre fournisseur est réalisé par les Managers.

---

# Drivers

Liste des pilotes à intégrer.

---

# Tweaks

Liste des Tweaks sélectionnés après fusion du profil.

Chaque Tweak contient :

- son état ;
- ses métadonnées ;
- ses Actions ;
- son résultat d'exécution ;
- ses statistiques.

---

# Services

Liste des services Windows manipulés pendant le Build.

---

# Features

Liste des fonctionnalités Windows à installer ou supprimer.

---

# PostInstall

Le BuildContext conserve les informations nécessaires à la préparation du runtime **PostInstall** lorsque celles-ci sont partagées avec les composants du Build.

La préparation du PostInstall intervient dans le pipeline après l'application des drivers et avant les étapes suivantes de préparation de l'image.

Le runtime PostInstall est installé dans l'image Windows sous :

```text
C:\ProgramData\PimsOS\PostInstall\
```

Les composants préparés comprennent notamment :

```text
Bootstrap.ps1
Network.ps1
UI.ps1
PostInstall.ps1
State.ps1
```

La configuration FirstBoot et `unattend.xml` permettent ensuite de déclencher le Bootstrap lors du premier démarrage de Windows.

Le BuildContext ne contient pas la logique d'exécution du PostInstall. Il transporte uniquement les informations nécessaires aux composants du Build.

---

# Report

Contient le rapport d'exécution.

Il est enrichi tout au long du pipeline.

Il regroupe :

- les phases ;
- les erreurs ;
- les avertissements ;
- les informations ;
- les résultats finaux.

---

# Logger

Informations utilisées par le système de journalisation.

Exemples :

- état ;
- fichier courant ;
- activation.

---

# Statistics

Le BuildContext centralise également toutes les statistiques du Build.

Exemples :

- ActionsProcessed ;
- PackagesProcessed ;
- DriversProcessed ;
- FeaturesProcessed ;
- CapabilitiesProcessed ;
- CommandsProcessed ;
- FilesProcessed ;
- FoldersProcessed ;
- EnvironmentVariablesProcessed ;
- ScheduledTasksProcessed ;
- ShortcutsProcessed ;
- ServicesProcessed ;
- RegistryActionsProcessed ;
- TweaksApplied ;
- Errors ;
- Warnings.

Ces statistiques sont mises à jour automatiquement par les différents Engines.

---

# Principes de conception

Le BuildContext respecte les principes suivants :

- créé une seule fois ;
- enrichi progressivement ;
- jamais remplacé ;
- jamais cloné ;
- transmis à tous les composants ;
- aucune logique métier ;
- aucune variable globale.

---

# Évolutions

Toute nouvelle fonctionnalité du Builder doit être intégrée au BuildContext uniquement si elle représente un état partagé entre plusieurs composants.

Le BuildContext constitue le contrat officiel entre tous les modules du framework.

Toute évolution de sa structure doit être accompagnée :

- d'une mise à jour de cette documentation ;
- d'une mise à jour de l'ADR correspondante lorsque nécessaire.
