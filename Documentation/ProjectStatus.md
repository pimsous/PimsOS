# PimsOS Builder - État du projet

> Version : 0.4.0
>
> Dernière mise à jour : 2026-08-03

---

# Informations générales

## Projet

PimsOS Builder

## Version

0.4.0

## Statut

🚧 Développement actif

## Objectif

Développer un moteur modulaire capable de personnaliser automatiquement différentes versions de Windows à partir de fichiers de configuration JSON, puis de générer une image Windows personnalisée.

Le projet est conçu pour être indépendant d'une version particulière de Windows afin de faciliter le support des futures versions.

Développer un framework de build permettant de construire des images Windows personnalisées.

Le Builder est conçu pour prendre en charge plusieurs versions de Windows et produire une image personnalisée nommée PimsOS.

---

# État global

| Domaine | Avancement |
|----------|-----------:|
| Architecture | ✅ 100 % |
| Documentation | 🚧 95 % |
| ADR | ✅ 100 % |
| BuildContext | ✅ 100 % |
| BuildState | ✅ 100 % |
| Pipeline | ✅ 90 % |
| Recovery | ✅ 100 % |
| Validation | ✅ 100 % |
| Framework de configuration | 🚧 90 % |
| ActionRegistry | ✅ 100 % |
| Engines spécialisés | 🚧 80 % |
| Reporting | 🚧 40 % |
| Tests | 🚧 En progression |

---

# Fonctionnalités opérationnelles

## Infrastructure

- BuildContext
- BuildState
- Logger
- Validation
- Recovery
- Pipeline
- Workflow

---

## Gestion des images

- Détection de l'ISO
- Montage ISO
- Détection du WIM
- Copie du WIM
- Lecture des éditions Windows
- Sélection interactive de l'édition
- Montage du WIM
- Démontage sécurisé
- Nettoyage automatique

---

## Registre

- Montage automatique des ruches
- Application des clés
- Création automatique des clés manquantes
- Gestion des types de données

---

## Configuration

- Chargement automatique des catégories
- Chargement des Tweaks
- Chargement des profils
- Fusion Profil + Tweaks
- Validation complète des définitions
- Construction de la configuration finale

---

## Moteur d'actions

Implémentés :

- ActionRegistry
- ActionEngine
- RegistryEngine
- ServiceEngine
- PackageEngine
- FeatureEngine

L'ajout d'un nouveau type d'action ne nécessite plus de modification de l'Engine principal.

---

# Avancement du pipeline

Les phases suivantes sont opérationnelles :

- Recovery
- Validation de l'environnement
- Montage ISO
- Détection du WIM
- Copie du WIM
- Lecture des éditions Windows
- Sélection de l'édition
- Montage du WIM
- Montage des ruches du registre
- Chargement de la configuration
- Validation des Tweaks
- Chargement des profils
- Fusion des profils
- Application des Tweaks
- Commit de l'image
- Démontage des ressources
- Nettoyage final

---

# Fonctionnalités en cours

Les développements actuels concernent principalement :

- finalisation du moteur de configuration ;
- enrichissement des Managers ;
- statistiques détaillées ;
- génération des rapports ;
- génération finale de l'ISO.

---

# Fonctionnalités prévues

- DriverManager
- CapabilityManager
- ScheduledTaskManager
- EnvironmentVariableManager
- ShortcutManager
- FileManager
- FolderManager
- Reporting HTML
- Reporting PDF
- Génération complète de l'ISO

---

# Sprint actuel

## Sprint 6

### Objectif

Finaliser le moteur de configuration et les moteurs spécialisés.

Travaux principaux :

- stabilisation de la configuration ;
- finalisation des Managers ;
- enrichissement du Reporting ;
- amélioration des statistiques.

---

# Prochaines étapes

Par ordre de priorité :

1. Finaliser le moteur de configuration.
2. Finaliser les Managers.
3. Étendre les types d'actions.
4. Générer les rapports.
5. Construire automatiquement l'ISO.
6. Développer les profils complets.
7. Ajouter de nouvelles personnalisations Windows.
8. Préparer la version bêta.

---

# État des tests

Les composants historiques conservent leur couverture de tests.

Le nouveau Builder est progressivement couvert par de nouveaux tests Pester.

Les nouveaux composants doivent systématiquement être accompagnés de tests adaptés.

---

# Architecture

L'architecture est désormais considérée comme stable.

Les principes suivants sont appliqués :

- module PowerShell unique ;
- architecture en couches ;
- BuildContext unique ;
- BuildState centralisé ;
- ActionRegistry ;
- moteurs spécialisés ;
- validation systématique avant exécution.

---

# Version

Les informations de version sont centralisées dans :

```text
version.json
```

Ce fichier constitue la source officielle des informations de version du projet.

---

# Vision du projet

À terme, PimsOS Builder devra permettre :

- de personnaliser plusieurs versions de Windows ;
- d'ajouter de nouveaux types de personnalisations sans modifier le moteur principal ;
- de produire automatiquement une image Windows prête à être installée ;
- de générer des rapports détaillés ;
- de garantir des builds reproductibles et entièrement configurables.

---

# Documents associés

- Architecture.md
- ArchitectureRules.md
- BuildContext.md
- Lifecycle.md
- Milestones.md
- Roadmap.md
- ReleaseNotes.md
- Documentation/ADR/

---

# Résumé

Le projet dispose désormais d'un moteur de build modulaire, extensible et largement fonctionnel.

Les travaux actuels portent principalement sur la finalisation des moteurs de personnalisation, l'enrichissement du reporting et la génération automatique des images Windows personnalisées.