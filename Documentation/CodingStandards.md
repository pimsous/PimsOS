# Standards de développement

> Version : 0.4.0
>
> Architecture : 2.x

---

# Objectif

Ce document définit les conventions de développement utilisées dans l'ensemble du projet **PimsOS Builder**.

Tous les composants du framework doivent respecter ces règles.

L'objectif est de garantir :

- une architecture homogène ;
- un code lisible ;
- une maintenance simplifiée ;
- une excellente testabilité ;
- une évolutivité durable.

---

# Principes fondamentaux

Le projet repose sur les principes suivants :

- responsabilité unique ;
- faible couplage ;
- forte cohésion ;
- architecture modulaire ;
- aucune duplication inutile ;
- BuildContext unique ;
- séparation de la logique métier et de la logique technique.

---

# Organisation du projet

Le projet est organisé autour des domaines fonctionnels suivants :

```text
Modules
│
├── Infrastructure
├── Core
├── Configuration
├── Image
├── Windows
├── Actions
├── Managers
└── Package
```

Chaque dossier possède une responsabilité clairement définie.

---

# Organisation des fichiers

Un fichier ne doit contenir qu'un seul composant principal.

Exemples :

```text
BuildContext.ps1
Pipeline.ps1
ActionRegistry.ps1
RegistryEngine.ps1
PackageManager.ps1
```

Les très petits composants peuvent être regroupés lorsque cela améliore la lisibilité.

---

# Responsabilités

Chaque composant possède une responsabilité unique.

Exemples :

| Composant | Responsabilité |
|-----------|----------------|
| Engine | Orchestration |
| ActionEngine | Routage des Actions |
| ActionRegistry | Association Action → Engine |
| Engine spécialisé | Logique métier |
| Manager | Opérations techniques |
| Module Windows | Accès aux API Windows |

---

# Convention de nommage

## Fonctions

Toujours utiliser le format :

```text
Verbe-Nom
```

Exemples :

```text
Get-Configuration
Invoke-Action
New-BuildContext
Mount-WimImage
```

Les verbes doivent appartenir à la liste officielle PowerShell.

---

## Variables

Toujours utiliser des noms explicites.

Exemple :

```powershell
$Context
$Configuration
$Tweak
$Action
$Package
$Category
```

Éviter :

```powershell
$tmp
$obj
$a
$x
```

---

## Paramètres

Toujours utiliser des noms explicites.

Exemple :

```powershell
-Context
-Tweak
-Action
-Configuration
-Profile
```

---

## Classes

Les classes utilisent le PascalCase.

Exemple :

```text
BuildContext
RegistryAction
PackageAction
FeatureAction
```

---

# Structure des fonctions

Toutes les fonctions doivent utiliser :

```powershell
[CmdletBinding()]
```

puis

```powershell
param()
```

Les fonctions longues sont organisées en sections :

```text
Initialisation

Validation

Traitement

Journalisation

Retour
```

Les blocs `begin/process/end` sont réservés aux fonctions pipeline.

---

# Commentaires

Les sections utilisent le format standard du projet :

```powershell
# ==========================================
# Initialisation
# ==========================================
```

Les commentaires expliquent :

- pourquoi ;
- jamais ce que fait une instruction évidente.

---

# Journalisation

Toute la journalisation passe exclusivement par :

```powershell
Write-Log
```

Les appels suivants sont interdits dans la logique métier :

```powershell
Write-Host
```

Les fonctions peuvent utiliser :

- Write-Verbose
- Write-Debug

pour les informations de diagnostic uniquement.

---

# Gestion des erreurs

Les erreurs doivent :

- être interceptées ;
- être journalisées ;
- être propagées.

Toujours utiliser :

```powershell
throw
```

Ne jamais utiliser :

```powershell
exit
```

dans un module.

---

# BuildContext

Toutes les informations partagées transitent par le BuildContext.

Il est interdit d'utiliser :

- variables globales ;
- variables partagées ;
- états implicites.

Le BuildContext constitue le contrat officiel entre les composants.

---

# Architecture Engine / Manager

Les responsabilités sont strictement séparées.

```text
Engine
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
Module Windows
```

Les Engines ne doivent jamais appeler directement les API Windows.

---

# Configuration

Toutes les données métier doivent provenir :

- des fichiers JSON ;
- du BuildContext ;
- des profils ;
- des paramètres utilisateur.

Aucune valeur métier ne doit être codée en dur.

---

# Compatibilité Windows

Le Builder ne doit jamais être développé pour une seule version de Windows.

Les versions supportées sont déterminées dynamiquement :

- à partir du WIM ;
- des profils ;
- des contraintes déclarées dans les Tweaks.

---

# Encodage

Tous les fichiers utilisent :

- UTF-8
- sans BOM
- CRLF

---

# Indentation

- 4 espaces
- aucune tabulation

---

# Mise en forme

Respecter systématiquement :

- une ligne vide entre deux fonctions ;
- une ligne vide entre les grandes sections ;
- alignement cohérent des propriétés PowerShell.

---

# Tests

Tout nouveau composant doit être accompagné de tests Pester.

Les tests doivent couvrir :

- le comportement nominal ;
- les erreurs ;
- les cas limites.

---

# Documentation

Toute évolution importante doit mettre à jour :

- Architecture.md
- BuildContext.md
- API.md
- Roadmap.md (si nécessaire)
- les ADR concernées.

La documentation fait partie intégrante du développement.

---

# Dépendances

Les dépendances circulaires sont interdites.

Le sens des dépendances est toujours :

```text
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
Engine
        │
        ▼
Manager
        │
        ▼
Windows
```

---

# Compatibilité de développement

| Composant | Version minimale |
|-----------|------------------|
| Windows | 11 |
| PowerShell | 7.6 |
| Pester | 5.x |
| Git | 2.55 |

---

# Revue de code

Avant chaque commit :

- le projet compile ;
- les tests passent ;
- aucun avertissement critique ;
- la documentation est à jour ;
- les ADR sont mises à jour si nécessaire ;
- les nouveaux composants respectent les Architecture Rules.

---

# Philosophie

Le code doit être :

- simple ;
- lisible ;
- modulaire ;
- testable ;
- prévisible ;
- facilement extensible.

La simplicité est toujours préférée à la complexité.

Une nouvelle fonctionnalité doit pouvoir être ajoutée sans modifier les composants existants lorsque l'architecture le permet.