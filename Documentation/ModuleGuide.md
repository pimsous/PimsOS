# PimsOS Builder - Guide des modules

> Version technique : 3.0.0
>
> Statut : Référence
>
> Dernière mise à jour : 2026-08-31

---

# Objectif

Ce document décrit l'organisation des composants internes du module **PimsOS Builder**.

PimsOS repose sur un module PowerShell unique. Les sous-répertoires de `Modules` regroupent les composants internes par responsabilité.

L'objectif est de garantir :

- une architecture cohérente ;
- une séparation claire des responsabilités ;
- une maintenance simplifiée ;
- un faible couplage ;
- une bonne testabilité ;
- une évolution localisée des fonctionnalités.

---

# Architecture générale

PimsOS Builder est distribué sous la forme d'un module PowerShell unique :

```text
Modules
├── PimsOS.psd1
└── PimsOS.psm1
```

Le fichier `PimsOS.psm1` constitue le point d'entrée du module et charge les composants internes.

Les fichiers situés dans les sous-répertoires de `Modules` sont des composants internes du même module.

Aucun sous-module PowerShell indépendant n'est utilisé pour les composants internes.

---

# Organisation réelle des composants

L'organisation actuelle est :

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
│
├── PimsOS.psd1
└── PimsOS.psm1
```

Chaque répertoire correspond à une responsabilité fonctionnelle ou technique.

---

# Core

Le dossier `Core` contient le cœur du framework.

Structure principale :

```text
Core
├── ActionRegistry.ps1
├── BuildContext.ps1
├── Complete-Build.ps1
├── Core.ps1
├── Engine.ps1
├── Pipeline.ps1
├── Report.ps1
└── Workflow.ps1
```

Responsabilités :

- création et initialisation du BuildContext ;
- gestion du BuildState ;
- orchestration du Workflow ;
- orchestration du Pipeline ;
- routage des Actions ;
- reporting ;
- finalisation du Build.

Le Core contient la logique centrale du framework mais ne doit pas remplacer les Engines spécialisés ou les Managers techniques.

---

# Infrastructure

Le dossier `Infrastructure` contient les services transverses utilisés par plusieurs composants.

Structure actuelle :

```text
Infrastructure
├── Check.ps1
├── Converters.ps1
├── Logger.ps1
├── Recovery.ps1
├── Security.ps1
├── Service.ps1
└── Validation.ps1
```

## Check

Fournit les vérifications nécessaires à l'environnement du Builder.

## Logger

Fournit le système de journalisation centralisé.

## Recovery

Prépare et nettoie l'environnement lorsqu'un Build précédent a laissé des ressources exploitables ou invalides.

## Security

Contient les fonctions techniques liées aux contrôles de sécurité du framework.

## Service

Contient les fonctions techniques relatives aux services Windows utilisées par les composants concernés.

## Validation

Centralise les validations communes.

## Converters

Le fichier existe dans l'architecture mais son implémentation n'est pas encore réalisée.

---

# Configuration

Le dossier `Configuration` contient les composants responsables de la construction de la configuration du Build.

Structure actuelle :

```text
Configuration
├── Categories.ps1
├── Configuration.ps1
├── Profile.ps1
└── Tweak.ps1
```

Responsabilités :

- chargement des catégories ;
- chargement des Tweaks ;
- chargement des profils ;
- validation des définitions ;
- fusion Profil + Tweaks ;
- construction de la configuration finale ;
- création des Actions à exécuter.

Les données de configuration restent séparées de la logique d'exécution.

---

# Actions

Le dossier `Actions` contient les Engines spécialisés.

Structure actuelle :

```text
Actions
├── ActionEngine.ps1
├── CapabilityEngine.ps1
├── CommandEngine.ps1
├── DriverEngine.ps1
├── EnvironmentEngine.ps1
├── FeatureEngine.ps1
├── FileEngine.ps1
├── FolderEngine.ps1
├── PackageEngine.ps1
├── RegistryEngine.ps1
├── ScheduledTaskEngine.ps1
├── ServiceEngine.ps1
└── ShortcutEngine.ps1
```

`ActionEngine` constitue le point central de routage.

Les autres Engines prennent en charge les domaines spécialisés.

La chaîne d'exécution est :

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
```

Un nouveau type d'Action doit être enregistré dans l'ActionRegistry.

---

# Managers

Le dossier `Managers` contient les composants qui encapsulent les opérations techniques des différents domaines fonctionnels.

Structure actuelle :

```text
Managers
├── CapabilityManager.ps1
├── CommandManager.ps1
├── DriverManager.ps1
├── EnvironmentManager.ps1
├── FeatureManager.ps1
├── FileManager.ps1
├── FolderManager.ps1
├── PackageManager.ps1
├── ScheduledTaskManager.ps1
└── ShortcutManager.ps1
```

Les Managers sont utilisés par les Engines spécialisés.

La chaîne de traitement est :

```text
Engine spécialisé
        │
        ▼
Manager
        │
        ▼
Provider ou module technique
```

Les Managers ne doivent pas contenir la logique générale du Workflow ou du Pipeline.

---

# Package

Le dossier `Package` contient les providers techniques destinés aux gestionnaires de packages.

Structure actuelle :

```text
Package
├── Chocolatey.ps1
└── Winget.ps1
```

Les providers prévus sont :

- Chocolatey ;
- Winget.

Les fichiers existent dans l'architecture, mais leurs implémentations techniques ne sont pas encore disponibles.

Le routage vers les providers est déjà prévu au niveau de `PackageManager`.

---

# Windows

Le dossier `Windows` contient les composants spécifiques aux technologies Windows.

Structure actuelle :

```text
Windows
└── Registry.ps1
```

## Registry

Le composant Registry prend notamment en charge :

- le registre Windows offline ;
- les ruches ;
- les clés ;
- les valeurs ;
- les types de données ;
- le montage des ruches ;
- le démontage des ruches.

Registry est un composant technique utilisé par les Actions concernées.

---

# Image

Le dossier `Image` contient les composants responsables de la manipulation des images Windows.

Structure actuelle :

```text
Image
├── Dism.ps1
├── Iso.ps1
└── Wim.ps1
```

## Dism

Encapsule les opérations DISM utilisées pendant le Build.

## Iso

Gère les opérations liées aux images ISO.

## Wim

Gère les images WIM et leur cycle de montage, modification et démontage.

Les opérations d'image sont des opérations techniques et ne doivent pas contenir la logique métier des Tweaks.

---

# Chargement des composants

Les composants sont chargés par :

```text
Modules\PimsOS.psm1
```

Le module charge notamment les domaines dans l'ordre suivant :

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
Managers
        │
        ▼
Package
        │
        ▼
Windows
        │
        ▼
Image
        │
        ▼
Actions
```

Cet ordre correspond au chargement des composants internes dans le module.

Il ne doit pas être confondu avec le flux logique d'exécution d'une Action.

---

# Flux logique d'une Action

Le flux d'exécution d'une Action est :

```text
Configuration
      │
      ▼
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
Provider ou module technique
      │
      ▼
Windows
```

Cette séparation permet de maintenir les responsabilités à leur niveau approprié.

---

# BuildContext

Tous les composants concernés par le Build utilisent le même BuildContext.

Le BuildContext constitue le contrat central entre les couches.

Il contient notamment :

- les informations du projet ;
- le BuildState ;
- la configuration ;
- les ressources ;
- les résultats ;
- les statistiques ;
- les rapports.

Les composants ne doivent pas utiliser une variable globale pour transporter l'état du Build.

Les variables de portée `script:` peuvent être utilisées pour l'état interne limité d'un composant, par exemple une table de providers, mais elles ne doivent pas servir à transporter l'état du Build entre les couches.

---

# ActionRegistry

L'ActionRegistry centralise l'association entre les types d'Actions et leurs Engines.

Son rôle est de permettre au moteur de résoudre un Engine spécialisé sans coder directement cette association dans chaque appelant.

Pour ajouter un nouveau type d'Action :

1. créer l'Engine spécialisé ;
2. définir son contrat ;
3. enregistrer le type dans l'ActionRegistry ;
4. ajouter les tests correspondants ;
5. mettre à jour la documentation si nécessaire.

L'ActionEngine ne doit pas contenir une série de conditions spécifiques à chaque type d'Action lorsque cette logique peut être gérée par l'ActionRegistry.

---

# Validation

La couche de validation vérifie les données avant leur utilisation par les composants d'exécution.

Selon le composant concerné, les contrôles peuvent porter notamment sur :

- les catégories ;
- les identifiants ;
- les groupes ;
- les tags ;
- les niveaux ;
- les versions supportées ;
- les scores ;
- les Actions ;
- les propriétés obligatoires.

Les composants doivent conserver leurs propres validations nécessaires au respect de leur contrat.

La validation globale ne dispense donc pas les Engines et Managers de vérifier les paramètres obligatoires dont ils dépendent.

---

# Ajout d'un nouveau composant

Avant de créer un nouveau composant :

- vérifier qu'un composant existant ne répond pas déjà au besoin ;
- identifier clairement sa responsabilité ;
- choisir la couche appropriée ;
- vérifier ses dépendances ;
- prévoir les tests nécessaires ;
- documenter l'évolution lorsque cela est nécessaire.

Un composant ne doit pas cumuler plusieurs responsabilités indépendantes.

---

# Bonnes pratiques

Les composants internes doivent :

- respecter une responsabilité unique ;
- utiliser le BuildContext pour les données partagées du Build ;
- utiliser le Logger officiel ;
- propager correctement les erreurs ;
- éviter les dépendances inutiles ;
- respecter les dépendances descendantes ;
- rester testables ;
- ne pas devenir automatiquement des API publiques.

Les composants techniques ne doivent pas contenir la logique métier des Tweaks ou des profils.

---

# API publique

Le module PimsOS expose volontairement une API publique minimale.

La fonction actuellement exportée est :

```powershell
Initialize-PimsOS
```

Les composants internes ne doivent pas être considérés comme des API publiques simplement parce qu'ils sont chargés dans `PimsOS.psm1`.

Toute nouvelle fonction publique doit être explicitement exportée et documentée.

---

# Tests

Les nouveaux composants importants doivent disposer de tests Pester adaptés.

Les tests doivent couvrir, lorsque cela est pertinent :

- le fonctionnement nominal ;
- les paramètres invalides ;
- les erreurs attendues ;
- les changements d'état ;
- les statistiques ;
- les interactions avec les dépendances.

Les Engines et Managers actuellement stabilisés disposent de tests unitaires dédiés.

---

# Évolution

L'architecture des composants est conçue pour permettre une évolution progressive du Builder.

L'ajout d'un nouveau type d'Action doit rester localisé autant que possible :

```text
Nouveau type d'Action
        │
        ├── Engine
        ├── Manager / Provider si nécessaire
        ├── ActionRegistry
        └── Tests
```

L'évolution d'un composant ne doit pas entraîner de modification inutile du cœur du framework.

Toute évolution architecturale importante doit être documentée dans `Architecture.md` et, lorsque nécessaire, dans une nouvelle ADR.

---

# Références

- `API.md`
- `Architecture.md`
- `ArchitectureRules.md`
- `BuildContext.md`
- `ProjectStructure.md`
- `Testing.md`
- `TechnicalDecisions.md`
- `Documentation\ADR\`

## PostInstall

Le dossier `Modules/PostInstall/` contient :

| Fichier | Rôle |
|---|---|
| `State.ps1` | état persistant du PostInstall |
| `Network.ps1` | détection et attente réseau |
| `PostInstall.ps1` | moteur d'exécution |
| `Bootstrap.ps1` | point d'entrée FirstBoot |
| `FirstBoot.ps1` | construction des commandes FirstLogon |
| `Unattend.ps1` | génération de `unattend.xml` |
| `Installer.ps1` | installation du runtime dans le WIM |
| `UI.ps1` | interface console du premier démarrage et attente réseau |

Les tests sont regroupés dans :

`Tests/Unit/Modules/PostInstall/`
