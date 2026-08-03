# Jalons du projet

> Version : 0.4.0
>
> Dernière mise à jour : 2026-08-03

---

# Objectif

Ce document présente les principaux jalons (Milestones) du projet **PimsOS Builder**.

Chaque jalon représente une étape majeure de l'évolution du projet.

Un jalon est considéré comme atteint lorsque :

- les fonctionnalités prévues sont terminées ;
- les tests sont validés ;
- la documentation est à jour ;
- aucune anomalie bloquante n'est présente.

---

# État actuel du projet

| Jalon | Version | Statut |
|--------|---------|--------|
| Architecture du framework | v0.1 | ✅ Terminé |
| Module PowerShell unique | v0.2 | ✅ Terminé |
| Moteur de Build | v0.3 | ✅ Terminé |
| Framework de configuration | v0.4 | 🚧 En cours |
| Génération d'image ISO | v0.5 | ⏳ Prévu |
| Première version stable | v1.0 | ⏳ Objectif |

---

# Milestone 1 — Architecture du framework

## Objectif

Définir l'architecture globale du projet.

### Réalisations

- Architecture documentée
- Architecture Rules
- ADR
- Module PowerShell unique
- Documentation technique
- Standards de développement

### Résultat

Le framework dispose d'une architecture stable servant de base à tous les développements.

---

# Milestone 2 — Module PowerShell unique

## Objectif

Centraliser entièrement le chargement du framework.

### Réalisations

- Création de PimsOS.psm1
- Chargement automatique des composants
- API publique centralisée
- Suppression des anciens modules indépendants
- Initialisation unifiée

### Résultat

Le framework est désormais chargé depuis un point d'entrée unique.

---

# Milestone 3 — Moteur de Build

## Objectif

Construire le moteur principal de PimsOS Builder.

### Réalisations

- BuildContext
- BuildState
- Pipeline
- Workflow
- Recovery
- Validation de l'environnement
- Gestion ISO
- Gestion WIM
- Gestion des ruches du registre
- Journalisation
- Gestion des phases
- Nettoyage automatique

### Résultat

Framework capable de détecter plusieurs éditions Windows, de permettre leur sélection, d'appliquer une configuration de personnalisation et de reconstruire une image Windows avec reprise de build.

---

# Milestone 4 — Framework de configuration

## Objectif

Construire un moteur de personnalisation entièrement piloté par des fichiers JSON.

### État actuel

### Déjà réalisé

- Chargement automatique des catégories
- Chargement automatique des Tweaks
- Chargement des profils
- Fusion Profil + Tweaks
- Validation complète des définitions
- ActionRegistry
- ActionEngine
- RegistryEngine
- ServiceEngine
- PackageEngine
- FeatureEngine
- Architecture orientée moteurs spécialisés

### En cours

- Finalisation des Managers
- Intégration complète des nouveaux types d'actions
- Statistiques détaillées
- Amélioration des rapports
- Extension des profils

### Résultat attendu

Le moteur devra pouvoir appliquer automatiquement toute personnalisation décrite dans les fichiers JSON sans modification du code.

---

# Milestone 5 — Génération d'image

## Objectif

Produire automatiquement une image Windows personnalisée.

### Prévu

- Commit final du WIM
- Reconstruction de l'ISO
- Validation automatique
- Génération des rapports
- Gestion des erreurs de build
- Nettoyage complet

### Résultat attendu

Le Builder générera une image Windows prête à être installée.

---

# Milestone 6 — Version 1.0

## Objectif

Publier la première version stable.

### Conditions

- Pipeline totalement fonctionnel
- Tous les moteurs finalisés
- Documentation complète
- Tests validés
- Génération ISO stable
- API stabilisée

---

# Avancement actuel

Le projet dispose désormais de :

- BuildContext centralisé
- BuildState
- Pipeline modulaire
- Recovery automatique
- Validation complète des Tweaks
- Framework de configuration
- Profils
- Catégories
- ActionRegistry
- ActionEngine
- RegistryEngine
- ServiceEngine
- PackageEngine
- FeatureEngine
- version.json centralisant les informations du projet
- Journalisation complète
- Gestion des statistiques
- Nettoyage automatique des ressources

Le développement est actuellement concentré sur la finalisation du moteur de configuration et des nouveaux Managers.

---

# Critères de validation

Un jalon est terminé lorsque :

- toutes les fonctionnalités prévues sont développées ;
- les tests sont validés ;
- la documentation est mise à jour ;
- les ADR sont publiées si nécessaire ;
- aucune anomalie critique n'est ouverte.

---

# Suivi

À chaque jalon terminé :

- mise à jour de ProjectStatus.md ;
- mise à jour de ReleaseNotes.md ;
- mise à jour de Roadmap.md ;
- mise à jour de la documentation technique ;
- création d'un commit Git.

---

# Documents associés

- Architecture.md
- ArchitectureRules.md
- BuildContext.md
- Lifecycle.md
- ProjectStatus.md
- ReleaseNotes.md
- Roadmap.md
- Documentation/ADR/

---

# Vision

L'objectif de PimsOS Builder est de proposer un moteur entièrement modulaire permettant de personnaliser différentes versions de Windows uniquement à partir de fichiers de configuration, sans modifier le code source.

À terme, le framework devra être capable de construire automatiquement une image Windows complète, reproductible et entièrement personnalisable.