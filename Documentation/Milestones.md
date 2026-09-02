# PimsOS Builder - Jalons du projet

> Version technique : 3.0.0
>
> Statut : Développement / architecture stabilisée
>
> Dernière mise à jour : 2026-09-02

---

> Les références antérieures au 02/09/2026 sont historiques ; l’état courant est celui du 02/09/2026.


# Objectif

Ce document présente les principaux jalons du projet **PimsOS Builder**.

Chaque jalon représente une étape majeure de l'évolution du framework.

Un jalon est considéré comme atteint lorsque les objectifs définis pour celui-ci sont réalisés et validés selon les critères du projet.

---

# État actuel des jalons

| Jalon | Objet | Statut |
|---|---|---|
| Milestone 1 | Architecture du framework | ✅ Terminé |
| Milestone 2 | Module PowerShell unique | ✅ Terminé |
| Milestone 3 | Moteur de Build | ✅ Terminé |
| Milestone 4 | Framework de configuration | ✅ Stabilisé |
| Milestone 5 | Génération d'image | 🟢 Validé techniquement |
| Milestone 6 | Première version stable | ⏳ À venir |

---

# Milestone 1 — Architecture du framework

## Objectif

Définir l'architecture globale du projet.

### Réalisations

* architecture modulaire ;
* module PowerShell unique ;
* règles d'architecture ;
* Architecture Decision Records ;
* documentation technique ;
* standards de développement ;
* séparation des responsabilités ;
* BuildContext centralisé ;
* BuildState centralisé.

### Résultat

Le framework dispose d'une architecture structurée servant de base aux développements suivants.

L'architecture du module unique est désormais le modèle de référence du projet.

---

# Milestone 2 — Module PowerShell unique

## Objectif

Centraliser le chargement du framework dans un module PowerShell unique.

### Réalisations

* création de `PimsOS.psm1` ;
* création de `PimsOS.psd1` ;
* chargement centralisé des composants ;
* API publique centralisée ;
* suppression du modèle à plusieurs modules indépendants ;
* initialisation unifiée du framework ;
* définition de `Initialize-PimsOS` comme point d'entrée public.

### API publique

Le module expose l'API publique nécessaire au fonctionnement du framework.

Le principe actuellement validé est que les composants internes restent internes au module et ne constituent pas automatiquement une API publique.

### Résultat

PimsOS Builder fonctionne autour d'un module PowerShell unique.

L'architecture publique est couverte par les tests d'intégration.

---

# Milestone 3 — Moteur de Build

## Objectif

Mettre en place le moteur principal d'orchestration du Build.

### Réalisations

* BuildContext ;
* BuildState ;
* Workflow ;
* Pipeline ;
* Recovery ;
* vérification de l'environnement ;
* vérification des prérequis ;
* gestion ISO ;
* gestion WIM ;
* gestion DISM ;
* gestion des ruches du registre ;
* journalisation ;
* suivi des phases ;
* nettoyage des ressources ;
* finalisation du Build.

### Wizard

Le Wizard de configuration est intégré au flux du Build.

Il permet de configurer :

* le profil ;
* les options du Build ;
* les drivers ;
* le résumé ;
* la validation ou l'annulation.

La configuration sélectionnée est transmise au `BuildContext`, puis au pipeline.

### Drivers

La préparation des drivers est intégrée au pipeline.

Les sources supportées sont :

* `None` ;
* `CurrentSystem` ;
* `Folder`.

L'application des drivers intervient après le montage du WIM.

### PostInstall

La préparation du runtime PostInstall est intégrée au pipeline.

L'ordre actuellement validé est :

```text
MountWim
    ↓
ApplyDrivers
    ↓
PreparePostInstall
    ↓
MountSoftwareHive
```

Le runtime installé dans l'image contient notamment :

```text
Bootstrap.ps1
Network.ps1
UI.ps1
PostInstall.ps1
State.ps1
```

Le Build prépare également `unattend.xml` afin de lancer le Bootstrap lors du premier démarrage.

### Résultat

Le framework dispose d'un moteur de Build capable d'orchestrer les principales étapes de préparation et de personnalisation d'une image Windows.

La chaîne d'orchestration et ses principaux contrats sont couverts par les tests unitaires et d'intégration.

---

# Milestone 4 — Framework de configuration

## Objectif

Construire un moteur de personnalisation piloté par des données de configuration.

### Réalisations

* chargement des catégories ;
* chargement des Tweaks ;
* chargement des profils ;
* fusion Profil + Tweaks ;
* validation des définitions ;
* création des Actions ;
* ActionRegistry ;
* ActionEngine ;
* Engines spécialisés ;
* Managers spécialisés ;
* suivi des statistiques ;
* gestion du BuildContext.

### Engines actuellement implémentés

* `RegistryEngine` ;
* `ServiceEngine` ;
* `PackageEngine` ;
* `DriverEngine` ;
* `FeatureEngine` ;
* `CapabilityEngine` ;
* `CommandEngine` ;
* `FileEngine` ;
* `FolderEngine` ;
* `EnvironmentEngine` ;
* `ScheduledTaskEngine` ;
* `ShortcutEngine`.

### Managers actuellement implémentés

* `PackageManager` ;
* `DriverManager` ;
* `FeatureManager` ;
* `CapabilityManager` ;
* `CommandManager` ;
* `FileManager` ;
* `FolderManager` ;
* `EnvironmentManager` ;
* `ScheduledTaskManager` ;
* `ShortcutManager`.

### Catégories

Le système de catégories est implémenté.

Les niveaux actuellement définis sont :

```text
Official
Advanced
Experimental
```

Les catégories actuellement définies dans `Config\Categories.json` sont :

```text
Applications
Edge
Explorer
Gaming
OneDrive
Performance
Privacy
Widgets
Windows
WindowsUpdate
```

### Profils

Le système de profils est implémenté.

Les profils sont sélectionnés depuis :

```text
Profiles\
```

Le profil sélectionné est conservé dans le `BuildContext`.

### État

Le framework de configuration et la chaîne Engine / Manager sont considérés comme stabilisés pour la version technique 3.0.0.

La couverture des tests est importante et continue d'être étendue sur les composants d'infrastructure.

### Résultat

Le Builder peut construire une configuration à partir des données disponibles et acheminer les Actions vers les Engines spécialisés correspondants.

---

# Milestone 5 — Génération d'image

## Objectif

Finaliser la chaîne permettant de produire automatiquement l'image PimsOS.

### Déjà disponible

* manipulation des ISO ;
* manipulation des WIM ;
* opérations DISM ;
* sélection d'une image Windows ;
* montage et démontage des ressources ;
* préparation du cycle de Build ;
* application des drivers ;
* préparation du runtime PostInstall ;
* génération de `unattend.xml` ;
* gestion du nettoyage ;
* infrastructure de finalisation ;
* reporting de base.

### PostInstall / FirstBoot

La préparation PostInstall et FirstBoot est implémentée.

Les composants suivants sont disponibles et testés :

* State ;
* Network ;
* PostInstall ;
* Bootstrap ;
* UI ;
* FirstBoot ;
* Unattend ;
* Installer.

La génération de `unattend.xml` et la préparation de `FirstLogonCommands` sont également couvertes.

Une validation réelle de l'injection du runtime dans un WIM temporaire a été réalisée.

### Travaux restants

* validation réelle de l'exécution de `FirstLogonCommands` lors de la première connexion ;
* validation complète du Build de bout en bout ;
* finalisation de la chaîne de production de l'ISO ;
* validation de l'artefact ISO final ;
* finalisation de certains traitements du WIM ;
* validation complète de la reprise du Build ;
* validation complète de la reprise après perte puis disponibilité du réseau ;
* implémentation du provider Chocolatey ;
* implémentation du provider Winget ;
* intégration Microsoft Store ;
* enrichissement des rapports.

### Résultat attendu

Le Builder doit être capable de produire automatiquement une ISO PimsOS complète, validée, reproductible et exploitable.

---

# Milestone 6 — Première version stable

## Objectif

Publier une première version stable du produit.

### Conditions

* Pipeline validé de bout en bout ;
* générateur ISO stable ;
* composants nécessaires finalisés ;
* PostInstall validé sur un environnement Windows réel ;
* FirstBoot validé ;
* tests validés ;
* documentation synchronisée ;
* API publique stabilisée ;
* absence d'anomalie bloquante ;
* Build reproductible ;
* artefact ISO final validé.

### Statut

⏳ À venir.

---

# Validation et qualité

La campagne officielle Pester utilise :

```text
Tests\Unit
Tests\Integration
```

Les tests historiques sont conservés séparément dans :

```text
Tests\Legacy
```

Ils ne font pas partie de la campagne officielle.

La dernière campagne de référence donne :

```text
815 Passed / 0 Failed / 1 Skipped (reference — 02/09/2026)
0 Failed
1 Skipped
0 Inconclusive
0 NotRun
```

Le seul test ignoré est conditionnel et concerne le cas d'une catégorie sans groupes alors que les catégories actuellement définies possèdent toutes des groupes.

La campagne complète s'exécute actuellement en environ :

```text
durée variable selon les tests et l’environnement
```

---

# État technique actuel

La version technique actuelle du framework est :

```text
3.0.0
```

L'architecture est considérée comme stabilisée.

Le développement fonctionnel se poursuit principalement autour de la finalisation de la chaîne de génération d'image, de la validation FirstBoot réelle et de l'intégration des providers de packages.

---

# Prochaines étapes prioritaires

1. Finaliser la génération de l'ISO.
2. Valider le Build complet de bout en bout.
3. Valider l'exécution réelle de FirstBoot.
4. Valider les scénarios réseau réels du PostInstall.
5. Finaliser Chocolatey et Winget.
6. Compléter Recovery et Security.
7. Enrichir le Reporting.
8. Synchroniser la documentation.
9. Préparer la première release stable.
