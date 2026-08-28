# PimsOS Builder - Prérequis

> Version technique : 3.0.0
>
> Statut : Référence
>
> Dernière mise à jour : 2026-08-28

---

# Objectif

Ce document décrit les logiciels, outils et conditions nécessaires au développement et à l'utilisation de **PimsOS Builder**.

Le Builder vérifie automatiquement une partie des prérequis avant l'exécution du Build.

---

# Système d'exploitation

L'environnement de développement de référence actuel utilise :

```text
Windows 11
Release : 25H2
Build   : 26100
```

Le projet est conçu pour ne pas dépendre d'une version unique de Windows.

Les informations relatives à l'image réellement traitée doivent être découvertes à partir de l'image Windows et du BuildContext ou provenir de la configuration appropriée.

---

# PowerShell

## Version minimale du framework

Le module PimsOS nécessite :

```text
PowerShell 7.0+
```

## Version de référence du développement

L'environnement de développement actuel utilise :

```text
PowerShell 7.6.x
```

Windows PowerShell 5.1 n'est pas l'environnement de développement de référence du projet.

Vérifier la version :

```powershell
$PSVersionTable.PSVersion
```

---

# Git

Git est utilisé pour :

- le suivi des versions ;
- les commits ;
- les branches ;
- le dépôt du projet ;
- les publications.

Vérifier son installation :

```powershell
git --version
```

Configuration recommandée :

```powershell
git config --global user.name "Votre Nom"
git config --global user.email "vous@example.com"
```

La version exacte de Git n'est pas considérée comme une contrainte architecturale du Builder.

---

# Visual Studio Code

Visual Studio Code constitue l'environnement de développement recommandé.

Extensions utiles :

- PowerShell ;
- GitLens ;
- EditorConfig ;
- Markdown All in One.

Les extensions ne sont pas nécessaires au fonctionnement du Builder lui-même.

---

# Pester

Les tests automatisés utilisent :

```text
Pester 5.x
```

Vérifier les versions disponibles :

```powershell
Get-Module Pester -ListAvailable
```

Installer Pester si nécessaire :

```powershell
Install-Module Pester -Scope CurrentUser
```

Les tests du framework doivent être exécutés avec Pester 5.x.

---

# DISM

DISM doit être disponible dans l'environnement Windows.

Vérification :

```powershell
dism /?
```

DISM est utilisé pour les opérations de déploiement et de modification des images Windows.

---

# Windows ADK

Certaines opérations de génération d'images peuvent nécessiter des outils fournis par le **Windows ADK**.

Les outils concernés peuvent notamment inclure :

- les outils de déploiement Windows ;
- `Oscdimg` pour certaines opérations de génération d'ISO.

L'ADK est principalement pertinent pour la phase de génération finale des artefacts.

---

# Droits administrateur

Certaines opérations du Builder nécessitent des privilèges administrateur, notamment celles qui concernent :

- DISM ;
- le montage d'images ;
- le registre offline ;
- certaines opérations système.

Le Builder vérifie les droits nécessaires dans le cadre de ses contrôles d'environnement.

Le niveau de privilège requis dépend de l'étape exécutée.

---

# Image Windows source

Un média Windows compatible est nécessaire pour réaliser un Build complet.

Selon le scénario pris en charge, le Builder peut travailler avec les ressources d'une image Windows et notamment :

```text
install.wim
install.esd
```

Les éditions disponibles sont découvertes à partir de l'image.

Le Builder sélectionne ensuite l'image ou l'édition à personnaliser selon le processus de Build.

Les médias sources ne doivent pas être modifiés directement lorsque le processus utilise une copie de travail dans le Workspace.

---

# Espace disque

Le Build utilise un Workspace temporaire pour :

- les ressources ISO ;
- les copies WIM ;
- les images montées ;
- les fichiers temporaires ;
- les artefacts intermédiaires ;
- les résultats du Build.

Un espace disque suffisant doit donc être disponible avant de commencer un Build.

La disponibilité de l'espace disque fait partie des vérifications d'environnement.

---

# Version du projet

Les informations générales du projet sont centralisées dans :

```text
version.json
```

Ce fichier contient notamment :

- le nom du projet ;
- la version ;
- la release Windows de référence ;
- le Build Windows de référence ;
- l'auteur ;
- l'entreprise ;
- le dépôt Git.

La version technique actuelle du framework est :

```text
3.0.0
```

---

# Vérifications automatiques

Avant l'exécution du Build, PimsOS réalise des contrôles d'environnement.

Ces contrôles portent notamment sur :

- la version de PowerShell ;
- les privilèges administrateur lorsqu'ils sont nécessaires ;
- la présence de Git ;
- la présence de DISM ;
- les ressources d'entrée nécessaires ;
- l'espace disque disponible.

D'autres contrôles peuvent être ajoutés selon les étapes du Build.

Un Build est interrompu lorsqu'un prérequis obligatoire n'est pas satisfait.

---

# Encodage

Les fichiers texte du projet utilisent :

- UTF-8 ;
- sans BOM.

Les conventions de fin de ligne doivent rester cohérentes avec les règles du dépôt et de l'environnement de développement.

---

# Compatibilité de développement

| Composant | Référence actuelle |
|-----------|--------------------|
| Windows | Windows 11 25H2 |
| Build Windows | 26100 |
| PowerShell | 7.6.x |
| Pester | 5.x |
| Git | Version compatible avec le dépôt |
| Visual Studio Code | Version stable récente |

Ces valeurs décrivent l'environnement de référence du développement et ne constituent pas toutes des contraintes codées en dur dans le framework.

---

# Avant un premier Build

Vérifier au minimum :

```powershell
$PSVersionTable.PSVersion
git --version
dism /?
Get-Module Pester -ListAvailable
```

Vérifier également que :

- les privilèges nécessaires sont disponibles ;
- le média Windows source est accessible ;
- l'espace disque nécessaire est disponible ;
- le dépôt est correctement cloné ;
- les tests passent.

Exécuter les tests :

```powershell
Invoke-Pester -Path .\Tests\Unit
Invoke-Pester -Path .\Tests\Integration
```

---

# Références

Consulter également :

- `GettingStarted.md`
- `DeveloperGuide.md`
- `BuildContext.md`
- `Architecture.md`
- `ArchitectureRules.md`
- `CodingStandards.md`
- `Testing.md`

---

# Conclusion

Le respect des prérequis permet de disposer d'un environnement cohérent pour développer et exécuter **PimsOS Builder**.

Le projet vérifie automatiquement une partie des prérequis avant les opérations de Build et peut interrompre l'exécution lorsqu'une condition obligatoire n'est pas satisfaite.

