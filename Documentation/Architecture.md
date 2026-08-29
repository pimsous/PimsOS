# PimsOS Builder - Architecture

> Documentation de l'architecture logicielle
>
> Version technique : 3.0.0
>
> Statut : Développement / architecture stabilisée
>
> Dernière mise à jour : 2026-08-29

---

# Sommaire

- Présentation
- État architectural actuel
- Philosophie
- Objectifs
- Principes d'architecture
- Architecture du module PimsOS
- Vue d'ensemble
- Architecture logique
- Les couches du Builder
- Engines spécialisés
- Managers
- Modules techniques
- Flux d'exécution
- Communication entre les composants
- Dépendances
- BuildContext
- ActionRegistry
- Recovery
- Décisions d'architecture
- Documentation associée
- Conclusion

---

# Présentation

PimsOS Builder est un framework PowerShell permettant de construire et de personnaliser des images Windows à partir d'images sources compatibles.

Le projet automatise progressivement les différentes étapes du processus de Build tout en conservant une architecture :

- modulaire ;
- testable ;
- extensible ;
- maintenable ;
- indépendante d'une version précise de Windows ciblée.

Le Builder ne doit pas modifier directement les ressources sources lorsqu'une copie de travail est nécessaire.

Les opérations de modification sont réalisées dans l'environnement de travail du Build afin de préserver les ressources sources.

---

# État architectural actuel

La version technique actuelle du framework est :

```text
3.0.0
```

L'architecture est considérée comme stabilisée.

Le framework dispose notamment de :

- un module PowerShell unique ;
- un BuildContext centralisé ;
- un BuildState ;
- un Workflow ;
- un Pipeline ;
- un ActionRegistry ;
- un ActionEngine ;
- des Engines spécialisés ;
- des Managers spécialisés ;
- des composants techniques pour les images, le registre et l'environnement ;
- une couverture de tests Pester importante.

Le pipeline prend notamment en charge :

- la préparation de l'environnement ;
- la vérification des prérequis ;
- la gestion des ressources ISO et WIM ;
- le chargement de la configuration ;
- la sélection et la fusion des profils et Tweaks ;
- la validation de la configuration ;
- l'exécution des Actions via les Engines spécialisés ;
- le nettoyage et la finalisation du Build.

La génération complète de l'ISO finale ainsi que certains providers et composants restent en cours de finalisation.

L'architecture est conçue pour permettre l'ajout de nouveaux types d'Actions avec un impact limité sur les composants existants.

---

# Philosophie

L'architecture de PimsOS repose sur quelques principes simples qui guident l'ensemble du développement.

## Responsabilité unique

Chaque composant possède une responsabilité clairement définie.

Un composant ne doit pas réaliser plusieurs responsabilités indépendantes.

---

## Modularité

Les fonctionnalités sont isolées dans des composants spécialisés.

L'ajout d'une nouvelle fonctionnalité doit rester aussi localisé que possible.

---

## Séparation des responsabilités

Chaque couche possède un rôle précis.

Les Engines portent la logique métier de leur domaine.

Les Managers et modules techniques encapsulent les opérations techniques.

---

## Testabilité

Les composants doivent pouvoir être testés indépendamment lorsque cela est pertinent.

Les tests unitaires font partie intégrante du développement.

---

## Extensibilité

L'architecture doit permettre l'ajout de nouveaux Engines, Managers, providers et types d'Actions sans modifier inutilement les composants existants.

---

## Maintenabilité

Le projet privilégie :

- un code lisible ;
- des contrats clairs ;
- une documentation synchronisée ;
- une architecture cohérente ;
- des changements localisés.

---

# Objectifs

Le développement de PimsOS poursuit plusieurs objectifs.

## Construire une image Windows personnalisée

Créer automatiquement une image adaptée aux besoins de l'utilisateur.

---

## Industrialiser les personnalisations

Les personnalisations sont décrites sous forme de données de configuration.

Aucune logique métier exécutable ne doit être placée dans les fichiers JSON.

---

## Garantir la reproductibilité

Deux Builds réalisés avec les mêmes données, les mêmes paramètres et le même environnement compatible doivent viser un résultat reproductible.

---

## Faciliter la maintenance

Les composants du framework sont séparés par responsabilité.

Les évolutions doivent pouvoir être réalisées avec un impact limité sur le reste du projet.

---

## Centraliser les échanges

Les informations partagées pendant le Build transitent par un BuildContext unique.

---

# Principes d'architecture

L'architecture de PimsOS repose notamment sur les principes suivants :

- module PowerShell unique ;
- API publique minimale ;
- BuildContext centralisé ;
- BuildState centralisé pour l'état d'exécution ;
- séparation Workflow / Pipeline ;
- ActionRegistry pour le routage ;
- séparation Engine / Manager ;
- modules techniques spécialisés ;
- dépendances descendantes ;
- absence de dépendance circulaire ;
- validation des données avant exécution ;
- journalisation centralisée ;
- tests automatisés.

Les règles détaillées sont définies dans :

```text
Documentation\ArchitectureRules.md
```

---

# Architecture du module PimsOS

L'architecture de PimsOS repose sur un module PowerShell unique.

Le projet n'est pas constitué d'une collection de modules PowerShell indépendants, mais d'un framework unique composé de composants internes.

Cette organisation simplifie les dépendances, facilite le chargement et permet de conserver une API publique cohérente.

---

## Module unique

Le module public du projet est :

```text
PimsOS
```

Tous les composants internes appartiennent à ce module.

---

## Rôle de PimsOS.psd1

Le manifeste décrit le module.

Il contient notamment :

- les métadonnées ;
- la version ;
- les paramètres du module ;
- l'identification du module.

Il ne contient pas la logique métier du Builder.

---

## Rôle de PimsOS.psm1

`PimsOS.psm1` constitue le point d'entrée du framework.

Il est responsable :

- du chargement des composants internes ;
- de l'initialisation du framework ;
- de l'exposition de l'API publique.

L'API publique actuelle est volontairement minimale et expose :

```powershell
Initialize-PimsOS
```

---

## Organisation des composants

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

---

## API publique

Les fonctions publiques sont exportées uniquement depuis `PimsOS.psm1`.

Les composants internes ne doivent pas définir leur propre API publique.

Les fonctions internes ne deviennent pas publiques simplement parce qu'elles sont chargées dans le module.

---

## Composants internes

Les composants internes comprennent notamment :

- Core ;
- Configuration ;
- Infrastructure ;
- Image ;
- Actions ;
- Managers ;
- Package ;
- Windows.

Ils ne sont pas destinés à être importés individuellement.

Ils sont chargés par `PimsOS.psm1` et constituent les composants internes du module PimsOS.

---

# Architecture en couches

Chaque couche possède une responsabilité unique.

Une couche ne doit pas contourner inutilement une autre couche.

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

Les composants Core et Infrastructure fournissent les services nécessaires autour de ce flux.

---

# Vue d'ensemble

Le fonctionnement général de PimsOS peut être résumé ainsi :

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
    ▼
Initialize-PimsOS
    │
    ▼
BuildContext
    │
    ├───────────────┬────────────────┐
    ▼               ▼                ▼
Infrastructure     Core        Configuration
    │               │                │
    └───────────────┴────────────────┘
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

Cette organisation permet :

- un faible couplage entre composants ;
- une forte modularité ;
- une bonne testabilité ;
- une maintenance simplifiée ;
- une extensibilité maîtrisée.

---

# Architecture logique

PimsOS Builder est organisé selon une architecture en couches.

Chaque couche possède une responsabilité clairement définie.

```text
Utilisateur
    │
    ▼
Initialize-PimsOS
    │
    ▼
BuildContext
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

Cette organisation garantit :

- une séparation stricte des responsabilités ;
- un faible couplage ;
- une forte cohésion ;
- une bonne testabilité.

---

# Les couches du Builder

## Entrée du Builder

Le script de lancement prépare l'environnement nécessaire au démarrage du framework.

Le point d'entrée fonctionnel du module reste :

```powershell
Initialize-PimsOS
```

---

## Builder

Le Builder est implémenté au sein du module PimsOS et constitue l'orchestrateur principal du projet.

Il prépare l'environnement avant le lancement du Workflow.

Il est notamment responsable de :

- l'initialisation du projet ;
- la création du BuildContext ;
- l'initialisation du Logger ;
- la vérification de l'environnement ;
- le démarrage du Workflow ;
- la finalisation du Build.

Le Builder ne réalise pas directement les opérations techniques Windows.

---

## Workflow

Le Workflow décrit les grandes phases d'un Build.

Il reste principalement déclaratif et ne doit pas contenir de logique technique détaillée.

La phase Recovery intervient en amont afin d'identifier et de traiter les ressources éventuellement laissées par un Build précédent.

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

Chaque phase est ensuite traitée par les composants appropriés.

---

## Pipeline

Le Pipeline exécute les différentes étapes définies par le Workflow.

Ses responsabilités sont notamment :

- exécuter les étapes dans le bon ordre ;
- propager le BuildContext ;
- suivre l'état d'exécution ;
- gérer les erreurs au niveau de l'orchestration ;
- journaliser les étapes.

Le Pipeline ne connaît pas les détails des personnalisations.

Les décisions techniques doivent être déléguées à des composants spécialisés.

Par exemple, la décision de réutiliser un montage WIM est centralisée par :

```powershell
Test-WimMountState()
```

Le Pipeline orchestre et ne doit pas dupliquer cette décision.

---

# Engine

L'Engine représente la logique de traitement des Actions.

Il reçoit les objets construits à partir de la configuration et utilise le routage centralisé pour déterminer quel Engine spécialisé doit traiter chaque Action.

Il ne réalise pas directement les opérations Windows.

---

# ActionEngine

`ActionEngine` centralise le routage des Actions.

Le routage repose sur `ActionRegistry`, qui associe les types d'Actions aux Engines spécialisés.

Cette architecture permet d'ajouter un nouveau type d'Action sans modifier la logique de routage principale.

Exemple :

```text
Registry   ─────► RegistryEngine
Service    ─────► ServiceEngine
Feature    ─────► FeatureEngine
Package    ─────► PackageEngine
Driver     ─────► DriverEngine
Command    ─────► CommandEngine
```

Cette couche permet :

- d'isoler les Engines spécialisés ;
- d'ajouter de nouveaux types d'Actions ;
- de limiter le couplage.

---

# Les Engines spécialisés

Chaque Engine est spécialisé dans un domaine fonctionnel.

Les Engines utilisent un contrat commun :

**Entrées**

- BuildContext ;
- Action.

**Sortie**

- BuildContext.

Les Engines actuellement implémentés sont :

| Engine | Responsabilité |
|---------|----------------|
| RegistryEngine | Registre Windows |
| ServiceEngine | Services Windows |
| PackageEngine | Packages |
| DriverEngine | Pilotes |
| FeatureEngine | Fonctionnalités Windows |
| CapabilityEngine | Windows Capabilities |
| CommandEngine | Exécution de commandes |
| FileEngine | Opérations sur les fichiers |
| FolderEngine | Opérations sur les dossiers |
| EnvironmentEngine | Variables d'environnement |
| ScheduledTaskEngine | Tâches planifiées |
| ShortcutEngine | Raccourcis Windows |

Chaque nouveau type d'Action doit être accompagné d'un Engine spécialisé lorsque le domaine le justifie.

---

# Les Managers

Les Engines ne réalisent pas directement les opérations techniques Windows.

Ils délèguent les traitements aux Managers spécialisés.

Managers actuellement implémentés :

- PackageManager ;
- DriverManager ;
- FeatureManager ;
- CapabilityManager ;
- CommandManager ;
- FileManager ;
- FolderManager ;
- EnvironmentManager ;
- ScheduledTaskManager ;
- ShortcutManager.

Les Managers encapsulent les opérations techniques et la résolution des providers de leur domaine.

Ils disposent de tests unitaires dédiés.

---

# Les modules techniques

Les modules techniques constituent la couche qui interagit directement avec les technologies Windows.

Ils encapsulent les opérations techniques utilisées par le framework.

Exemples actuels :

| Module | Responsabilité |
|---------|----------------|
| Registry.ps1 | Registre Windows |
| Service.ps1 | Services Windows |
| Dism.ps1 | Opérations DISM |
| Wim.ps1 | Images WIM |
| Iso.ps1 | Images ISO |
| Recovery.ps1 | Récupération et préparation de l'environnement |

Les providers de packages suivants existent dans l'organisation du projet :

| Provider | État |
|----------|------|
| Chocolatey.ps1 | Architecture prévue, implémentation à finaliser |
| Winget.ps1 | Architecture prévue, implémentation à finaliser |

Les modules techniques ne doivent pas contenir de logique métier liée aux profils, Tweaks ou Actions.

---

# Principes de fonctionnement

Les personnalisations suivent le parcours suivant :

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

---

# Flux d'exécution

Le cycle général du Build est :

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
Workflow / Pipeline
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
Windows
    │
    ▼
Complete-Build
```

Chaque étape utilise le BuildContext approprié.

---

# Communication entre les composants

Les composants de PimsOS communiquent selon les règles suivantes.

## Communication interne au module

Tous les composants internes appartiennent au module PimsOS.

Ils partagent le même espace d'exécution et peuvent collaborer au sein du module.

Aucun composant interne ne doit être importé individuellement.

Les composants internes ne doivent jamais utiliser :

```powershell
Import-Module
```

pour charger un autre composant interne.

Ils sont chargés par `PimsOS.psm1`.

---

## Communication descendante

Le flux normal des dépendances est descendant :

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
```

Une couche ne doit pas contourner inutilement une couche intermédiaire.

---

## Communication via le BuildContext

Les informations nécessaires au partage de l'état et des données du Build transitent par le BuildContext.

Aucun composant ne doit utiliser :

- une variable globale ;
- un état global implicite ;
- un mécanisme de partage caché.

Les variables `script:` peuvent exister pour l'état interne limité d'un composant, par exemple une table de providers, mais elles ne doivent pas servir de substitut au BuildContext.

Le BuildContext constitue le contrat central du Build.

---

# Dépendances

Les dépendances suivent une structure descendante :

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
```

Les dépendances circulaires sont interdites.

Le module PimsOS constitue la racine de chargement des composants internes.

Les composants internes ne sont pas des modules PowerShell indépendants.

Ils sont chargés par :

```text
PimsOS.psm1
```

Le manifeste `PimsOS.psd1` décrit le module public et ses métadonnées ; il ne constitue pas le système de chargement des composants internes.

---

# BuildContext

Le BuildContext constitue le contrat central entre les composants du framework.

Il est créé au début du Build puis enrichi progressivement.

Il contient notamment :

- les informations du projet ;
- les informations de version ;
- les chemins de travail ;
- le BuildState ;
- les statistiques ;
- les rapports ;
- les configurations ;
- les ressources montées ;
- les objets métier tels que Tweaks et Actions.

Chaque étape du Pipeline met à jour le contexte relevant de sa responsabilité.

Aucun état global supplémentaire ne doit être créé pour transporter les informations du Build.

Les détails du modèle sont documentés dans :

- `BuildContext.md` ;
- `Schema.md` ;
- `ADR-0002` ;
- `ADR-0010`.

---

# ActionRegistry

`ActionRegistry` centralise l'association entre les types d'Actions et leurs Engines spécialisés.

Son objectif est de permettre au moteur de résoudre un Engine sans coder cette association directement dans chaque appelant.

Pour ajouter un nouveau type d'Action :

1. créer l'Engine spécialisé ;
2. définir son contrat ;
3. enregistrer le type dans `ActionRegistry` ;
4. ajouter les tests correspondants ;
5. mettre à jour la documentation lorsque nécessaire.

---

# Recovery

Le mécanisme Recovery constitue le point d'entrée technique pour la récupération et la préparation de l'environnement.

Il vérifie et traite notamment :

- les montages DISM ;
- les ressources ISO ;
- les ruches du registre ;
- le Workspace.

La décision de réutiliser un montage WIM est centralisée dans :

```powershell
Test-WimMountState()
```

Le mécanisme Recovery est implémenté.

Sa couverture de tests et certains diagnostics détaillés restent à compléter.

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
| ADR-0004 | Pipeline de Build |
| ADR-0005 | Journalisation centralisée |
| ADR-0006 | Configuration JSON |
| ADR-0007 | Stratégie de tests |
| ADR-0008 | Gestion des erreurs |
| ADR-0009 | Dépendances entre composants |
| ADR-0010 | Cycle de vie du BuildContext |
| ADR-0011 | Contrats entre composants |
| ADR-0012 | Module PowerShell unique |

Toute évolution importante de l'architecture doit être accompagnée d'une nouvelle ADR lorsque nécessaire.

---

# Documentation associée

Le présent document décrit l'architecture générale de PimsOS.

Les aspects détaillés sont documentés dans :

## Documentation technique

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
- `Roadmap.md`
- `Schema.md`
- `Testing.md`
- `TechnicalDecisions.md`

## Gouvernance

- `CHANGELOG.md`
- `README.md`

## Architecture

- `Documentation\ADR\`

---

# Conclusion

L'architecture de PimsOS repose sur une séparation stricte des responsabilités et sur un module PowerShell unique.

Le module PimsOS centralise le chargement des composants internes, expose l'API publique et fournit un espace d'exécution commun aux différents composants du framework.

Le flux principal est :

```text
BuildContext
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
```

Cette architecture permet :

- une maintenance simplifiée ;
- une bonne testabilité ;
- une forte extensibilité ;
- une évolution maîtrisée ;
- une gestion cohérente des responsabilités.

Les décisions structurantes sont documentées dans les ADR afin de préserver la cohérence de l'architecture au fil des évolutions.

## PostInstall

Le Build prépare le système, tandis que le runtime **PostInstall**
exécute les opérations nécessaires après l'installation de Windows.

La séparation des responsabilités est :

```text
Build
    |
    v
WIM préparé
    |
    v
FirstBoot
    |
    v
PostInstall Bootstrap
    |
    v
Initialisation de l'état
    |
    v
Vérification réseau / Internet
    |
    +-- Réseau disponible
    |       |
    |       v
    |   Installation locale
    |       |
    |       v
    |   Opérations réseau
    |
    +-- Réseau indisponible
            |
            v
       WaitingForNetwork
            |
            v
       Reprise automatique
            |
            v
       PostInstall
            |
            v
       PackageManager
            |
            v
       Applications
```

### Runtime autonome

Le runtime PostInstall est embarqué dans le WIM lors du Build.

Il est ensuite exécuté depuis :

```text
C:\ProgramData\PimsOS\PostInstall\
```

Le runtime ne dépend pas du chemin du dépôt PimsOS présent sur la
machine ayant construit l'image.

Les fichiers nécessaires au runtime sont notamment :

```text
Bootstrap.ps1
Network.ps1
UI.ps1
PostInstall.ps1
State.ps1
```

L'installation du runtime est réalisée par :

```powershell
Install-PimsOSPostInstallRuntime
```

Cette fonction valide la présence du runtime source, crée le dossier
de destination et copie les fichiers nécessaires dans l'image Windows.

### Bootstrap

`Bootstrap.ps1` constitue le point d'entrée du runtime PostInstall.

Il :

- localise le runtime installé ;
- vérifie la présence des composants nécessaires ;
- charge `State.ps1` ;
- charge `Network.ps1` ;
- charge `UI.ps1` ;
- charge `PostInstall.ps1` ;
- démarre l'exécution PostInstall.

Le Bootstrap permet ainsi au runtime d'être initialisé indépendamment
du dépôt de Build.

### État PostInstall

L'exécution PostInstall repose sur un état persistant permettant
d'identifier la progression du processus.

L'état permet notamment de gérer :

- l'initialisation ;
- l'exécution des phases locales ;
- l'attente du réseau ;
- la reprise après disponibilité du réseau ;
- les erreurs d'exécution.

### Gestion réseau

La couche réseau distingue la disponibilité du réseau local de
l'accès réel à Internet.

La vérification suit le principe :

```text
Adaptateur réseau
        |
        v
Connexion réseau
        |
        v
Accès Internet
```

Un adaptateur actif ne signifie donc pas nécessairement qu'Internet
est disponible.

PostInstall distingue notamment les situations suivantes :

```text
Aucun adaptateur
        |
        v
Réseau indisponible
```

et :

```text
Adaptateur actif
        |
        v
Réseau local disponible
        |
        v
Internet indisponible
```

Cette distinction est importante car certaines opérations PostInstall
nécessitent un accès Internet.

### Interface réseau du premier démarrage

`UI.ps1` fournit l'interface console utilisée pendant le premier
démarrage.

Elle expose notamment :

```powershell
Show-PostInstallNetworkStatus
Show-PostInstallNetworkHelp
Wait-PostInstallNetworkUI
```

`Show-PostInstallNetworkStatus` présente l'état courant du réseau et
de l'accès Internet.

`Show-PostInstallNetworkHelp` fournit les indications nécessaires à
l'utilisateur lorsqu'une connexion réseau est requise.

`Wait-PostInstallNetworkUI` assure l'attente avec affichage de l'état
et permet la reprise automatique lorsque la connexion devient
disponible.

La couche UI reste séparée de la logique métier de PostInstall.

### Intégration FirstBoot

Le Build génère également la configuration `unattend.xml` permettant
de lancer le Bootstrap lors du premier démarrage de Windows.

Le fichier est installé dans :

```text
C:\Windows\Panther\unattend.xml
```

Le flux est donc :

```text
Build
    |
    v
Installation du runtime
    |
    v
Génération unattend.xml
    |
    v
Installation de Windows
    |
    v
FirstLogonCommands
    |
    v
Bootstrap.ps1
    |
    v
PostInstall
```

La génération du fichier `unattend.xml` est réalisée par les
composants FirstBoot/Unattend du framework.

### Séparation Build / PostInstall

Le Build et PostInstall possèdent des responsabilités différentes.

**Build :**

- prépare l'image Windows ;
- applique les personnalisations offline ;
- installe le runtime PostInstall ;
- prépare FirstBoot ;
- génère `unattend.xml`.

**PostInstall :**

- s'exécute dans Windows installé ;
- initialise son état ;
- vérifie l'environnement réseau ;
- vérifie l'accès Internet ;
- attend si nécessaire la disponibilité du réseau ;
- reprend automatiquement l'exécution lorsque les conditions sont
  réunies ;
- exécute les opérations prévues après installation.

Cette séparation conserve une frontière claire entre les opérations
offline du Build et les opérations runtime réalisées après
l'installation de Windows.
