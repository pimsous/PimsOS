# PimsOS Builder - Bien démarrer

> Version technique : 3.0.0
>
> Statut : Développement / architecture stabilisée
>
> Dernière mise à jour : 2026-08-28

Bienvenue dans **PimsOS Builder**.

Ce document explique comment préparer un environnement de développement, vérifier le projet, exécuter les tests et démarrer un Build.

---

# Prérequis

Avant de commencer, disposer au minimum des éléments suivants :

| Logiciel | Version / recommandation |
|-----------|---------------------------|
| Windows | Windows 11 |
| PowerShell | 7.6.x |
| Git | Version compatible avec le dépôt |
| Visual Studio Code | Version récente |
| Extension PowerShell | Version récente |
| Pester | 5.x |
| DISM | Disponible dans Windows |

Consultez également :

- `Prerequisites.md`

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

Version de référence du développement actuel :

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

DISM doit être disponible et fonctionnel dans l'environnement Windows.

---

# Vérifier Pester

Afficher les versions installées :

```powershell
Get-InstalledModule Pester -ErrorAction SilentlyContinue
```

Installer Pester 5.x si nécessaire :

```powershell
Install-Module Pester -Scope CurrentUser
```

Vérifier ensuite :

```powershell
Get-Module Pester -ListAvailable
```

---

# Ouvrir le projet

Depuis la racine du dépôt :

```powershell
code .
```

---

# Vérifier l'arborescence

La structure principale du projet est notamment organisée ainsi :

```text
PimsOS
│
├── Build
├── Config
├── Documentation
├── ISO
├── Logs
├── Modules
│   ├── Actions
│   ├── Configuration
│   ├── Core
│   ├── Image
│   ├── Infrastructure
│   ├── Managers
│   ├── Package
│   ├── Windows
│   ├── PimsOS.psd1
│   └── PimsOS.psm1
├── Output
├── Tests
├── Workspace
└── version.json
```

Le répertoire `Classes` n'est plus utilisé comme couche de classes métier du Builder.

---

# Comprendre l'architecture

Le framework repose sur un module PowerShell unique et une architecture en couches.

Le flux logique principal est :

```text
Infrastructure / Core / Configuration
                │
                ▼
            Workflow
                │
                ▼
            Pipeline
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
        Module technique
                │
                ▼
             Windows
```

Avant de modifier le code, prendre connaissance des documents d'architecture.

---

# Vérifier le projet

Avant toute modification importante, exécuter les tests :

```powershell
Invoke-Pester
```

Pour exécuter explicitement les tests du projet :

```powershell
Pour exécuter explicitement les tests du Builder :

Invoke-Pester -Path .\Tests\Unit
Invoke-Pester -Path .\Tests\Integration
```
Pour exécuter les tests d'acceptance :

Invoke-Pester -Path .\Tests\Acceptance

Les tests obligatoires doivent être validés avant de considérer une évolution comme stable.

---

# Charger le module

Le module PimsOS est défini par :

```text
Modules\PimsOS.psd1
Modules\PimsOS.psm1
```

Charger le module :

```powershell
Import-Module .\Modules\PimsOS.psd1
```

Vérifier son chargement :

```powershell
Get-Module PimsOS
```

Vérifier la fonction publique :

```powershell
Get-Command Initialize-PimsOS
```

---

# Point d'entrée public

L'API publique actuelle du module est :

```powershell
Initialize-PimsOS
```

Exemple :

```powershell
Import-Module .\Modules\PimsOS.psd1

$Context = Initialize-PimsOS
```

Le BuildContext retourné permet ensuite d'inspecter l'état du Build :

```powershell
$Context.BuildState
```

ou le rapport :

```powershell
$Context.Report
```

---

# Premier Build

Le script de lancement du projet est :

```text
Build\Build-PimsOS.ps1
```

Lancer le Builder depuis la racine du projet :

```powershell
.\Build\Build-PimsOS.ps1
```

Le Builder prépare notamment :

- l'environnement ;
- le Recovery ;
- les vérifications des prérequis ;
- les ressources ISO et WIM ;
- la configuration ;
- les personnalisations ;
- le nettoyage et la finalisation.

Le traitement exact dépend de l'état du projet et de la configuration utilisée.

---

# Premier lancement

Pour tester uniquement le chargement et le point d'entrée du module :

```powershell
Import-Module .\Modules\PimsOS.psd1

$Context = Initialize-PimsOS
```

Pour lancer ensuite le processus de Build complet :

```powershell
.\Build\Build-PimsOS.ps1
```

`Initialize-PimsOS` et `Build-PimsOS.ps1` ne doivent pas être considérés comme deux étapes obligatoires à exécuter successivement dans le cadre d'un même Build.

Le script `Build-PimsOS.ps1` constitue le lanceur du processus de Build, tandis que `Initialize-PimsOS` est l'entrée fonctionnelle publique du module.

---

# Premier Tweak

Les personnalisations sont définies dans les ressources de configuration du projet.

Les Tweaks sont séparés des profils.

Un Tweak contient notamment :

- son identifiant ;
- sa catégorie ;
- sa description ;
- ses Actions ;
- ses métadonnées ;
- ses éventuelles contraintes de compatibilité.

Les profils déterminent quelles personnalisations sont sélectionnées pour un Build.

Les Tweaks ne contiennent pas de logique PowerShell exécutable.

---

# Ajouter une fonctionnalité

Avant d'écrire du code :

1. identifier la responsabilité concernée ;
2. vérifier qu'un composant similaire n'existe pas déjà ;
3. déterminer la couche concernée ;
4. définir le contrat du nouveau composant ;
5. développer ;
6. ajouter les tests ;
7. mettre à jour la documentation ;
8. vérifier les ADR si nécessaire.

---

# Ajouter un nouveau type d'Action

Les étapes sont les suivantes :

1. créer l'Engine spécialisé dans `Modules\Actions` ;
2. créer ou adapter le Manager dans `Modules\Managers` si nécessaire ;
3. enregistrer le nouveau type dans `ActionRegistry.ps1` ;
4. ajouter les validations nécessaires ;
5. mettre à jour le BuildContext ou les statistiques si nécessaire ;
6. créer les tests Pester ;
7. mettre à jour la documentation.

Le flux doit respecter :

```text
Action
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
Module technique
```

---

# Documentation

Avant toute contribution, il est recommandé de lire :

- `API.md`
- `Architecture.md`
- `ArchitectureRules.md`
- `BuildContext.md`
- `CodingStandards.md`
- `DeveloperGuide.md`
- `ModuleGuide.md`
- `ProjectStructure.md`
- `Testing.md`

Ces documents décrivent l'architecture, les conventions et la stratégie de tests du framework.

---

# Workflow recommandé

Chaque évolution importante suit le processus suivant :

```text
Besoin
    ↓
Analyse
    ↓
Conception
    ↓
Développement
    ↓
Tests
    ↓
Validation
    ↓
Documentation
    ↓
Revue
    ↓
Commit Git
```

Il n'y a pas de phase de compilation classique du framework PowerShell.

La validation repose notamment sur :

- le parsing PowerShell ;
- le chargement du module ;
- les tests Pester ;
- les validations fonctionnelles nécessaires.

---

# Bonnes pratiques

Avant un commit important :

- exécuter les tests ;
- vérifier le chargement du module ;
- vérifier les journaux ;
- vérifier le Build si le changement le concerne ;
- mettre à jour la documentation ;
- vérifier les ADR si l'architecture a évolué ;
- vérifier `git status`.

---

# Besoin d'aide ?

Les principales références du projet sont :

- `API.md`
- `Architecture.md`
- `ArchitectureRules.md`
- `BuildContext.md`
- `DeveloperGuide.md`
- `ModuleGuide.md`
- `Testing.md`
- `ProjectStatus.md`

Ces documents constituent la référence du fonctionnement et du développement de **PimsOS Builder**.

