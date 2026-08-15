# Bien démarrer

> Version : 0.4.0
>
> Architecture : 2.x

Bienvenue dans **PimsOS Builder**.

Ce document explique comment préparer un environnement de développement complet afin de compiler, tester et faire évoluer le projet.

---

# Prérequis

Avant de commencer, assurez-vous de disposer des éléments suivants :

| Logiciel | Version minimale |
|-----------|------------------|
| Windows | 11 |
| PowerShell | 7.6 |
| Git | 2.55 |
| Visual Studio Code | Dernière version |
| Extension PowerShell | Dernière version |
| Pester | 5.x |

Consultez également :

- Prerequisites.md

---

# Cloner le dépôt

```powershell
git clone https://github.com/Pims/PimsOS.git

cd PimsOS
```

---

# Vérifier PowerShell

```powershell
$PSVersionTable.PSVersion
```

Version recommandée :

```text
7.6.x
```

---

# Vérifier Git

```powershell
git --version
```

---

# Vérifier DISM

```powershell
dism /?
```

---

# Vérifier Pester

```powershell
Get-InstalledModule Pester
```

Installation si nécessaire :

```powershell
Install-Module Pester -Scope CurrentUser
```

---

# Ouvrir le projet

Depuis la racine :

```powershell
code .
```

---

# Vérifier l'arborescence

La structure principale doit ressembler à :

```text
PimsOS
│
├── Build
├── Classes
├── Config
├── Documentation
├── Modules
├── Profiles
├── Resources
├── Tests
├── Tools
├── Tweaks
└── Workspace
```

---

# Comprendre l'architecture

Le framework est organisé autour des composants suivants :

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
Modules Windows
```

Avant de modifier le code, prendre connaissance de cette architecture.

---

# Vérifier le projet

Avant toute modification, exécuter :

```powershell
Invoke-Pester
```

Tous les tests doivent réussir.

---

# Premier Build

Le Builder détecte automatiquement les images Windows disponibles.

Selon la configuration choisie, il est possible de sélectionner l'édition Windows à personnaliser.

Le Builder n'est pas limité à une version spécifique de Windows.

Le point d'entrée du projet est :

```text
Build\Build-PimsOS.ps1
```

Lancer :

```powershell
.\Build\Build-PimsOS.ps1
```

Le Builder réalise automatiquement :

- préparation de l'environnement ;
- Recovery ;
- vérification des prérequis ;
- montage de l'ISO ;
- détection du WIM ;
- montage DISM ;
- chargement de la configuration ;
- application des Tweaks ;
- démontage des ressources ;
- génération du rapport.

---
# Premier lancement

Le premier lancement du Builder permet de vérifier que l'environnement est correctement configuré.

Exécutez :

```powershell
Import-Module .\Modules\PimsOS.psd1

Initialize-PimsOS

.\Build\Build-PimsOS.ps1
```

Si toutes les vérifications sont validées, le Builder prépare automatiquement le Workspace et démarre le pipeline de build.

# Premier Tweak

Les personnalisations sont définies dans :

```text
Tweaks/
```

Chaque Tweak est décrit dans un fichier JSON.

Les profils permettent de sélectionner les Tweaks à appliquer.

---

# Ajouter une fonctionnalité

Avant d'écrire du code :

1. identifier le module concerné ;
2. vérifier qu'une fonctionnalité similaire n'existe pas déjà ;
3. déterminer s'il faut créer un Engine ou un Manager ;
4. mettre à jour le BuildContext si nécessaire ;
5. ajouter les tests ;
6. mettre à jour la documentation.

---

# Ajouter un nouveau type d'Action

Les étapes sont les suivantes :

1. créer un Engine dans `Modules/Actions` ;
2. créer un Manager dans `Modules/Managers` si nécessaire ;
3. enregistrer le nouvel Engine dans `ActionRegistry.ps1` ;
4. mettre à jour les statistiques du BuildContext si besoin ;
5. créer les tests Pester ;
6. documenter la nouvelle Action.

---

# Documentation

Avant toute contribution, il est recommandé de lire :

- Architecture.md
- ArchitectureRules.md
- BuildContext.md
- CodingStandards.md
- DeveloperGuide.md
- ModuleGuide.md
- API.md

Ces documents décrivent le fonctionnement interne du framework.

---

# Workflow recommandé

Chaque évolution importante suit le processus suivant :

```text
Développement

↓

Compilation

↓

Tests

↓

Documentation

↓

ADR (si nécessaire)

↓

Commit Git

↓

Push
```

---

# Bonnes pratiques

Avant chaque commit :

- exécuter le Build ;
- lancer les tests ;
- vérifier les journaux ;
- mettre à jour la documentation ;
- vérifier les ADR si l'architecture a évolué.

---

# Besoin d'aide ?

Les documents suivants constituent les principales références du projet :

- Architecture.md
- ArchitectureRules.md
- BuildContext.md
- API.md
- DeveloperGuide.md

Ils décrivent l'ensemble de l'architecture et des conventions de développement utilisées par **PimsOS Builder**.