# ADR-0009 — Gestion des dépendances entre composants

- **Statut** : Acceptée
- **Date** : 2026-07-19
- **Dernière mise à jour** : 2026-08-16
- **Décideur** : Pims
- **Impact** : Architecture interne du framework

---

# Contexte

L'architecture initiale de PimsOS reposait sur plusieurs frameworks indépendants.

L'architecture actuelle a évolué vers un **module PowerShell unique** contenant plusieurs composants internes organisés par responsabilité.

Cette organisation nécessite néanmoins des règles explicites concernant les dépendances entre composants afin d'éviter :

- les dépendances circulaires ;
- les couplages inutiles ;
- les chargements complexes ;
- les difficultés de test ;
- les dépendances implicites ;
- les violations des responsabilités des couches.

---

# Décision

Les dépendances entre composants suivent une direction définie par l'architecture.

Le flux de dépendance de référence est :

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

Les composants `Core`, `Configuration` et `Infrastructure` fournissent les services nécessaires aux autres parties du framework selon leurs responsabilités.

Tous les composants appartiennent au module :

```text
PimsOS
```

Ils ne constituent pas des modules PowerShell indépendants.

---

# Principes

Les dépendances doivent être :

- explicites ;
- minimales ;
- unidirectionnelles ;
- justifiées ;
- compatibles avec la responsabilité du composant ;
- facilement testables.

Une nouvelle dépendance ne doit pas être ajoutée uniquement pour contourner une mauvaise séparation des responsabilités.

---

# Dépendances autorisées

Un composant peut utiliser :

- les fonctions et contrats internes du module nécessaires à sa responsabilité ;
- le BuildContext ;
- le BuildState lorsque l'état d'exécution est concerné ;
- les composants situés dans les couches autorisées par l'architecture ;
- les bibliothèques et commandes système nécessaires à son fonctionnement technique.

Les Engines spécialisés utilisent les Managers de leur domaine.

Les Managers utilisent les providers ou modules techniques nécessaires.

---

# Dépendances interdites

Les composants ne doivent jamais :

- créer une dépendance circulaire ;
- contourner inutilement une couche ;
- accéder à une responsabilité appartenant à une couche supérieure ;
- dupliquer les fonctions d'un autre composant pour éviter une dépendance ;
- utiliser un état global pour contourner le BuildContext.

Les composants internes ne doivent pas utiliser :

```powershell
Import-Module
```

pour charger un autre composant interne de PimsOS.

Le chargement des composants est centralisé dans :

```text
PimsOS.psm1
```

---

# Architecture des dépendances

Le modèle de référence est :

```text
Core / Infrastructure
          │
          ▼
    Configuration
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

Les relations exactes peuvent varier selon le domaine, mais elles doivent toujours respecter les responsabilités et la direction générale des couches.

---

# ActionRegistry

`ActionRegistry` constitue un point central de résolution des Engines spécialisés.

Un appelant ne doit pas contourner le registre pour résoudre directement un Engine lorsqu'il s'agit du routage normal d'une Action.

Le parcours attendu est :

```text
Action
   ↓
ActionEngine
   ↓
ActionRegistry
   ↓
Engine spécialisé
```

Cette règle limite le couplage entre l'appelant et les Engines spécialisés.

---

# BuildContext comme contrat commun

Le BuildContext constitue un mécanisme commun de partage des données du Build.

Il ne doit pas être utilisé pour masquer une dépendance directe qui devrait être exprimée par un contrat de composant.

Le BuildContext transporte l'état et les données partagés ; il ne remplace pas les responsabilités des composants.

---

# Inversion de dépendance

Lorsqu'une collaboration doit être introduite entre deux composants, privilégier lorsque c'est pertinent :

- un contrat clairement défini ;
- une fonction interne bien identifiée ;
- le BuildContext pour les données réellement partagées ;
- un point central de résolution comme l'ActionRegistry pour le routage des Actions.

Une dépendance doit être conçue pour rester remplaçable et testable lorsque cela apporte une valeur réelle.

---

# Chargement des composants

Le chargement des composants internes est centralisé par :

```text
Modules\PimsOS.psm1
```

L'ordre de chargement doit permettre aux fonctions utilisées par les composants dépendants d'être disponibles au moment de leur exécution.

Les composants ne doivent pas implémenter leur propre système de chargement.

---

# Conséquences

## Avantages

- architecture plus lisible ;
- faible couplage ;
- dépendances prévisibles ;
- tests facilités ;
- évolution plus localisée ;
- réduction des dépendances implicites.

## Inconvénients

- nécessité de respecter les couches ;
- conception plus rigoureuse des contrats ;
- ajout d'une nouvelle dépendance nécessitant une analyse préalable.

---

# Alternatives étudiées

## Dépendances libres

Rejetées.

Sans direction de dépendance, les composants pourraient progressivement créer des relations circulaires et devenir difficiles à maintenir.

---

## Appels directs entre tous les composants

Rejetés.

Une telle organisation augmenterait fortement le couplage et rendrait les contrats moins lisibles.

---

## Frameworks PowerShell indépendants

Non retenus comme modèle actuel.

L'architecture actuelle conserve la séparation des responsabilités au sein du module PimsOS unique.

---

# Règles

Toute nouvelle dépendance doit :

- être nécessaire ;
- respecter les couches ;
- ne pas créer de cycle ;
- être cohérente avec la responsabilité du composant ;
- être testable ;
- être documentée lorsque son impact est important.

Avant de créer une nouvelle dépendance, vérifier qu'un composant existant ne fournit pas déjà la capacité recherchée.

---

# Tests

Les tests doivent notamment permettre de détecter :

- les dépendances implicites ;
- les appels impossibles ;
- les contrats incorrects ;
- les résolutions de provider incorrectes ;
- les violations du routage des Actions lorsque cela est testable.

Une évolution de dépendance importante doit être accompagnée des tests correspondants.

---

# Évolution

Toute modification importante du modèle de dépendances doit être évaluée au regard de :

- `Architecture.md` ;
- `ArchitectureRules.md` ;
- `ModuleGuide.md` ;
- `ADR-0001` ;
- `ADR-0003` ;
- `ADR-0012`.

Lorsqu'une évolution modifie réellement l'architecture des dépendances, une nouvelle ADR doit être créée ou la décision existante doit être mise à jour.

---

# Décision finale

PimsOS conserve une organisation modulaire interne tout en utilisant un module PowerShell unique.

Les dépendances suivent une direction descendante et restent limitées aux responsabilités nécessaires.

Le principe de référence est :

```text
Orchestration
    ↓
Routage
    ↓
Logique métier
    ↓
Opérations techniques
```

Les dépendances circulaires et les contournements de couches sont interdits.

---

# Références

- `Architecture.md`
- `ArchitectureRules.md`
- `ModuleGuide.md`
- `ADR-0001-ModularArchitecture.md`
- `ADR-0003-FrameworkStructure.md`
- `ADR-0012-ModuleUnique.md`
