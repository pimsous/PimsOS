# PimsOS Builder - Guide du développeur

> Version technique : 3.0.0
>
> Statut : Référence
>
> Dernière mise à jour : 2026-08-29

---

# Objectif

Ce document décrit les bonnes pratiques à suivre pour contribuer au projet **PimsOS Builder**.

Il s'adresse à toute personne souhaitant :

- corriger un bug ;
- développer une nouvelle fonctionnalité ;
- ajouter un nouveau type d'Action ;
- améliorer l'architecture ;
- participer à la maintenance du framework.

---

# Avant de commencer

Avant toute modification, lire les documents suivants :

- `Architecture.md`
- `ArchitectureRules.md`
- `BuildContext.md`
- `CodingStandards.md`
- `ModuleGuide.md`
- `ProjectStructure.md`
- `Testing.md`

Ces documents constituent les références officielles du projet.

---

# Comprendre l'architecture

PimsOS repose sur un module PowerShell unique et une architecture en couches.

Chaque composant possède une responsabilité clairement définie.

Le flux logique principal est :

```text
Infrastructure / Core / Configuration
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

Avant d'ajouter du code, toujours identifier la couche et le composant responsables du besoin.

---

# Cycle de développement

Toute nouvelle fonctionnalité suit le cycle suivant :

1. Identifier le besoin.
2. Vérifier qu'un composant similaire n'existe pas déjà.
3. Déterminer la couche et le composant concernés.
4. Concevoir la solution.
5. Développer.
6. Écrire ou adapter les tests.
7. Mettre à jour la documentation.
8. Valider le fonctionnement.
9. Mettre à jour les ADR si nécessaire.
10. Effectuer le commit.

---

# Organisation des composants

Les composants internes sont répartis dans :

```text
Modules/
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

Les composants internes ne sont pas des modules PowerShell indépendants.

---

# Ajouter un nouvel Engine

Les Engines sont placés dans :

```text
Modules\Actions
```

Chaque Engine :

- traite un domaine d'Action défini ;
- contient la logique métier de ce domaine ;
- ne réalise pas directement les appels aux API Windows ;
- reçoit le BuildContext et l'Action ;
- met à jour l'état relevant de sa responsabilité ;
- utilise le Logger officiel ;
- propage correctement les erreurs.

Le traitement technique est délégué au Manager approprié.

Exemples :

```text
RegistryEngine
FeatureEngine
PackageEngine
DriverEngine
```

---

# Ajouter un nouveau Manager

Les Managers sont placés dans :

```text
Modules\Managers
```

Ils encapsulent les opérations techniques de leur domaine.

Ils peuvent notamment interagir avec :

- DISM ;
- le registre Windows ;
- le système de fichiers ;
- les fournisseurs de packages ;
- les fonctionnalités Windows ;
- les autres composants techniques nécessaires à leur domaine.

Les Managers ne prennent pas les décisions métier relatives aux profils ou aux Tweaks.

---

# Ajouter un nouveau type d'Action

Pour ajouter un nouveau type d'Action :

1. identifier son domaine fonctionnel ;
2. créer l'Engine spécialisé ;
3. créer ou adapter le Manager correspondant si nécessaire ;
4. enregistrer le type dans `ActionRegistry.ps1` ;
5. ajouter les validations nécessaires ;
6. ajouter les tests Pester ;
7. mettre à jour le BuildContext ou les statistiques si nécessaire ;
8. mettre à jour la documentation.

Le traitement doit suivre :

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

Aucun composant ne doit appeler directement un Engine spécialisé en contournant le routage normal.

---

# Ajouter un Tweak

Les Tweaks sont des définitions de configuration.

Ils doivent rester séparés de la logique PowerShell.

Un Tweak peut notamment contenir :

- un identifiant ;
- une catégorie ;
- une description ;
- des Actions ;
- des métadonnées ;
- des contraintes de compatibilité.

Les Tweaks ne doivent pas contenir de logique PowerShell exécutable.

---

# Profils

Les profils déterminent les personnalisations sélectionnées pour un Build.

Ils peuvent activer ou désactiver des Tweaks selon le scénario choisi.

Le profil ne doit pas contenir de logique d'exécution.

Le moteur de configuration construit une configuration finale avant l'exécution des Actions.

---

# BuildContext

Le BuildContext est le contrat central entre les composants.

Il ne doit jamais être remplacé par un nouvel objet au cours du Build.

Chaque composant enrichit ou met à jour uniquement les informations relevant de sa responsabilité.

Toute nouvelle donnée doit être ajoutée au BuildContext uniquement lorsqu'elle représente un état ou une information réellement partagée entre plusieurs composants.

Les composants ne doivent pas utiliser un état global pour transporter les données du Build.

---

# BuildState

Le BuildState représente l'état courant de l'exécution.

Il doit être utilisé pour les informations de progression et d'état du Build.

Les nouveaux composants doivent mettre à jour le BuildState lorsque leur contrat l'exige.

---

# PostInstall

Le PostInstall est le runtime exécuté après l'installation de Windows.

Il est préparé pendant le Build puis embarqué dans l'image Windows. Le runtime installé doit être autonome et ne doit pas dépendre du chemin du dépôt PimsOS utilisé sur la machine de Build.

Le runtime est installé dans :

```text
C:\ProgramData\PimsOS\PostInstall\
```

Les composants principaux sont :

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

Le flux d'exécution est :

```text
Build
    │
    ▼
Runtime PostInstall
    │
    ▼
unattend.xml
    │
    ▼
FirstLogonCommands
    │
    ▼
Bootstrap.ps1
    │
    ▼
PostInstall
```

## Bootstrap

`Bootstrap.ps1` constitue le point d'entrée du runtime.

Il localise le runtime installé, vérifie les composants nécessaires, charge les scripts requis puis démarre le PostInstall.

Le Bootstrap ne doit pas dépendre du chemin du dépôt utilisé pour construire l'image.

## État

`State.ps1` fournit la gestion de l'état persistant du PostInstall.

L'état permet notamment de suivre :

- l'état courant ;
- la phase d'exécution ;
- les tâches terminées ;
- la disponibilité du réseau ;
- les erreurs ;
- le statut final.

## Réseau

`Network.ps1` fournit les vérifications réseau.

Le runtime distingue :

- la présence d'un adaptateur ;
- la disponibilité du réseau local ;
- l'accès à Internet.

Un adaptateur actif ne signifie donc pas nécessairement qu'Internet est disponible.

Lorsque l'accès réseau est requis et indisponible, le PostInstall peut passer par l'état `WaitingForNetwork` puis reprendre automatiquement lorsque les conditions sont réunies.

## Interface utilisateur

`UI.ps1` fournit l'affichage console du premier démarrage.

Les fonctions principales sont :

```powershell
Show-PostInstallNetworkStatus
Show-PostInstallNetworkHelp
Wait-PostInstallNetworkUI
```

La couche UI présente l'état du réseau et les instructions nécessaires à l'utilisateur. Elle ne doit pas absorber la logique métier du PostInstall.

## Installer

`Installer.ps1` prépare le runtime dans l'image Windows et installe la configuration FirstBoot.

Il vérifie la présence des fichiers requis avant leur copie et installe `unattend.xml` dans :

```text
C:\Windows\Panther\unattend.xml
```

## Tests PostInstall

Les composants PostInstall doivent disposer de tests Pester adaptés.

Les tests doivent couvrir, lorsque cela est pertinent :

- l'initialisation de l'état ;
- les vérifications réseau ;
- la disponibilité d'Internet ;
- l'attente et la reprise réseau ;
- les erreurs ;
- le Bootstrap ;
- l'installation du runtime ;
- la génération de `unattend.xml` ;
- l'intégration au Pipeline.

---

# Compatibilité Windows

Le Builder n'est pas conçu pour une seule version de Windows.

Les informations relatives à la cible doivent provenir :

- de l'image Windows ;
- du BuildContext ;
- de la configuration ;
- des contraintes déclarées par les Tweaks.

Les composants ne doivent pas coder en dur une version telle que `24H2` ou `25H2` lorsqu'il s'agit d'une information de configuration ou de compatibilité.

---

# Journalisation

Toute opération importante doit être journalisée via :

```powershell
Write-Log
```

Les appels à :

```powershell
Write-Host
```

sont interdits dans la logique métier.

`Write-Verbose` et `Write-Debug` peuvent être utilisés pour les informations de diagnostic appropriées.

L'interface console du runtime PostInstall constitue une exception fonctionnelle : `UI.ps1` utilise volontairement `Write-Host` pour afficher les informations destinées à l'utilisateur lors du premier démarrage. Cette utilisation doit rester limitée à la couche UI.

---

# Gestion des erreurs

Les erreurs doivent :

- être détectées ;
- être traitées au niveau approprié ;
- être journalisées lorsque nécessaire ;
- être propagées lorsqu'elles ne peuvent pas être traitées localement.

Ne jamais masquer une exception sans justification.

Dans un module, ne pas utiliser :

```powershell
exit
```

pour interrompre arbitrairement le processus appelant.

---

# Tests

Toute nouvelle fonctionnalité importante doit être accompagnée de tests Pester adaptés.

Les tests doivent couvrir, lorsque cela est pertinent :

- le fonctionnement nominal ;
- les paramètres invalides ;
- les cas d'erreur ;
- les cas limites ;
- les changements d'état ;
- les statistiques ;
- les régressions.

Pour une correction de bug, ajouter ou adapter un test de régression lorsque cela est pertinent.

---

# Documentation

Toute évolution importante doit mettre à jour les documents concernés.

Selon le changement, cela peut inclure :

- `API.md`
- `Architecture.md`
- `ArchitectureRules.md`
- `BuildContext.md`
- `CodingStandards.md`
- `ModuleGuide.md`
- `ProjectStatus.md`
- `ProjectStructure.md`
- `Roadmap.md`
- `Milestones.md`
- `ReleaseNotes.md`
- `Testing.md`

Si l'architecture évolue, une nouvelle ADR doit être créée lorsque la décision le justifie.

---

# Revue de code

Avant un commit important, vérifier :

- le code est syntaxiquement valide ;
- le module se charge correctement ;
- les tests concernés passent ;
- aucune erreur critique n'est introduite ;
- le BuildContext respecte son contrat ;
- les nouveaux composants respectent les Architecture Rules ;
- la documentation est à jour ;
- les ADR sont mises à jour si nécessaire.

PowerShell n'étant pas compilé comme un langage classique, la validation doit notamment porter sur le parsing, le chargement du module et l'exécution des tests.

---

# Workflow Git

Chaque évolution importante suit le processus suivant :

1. Développement.
2. Validation locale.
3. Exécution des tests.
4. Mise à jour de la documentation.
5. Vérification des ADR si nécessaire.
6. Vérification de `git status`.
7. Commit Git.
8. Push vers le dépôt distant lorsque l'évolution est prête.

Un commit doit représenter une évolution cohérente.

---

# Ajout d'un composant

Avant de créer un nouveau composant :

- vérifier qu'un composant existant ne répond pas déjà au besoin ;
- définir clairement sa responsabilité ;
- choisir la couche appropriée ;
- identifier ses dépendances ;
- prévoir ses tests ;
- documenter l'évolution lorsque nécessaire.

Un composant ne doit pas cumuler plusieurs responsabilités indépendantes.

---

# Philosophie

Le développement de PimsOS Builder repose sur les principes suivants :

- simplicité ;
- lisibilité ;
- modularité ;
- réutilisabilité ;
- testabilité ;
- maintenabilité ;
- extensibilité.

Le respect de l'architecture est prioritaire sur la rapidité de développement.

Une nouvelle fonctionnalité doit, lorsque l'architecture le permet, avoir un impact limité sur les composants existants.

Les duplications doivent être évitées lorsqu'une solution réutilisable existe.

---

# Références

- `Architecture.md`
- `ArchitectureRules.md`
- `BuildContext.md`
- `CodingStandards.md`
- `ModuleGuide.md`
- `ProjectStructure.md`
- `Testing.md`
- `TechnicalDecisions.md`
- `Documentation\ADR\`
