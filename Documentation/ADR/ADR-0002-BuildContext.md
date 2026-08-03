# ADR-0002 — Utilisation d'un BuildContext central

- **Statut** : Acceptée
- **Date** : 2026-07-19
- **Décideur** : Pims
- **Impact** : Architecture des frameworks

---

# Contexte

PimsOS est constitué de plusieurs frameworks collaborant au sein d'un même pipeline de build.

Ces frameworks ont besoin d'accéder à des informations communes telles que :

- les paramètres du projet ;
- la configuration ;
- les profils ;
- les chemins de travail ;
- l'image Windows ;
- les packages ;
- les pilotes ;
- les journaux ;
- les rapports.

Sans mécanisme commun, ces informations devraient être transmises individuellement entre les fonctions, entraînant :

- une multiplication des paramètres ;
- un fort couplage entre les composants ;
- une maintenance plus complexe.

---

# Décision

Toutes les informations relatives à l'exécution d'un build sont regroupées dans un objet unique nommé **BuildContext**.

Le `BuildContext` est créé au démarrage du pipeline puis transmis aux différents frameworks.

Chaque framework lit ou met à jour uniquement les propriétés dont il est responsable.

---

# Structure générale

Le `BuildContext` est organisé en plusieurs catégories fonctionnelles :

- Project
- Build
- Configuration
- Profiles
- Workspace
- Image
- Registry
- Packages
- Drivers
- Logs
- Report
- DryRun

Cette organisation permet de conserver une séparation claire des responsabilités.

---

# Conséquences

## Avantages

- réduction du nombre de paramètres ;
- échange d'informations simplifié ;
- cohérence entre les frameworks ;
- meilleure lisibilité du code ;
- facilité d'extension.

## Inconvénients

- définition initiale plus importante ;
- nécessité de maintenir la structure du contexte.

---

# Alternatives étudiées

## Transmission des paramètres

Rejetée.

Chaque fonction aurait nécessité un grand nombre de paramètres, rendant les appels plus complexes.

## Variables globales

Rejetée.

Les variables globales augmentent le couplage et compliquent les tests ainsi que la maintenance.

---

# Règles

Les frameworks ne doivent pas modifier arbitrairement le `BuildContext`.

Chaque composant ne met à jour que les sections dont il est responsable.

Toute évolution importante de la structure du `BuildContext` doit être documentée dans une nouvelle ADR.

---

# Conséquences sur le développement

Toutes les nouvelles fonctionnalités devront utiliser le `BuildContext` comme point d'échange des informations communes.

Les interfaces publiques devront privilégier la transmission du `BuildContext` plutôt qu'une multiplication des paramètres.