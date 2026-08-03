# Guide des modules

> Version : 0.4.0
>
> Dernière mise à jour : 2026-08-03

---

# Objectif

Ce document décrit l'organisation des modules composant **PimsOS Builder**.

Chaque module possède une responsabilité unique et participe à une architecture modulaire en couches.

L'objectif est de garantir :

- une architecture cohérente ;
- une maintenance simplifiée ;
- une forte réutilisabilité ;
- une évolutivité importante ;
- un faible couplage.

---

# Architecture générale

PimsOS Builder est constitué d'un **module PowerShell unique** :

```text
PimsOS.psm1
```

Ce module charge automatiquement l'ensemble des composants internes.

Aucun sous-module PowerShell indépendant n'est utilisé.

---

# Organisation des modules

```text
Modules
│
├── Core
├── Infrastructure
├── Configuration
├── Actions
├── Windows
├── Image
├── Registry
├── Services
├── Packages
├── Drivers
├── Reporting
└── ...
```

Chaque dossier représente un domaine fonctionnel clairement identifié.

---

# Core

Le dossier **Core** contient les composants centraux du Builder.

Exemples :

- BuildContext
- Pipeline
- Workflow
- Engine
- ActionRegistry
- Recovery
- Logger
- Initialisation

Le Core orchestre l'ensemble du Build.

---

# Infrastructure

Le dossier **Infrastructure** regroupe les services transverses.

Exemples :

- Validation
- Helpers
- Utilitaires
- Gestion des erreurs

Ces composants ne contiennent aucune logique métier.

---

# Configuration

Le dossier **Configuration** est responsable du moteur de configuration.

Il assure notamment :

- le chargement des catégories ;
- le chargement des Tweaks ;
- le chargement des profils ;
- la fusion Profil + Tweaks ;
- la construction de la configuration finale.

---

# Actions

Le dossier **Actions** contient les moteurs spécialisés.

Chaque moteur applique un type d'action particulier.

Exemples :

- RegistryEngine
- ServiceEngine
- PackageEngine
- FeatureEngine

Les nouveaux moteurs doivent simplement être enregistrés dans l'ActionRegistry.

---

# Windows

Le dossier **Windows** contient les composants spécifiques à l'image Windows.

Exemples :

- gestion des images WIM ;
- montage des ISO ;
- intégration DISM ;
- manipulation des ruches du registre.

---

# Reporting

Le dossier **Reporting** regroupe les composants produisant les rapports de Build.

À terme, il permettra de générer :

- JSON ;
- HTML ;
- PDF.

---

# Chargement des composants

Tous les composants sont chargés automatiquement par :

```text
PimsOS.psm1
```

Le chargement suit un ordre déterminé afin de respecter les dépendances internes.

Les composants ne doivent jamais effectuer de `Import-Module` entre eux.

---

# Dépendances

Les dépendances suivent toujours le même sens.

```text
Infrastructure
        ↓
Core
        ↓
Configuration
        ↓
Engine
        ↓
ActionRegistry
        ↓
ActionEngine
        ↓
Engine spécialisé
```

Les dépendances circulaires sont interdites.

---

# ActionRegistry

Toutes les actions sont centralisées dans l'ActionRegistry.

L'Engine ne connaît jamais directement les moteurs spécialisés.

Pour ajouter un nouveau type d'action, il suffit :

1. de créer un nouveau moteur spécialisé ;
2. de l'enregistrer dans l'ActionRegistry.

Aucune modification de l'Engine n'est nécessaire.

---

# BuildContext

Tous les modules utilisent le même BuildContext.

Aucune information ne doit être échangée via :

- des variables globales ;
- des variables script ;
- des états implicites.

Le BuildContext constitue la seule source de vérité pendant le Build.

---

# Validation

Avant d'atteindre le Pipeline, toutes les définitions sont validées.

La validation vérifie notamment :

- les catégories ;
- les identifiants ;
- les groupes ;
- les tags ;
- les niveaux ;
- les versions supportées ;
- les scores ;
- les actions.

Les modules peuvent donc supposer que les données reçues sont cohérentes.

---

# Ajout d'un nouveau module

Avant de créer un nouveau module, vérifier :

- qu'un module existant ne répond pas déjà au besoin ;
- que la responsabilité est clairement définie ;
- que le module respecte l'architecture en couches.

Un module ne doit jamais cumuler plusieurs responsabilités.

---

# Bonnes pratiques

Tous les modules doivent :

- respecter une responsabilité unique ;
- utiliser exclusivement le BuildContext ;
- utiliser le Logger officiel ;
- propager correctement les erreurs ;
- éviter les dépendances inutiles ;
- rester indépendants des autres modules.

---

# Évolution

L'architecture des modules est conçue pour être extensible.

L'ajout d'un nouveau moteur ou d'un nouveau type d'action ne doit nécessiter que des modifications localisées, sans impacter le reste du Builder.

Cette approche garantit la stabilité et la maintenabilité du projet.