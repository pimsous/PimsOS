# PimsOS Builder

> Documentation de l'architecture logicielle

Version : 0.4.0
Architecture : 2.x

---

# Sommaire

- Présentation
- Philosophie
- Objectifs
- Principes d'architecture
- Vue d'ensemble
- Architecture logique
- Les couches du Builder
- Flux d'exécution
- Communication entre les composants
- Dépendances
- Décisions d'architecture (ADR)
- Documentation associée

---

# Présentation

PimsOS Builder est un framework PowerShell permettant de créer une image Windows personnalisée à partir d'une image ISO officielle Microsoft.

Le projet automatise l'ensemble du processus de personnalisation d'une image Windows tout en conservant une architecture :

- modulaire ;
- testable ;
- extensible ;
- maintenable.

Le Builder ne modifie jamais directement l'image ISO d'origine.

Toutes les opérations sont réalisées sur une copie de travail afin de garantir l'intégrité des fichiers source.

---
## État actuel du projet

Depuis la version 0.4.0, PimsOS Builder dispose d'une architecture modulaire complète reposant sur un moteur d'exécution orienté Actions.

Le pipeline est désormais capable de :

- monter automatiquement une image ISO ;
- détecter et copier l'image Windows (WIM) ;
- monter l'image avec DISM ;
- charger les ruches du registre hors ligne ;
- construire une configuration à partir des fichiers JSON et des profils ;
- valider l'ensemble des définitions ;
- appliquer les personnalisations via des Engines spécialisés ;
- démonter proprement toutes les ressources ;
- produire un BuildContext complet ainsi qu'un rapport de build.

L'architecture est conçue pour permettre l'ajout de nouveaux types d'Actions sans modifier les composants existants.

# Philosophie

L'architecture de PimsOS repose sur quelques principes simples qui guident l'ensemble du développement.

## Responsabilité unique

Chaque composant possède une responsabilité clairement définie.

Un composant ne doit réaliser qu'une seule tâche et la réaliser correctement.

---

## Modularité

Les fonctionnalités sont isolées dans des composants indépendants.

L'ajout d'une nouvelle fonctionnalité ne doit pas nécessiter la modification des composants existants.

---

## Séparation des responsabilités

Chaque couche de l'application possède un rôle précis.

Les composants communiquent uniquement via leurs interfaces publiques et le BuildContext.

---

## Testabilité

Tous les composants doivent pouvoir être testés indépendamment.

Les tests unitaires font partie intégrante du développement.

---

## Extensibilité

L'architecture doit permettre l'ajout de nouveaux moteurs, modules ou composants avec un impact minimal sur le reste du projet.

---

## Maintenabilité

Le projet privilégie :

- un code lisible ;
- des interfaces stables ;
- une documentation complète ;
- une architecture cohérente.

---

# Objectifs

Le développement de PimsOS poursuit plusieurs objectifs.

PimsOS Builder constitue le moteur de construction du projet.

Son architecture est indépendante de la version de Windows ciblée.

Le Builder sélectionne dynamiquement une image Windows (édition et version), applique une configuration, puis génère une image Windows personnalisée.

L'image produite est appelée **PimsOS**.

## Construire une image Windows personnalisée

Créer automatiquement une image Windows adaptée aux besoins de l'utilisateur.

---

## Industrialiser les personnalisations

Toutes les personnalisations sont décrites sous forme de données.

Aucune logique métier n'est présente dans les fichiers JSON.

---

## Garantir la reproductibilité

Deux builds utilisant les mêmes paramètres doivent produire le même résultat.

---

## Faciliter la maintenance

Chaque framework est indépendant.

Les évolutions peuvent être réalisées avec un impact limité sur le reste du projet.

---

## Centraliser les échanges

Toutes les informations échangées pendant le build transitent par un BuildContext unique.

---

# Principes d'architecture

L'architecture de PimsOS repose sur plusieurs règles fondamentales.

# Architecture du module PimsOS

L'architecture de PimsOS repose sur un module PowerShell unique.

Le projet n'est pas constitué d'une collection de modules indépendants, mais d'un framework unique composé de composants internes.

Cette organisation simplifie les dépendances, améliore la maintenabilité et garantit une API publique cohérente.

---

## Module unique

Le seul module PowerShell public du projet est :

```text
PimsOS
```

Tous les composants internes appartiennent à ce module.

---

## Rôle de PimsOS.psd1

Le manifeste décrit le module.

Il contient uniquement :

- les métadonnées ;
- la version ;
- les dépendances externes.

Il ne contient aucune logique métier.

---

## Rôle de PimsOS.psm1

PimsOS.psm1 constitue le point d'entrée du framework.

Il est responsable :

- du chargement des composants internes ;
- de l'initialisation du framework ;
- de l'exposition de l'API publique.

---

## Organisation des composants

PimsOS
│
├── Build
├── Config
├── Documentation
├── ISO
├── Logs
├── Modules
│   ├── PimsOS.psd1
│   ├── PimsOS.psm1
│   ├── Infrastructure
│ 	├── Core
│ 	├── Configuration
│ 	├── Image
│ 	├── Windows
│ 	├── Actions
│ 	├── Managers
│ 	└── Package
├── Output
└── Tests

---

## API publique

Toutes les fonctions publiques sont exportées uniquement depuis PimsOS.psm1.

Les composants internes ne doivent pas définir leur propre API publique.

---

## Composants internes

Les composants internes :

- Logger
- Workflow
- Registry
- Image
- Report
- Check

ne sont pas destinés à être importés individuellement.

Ils collaborent librement au sein du module PimsOS.

## Architecture en couches

Chaque couche possède une responsabilité unique.

Une couche ne doit jamais contourner une autre couche.

---

## Composants indépendants

Les composants communiquent uniquement :

- via le BuildContext ;
- via leurs interfaces publiques.

Les dépendances circulaires sont interdites.

---

## Logique métier séparée

Les règles métier sont implémentées dans les composants.

Les fichiers JSON ne contiennent que des données.

---

## Modules techniques spécialisés

Les opérations Windows sont exclusivement réalisées par des modules spécialisés.

Les composants ne réalisent jamais directement d'appels aux API Windows.

---

## BuildContext central

Le BuildContext constitue l'objet central du Builder.

Il est créé une seule fois puis enrichi progressivement tout au long du pipeline.

Les détails de son fonctionnement sont décrits dans **BuildContext.md** ainsi que dans les ADR correspondantes.

---

# Vue d'ensemble

Le fonctionnement général de PimsOS est résumé par le schéma suivant.

```text
              Utilisateur
				  │
				  ▼
			Build-PimsOS.ps1
				  │
				  ▼
			Import-Module PimsOS
				  │
				  ▼
			PimsOS.psm1
				  │
				  ├─────────────┐
				  │             │
				  ▼             ▼
			Infrastructure    Core
				  │             │
				  ├──────┬──────┤
				  ▼      ▼      ▼
			Configuration Windows Image
				  │
				  ▼
			Actions
				  │
				  ▼
			BuildContext
				  │
				  ▼
			Pipeline de Build
				  │
				  ▼
			Windows
```

Chaque couche possède une responsabilité clairement définie.

Cette organisation permet :

- un faible couplage entre composants ;
- une forte modularité ;
- une excellente testabilité ;
- une maintenance simplifiée ;
- une grande extensibilité.

Les détails de chaque composant sont décrits dans les chapitres suivants.

# Architecture logique

PimsOS Builder est organisé selon une architecture en couches.

Chaque couche possède une responsabilité clairement définie et ne communique qu'avec les couches qui lui sont directement associées.

```text
Utilisateur
      │
      ▼
Build-PimsOS.ps1

↓

PimsOS.psm1

↓

Workflow

↓

Pipeline

↓

Engines

↓

Modules Windows

↓

Windows
```

Cette organisation garantit :

- une séparation stricte des responsabilités ;
- un faible couplage ;
- une forte cohérence ;
- une excellente testabilité.

---

# Les couches du Builder

## Build

Le Build constitue le point d'entrée du projet.

Son unique responsabilité est de récupérer les paramètres utilisateur puis de démarrer le Builder.

Le Build ne contient aucune logique métier.

**Entrées**

- Paramètres utilisateur

**Sorties**

- Initialisation du Builder

---

## Builder

Le Builder est implémenté au sein du module PimsOS. Il orchestre le pipeline de construction et prépare l'environnement avant le lancement du Workflow.

Le Builder est l'orchestrateur principal du projet.

Il prépare l'environnement avant le lancement du Workflow.

Il est notamment responsable de :

- l'initialisation du projet ;
- la création du BuildContext ;
- le chargement de la configuration ;
- la vérification de l'environnement ;
- l'initialisation des composants ;
- le démarrage du Workflow.

Le Builder ne réalise jamais directement une opération Windows.

**Voir également**

- BuildContext.md
- ADR-0002
- ADR-0004

---

## Workflow

Le Workflow commence désormais systématiquement par une phase **Recovery**.

Cette phase est responsable de :

- détecter les ressources déjà montées ;
- nettoyer les montages invalides ;
- préparer une reprise de build si elle est possible.

Le Workflow reste purement déclaratif : il décrit uniquement les grandes étapes d'un build.

Le Workflow décrit les grandes phases d'un Build.

Il ne contient aucune logique technique.

Il définit uniquement l'ordre général des traitements.

Exemple :

```text
Recovery
    │
    ▼
Environment
    │
    ▼
ISO
    │
    ▼
WIM
    │
    ▼
Registry
    │
    ▼
Configuration
    │
    ▼
Actions
    │
    ▼
Commit
    │
    ▼
Cleanup
```

Chaque phase est ensuite confiée au Pipeline.

---

## Pipeline

Le Pipeline exécute les différentes étapes définies par le Workflow.

Ses responsabilités sont :

- exécuter les étapes dans le bon ordre ;
- propager le BuildContext ;
- assurer le suivi de l'exécution ;
- gérer les erreurs ;
- journaliser les étapes.

Le Pipeline ne connaît jamais les détails des personnalisations.
Le Pipeline orchestre uniquement les différentes étapes du build.

Les décisions techniques (par exemple la réutilisation d'un montage WIM) sont déléguées à des composants spécialisés.

Ainsi, le Pipeline ne contient aucune logique de décision métier.

**Voir également**

- ADR-0004
- ADR-0008

---

## Engine

L'Engine représente le cœur de la logique métier.

Il reçoit les objets créés à partir des fichiers JSON et détermine quel moteur spécialisé doit traiter chaque Action.

Il ne réalise jamais directement une opération Windows.

Ses responsabilités sont :

- analyser les Actions ;
- sélectionner le moteur adapté ;
- transmettre le BuildContext ;
- récupérer le résultat.

---

## ActionEngine

ActionEngine centralise le routage des Actions.

Le routage repose désormais sur un registre central (`ActionRegistry`) qui associe dynamiquement chaque type d'Action à son Engine spécialisé.

Cette architecture permet d'ajouter un nouveau type d'Action sans modifier l'Engine principal.

Pour chaque Action, il sélectionne automatiquement l'Engine spécialisé correspondant.

Exemple :

```text
Registry  ─────► RegistryEngine

Service   ─────► ServiceEngine

Feature   ─────► FeatureEngine

Package   ─────► PackageEngine
```

Cette couche permet :

- d'isoler les moteurs spécialisés ;
- d'ajouter facilement de nouveaux types d'Actions ;
- de limiter le couplage entre les composants.

---

# Les Engines spécialisés

Chaque Engine est spécialisé dans un domaine fonctionnel unique.

Tous les Engines respectent la même interface :

**Entrées**

- BuildContext
- Action

**Sortie**

- BuildContext

Les principaux Engines actuellement prévus sont :

| Engine | Responsabilité |
|---------|----------------|
| RegistryEngine | Registre Windows |
| ServiceEngine | Services Windows |
| PackageEngine | Installation de logiciels |
| DriverEngine | Gestion des pilotes |
| FeatureEngine | Fonctionnalités Windows |
| CapabilityEngine | Windows Capabilities |
| CommandEngine | Exécution de commandes |
| FileEngine | Copie, suppression et modification de fichiers |
| FolderEngine | Gestion des dossiers |
| EnvironmentEngine | Variables d'environnement |
| ScheduledTaskEngine | Tâches planifiées |
| ShortcutEngine | Raccourcis Windows |

Chaque nouveau type d'Action devra disposer de son propre Engine.

---
## Les Managers

Les Engines ne réalisent jamais directement les opérations Windows.

Ils délèguent les traitements techniques à des Managers spécialisés.

Managers actuellement disponibles :

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

Chaque Manager encapsule les appels système nécessaires à son domaine fonctionnel.

# Les modules techniques

## Recovery

Le mécanisme Recovery constitue le point d'entrée technique du pipeline.

Il vérifie notamment :

- les montages DISM ;
- les images ISO ;
- les ruches du registre ;
- le Workspace.

La décision de reprendre ou non un build est entièrement centralisée dans :

Test-WimMountState()

À terme, cette fonction retournera un objet de diagnostic complet décrivant l'état du build et les actions à effectuer.

Les modules techniques constituent la seule couche autorisée à communiquer directement avec Windows.

Ils encapsulent toutes les API Windows utilisées par le projet.

Ils ignorent totalement :

- les profils ;
- les catégories ;
- les Tweaks ;
- les Actions ;
- les fichiers JSON.

Ils réalisent uniquement des opérations techniques.

Exemples :

| Module | Responsabilité |
|---------|----------------|
| Registry.ps1 | Registre Windows |
| Service.ps1 | Services Windows |
| Dism.ps1 | Gestion DISM |
| Wim.ps1 | Images WIM |
| Iso.ps1 | Images ISO |
| Chocolatey.ps1 | Gestionnaire Chocolatey |
| Winget.ps1 | Gestionnaire Winget |

Les modules techniques ne doivent contenir aucune logique métier.

Ils sont conçus pour être réutilisables et facilement testables.

---

# Principes de fonctionnement

Toutes les personnalisations suivent le même parcours.

```text
Configuration JSON
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
        │
        ▼
Engine spécialisé
        │
        ▼
Module technique
        │
        ▼
Windows
```

Cette architecture garantit :

- un comportement uniforme ;
- une exécution prévisible ;
- une maintenance simplifiée ;
- une forte extensibilité.

# Flux d'exécution

Toutes les personnalisations suivent le même cycle de traitement.

```text
Utilisateur
      │
      ▼
Build-PimsOS.ps1
      │
      ▼
Import-Module PimsOS
      │
      ▼
Initialize-PimsOS
	  │
      ▼
Création du BuildContext
      │
      ▼
Chargement de la configuration
      │
      ▼
Chargement des profils
      │
      ▼
Chargement des catégories
      │
      ▼
Création des objets Tweak
      │
      ▼
Création des Actions
      │
      ▼
Validation
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

Chaque étape produit des objets qui sont transmis à la suivante via le BuildContext.

Cette organisation garantit une exécution prévisible et reproductible.

---

# Communication entre les composants

Les composants de PimsOS communiquent exclusivement selon les règles suivantes.

## Communication interne au module

Tous les composants internes appartiennent au module PimsOS.

Ils partagent le même espace de noms et peuvent collaborer directement.

Aucun composant interne ne doit être importé individuellement.

Les composants internes ne doivent jamais utiliser
Import-Module pour communiquer entre eux.

Toute collaboration s'effectue directement
au sein du module PimsOS.

## Communication descendante

Une couche ne communique qu'avec la couche immédiatement inférieure.

```text
Builder
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
    │
    ▼
Engine spécialisé
    │
    ▼
Module technique
```

Une couche ne doit jamais contourner une couche intermédiaire.

---

## Communication via le BuildContext

Toutes les informations nécessaires à l'exécution transitent par le BuildContext.

Aucun composant ne doit utiliser :

- des variables globales ;
- des états partagés ;
- des échanges implicites.

Le BuildContext constitue l'unique source de vérité pendant toute l'exécution du Build.

Pour plus d'informations, consulter :

- BuildContext.md
- ADR-0002
- ADR-0010

---

## Dépendances

Les dépendances suivent également une structure strictement descendante.

```text
Build
    │
    ▼
Builder
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
    │
    ▼
Engines spécialisés
    │
    ▼
Modules techniques
```

Les dépendances circulaires sont interdites.

Chaque composant ne dépend que des éléments nécessaires à sa responsabilité.

Cette organisation facilite :

- les tests unitaires ;
- le remplacement d'un composant ;
- l'ajout de nouvelles fonctionnalités ;
- la maintenance du projet.

Le module PimsOS constitue la racine de toutes les dépendances.

Les composants internes ne sont pas des modules PowerShell indépendants.
Ils sont chargés par PimsOS.psm1.
Le manifeste PimsOS.psd1 ne décrit pas les dépendances internes.

Celles-ci sont gérées exclusivement par PimsOS.psm1.

---

# Décisions d'architecture (ADR)

Les décisions structurantes de PimsOS sont documentées sous forme d'Architecture Decision Records (ADR).

Les ADR décrivent les choix d'architecture, leurs motivations ainsi que leurs conséquences.

Les ADR actuellement publiées sont :

| ADR | Sujet |
|------|-------|
| ADR-0001 | Architecture modulaire |
| ADR-0002 | BuildContext central |
| ADR-0003 | Organisation des composants |
| ADR-0004 | Pipeline de build |
| ADR-0005 | Journalisation centralisée |
| ADR-0006 | Configuration JSON |
| ADR-0007 | Stratégie de tests |
| ADR-0008 | Gestion des erreurs |
| ADR-0009 | Dépendances entre composants |
| ADR-0010 | Cycle de vie du BuildContext |
| ADR-0011 | Contrats entre composants |
| ADR-0012 | Module PowerShell unique

Toute évolution importante de l'architecture devra faire l'objet d'une nouvelle ADR.

---

# Documentation associée

Le présent document décrit uniquement l'architecture générale de PimsOS.

Les aspects détaillés sont documentés dans les fichiers suivants.

## Documentation technique

- API.md
- BuildContext.md
- CodingStandards.md
- DeveloperGuide.md
- GettingStarted.md
- Lifecycle.md
- ModuleGuide.md
- Prerequisites.md
- ProjectStructure.md
- Roadmap.md
- Schema.md
- Testing.md

## Gouvernance

- CONTRIBUTING.md
- SECURITY.md
- SUPPORT.md
- CHANGELOG.md

## Architecture

- Documentation/ADR/

---
# BuildContext

Le BuildContext constitue désormais le contrat unique entre tous les composants du framework.

Il contient notamment :

- les informations du projet ;
- les informations de version ;
- les chemins de travail ;
- l'état du build (`BuildState`) ;
- les statistiques ;
- les rapports ;
- les configurations ;
- les ressources montées ;
- les objets métier (Tweaks, Actions, Packages, Drivers, Services, Features).

Chaque étape du pipeline enrichit progressivement ce contexte sans jamais créer d'état global supplémentaire.

# Conclusion

L'architecture de PimsOS repose sur une séparation stricte des responsabilités et sur un module PowerShell unique.

Le module PimsOS centralise le chargement des composants internes, expose l'API publique et garantit un espace de noms commun à l'ensemble du framework.

Cette architecture permet :

- une maintenance simplifiée ;
- une excellente testabilité ;
- une forte extensibilité ;
- une évolution maîtrisée ;
- la suppression des problèmes de portée entre composants.

Les décisions structurantes sont documentées dans les ADR afin de garantir la pérennité de l'architecture et de faciliter les évolutions futures.