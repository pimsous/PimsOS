# PimsOS Builder - Standards de développement

> Version technique : 3.0.0
>
> Statut : Référence
>
> Dernière mise à jour : 2026-08-31

---

# Objectif

Ce document définit les conventions de développement utilisées dans l'ensemble du projet **PimsOS Builder**.

Tous les composants du framework doivent respecter ces règles.

L'objectif est de garantir :

- une architecture homogène ;
- un code lisible ;
- une maintenance simplifiée ;
- une bonne testabilité ;
- une évolutivité durable.

---

# Principes fondamentaux

Le projet repose sur les principes suivants :

- responsabilité unique ;
- faible couplage ;
- forte cohésion ;
- architecture modulaire ;
- aucune duplication inutile ;
- BuildContext unique ;
- séparation de la logique métier et de la logique technique ;
- API publique minimale ;
- tests automatisés.

---

# Organisation du projet

Le projet est organisé autour des domaines suivants :

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

Chaque dossier possède une responsabilité clairement définie.

---

# Organisation des fichiers

Un fichier doit contenir un composant principal clairement identifiable.

Exemples :

```text
BuildContext.ps1
Pipeline.ps1
ActionRegistry.ps1
RegistryEngine.ps1
PackageManager.ps1
```

Les composants fortement liés peuvent être regroupés lorsque cela améliore la lisibilité et respecte leur responsabilité.

---

# Responsabilités

Chaque composant possède une responsabilité clairement définie.

| Composant | Responsabilité |
|-----------|----------------|
| Core | Fonctionnement central du framework |
| Workflow | Définition des grandes phases |
| Pipeline | Orchestration des étapes |
| ActionEngine | Routage des Actions |
| ActionRegistry | Association Action → Engine |
| Engine spécialisé | Logique métier du domaine |
| Manager | Opérations techniques du domaine |
| Module technique | Accès aux technologies système |

---

# Convention de nommage

## Fonctions

Les fonctions publiques ou internes suivent le verbe PowerShell approprié :

```text
Verbe-Nom
```

Exemples :

```powershell
Get-Configuration
Invoke-Action
New-BuildContext
Test-WimMountState
```

Les verbes PowerShell officiels doivent être privilégiés lorsqu'ils correspondent au comportement de la fonction.

---

## Variables

Les variables doivent utiliser des noms explicites.

Exemples :

```powershell
$Context
$Configuration
$Tweak
$Action
$Package
$Category
```

Éviter les noms ambigus tels que :

```powershell
$tmp
$obj
$a
$x
```

sauf lorsque leur portée et leur signification sont évidentes dans un contexte très local.

---

## Paramètres

Les paramètres doivent utiliser des noms explicites et cohérents avec les contrats du framework.

Exemples :

```powershell
-Context
-Action
-Configuration
-Profile
-Provider
-Source
-Destination
```

---

## Objets métier

Les objets métier sont construits avec des `PSCustomObject` et des fonctions constructeurs lorsque cela est approprié.

Exemple :

```powershell
New-BuildContext
```

Les anciennes classes PowerShell ne constituent plus le modèle de référence pour les objets métier du framework.

---

# Structure des fonctions

Les fonctions doivent utiliser :

```powershell
[CmdletBinding()]
```

lorsqu'elles constituent des commandes ou fonctions nécessitant le comportement avancé PowerShell.

Les paramètres doivent être déclarés dans :

```powershell
param()
```

Les fonctions importantes sont organisées de manière lisible, généralement selon :

```text
Initialisation
Validation
Traitement
Journalisation
Retour
```

Les blocs `begin`, `process` et `end` sont réservés aux fonctions ayant un véritable besoin de traitement par pipeline.

---

# Commentaires

Les commentaires doivent expliquer principalement :

- pourquoi un traitement existe ;
- pourquoi une décision particulière a été prise ;
- quelles contraintes techniques doivent être respectées.

Ils ne doivent pas simplement répéter une instruction évidente.

Les grandes sections peuvent utiliser le format standard du projet :

```powershell
# ==========================================
# Initialisation
# ==========================================
```

---

# Journalisation

Toute la journalisation du framework passe par :

```powershell
Write-Log
```

L'utilisation de :

```powershell
Write-Host
```

est interdite dans la logique métier du Builder.

Les fonctions peuvent utiliser :

```powershell
Write-Verbose
Write-Debug
```

pour les informations de diagnostic adaptées à ces mécanismes.

---

# Gestion des erreurs

Les erreurs doivent être traitées au niveau approprié.

Lorsqu'une erreur doit être propagée, utiliser :

```powershell
throw
```

Les blocs `catch` ne doivent pas masquer silencieusement une erreur.

Une erreur propagée doit conserver suffisamment de contexte pour permettre son diagnostic.

Un module ne doit pas utiliser :

```powershell
exit
```

pour arrêter le processus appelant.

---

# BuildContext

Les informations partagées entre plusieurs composants du Build doivent transiter par le BuildContext.

Le BuildContext constitue le contrat central entre les couches.

Il est interdit d'utiliser un état global pour transporter les informations du Build.

Les variables de portée `script:` peuvent être utilisées pour l'état interne limité d'un composant, par exemple une table de providers, mais elles ne doivent pas remplacer le BuildContext.

---

# Architecture Engine / Manager

Les responsabilités sont strictement séparées.

```text
Engine spécialisé
        │
        ▼
Manager
        │
        ▼
Provider / module technique
        │
        ▼
Windows
```

Les Engines portent la logique métier de leur domaine.

Les Managers encapsulent les opérations techniques.

Les Engines ne doivent pas appeler directement les API Windows lorsqu'un Manager ou un module technique doit assurer cette responsabilité.

---

# Routage des Actions

Le traitement d'une Action suit le mécanisme :

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
```

Un nouveau type d'Action doit être enregistré dans l'ActionRegistry.

L'ActionEngine ne doit pas devenir un ensemble de conditions spécifiques à chaque type d'Action.

---

# Configuration

Les données métier configurables doivent provenir, selon leur nature :

- des fichiers JSON ;
- des profils ;
- des paramètres utilisateur ;
- du BuildContext.

Les valeurs qui relèvent de la configuration métier ne doivent pas être dupliquées inutilement dans le code.

Les contraintes techniques internes au framework peuvent naturellement rester définies dans le code lorsque leur nature n'est pas configurable.

---

# Compatibilité Windows

Le Builder ne doit pas être conçu autour d'une seule version spécifique de Windows.

Les informations relatives à l'image ciblée doivent être découvertes ou fournies par la configuration et le BuildContext.

Les Tweaks peuvent déclarer leurs propres contraintes de compatibilité lorsqu'elles existent.

Une nouvelle version compatible de Windows ne doit pas nécessiter de modification de l'architecture générale du framework.

---

# Encodage

Les fichiers texte du projet utilisent :

- UTF-8 ;
- sans BOM.

Les fins de lignes et les paramètres d'éditeur doivent rester cohérents avec les conventions du dépôt.

---

# Indentation

Le code PowerShell utilise :

- 4 espaces pour l'indentation ;
- aucune tabulation dans les blocs de code.

---

# Mise en forme

Respecter systématiquement :

- une ligne vide entre les fonctions ;
- une ligne vide entre les grandes sections ;
- une indentation cohérente ;
- des noms de propriétés et variables lisibles ;
- des blocs de code facilement identifiables.

---

# Tests

Tout nouveau composant important doit être accompagné de tests Pester adaptés.

Les tests doivent couvrir, lorsque cela est pertinent :

- le comportement nominal ;
- les paramètres invalides ;
- les erreurs attendues ;
- les cas limites ;
- les changements d'état ;
- les statistiques ;
- les régressions connues.

Les tests unitaires doivent rester déterministes et reproductibles autant que possible.

---

# Documentation

Toute évolution importante doit mettre à jour les documents concernés.

Selon le changement, cela peut inclure :

- `Architecture.md`
- `ArchitectureRules.md`
- `API.md`
- `BuildContext.md`
- `ModuleGuide.md`
- `ProjectStatus.md`
- `ProjectStructure.md`
- `Roadmap.md`
- `Milestones.md`
- `ReleaseNotes.md`
- les ADR concernées.

La documentation fait partie intégrante du développement.

---

# Dépendances

Les dépendances circulaires sont interdites.

Le flux logique principal suit :

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

Les composants ne doivent pas contourner inutilement les couches.

---

# Compatibilité de développement

| Composant | Version / règle |
|-----------|------------------|
| Windows | Windows 11, environnement de référence actuel |
| PowerShell | 7.6.x |
| Pester | 5.x |
| Git | version compatible avec le dépôt |

Les versions exactes d'outils susceptibles d'évoluer ne doivent pas être présentées comme des contraintes architecturales.

---

# Revue de code

Avant un commit important, vérifier notamment :

- le code est syntaxiquement valide ;
- le module se charge correctement ;
- les tests concernés passent ;
- aucune erreur critique n'est introduite ;
- la documentation est à jour ;
- les ADR sont mises à jour si nécessaire ;
- les nouveaux composants respectent les Architecture Rules ;
- les dépendances restent cohérentes.

PowerShell n'est pas un langage compilé au sens classique ; la validation doit donc porter notamment sur le parsing, le chargement du module et l'exécution des tests.

---

# Philosophie

Le code doit être :

- simple ;
- lisible ;
- modulaire ;
- testable ;
- prévisible ;
- facilement extensible.

La simplicité est préférée à la complexité inutile.

Une nouvelle fonctionnalité doit, lorsque l'architecture le permet, être ajoutée avec un impact limité sur les composants existants.

Toute duplication introduite doit avoir une justification claire.

---

# PostInstall

Le développement du runtime **PostInstall** suit les mêmes standards
que les autres composants du framework.

## Composants

Le runtime PostInstall comprend notamment :

```text
State.ps1
Network.ps1
UI.ps1
PostInstall.ps1
Bootstrap.ps1
FirstBoot.ps1
Unattend.ps1
Installer.ps1
```

Chaque composant conserve une responsabilité distincte.

## Interface utilisateur

`UI.ps1` fournit l'interface console du premier démarrage pour les
vérifications réseau.

Les fonctions principales sont :

```powershell
Show-PostInstallNetworkStatus
Show-PostInstallNetworkHelp
Wait-PostInstallNetworkUI
```

La couche UI ne doit pas absorber la logique métier du PostInstall.

## Réseau

La vérification distingue :

- la présence d'un adaptateur réseau ;
- la disponibilité du réseau local ;
- la disponibilité d'Internet.

Un réseau local disponible sans accès Internet est donc traité comme
une situation distincte.

Lorsque cela est nécessaire, le runtime attend la disponibilité du
réseau et reprend automatiquement son traitement.

## Runtime installé

Le runtime est préparé par le Build puis installé dans :

```text
C:\ProgramData\PimsOS\PostInstall\
```

Le runtime installé ne doit pas dépendre du chemin du dépôt utilisé
pour construire l'image.

`Installer.ps1` vérifie la présence des fichiers nécessaires avant de
les copier dans l'image Windows.

## FirstBoot

Le Build prépare également le démarrage automatique du PostInstall
via `unattend.xml`.

Le flux est :

```text
Build
    ↓
Runtime PostInstall
    ↓
unattend.xml
    ↓
FirstLogonCommands
    ↓
Bootstrap.ps1
    ↓
PostInstall
```

## Tests

Les composants PostInstall doivent disposer de tests Pester couvrant
notamment :

- le comportement nominal ;
- les erreurs ;
- les cas réseau ;
- l'attente et la reprise ;
- l'intégration du Bootstrap ;
- l'installation du runtime ;
- la génération de `unattend.xml`.

Toute modification importante doit être validée par les tests unitaires
concernés et par les tests d'intégration lorsque l'impact le justifie.

# Références

- `Architecture.md`
- `ArchitectureRules.md`
- `ModuleGuide.md`
- `Testing.md`
- `TechnicalDecisions.md`
- `Documentation\ADR\`
