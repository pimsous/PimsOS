# PimsOS Builder - Jalons du projet

> Version technique : 3.0.0
>
> Statut : Développement / architecture stabilisée
>
> Dernière mise à jour : 2026-08-16

---

# Objectif

Ce document présente les principaux jalons du projet **PimsOS Builder**.

Chaque jalon représente une étape majeure de l'évolution du framework.

Un jalon est considéré comme atteint lorsque les objectifs définis pour celui-ci sont réalisés et validés selon les critères du projet.

---

# État actuel des jalons

| Jalon | Objet | Statut |
|--------|--------|--------|
| Milestone 1 | Architecture du framework | ✅ Terminé |
| Milestone 2 | Module PowerShell unique | ✅ Terminé |
| Milestone 3 | Moteur de Build | ✅ Terminé |
| Milestone 4 | Framework de configuration | ✅ Stabilisé |
| Milestone 5 | Génération d'image | 🟡 En cours |
| Milestone 6 | Première version stable | ⏳ À venir |

---

# Milestone 1 — Architecture du framework

## Objectif

Définir l'architecture globale du projet.

### Réalisations

- architecture modulaire ;
- règles d'architecture ;
- Architecture Decision Records ;
- documentation technique ;
- standards de développement ;
- séparation des responsabilités ;
- BuildContext centralisé.

### Résultat

Le framework dispose d'une architecture structurée servant de base aux développements suivants.

---

# Milestone 2 — Module PowerShell unique

## Objectif

Centraliser le chargement du framework dans un module PowerShell unique.

### Réalisations

- création de `PimsOS.psm1` ;
- création de `PimsOS.psd1` ;
- chargement centralisé des composants ;
- API publique centralisée ;
- suppression du modèle à plusieurs modules indépendants ;
- initialisation unifiée du framework.

### Résultat

PimsOS Builder fonctionne autour d'un module PowerShell unique.

---

# Milestone 3 — Moteur de Build

## Objectif

Mettre en place le moteur principal d'orchestration du Build.

### Réalisations

- BuildContext ;
- BuildState ;
- Workflow ;
- Pipeline ;
- Recovery ;
- vérification de l'environnement ;
- gestion ISO ;
- gestion WIM ;
- gestion DISM ;
- gestion des ruches du registre ;
- journalisation ;
- suivi des phases ;
- nettoyage des ressources ;
- finalisation du Build.

### Résultat

Le framework dispose d'un moteur de Build capable d'orchestrer les principales étapes de préparation et de personnalisation d'une image Windows.

---

# Milestone 4 — Framework de configuration

## Objectif

Construire un moteur de personnalisation piloté par des données de configuration.

### Réalisations

- chargement des catégories ;
- chargement des Tweaks ;
- chargement des profils ;
- fusion Profil + Tweaks ;
- validation des définitions ;
- création des Actions ;
- ActionRegistry ;
- ActionEngine ;
- Engines spécialisés ;
- Managers spécialisés ;
- suivi des statistiques ;
- gestion du BuildContext.

### Engines actuellement implémentés

- RegistryEngine ;
- ServiceEngine ;
- PackageEngine ;
- DriverEngine ;
- FeatureEngine ;
- CapabilityEngine ;
- CommandEngine ;
- FileEngine ;
- FolderEngine ;
- EnvironmentEngine ;
- ScheduledTaskEngine ;
- ShortcutEngine.

### Managers actuellement implémentés

- PackageManager ;
- DriverManager ;
- FeatureManager ;
- CapabilityManager ;
- CommandManager ;
- FileManager ;
- FolderManager ;
- EnvironmentManager ;
- ScheduledTaskManager ;
- ShortcutManager.

### État

Le framework de configuration et la chaîne Engine / Manager sont considérés comme stabilisés pour la version technique 3.0.0.

La couverture des tests continue d'être étendue et certains composants d'infrastructure nécessitent encore une validation complémentaire.

### Résultat

Le Builder peut construire une configuration à partir des données disponibles et acheminer les Actions vers les Engines spécialisés correspondants.

---

# Milestone 5 — Génération d'image

## Objectif

Finaliser la chaîne permettant de produire automatiquement l'image PimsOS.

### Déjà disponible

- manipulation des ISO ;
- manipulation des WIM ;
- opérations DISM ;
- sélection d'une image Windows ;
- montage et démontage des ressources ;
- préparation du cycle de Build ;
- gestion du nettoyage ;
- infrastructure de finalisation.

### Travaux restants

- finalisation de la chaîne de production de l'ISO ;
- finalisation de certains traitements du WIM ;
- validation complète de bout en bout ;
- finalisation des rapports ;
- implémentation des providers Chocolatey et Winget ;
- validation complète de la reprise de Build ;
- validation de l'artefact ISO final.

### Résultat attendu

Le Builder doit être capable de produire automatiquement une ISO PimsOS complète, validée et exploitable.

---

# Milestone 6 — Première version stable

## Objectif

Publier une première version stable du produit.

### Conditions

- Pipeline validé de bout en bout ;
- générateur ISO stable ;
- composants nécessaires finalisés ;
- tests validés ;
- documentation synchronisée ;
- API publique stabilisée ;
- absence d'anomalie bloquante ;
- Build reproductible.

### Statut

⏳ À venir.

---

# État technique actuel

La version technique actuelle du framework est :

```text
3.0.0