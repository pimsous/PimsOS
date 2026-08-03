# Guide du développeur

> Version : 0.4.0
>
> Architecture : 2.x

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

- Architecture.md
- ArchitectureRules.md
- BuildContext.md
- CodingStandards.md
- ModuleGuide.md
- ProjectStructure.md

Ces documents constituent les références officielles du projet.

---

# Comprendre l'architecture

Le framework repose sur une architecture modulaire.

Chaque composant possède une responsabilité unique.

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
Module Windows
```

Avant d'ajouter du code, toujours identifier le composant concerné.

---

# Cycle de développement

Toute nouvelle fonctionnalité suit le cycle suivant :

1. Identifier le besoin.
2. Vérifier qu'un composant similaire n'existe pas déjà.
3. Déterminer le module concerné.
4. Concevoir la solution.
5. Développer.
6. Écrire les tests.
7. Mettre à jour la documentation.
8. Valider le fonctionnement.
9. Mettre à jour les ADR si nécessaire.

---

# Organisation des modules

Les composants sont répartis dans :

```text
Modules/
│
├── Infrastructure
├── Core
├── Configuration
├── Image
├── Windows
├── Actions
├── Managers
└── Package
```

Chaque dossier possède une responsabilité clairement définie.

---

# Ajouter un nouvel Engine

Les Engines sont placés dans :

```text
Modules/Actions
```

Chaque Engine :

- traite un seul type d'Action ;
- ne contient que la logique métier ;
- ne réalise jamais directement les appels Windows ;
- met à jour le BuildContext ;
- journalise toutes les opérations.

Exemple :

```
RegistryEngine
FeatureEngine
PackageEngine
```

---

# Ajouter un nouveau Manager

Les Managers sont placés dans :

```text
Modules/Managers
```

Ils encapsulent les opérations techniques.

Ils peuvent appeler :

- DISM ;
- Winget ;
- Chocolatey ;
- le registre Windows ;
- le système de fichiers.

Ils ne prennent aucune décision métier.

---

# Ajouter un nouveau type d'Action

Pour ajouter une nouvelle Action :

1. créer le nouvel Engine ;
2. créer le Manager correspondant si nécessaire ;
3. enregistrer l'Action dans **ActionRegistry.ps1** ;
4. ajouter les compteurs dans **BuildContext** si besoin ;
5. ajouter les validations ;
6. créer les tests Pester ;
7. documenter l'API.

Aucun composant ne doit appeler directement un Engine spécialisé.

Toutes les Actions transitent par l'ActionEngine.

---

# Ajouter un Tweak

Les Tweaks sont définis dans les fichiers JSON du dossier :

```text
Tweaks/
```

Un Tweak contient notamment :

- son identifiant ;
- sa catégorie ;
- sa description ;
- ses Actions ;
- ses contraintes de compatibilité ;
- ses métadonnées.

Les Tweaks ne contiennent jamais de logique PowerShell.

---

# BuildContext

Le BuildContext est le contrat officiel entre tous les composants.

Il ne doit jamais être remplacé.

Chaque composant enrichit uniquement les propriétés dont il est responsable.

Toute nouvelle information partagée doit être ajoutée au BuildContext.

---

# Compatibilité Windows

Le Builder ne cible pas une version unique de Windows.

Il doit pouvoir personnaliser différentes versions de Windows selon :

- l'image WIM sélectionnée ;
- le profil ;
- les contraintes déclarées dans les Tweaks.

Toute nouvelle fonctionnalité doit respecter ce principe.

---

# Journalisation

Toute opération importante doit être journalisée.

Utiliser :

```powershell
Write-Log
```

Les appels à :

```powershell
Write-Host
```

sont interdits dans la logique métier.

---

# Gestion des erreurs

Les erreurs doivent :

- être interceptées ;
- être journalisées ;
- être propagées.

Ne jamais masquer une exception.

---

# Tests

Toute nouvelle fonctionnalité doit être accompagnée de tests Pester.

Les tests doivent couvrir :

- le fonctionnement nominal ;
- les cas d'erreur ;
- les paramètres invalides ;
- les cas limites.

---

# Documentation

Toute évolution importante doit mettre à jour :

- API.md
- Architecture.md
- ArchitectureRules.md
- BuildContext.md
- ModuleGuide.md
- Roadmap.md (si nécessaire)

Si l'architecture évolue, une nouvelle ADR doit être créée.

---

# Revue de code

Avant chaque commit Git, vérifier :

- le projet compile ;
- les tests passent ;
- le Build fonctionne ;
- les nouveaux composants respectent les Architecture Rules ;
- la documentation est à jour ;
- les ADR sont mises à jour si nécessaire.

---

# Workflow Git

Chaque évolution importante suit le processus suivant :

1. Développement.
2. Validation locale.
3. Exécution des tests.
4. Mise à jour de la documentation.
5. Vérification des ADR.
6. Commit Git.
7. Push vers le dépôt distant.

La documentation fait partie intégrante du développement.

---

# Philosophie

Le développement de PimsOS Builder repose sur quelques principes simples :

- simplicité ;
- lisibilité ;
- modularité ;
- réutilisabilité ;
- testabilité ;
- maintenabilité ;
- extensibilité.

Une nouvelle fonctionnalité doit pouvoir être ajoutée avec un impact minimal sur les composants existants.

Le respect de l'architecture est prioritaire sur la rapidité de développement.

# Philosophie du projet

PimsOS Builder est conçu pour être indépendant des versions de Windows.

Les composants ne doivent jamais contenir de logique spécifique à une version (24H2, 25H2, etc.).

Les informations sur la version cible doivent provenir du BuildContext ou de la configuration.