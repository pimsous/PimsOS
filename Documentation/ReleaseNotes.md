# Notes de version

## Objectif

Ce document présente les principales évolutions de chaque version de **PimsOS Builder**.

Ces notes décrivent les évolutions du moteur de build, de l'architecture et des fonctionnalités de personnalisation de Windows.

Contrairement au `CHANGELOG.md`, qui recense les modifications techniques détaillées, les notes de version mettent en avant les nouveautés, les améliorations et les éventuels changements importants pour les utilisateurs et les développeurs.

---

# Format

Chaque version documente les éléments suivants :

- nouveautés ;
- améliorations ;
- corrections ;
- changements incompatibles (Breaking Changes) ;
- problèmes connus.

---

# Version 0.3.0-dev

## État

🚧 En développement

---

## Nouveautés

### Architecture

- Migration complète vers un module PowerShell unique.
- Introduction de `Initialize-PimsOS`.
- Pipeline de build restructuré.

### Moteur de build

- Mise en place du mécanisme **Recovery**.
- Détection des montages DISM existants.
- Gestion des images WIM.
- Gestion des images ISO.
- Gestion des ruches du registre.
- Chargement automatique de la configuration.
- Chargement des profils de personnalisation.
- Fusion des profils avec les définitions de tweaks.
- Validation complète de la configuration avant exécution.
- Sélection interactive de l'édition Windows à personnaliser.
- Support des images Windows indépendamment de leur version.
- Premier pipeline de build entièrement fonctionnel.

### Validation

- Introduction de `Test-WimMountState()`.
- Validation des montages avant toute reprise de build.
- Reconstruction automatique des montages invalides.

### Configuration

- Introduction d'un système de profils de personnalisation.
- Séparation des profils et des définitions de tweaks.
- Chargement automatique des catégories.
- Validation complète des définitions JSON.
- Création d'une configuration prête à être exécutée par le moteur de build.

### Documentation

- Finalisation de l'architecture.
- Documentation du moteur Recovery.
- Mise à jour de la feuille de route.
- Mise à jour des jalons du projet.

### Qualité

- Mise en place de Pester.
- Premiers tests unitaires.
- Vérification des prérequis.
- Standardisation de la journalisation.

---

## Améliorations

- Simplification du pipeline de build.
- Centralisation des décisions de reprise dans `Test-WimMountState()`.
- Meilleure gestion des montages DISM.
- Nettoyage automatique des montages invalides.
- Réduction des risques lors des reprises de build.
- Documentation synchronisée avec la nouvelle architecture du Builder.
- Introduction du fichier `version.json`.
- Centralisation des informations du projet dans le BuildContext.
- Préparation du support multi-version de Windows.

---

## Corrections

- Correction de la gestion des montages DISM invalides (`MountStatus = Invalid`).
- Correction de la logique de reprise de build.
- Correction de la copie du WIM lors d'une reprise.
- Amélioration de la gestion des erreurs du pipeline.
---

## Breaking Changes

- Suppression de l'ancien indicateur `WimReuse`.
- Le mécanisme de reprise utilise désormais `Context.Recovery.ResumeBuild`.
- Les informations du projet sont désormais chargées depuis `version.json`.
- Le Builder n'est plus lié à une version spécifique de Windows.

---

## Problèmes connus

Le moteur Recovery est fonctionnel mais continue d'évoluer.

Les évolutions prévues sont :

- finalisation du BuildState ;
- développement des Engines spécialisés ;
- génération de l'image ISO finale ;
- automatisation complète de la personnalisation ;
- prise en charge de nouvelles versions de Windows compatibles DISM.
---

# Versions futures

Les prochaines versions seront ajoutées selon le modèle suivant.

---

# Version X.Y.Z

## État

- En développement
- Publiée
- Maintenance

---

## Nouveautés

...

---

## Améliorations

...

---

## Corrections

### Module Backup

- Finalisation complète du module Backup.
- Validation des opérations de sauvegarde et de restauration.
- Correction de la gestion des statistiques lorsqu'une seule sauvegarde est présente.
- Correction du nettoyage des anciennes sessions.
- Génération d'identifiants de session uniques avec une précision à la milliseconde.
- Validation complète de la suite Pester (40/40 tests).

---

## Breaking Changes

...

---

## Problèmes connus

...

---

# Politique de version

Le projet suit le principe du **Semantic Versioning (SemVer)**.

Format :

```text
MAJOR.MINOR.PATCH
```

- **MAJOR** : changements incompatibles.
- **MINOR** : nouvelles fonctionnalités compatibles.
- **PATCH** : corrections de bugs.

Exemple :

```text
1.4.2
```

---

# Références

Consulter également :

- CHANGELOG.md
- Milestones.md
- Roadmap.md