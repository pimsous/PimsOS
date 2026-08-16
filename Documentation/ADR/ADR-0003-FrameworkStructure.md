# ADR-0003 — Organisation des composants du framework

- **Statut** : Acceptée
- **Date** : 2026-07-19
- **Dernière mise à jour** : 2026-08-16
- **Décideur** : Pims
- **Impact** : Structure interne du framework

---

# Contexte

La première architecture de PimsOS prévoyait plusieurs frameworks PowerShell indépendants, chacun pouvant disposer de sa propre structure.

L'évolution du projet vers un module PowerShell unique a rendu nécessaire une révision de cette organisation.

Le projet doit conserver une séparation claire des responsabilités tout en évitant de multiplier les modules PowerShell indépendants.

Une convention d'organisation interne est donc nécessaire afin de garantir :

- une structure homogène ;
- une séparation claire des responsabilités ;
- une navigation facilitée ;
- une maintenance simplifiée ;
- une bonne testabilité.

---

# Décision

PimsOS utilise désormais **un module PowerShell unique** contenant des composants internes organisés par domaine fonctionnel.

La structure de référence est :

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

Les composants internes appartiennent tous au module :

```text
PimsOS
```

Ils sont chargés par :

```text
PimsOS.psm1
```

Ils ne constituent pas des modules PowerShell indépendants.

---

# Description des composants

## Manifest (`PimsOS.psd1`)

Le manifeste décrit notamment :

- les métadonnées du module ;
- la version ;
- la compatibilité PowerShell ;
- les fonctions publiques exportées ;
- les informations nécessaires à l'identification du module.

Il ne contient pas la logique métier du Builder.

---

## Module racine (`PimsOS.psm1`)

Le module racine constitue le point d'entrée du framework.

Il :

- charge les composants internes ;
- respecte l'ordre de chargement nécessaire aux dépendances ;
- initialise les composants nécessaires ;
- expose l'API publique ;
- exporte explicitement les fonctions publiques.

L'API publique actuelle est volontairement minimale :

```powershell
Initialize-PimsOS
```

---

## Core

Le dossier `Core` contient les composants centraux du framework.

Il comprend notamment :

- BuildContext ;
- BuildState ;
- Workflow ;
- Pipeline ;
- ActionRegistry ;
- Engine ;
- Report ;
- Complete-Build.

Le Core orchestre le fonctionnement général mais ne doit pas remplacer les Engines spécialisés ou les Managers techniques.

---

## Infrastructure

Le dossier `Infrastructure` contient les services transverses.

Il comprend notamment :

- Check ;
- Logger ;
- Recovery ;
- Security ;
- Service ;
- Validation ;
- Converters.

Ces composants fournissent des services communs et ne doivent pas contenir la logique métier des Tweaks.

---

## Configuration

Le dossier `Configuration` contient les composants responsables des données de configuration.

Il comprend notamment :

- Categories ;
- Configuration ;
- Profile ;
- Tweak.

Il assure notamment :

- le chargement des données ;
- la validation ;
- la construction des configurations ;
- la fusion des profils et des Tweaks.

---

## Actions

Le dossier `Actions` contient les Engines spécialisés.

Il comprend notamment :

- ActionEngine ;
- RegistryEngine ;
- ServiceEngine ;
- PackageEngine ;
- DriverEngine ;
- FeatureEngine ;
- CapabilityEngine ;
- CommandEngine ;
- FileEngine ;
- FolderEngine ;
- EnvironmentEngine ;
- ScheduledTaskEngine ;
- ShortcutEngine.

Chaque Engine possède une responsabilité fonctionnelle clairement définie.

---

## Managers

Le dossier `Managers` contient les composants techniques utilisés par les Engines spécialisés.

Il comprend notamment :

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

Les Managers encapsulent les traitements techniques de leur domaine.

---

## Package

Le dossier `Package` contient les providers de gestion de packages.

Les providers prévus comprennent notamment :

- Chocolatey ;
- Winget.

Ces providers restent des composants internes du module PimsOS.

---

## Image

Le dossier `Image` contient les composants techniques relatifs aux images Windows.

Il comprend notamment :

- Dism ;
- Iso ;
- Wim.

Ces composants encapsulent les opérations techniques nécessaires aux images Windows.

---

## Windows

Le dossier `Windows` contient les composants spécifiques aux technologies Windows.

Le composant actuellement présent comprend notamment :

- Registry.

---

# Tests

Les tests du framework sont centralisés dans :

```text
Tests
```

Les tests peuvent être organisés selon leur nature, par exemple :

```text
Tests
├── Unit
├── Integration
└── Legacy
```

Les tests unitaires des composants internes restent séparés des composants eux-mêmes afin de conserver une organisation commune du dépôt.

---

# Ressources et configuration du projet

Les ressources du projet qui ne constituent pas des composants du module restent organisées dans les répertoires appropriés du dépôt, notamment :

```text
Config
Profiles
Resources
Tweaks
Workspace
```

Ces répertoires ne constituent pas des modules PowerShell.

---

# Responsabilités

La structure doit respecter le principe de responsabilité unique.

Un composant ne doit pas :

- cumuler plusieurs domaines fonctionnels indépendants ;
- devenir une API publique sans décision explicite ;
- contourner inutilement les couches ;
- contenir une logique appartenant à une autre responsabilité.

---

# Conséquences

## Avantages

- architecture interne homogène ;
- module PowerShell unique ;
- responsabilités clairement séparées ;
- chargement centralisé ;
- API publique maîtrisée ;
- meilleure maintenabilité ;
- tests facilités ;
- évolution localisée.

## Inconvénients

- structure plus rigoureuse ;
- nombre de fichiers internes plus important ;
- nécessité de respecter les conventions de chargement et de dépendances ;
- nécessité de distinguer composants internes et API publique.

---

# Alternatives étudiées

## Organisation libre

Rejetée.

Chaque domaine aurait pu adopter une organisation différente, ce qui aurait rendu la navigation et la maintenance plus difficiles.

---

## Toutes les fonctions dans un seul fichier

Rejetée.

Un fichier unique serait rapidement devenu trop volumineux et aurait fortement augmenté le couplage entre responsabilités.

---

## Un module PowerShell indépendant par domaine

Rejeté comme modèle de référence actuel.

Cette approche augmenterait le nombre de frontières de modules, les imports et les dépendances à gérer.

Le projet conserve la modularité au niveau des composants internes d'un module PimsOS unique.

---

# Évolution par rapport à la décision initiale

La décision initiale du 19/07/2026 décrivait une structure générique applicable à plusieurs frameworks indépendants.

L'architecture actuelle a évolué vers un module PimsOS unique.

Cette ADR conserve donc le principe initial de séparation des responsabilités, mais adapte son organisation au modèle actuel.

Cette évolution est cohérente avec :

- ADR-0001 — Adoption d'une architecture modulaire ;
- ADR-0012 — Module PowerShell unique ;
- `Architecture.md` ;
- `ModuleGuide.md` ;
- `ArchitectureRules.md`.

---

# Règles

Tout nouveau composant doit :

1. être placé dans le domaine fonctionnel approprié ;
2. avoir une responsabilité clairement définie ;
3. respecter les dépendances existantes ;
4. disposer des tests nécessaires ;
5. rester interne au module PimsOS sauf décision explicite d'exposition publique.

Toute nouvelle organisation importante doit être documentée si elle modifie l'architecture du framework.

---

# Décision finale

La structure interne du projet repose sur un **module PowerShell unique** dont les composants sont organisés par responsabilité.

Cette organisation constitue la structure de référence de PimsOS Builder 3.0.0.

Toute évolution future doit préserver cette séparation des responsabilités et éviter la création de modules PowerShell indépendants sans décision architecturale explicite.

---

# Références

- `Architecture.md`
- `ArchitectureRules.md`
- `ModuleGuide.md`
- `ProjectStructure.md`
- `ADR-0001-ModularArchitecture.md`
- `ADR-0012-ModuleUnique.md`
