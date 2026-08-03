# Cycle de vie

> Version : 0.4.0
>
> Architecture : 2.x

---

# Objectif

Ce document décrit le cycle de vie complet d'une fonctionnalité au sein de **PimsOS Builder**.

Il couvre toutes les étapes, depuis l'identification d'un besoin jusqu'à la publication d'une nouvelle version.

Ce cycle garantit :

- la cohérence de l'architecture ;
- la qualité du code ;
- la stabilité du pipeline ;
- la traçabilité des évolutions ;
- la reproductibilité des builds.

---

# Vue d'ensemble

```text
Besoin
    │
    ▼
Analyse
    │
    ▼
Conception
    │
    ▼
Développement
    │
    ▼
Validation
    │
    ▼
Tests
    │
    ▼
Documentation
    │
    ▼
Git
    │
    ▼
Publication
```

---

# 1. Identification du besoin

Toute évolution débute par un besoin clairement identifié.

Il peut s'agir :

- d'une nouvelle fonctionnalité ;
- d'une correction de bug ;
- d'une optimisation ;
- d'une évolution de l'architecture ;
- d'une amélioration du pipeline ;
- de l'ajout d'un nouveau type d'action.

Le besoin doit être compris avant toute modification du code.

---

# 2. Analyse

Cette étape consiste à déterminer :

- les composants concernés ;
- les impacts sur le BuildContext ;
- les dépendances ;
- les risques de régression ;
- les besoins en documentation.

Les évolutions majeures peuvent nécessiter la création d'une ADR.

---

# 3. Conception

Avant toute implémentation :

- identifier les modules concernés ;
- vérifier qu'aucun composant existant ne répond déjà au besoin ;
- définir les nouvelles structures de données si nécessaire ;
- préserver la séparation des responsabilités.

Les nouvelles fonctionnalités doivent respecter les Architecture Rules.

---

# 4. Développement

Le développement est réalisé en respectant :

- CodingStandards.md ;
- DeveloperGuide.md ;
- ModuleGuide.md ;
- Architecture.md.

Les composants doivent respecter l'architecture en couches.

Toute nouvelle logique métier doit passer par le BuildContext.

---

# 5. Validation

Avant d'être exécutée, toute évolution est validée.

La validation vérifie notamment :

- la structure des fichiers JSON ;
- les propriétés obligatoires ;
- les identifiants ;
- les catégories ;
- les niveaux ;
- les tags ;
- les groupes ;
- les actions ;
- les versions supportées ;
- les scores.

Aucune configuration invalide ne doit atteindre le Pipeline.

---

# 6. Tests

Les tests permettent de vérifier :

- le fonctionnement nominal ;
- les erreurs ;
- les cas limites ;
- les régressions.

Les nouveaux composants doivent disposer de tests adaptés.

Les tests Legacy ne participent pas à cette validation.

---

# 7. Documentation

Toute évolution importante doit être documentée.

Les documents concernés peuvent être :

- API.md
- Architecture.md
- ArchitectureRules.md
- BuildContext.md
- DeveloperGuide.md
- ModuleGuide.md
- ReleaseNotes.md

La documentation évolue en même temps que le code.

---

# 8. Gestion du code source

Une fois la fonctionnalité validée :

- vérifier le formatage ;
- exécuter les tests ;
- mettre à jour la documentation ;
- effectuer un commit Git.

Chaque commit doit représenter une évolution cohérente et fonctionnelle.

---

# 9. Publication

Une nouvelle version peut être publiée lorsque :

- le pipeline est valide ;
- les tests sont réussis ;
- la documentation est à jour ;
- les évolutions prévues sont terminées.

Les informations de version sont centralisées dans :

```text
version.json
```

Le numéro de version est automatiquement utilisé par le Builder.

---

# Correction d'un bug

Une correction suit le même cycle de vie qu'une nouvelle fonctionnalité.

Le processus recommandé est :

1. reproduire le problème ;
2. identifier le composant concerné ;
3. écrire ou adapter un test ;
4. corriger le code ;
5. exécuter le pipeline ;
6. mettre à jour la documentation ;
7. réaliser un commit Git.

Cette méthode limite les régressions.

---

# Évolutions d'architecture

Toute évolution importante de l'architecture doit :

- respecter les Architecture Rules ;
- préserver la compatibilité du BuildContext ;
- documenter les changements ;
- être accompagnée de tests.

Si nécessaire, une nouvelle ADR est créée.

---

# Amélioration continue

Le cycle de développement de PimsOS Builder évolue avec le projet.

Toute amélioration doit viser à :

- simplifier le code ;
- renforcer la modularité ;
- améliorer les performances ;
- réduire les duplications ;
- améliorer la qualité des tests ;
- faciliter la maintenance.

---

# Résumé

Chaque évolution suit le processus suivant :

```text
Besoin
    ↓
Analyse
    ↓
Conception
    ↓
Développement
    ↓
Validation
    ↓
Tests
    ↓
Documentation
    ↓
Commit Git
    ↓
Publication
```

Aucune fonctionnalité ne doit être intégrée sans avoir suivi ce cycle.