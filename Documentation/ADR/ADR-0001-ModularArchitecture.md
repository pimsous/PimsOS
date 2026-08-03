# ADR-0001 — Adoption d'une architecture modulaire

- **Statut** : Acceptée
- **Date** : 2026-07-19
- **Décideur** : Pims
- **Impact** : Architecture globale

---

# Contexte

PimsOS est destiné à évoluer progressivement vers une plateforme complète de création d'images Windows.

Le projet comprendra de nombreux composants indépendants :

- Builder
- Migration
- Logger
- Registry
- Packages
- Drivers
- Pipeline
- Configuration

Une architecture monolithique deviendrait rapidement difficile à maintenir.

---

# Décision

Le projet adopte une architecture modulaire.

Chaque framework possède :

- son manifeste (`.psd1`) ;
- son module racine (`.psm1`) ;
- ses classes ;
- ses fonctions publiques ;
- ses fonctions privées ;
- ses ressources ;
- ses tests.

Chaque framework possède une responsabilité clairement définie.

---

# Conséquences

## Avantages

- meilleure lisibilité ;
- faible couplage ;
- réutilisation facilitée ;
- tests indépendants ;
- maintenance simplifiée ;
- évolutivité.

## Inconvénients

- davantage de fichiers ;
- organisation plus stricte ;
- chargement initial légèrement plus complexe.

---

# Alternatives étudiées

## Module unique

Rejeté.

Un unique module deviendrait difficile à maintenir.

## Scripts indépendants

Rejeté.

Les dépendances seraient difficiles à gérer.

---

# Décision finale

Toute nouvelle fonctionnalité devra être intégrée dans un framework existant ou faire l'objet d'un nouveau framework clairement identifié.

Le développement futur devra respecter cette architecture.