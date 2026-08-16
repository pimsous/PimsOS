# PimsOS Builder - Décisions techniques

> Version : 3.0.0
>
> Statut : Référence
>
> Dernière mise à jour : 2026-08-16

---

# Objectif

Ce document recense les principales décisions techniques prises au cours du développement de **PimsOS Builder**.

Contrairement aux **Architecture Decision Records (ADR)**, ces décisions concernent exclusivement les choix d'implémentation, les conventions de développement et les bonnes pratiques PowerShell.

Les décisions ayant un impact sur l'architecture générale du projet sont documentées dans le dossier **Documentation/ADR**.

---

# Principes

Les décisions documentées dans ce fichier doivent :

- concerner uniquement l'implémentation ;
- ne pas modifier l'architecture du projet ;
- être datées ;
- expliquer le contexte ;
- justifier le choix retenu ;
- préciser les composants concernés.

Toute décision ayant un impact sur l'architecture doit faire l'objet d'une ADR.

---

# Historique

## 2026-07-21

### Normalisation des collections PowerShell

#### Contexte

Certaines fonctions PowerShell peuvent retourner :

- aucun objet ;
- un objet ;
- plusieurs objets.

Lorsqu'un seul objet est retourné, la propriété `.Count` n'est plus disponible.

#### Décision

Toutes les collections manipulées avec `.Count` sont systématiquement encapsulées avec :

```powershell
@(...)
```

Cette règle garantit un comportement identique quel que soit le nombre d'éléments retournés.

#### Composants concernés

- Backup

---

## 2026-07-21

### Génération des identifiants de session

#### Contexte

Deux sauvegardes créées durant la même seconde pouvaient produire un identifiant identique.

#### Décision

Le format retenu est :

```powershell
Get-Date -Format "yyyy-MM-dd_HH-mm-ss-fff"
```

L'ajout des millisecondes garantit l'unicité.

#### Composants concernés

- Backup

---

## 2026-07-23

### Tests Pester sur les collections vides

#### Contexte

Une collection correctement initialisée mais vide provoquait des faux positifs avec :

```powershell
$Collection | Should -Not -BeNull
```

#### Décision

Les collections sont désormais validées explicitement :

```powershell
($null -eq $Collection) | Should -BeFalse
$Collection.Count | Should -Be 0
```

Cette règle est utilisée dans l'ensemble des nouveaux tests.

#### Composants concernés

- Migration

---

## 2026-07-24

### Abandon des classes PowerShell

#### Contexte

Les premières versions utilisaient plusieurs classes PowerShell.

Les tests ont montré qu'elles compliquaient :

- le rechargement des modules ;
- les tests Pester ;
- le développement itératif ;
- le chargement dynamique.

#### Décision

Les classes métier sont remplacées par des `PSCustomObject` créés par des fonctions constructeur (`New-*`).

Cette approche simplifie considérablement le développement et les tests.

#### Composants concernés

- Migration

---

## 2026-07-25

### Contrat commun des objets métier

#### Contexte

L'abandon des classes supprimait la possibilité d'utiliser :

```powershell
Should -BeOfType
```

#### Décision

Tous les objets métier possèdent désormais une propriété :

```text
ObjectType
```

Cette propriété constitue le contrat d'identification commun à tous les objets du projet.

#### Composants concernés

- Ensemble du projet

---

## 2026-07-26

### Recovery centralisé

#### Contexte

Le Builder devait être capable de reprendre un build interrompu.

Un simple indicateur de reprise ne permettait pas de distinguer :

- un montage existant ;
- un montage réellement exploitable.

#### Décision

La préparation de l'environnement est confiée au composant **Recovery**.

La validation d'un montage WIM est centralisée dans :

```powershell
Test-WimMountState()
```

Le Pipeline ne prend jamais lui-même la décision de réutiliser un montage.

#### Évolutions

Recovery assure désormais :

- la détection des montages DISM ;
- la validation des montages ;
- le démontage des montages invalides ;
- le nettoyage du Workspace ;
- la préparation de l'environnement.

#### Composants concernés

- Recovery
- Pipeline
- WIM
- Registry

---

## 2026-08-02

### Introduction du BuildState

#### Contexte

Le BuildContext regroupait progressivement :

- les informations du projet ;
- les paramètres du build ;
- l'état d'avancement du moteur.

Cette approche mélangeait les données permanentes et l'état d'exécution.

#### Décision

Un objet dédié :

```text
BuildState
```

est introduit afin de centraliser exclusivement l'état du moteur.

Le BuildContext conserve les données du projet tandis que BuildState décrit l'exécution du Builder.

Le BuildState regroupe notamment :

- l'initialisation ;
- le Recovery ;
- les vérifications de l'environnement ;
- la progression du Pipeline ;
- l'état des montages ;
- le chargement de la configuration ;
- l'application des personnalisations.

Cette séparation simplifie le développement, les tests et le suivi d'exécution.

#### Composants concernés

- BuildContext
- Pipeline
- Recovery
- Engine

---

## 2026-08-02

### Séparation des métadonnées du projet

#### Contexte

Les informations du projet étaient réparties entre plusieurs fichiers.

Certaines étaient codées en dur.

#### Décision

Toutes les métadonnées sont désormais centralisées dans :

```text
version.json
```

Le Builder charge automatiquement :

- le nom du projet ;
- la version ;
- la version de Windows cible ;
- le numéro de build ;
- l'auteur ;
- la société ;
- le dépôt Git.

Le code ne contient plus ces informations en dur.

#### Composants concernés

- BuildContext
- Configuration

---

## 2026-08-03

### Support de plusieurs versions de Windows

#### Contexte

Le projet ne doit pas être limité à une unique version de Windows.

À terme, il devra être capable de personnaliser plusieurs versions officielles de Windows.

#### Décision

La version cible de Windows est désormais décrite dans le BuildContext sous la forme :

```text
Project.Windows.Release
Project.Windows.Build
```

Le moteur de build sélectionne automatiquement les personnalisations compatibles selon la version choisie.

Les Tweaks pourront déclarer les versions Windows qu'ils supportent.

Cette architecture prépare le support de plusieurs versions de Windows sans modifier le moteur.

#### Composants concernés

- BuildContext
- Configuration
- Profiles
- Tweaks
- Engine

---

## 2026-08-03

### Configuration pilotée par les profils

#### Contexte

Le moteur devait permettre à un utilisateur de choisir les personnalisations à appliquer sans modifier les fichiers de définition.

#### Décision

Les définitions de Tweaks constituent désormais un catalogue de fonctionnalités.

Les profils déterminent quelles personnalisations sont activées.

Le moteur construit ensuite une configuration finale fusionnée.

Les objets de configuration sont indépendants des définitions originales afin de préserver leur intégrité.

#### Composants concernés

- Profiles
- Configuration
- Tweaks
- Engine

---

## 2026-08-16

### Stabilisation des Engines spécialisés

#### Contexte

Les différents types d'Actions nécessitaient des Engines dédiés afin d'éviter de concentrer toute la logique dans l'ActionEngine principal.

#### Décision

Chaque type d'Action important possède désormais un Engine spécialisé.

Les Engines suivent un contrat commun :

```text
Context + Action
        ↓
traitement
        ↓
Context
```

Les Engines assurent la logique métier de leur domaine et délèguent les opérations techniques aux Managers.

#### Composants concernés

- ActionEngine
- ActionRegistry
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

## 2026-08-16

### Standardisation du cycle de vie des Actions

#### Contexte

Les Engines spécialisés devaient avoir un comportement homogène concernant l'état d'une Action et l'état du Build.

#### Décision

Les Engines spécialisés suivent désormais un cycle de traitement commun :

```text
Application
    │
    ▼
Traitement
    │
    ▼
Succès
```

En cas d'erreur :

```text
Application
    │
    ▼
Erreur
    │
    ▼
Échec
```

Lorsque les propriétés correspondantes existent sur l'Action, le traitement met également à jour :

- `Success`
- `Duration`
- `Error`

Les statistiques correspondantes sont mises à jour lorsque le compteur existe dans le BuildContext.

#### Composants concernés

- ActionEngine
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

## 2026-08-16

### Standardisation des providers des Managers

#### Contexte

Les Managers doivent pouvoir sélectionner un fournisseur technique sans intégrer directement toute la logique d'exécution dans leur propre implémentation.

#### Décision

Les Managers utilisent une table de correspondance permettant d'associer :

```text
Provider
    │
    ▼
Handler
```

Le traitement d'un provider suit le principe :

1. validation du provider ;
2. validation des paramètres nécessaires ;
3. résolution du handler ;
4. vérification de l'existence du handler ;
5. exécution du handler ;
6. retour du BuildContext.

Les Managers qui le prévoient peuvent également enregistrer et réinitialiser leurs providers.

#### Composants concernés

- CapabilityManager
- CommandManager
- DriverManager
- EnvironmentManager
- FeatureManager
- FileManager
- FolderManager
- PackageManager
- ScheduledTaskManager
- ShortcutManager

---

## 2026-08-16

### Correction de l'utilisation des dictionnaires ordonnés PowerShell

#### Contexte

Les tests des Managers ont révélé une incompatibilité entre certaines tables de providers définies comme dictionnaires ordonnés et l'utilisation de :

```powershell
.ContainsKey()
```

Un `OrderedDictionary` ne fournit pas cette méthode sous la forme utilisée dans l'implémentation initiale.

#### Décision

Les recherches de providers doivent utiliser une méthode compatible avec le type réel de collection utilisé.

Cette règle est protégée par les tests unitaires des Managers concernés.

#### Composants concernés

- CommandManager
- EnvironmentManager
- FileManager
- FolderManager
- ScheduledTaskManager
- ShortcutManager

---

## 2026-08-16

### API publique minimale

#### Contexte

Le module PimsOS contient de nombreux composants internes qui ne doivent pas automatiquement devenir des éléments de l'API publique.

#### Décision

L'API publique reste volontairement minimale.

La fonction actuellement exportée est :

```powershell
Initialize-PimsOS
```

Les Engines, Managers, composants Core, Configuration, Infrastructure, Image et Windows restent internes au module :

```text
PimsOS.psm1
```

Cette séparation permet de faire évoluer l'implémentation interne sans créer de contrat public pour chaque fonction interne.

#### Composants concernés

- PimsOS.psd1
- PimsOS.psm1
- API publique
- Core
- Configuration
- Engines
- Managers

---

## 2026-08-16

### Couverture de tests des Engines et Managers

#### Contexte

La stabilisation des Engines et Managers nécessitait une validation homogène de leurs contrats et de leurs comportements.

#### Décision

Les composants importants doivent disposer de tests unitaires couvrant notamment :

- le fonctionnement nominal ;
- les paramètres obligatoires ;
- les erreurs attendues ;
- les changements d'état ;
- les statistiques lorsqu'elles sont concernées ;
- la propagation des erreurs ;
- la transmission du contexte et de l'Action.

Les dépendances techniques peuvent être simulées lorsque l'exécution réelle n'est pas nécessaire au test du contrat.

#### Composants concernés

- Engines spécialisés
- Managers
- Configuration
- Registry
- Core

---

# Références

- `Architecture.md`
- `ArchitectureRules.md`
- `BuildContext.md`
- `CodingStandards.md`
- `Lifecycle.md`
- `Documentation/ADR/`

---

# Conclusion

Ce document constitue la mémoire des principaux choix d'implémentation réalisés au cours du développement de **PimsOS Builder**.

Il complète les ADR en documentant les décisions techniques qui influencent le développement quotidien du projet, sans modifier son architecture.
