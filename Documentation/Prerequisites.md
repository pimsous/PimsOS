# Prérequis

> Version : 0.4.0
>
> Dernière mise à jour : 2026-08-03

---

# Objectif

Ce document décrit les logiciels, outils et versions nécessaires au développement et à l'utilisation de **PimsOS Builder**.

Le Builder vérifie automatiquement une partie de ces prérequis avant chaque build.

---

# Système d'exploitation

Le développement est officiellement supporté sur :

- Windows 11 24H2
- Windows 11 25H2

L'architecture du projet est conçue pour permettre la prise en charge de nouvelles versions de Windows sans modification majeure du moteur.

---

# PowerShell

## Version minimale

```text
PowerShell 7.4 LTS
```

## Version recommandée

```text
PowerShell 7.6 ou supérieur
```

Le développement sous Windows PowerShell 5.1 n'est pas supporté.

Le Builder vérifie automatiquement la version de PowerShell au démarrage.

---

# Git

Version minimale :

```text
2.50
```

Git est utilisé pour :

- le suivi des versions ;
- les commits ;
- la gestion des branches ;
- les publications.

Configuration recommandée :

```powershell
git config --global user.name "Votre Nom"
git config --global user.email "vous@example.com"
```

Le Builder vérifie automatiquement la présence de Git.

---

# Visual Studio Code

Dernière version stable recommandée.

Extensions conseillées :

- PowerShell
- GitLens
- EditorConfig
- Markdown All in One

---

# Pester

Version minimale :

```text
5.x
```

Installation :

```powershell
Install-Module Pester -Scope CurrentUser
```

Les tests utilisent exclusivement Pester.

---

# Windows ADK

Certaines fonctionnalités nécessitent le Windows ADK.

Il fournit notamment :

- Oscdimg
- les outils de déploiement Windows

L'ADK sera utilisé lors de la génération finale des images ISO.

---

# DISM

DISM doit être disponible sur le système.

Vérification :

```powershell
dism /?
```

Le Builder vérifie automatiquement sa disponibilité.

---

# Droits administrateur

Le Builder doit être exécuté avec des privilèges administrateur.

Cette vérification est réalisée automatiquement au démarrage.

---

# Image Windows

Une image Windows officielle est nécessaire.

Le Builder détecte automatiquement :

- install.wim ;
- install.esd ;
- les éditions disponibles.

L'utilisateur choisit ensuite l'édition à personnaliser.

À terme, le Builder permettra de personnaliser différentes versions de Windows à partir du même moteur.

---

# Version du projet

Les informations de version sont centralisées dans :

```text
version.json
```

Ce fichier contient notamment :

- la version du Builder ;
- les versions de Windows supportées ;
- l'auteur ;
- le dépôt Git.

---

# Vérifications automatiques

Avant chaque Build, PimsOS vérifie automatiquement :

- la version de PowerShell ;
- les droits administrateur ;
- Git ;
- DISM ;
- l'image ISO ;
- l'espace disque disponible.

Le Build est interrompu si un prérequis obligatoire est absent.

---

# Encodage

Tous les fichiers du projet utilisent :

- UTF-8
- sans BOM
- fins de ligne CRLF

---

# Compatibilité officielle

| Composant | Version minimale | Version recommandée |
|-----------|------------------|---------------------|
| Windows | 11 24H2 | 11 25H2 et versions futures |
| PowerShell | 7.4 LTS | 7.6+ |
| Git | 2.50 | Dernière version stable |
| Pester | 5.x | Dernière version stable |
| Visual Studio Code | Stable | Dernière version stable |

---

# Références

Consulter également :

- GettingStarted.md
- DeveloperGuide.md
- BuildContext.md
- Architecture.md
- CodingStandards.md

---

# Conclusion

Le respect de ces prérequis garantit le bon fonctionnement du Builder ainsi que la reproductibilité des builds.

La majorité de ces vérifications est désormais réalisée automatiquement lors de l'initialisation du pipeline.