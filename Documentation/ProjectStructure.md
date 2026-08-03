# Structure du projet

## Objectif

Ce document décrit l'organisation des répertoires du projet **PimsOS Builder**.

Le Builder est le framework chargé de construire des images Windows personnalisées. Cette organisation garantit une architecture modulaire, évolutive et indépendante de la version de Windows ciblée.

Chaque dossier possède une responsabilité clairement définie.

Cette organisation doit être respectée afin de conserver une architecture homogène et maintenable.

---

# Vue d'ensemble

```text
PimsOS
│
├── Assets
├── Build
├── Config
├── Documentation
├── ISO
├── Logs
├── Modules
├── Output
├── Packages
├── Profiles
├── Resources
├── Tests
├── Tools
├── Tweaks
├── Workspace
└── version.json
```

---

# Assets

Contient les ressources utilisées pendant le Build.

Exemples :

- logos
- images
- icônes
- fonds d'écran

---

# Build

Contient les scripts de lancement du projet.

Exemple :

```text
Build-PimsOS.ps1
```

---

# Config

Contient la configuration globale du projet.

Exemples :

- Config.json
- Settings.json

---

# Documentation

Documentation officielle du projet.

Elle contient notamment :

- Architecture
- Standards de développement
- Guides développeur
- Documentation API
- ADR

---

# ISO

Images ISO utilisées comme source.

Le Builder peut utiliser différentes versions de Windows compatibles (Windows 11, Windows Server ou futures versions).

Les images ISO d'origine ne sont jamais modifiées. Toutes les opérations sont réalisées dans le Workspace.
---

# Logs

Tous les journaux générés par le projet.

Exemples :

- Build.log
- Migration.log

---

# Modules

Contient les frameworks PowerShell.

Exemple :

```text
Modules
│
├── Core
├── Configuration
├── Windows
├── Image
├── Actions
├── Infrastructure
└── PimsOS.psm1
```

Chaque framework possède sa propre architecture interne.

---

# Output

Contient les résultats produits par le projet.

Exemples :

- ISO finale
- rapports
- exports

---

# Packages

Contient les packages utilisés pendant le Build.

Exemples :

- Chocolatey
- Winget
- pilotes
- logiciels

---

# Profiles

Profils de personnalisation.

Exemples :

```text
Default.json
Gaming.json
Workstation.json
```

---

# Tweaks

Contient les définitions des personnalisations disponibles.

Chaque tweak est décrit dans un fichier JSON regroupé par catégorie.

Exemples :

```text
Tweaks
│
├── Gaming
├── Privacy
├── Services
├── Explorer
└── WindowsUpdate
---

# Resources

Ressources statiques communes.

Exemples :

- modèles
- scripts
- fichiers XML
- fichiers JSON

---

# Tests

Tests automatisés du projet.

Organisation recommandée :

```text
Tests
│
├── Unit
├── Integration
└── Fixtures
```

---

# Tools

Outils internes du projet.

Chaque outil est indépendant.

Exemple :

```text
Tools
│
├── Migration
├── Packaging
├── Validation
└── Reporting
```

Chaque outil suit l'architecture standard des frameworks PimsOS.

---

# version.json

Le fichier `version.json` contient les métadonnées du projet.

Il est utilisé pour renseigner notamment :

- le nom du projet ;
- la version ;
- les versions de Windows supportées ;
- l'auteur ;
- l'entreprise ;
- le dépôt Git.

Ces informations sont chargées automatiquement dans le BuildContext au démarrage du Builder.

---

# Workspace

Répertoire de travail temporaire.

Il contient notamment :

- les images WIM copiées ;
- les ISO montées ;
- les images Windows montées ;
- les fichiers extraits ;
- les répertoires temporaires ;
- les ressources de travail utilisées pendant le Build.

Ce dossier peut être supprimé puis recréé automatiquement.

---

# Organisation d'un framework

Tous les frameworks utilisent la même structure.

```text
Framework
│
├── Framework.psd1
├── Framework.psm1
│
├── Classes
├── Modules
├── Private
├── Public
├── Resources
└── Tests
```

---

# Principes

Le projet applique les règles suivantes :

- une responsabilité par dossier ;
- aucune duplication de code ;
- séparation des responsabilités ;
- architecture modulaire ;
- composants réutilisables.
- indépendance vis-à-vis des versions de Windows ;
- séparation entre les profils de personnalisation et les définitions de tweaks ;
- utilisation d'un BuildContext unique pour partager l'état du Build.

---

# Évolution

Toute modification de l'arborescence doit être documentée.

Les changements majeurs doivent faire l'objet d'un **Architecture Decision Record (ADR)**.