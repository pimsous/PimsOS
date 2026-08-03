# Feuille de route

> Version : 1.0.0
>
> Dernière mise à jour : 2026-07-26

---

# Objectif

Cette feuille de route présente les grandes orientations du projet **PimsOS Builder**.

Elle décrit l'évolution du moteur de build, de l'architecture et des fonctionnalités permettant de construire des images Windows personnalisées.

Elle décrit les objectifs à moyen et long terme sans détailler les tâches d'implémentation.

Les évolutions importantes de l'architecture sont documentées dans les **Architecture Decision Records (ADR)**.

---

# Vision

PimsOS Builder a pour objectif de devenir un framework complet permettant de construire automatiquement des images Windows personnalisées à partir d'images officielles Microsoft.

Le moteur est conçu pour être indépendant de la version de Windows ciblée et pourra prendre en charge plusieurs versions compatibles avec DISM.

Le projet repose sur les principes suivants :

- simplicité ;
- modularité ;
- automatisation ;
- reproductibilité ;
- maintenabilité ;
- testabilité.

À terme, la création d'une image Windows complète devra pouvoir être réalisée à partir d'une unique commande.

---

# État actuel

## Architecture

✅ Finalisée

- Architecture validée
- Documentation validée
- ADR finalisées
- Architecture gelée (Architecture Freeze)

---

## Développement

🚧 En cours

L'architecture étant désormais stabilisée, le développement est centré sur la construction du moteur de build.

Les premières phases du pipeline sont désormais opérationnelles :

- Recovery
- Vérification de l'environnement
- Gestion des ISO
- Détection automatique des images WIM
- Sélection interactive de l'édition Windows
- Montage des images Windows
- Gestion des ruches du registre
- Chargement des définitions de tweaks
- Chargement des profils
- Fusion des profils avec les tweaks
- Validation complète de la configuration
- Application des personnalisations
- Pipeline principal

Le travail se concentre désormais sur la fiabilisation du moteur et le développement des Engines spécialisés.

---

# Phases du projet

## Phase 1 — Fondations

### Objectifs

- [x] Définir l'architecture générale.
- [x] Mettre en place la documentation.
- [x] Définir les conventions de développement.
- [x] Mettre en place les ADR.
- [x] Construire les premiers modules techniques.

Statut :

✅ Terminée

---

## Phase 2 — Migration vers le module unique

### Objectifs

### Objectifs

- [x] Créer PimsOS.psm1.
- [x] Centraliser les exports.
- [x] Supprimer les NestedModules.
- [x] Adapter Build-PimsOS.
- [x] Introduire Initialize-PimsOS.
- [x] Valider le module PowerShell unique.

Statut :

✅ Terminée

---

## Phase 3 — Framework de Build

### Objectifs

- [x] Finaliser le BuildContext.
- [x] Développer le Pipeline principal.
- [x] Développer le Workflow.
- [x] Mettre en place Recovery.
- [x] Gérer les images WIM.
- [x] Gérer les ISO.
- [x] Détecter automatiquement les éditions Windows.
- [x] Permettre la sélection de l'édition à personnaliser.
- [x] Gérer les ruches du registre.
- [x] Charger les définitions de tweaks.
- [x] Charger les profils.
- [x] Fusionner profils et tweaks.
- [x] Valider la configuration.
- [x] Appliquer les personnalisations.
- [ ] Renforcer Test-WimMountState().
- [ ] Finaliser BuildState.
- [ ] Développer ActionEngine.
- [ ] Développer les Engines spécialisés.

Statut :

🚧 En cours

---

## Phase 4 — Génération d'images Windows

### Objectifs

- [ ] Génération automatique de l'ISO.
- [ ] Reconstruction complète des images Windows.
- [ ] Validation automatique des builds.
- [ ] Support de plusieurs versions de Windows.
- [ ] Optimisation des performances.

Statut :

⏳ À venir

---

## Phase 5 — Personnalisation

### Objectifs

- [x] Profils.
- [x] Tweaks.
- [ ] Registre.
- [ ] Services.
- [ ] Fonctionnalités Windows.
- [ ] Packages.
- [ ] Drivers.

Statut :

⏳ À venir

---

## Phase 6 — Version 1.0

### Objectifs

- [ ] Documentation finalisée.
- [ ] Couverture de tests élevée.
- [ ] Validation complète.
- [ ] Première image Windows générée.
- [ ] Publication de PimsOS 1.0.

Statut :

⏳ À venir

---

# Modules

## Terminés

- Logger
- Check
- AST
- Replace
- Backup
- Report
- Migration

---

## En cours

- BuildState
- ActionEngine
- Services Engine
- Packages Engine
- Drivers Engine
- Features Engine

---

## À développer

- ServiceEngine
- FeatureEngine
- PackageEngine
- DriverEngine
- FileEngine
- FolderEngine

---

# Tests

Objectifs :

- augmenter progressivement la couverture ;
- ajouter des tests d'intégration ;
- préparer l'intégration continue (CI) ;
- automatiser l'exécution des tests.

---

# Documentation

Objectifs :

- maintenir la documentation technique ;
- documenter toutes les API publiques ;
- enrichir les diagrammes d'architecture ;
- produire une documentation utilisateur.

---

# Priorités actuelles

## Priorité 1

Finaliser BuildState afin de centraliser entièrement l'état du moteur.

---

## Priorité 2

Développer les Engines spécialisés.

---

## Priorité 3

Automatiser complètement la génération des images Windows.

---

## Priorité 4

Étendre le support à plusieurs versions de Windows.

---

## Priorité 5

Préparer la première version publique de PimsOS Builder.

---

# Prochain objectif technique

Le prochain objectif est de finaliser le moteur de build.

Les travaux prévus sont :

- finalisation de BuildState ;
- développement des Engines spécialisés ;
- génération automatique de l'image ISO ;
- amélioration des performances ;
- préparation du support multi-version de Windows.

# Hors périmètre

À ce stade, les fonctionnalités suivantes ne sont pas prévues :

- interface graphique complète ;
- prise en charge des versions de Windows non compatibles avec DISM ;
- support d'autres systèmes d'exploitation ;
- déploiement distribué.

Ces éléments pourront être réévalués ultérieurement.

---

# Suivi

La feuille de route est revue à chaque jalon majeur.

Les fonctionnalités terminées sont reportées dans :

- ReleaseNotes.md
- Milestones.md
- ProjectStatus.md

---

# Documents associés

- Architecture.md
- ArchitectureRules.md
- ProjectStatus.md
- Lifecycle.md
- Milestones.md
- ReleaseNotes.md
- Documentation/ADR/