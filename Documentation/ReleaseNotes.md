# PimsOS Builder - Notes de version

## Objectif

Ce document présente les principales évolutions de chaque version de **PimsOS Builder**.

Les notes de version mettent en avant les changements importants pour les utilisateurs et les développeurs.

Contrairement au `CHANGELOG.md`, qui recense les modifications techniques détaillées, ce document présente les évolutions majeures, les améliorations, les corrections et les changements importants.

---

# Format

Chaque version documente, lorsque cela est pertinent :

* nouveautés ;
* améliorations ;
* corrections ;
* changements incompatibles (Breaking Changes) ;
* problèmes connus.

---

# Version 3.0.0

## État

🚧 Développement / architecture stabilisée

La version 3.0.0 représente l'état technique actuel du framework.

Elle ne constitue pas encore une release complète du produit.

---

## Nouveautés

### Architecture

* Stabilisation du modèle de module PowerShell unique.
* Centralisation du chargement des composants dans `PimsOS.psm1`.
* Centralisation de l'API publique.
* Renforcement du `BuildContext` comme contrat central.
* Mise en place et stabilisation de l'`ActionRegistry`.
* Routage centralisé des Actions par `ActionEngine`.
* Séparation explicite entre les tests actifs et les tests historiques `Legacy`.

### Configuration

* Stabilisation du chargement des catégories.
* Stabilisation du chargement des Tweaks.
* Stabilisation du chargement des profils.
* Fusion des profils et des Tweaks.
* Validation des définitions de configuration.
* Construction de la configuration finale dans le `BuildContext`.
* Intégration de la sélection du profil dans le Wizard.
* Intégration des options du Build dans le Wizard.

### Wizard

Le Wizard de configuration est désormais intégré au flux principal.

Il permet notamment :

* de sélectionner un profil ;
* de modifier les options du Build ;
* de configurer les drivers ;
* d'afficher le résumé ;
* de valider ou d'annuler la configuration.

Les informations configurées dans le Wizard sont transmises au
`BuildContext`, puis au pipeline.

### Drivers

Le pipeline prend désormais en charge la préparation des drivers.

Les sources actuellement supportées sont :

* `None` ;
* `CurrentSystem` ;
* `Folder`.

Le Wizard permet de sélectionner la source des drivers.

Les actions DISM correspondantes sont construites et enregistrées dans
le contexte du Build.

### PostInstall / FirstBoot

Le sous-système PostInstall et sa préparation FirstBoot sont désormais
intégrés au BuildPipeline.

Les composants concernés comprennent :

* `State.ps1` ;
* `Network.ps1` ;
* `PostInstall.ps1` ;
* `Bootstrap.ps1` ;
* `FirstBoot.ps1` ;
* `Unattend.ps1` ;
* `Installer.ps1`.

La préparation du runtime PostInstall est exécutée après l'application
des drivers et avant le montage de la ruche `SOFTWARE`.

### Tests

Extension importante de la couverture Pester avec :

* tests dédiés aux Engines ;
* tests dédiés aux Managers ;
* tests du système de configuration ;
* tests du module Registry ;
* tests du Wizard ;
* tests des drivers ;
* tests du pipeline ;
* tests PostInstall ;
* tests FirstBoot ;
* tests réseau ;
* tests d'intégration de l'API publique ;
* tests d'intégration du BuildPipeline.

---

## Améliorations

### Core

* Stabilisation du `BuildContext`.
* Stabilisation du `BuildState`.
* Stabilisation du Workflow.
* Stabilisation du Pipeline.
* Amélioration de la finalisation du Build.
* Meilleure propagation des informations entre les différentes phases.

### Actions

* Routage centralisé via `ActionRegistry`.
* Séparation plus stricte entre Engines et Managers.
* Gestion homogène des états `Success`, `Duration` et `Error`.
* Amélioration de la gestion des erreurs des Actions.

### Managers

* Normalisation des mécanismes de sélection des providers.
* Validation systématique des paramètres.
* Amélioration de la gestion des handlers.
* Correction de plusieurs problèmes liés aux dictionnaires ordonnés
  PowerShell.
* Validation du comportement lorsqu'un handler inexistant est demandé.

### Configuration

* Meilleure propagation de l'état dans le `BuildContext`.
* Mise à jour des indicateurs de chargement de la configuration.
* Validation renforcée des définitions.
* Intégration du profil sélectionné dans le contexte.
* Tests de régression ajoutés.

### PostInstall

* Détection du réseau avec `Get-NetConnectionProfile`.
* Repli vers `Get-NetAdapter` lorsque nécessaire.
* Vérification de la connectivité Internet.
* Attente configurable de la disponibilité réseau.
* Préparation du runtime dans le WIM.
* Génération de `unattend.xml`.
* Préparation des commandes `FirstLogonCommands`.
* Intégration de `PreparePostInstall` dans le pipeline.

### Tests et qualité

La campagne officielle utilise désormais exclusivement :

```text
Tests\Unit
Tests\Integration
```

Les tests historiques sont conservés dans :

```text
Tests\Legacy
```

et ne font pas partie de la campagne officielle.

La campagne de référence actuelle donne :

```text
701 Passed
0 Failed
1 Skipped
0 Inconclusive
0 NotRun
```

Le seul test ignoré est conditionnel et concerne une catégorie sans
groupes qui n'existe pas dans les définitions actuelles.

---

## Corrections

Les travaux de stabilisation de la version 3.0.0 ont notamment permis
de corriger :

* la propagation incorrecte du `BuildContext` ;
* la mise à jour de l'état de chargement de la configuration ;
* la propagation du profil sélectionné ;
* la propagation des options du Build ;
* la propagation de la configuration des drivers ;
* l'ordre des étapes du BuildPipeline ;
* la préparation PostInstall dans le pipeline ;
* la gestion des sources de drivers ;
* la construction des actions DISM pour les drivers ;
* plusieurs problèmes de détection des providers ;
* l'utilisation incorrecte de `ContainsKey()` avec des dictionnaires
  ordonnés ;
* la propagation des erreurs dans les Engines ;
* plusieurs incohérences de gestion des statistiques ;
* des incohérences entre les contrats des Managers et leurs tests ;
* le comportement du test réseau expirant qui attendait réellement une
  minute avant de terminer ;
* la gestion d'un handler inexistant dans `CommandManager`.

---

## Breaking Changes

La version 3.0.0 poursuit et stabilise les changements introduits par
l'architecture du module unique.

Principes importants :

* `PimsOS.psm1` constitue le module central ;
* `Initialize-PimsOS` constitue le point d'entrée public fonctionnel ;
* les composants internes ne sont pas des modules PowerShell indépendants ;
* les fonctions internes ne constituent pas automatiquement une API
  publique ;
* le `BuildContext` constitue le contrat central entre les composants ;
* le Wizard transmet sa configuration au contexte puis au pipeline ;
* les tests `Legacy` sont séparés de la campagne officielle.

Les anciennes architectures basées sur plusieurs modules indépendants
ne constituent plus le modèle de référence.

---

## Problèmes connus

Les éléments suivants restent en développement :

* finalisation complète de la génération de l'ISO ;
* validation complète d'un Build de bout en bout ;
* validation réelle de l'exécution de `FirstLogonCommands` lors de la
  première connexion Windows ;
* validation complète de la reprise après perte puis disponibilité du
  réseau ;
* implémentation du provider Chocolatey ;
* implémentation du provider Winget ;
* intégration Microsoft Store ;
* implémentation de `Converters.ps1` ;
* couverture complémentaire de `Recovery.ps1` ;
* couverture complémentaire de `Security.ps1` ;
* enrichissement du Reporting.

La version 3.0.0 ne doit donc pas encore être considérée comme une
release stable finale.

---

# Historique

## Version 0.3.0-dev

### État

🚧 Historique

Cette version correspond à une étape précédente du développement du
Builder.

### Principales évolutions

* migration vers un module PowerShell unique ;
* introduction de `Initialize-PimsOS` ;
* restructuration du Pipeline ;
* introduction du mécanisme Recovery ;
* gestion des images WIM ;
* gestion des images ISO ;
* gestion des ruches du registre ;
* chargement de la configuration ;
* chargement des profils ;
* fusion des profils et des Tweaks ;
* validation de la configuration ;
* sélection interactive de l'image Windows ;
* introduction de `Test-WimMountState()` ;
* premiers tests Pester ;
* centralisation des informations du projet dans `version.json`.

### Corrections historiques

* correction de la gestion des montages DISM invalides ;
* amélioration de la logique de reprise ;
* amélioration de la copie du WIM ;
* amélioration de la gestion des erreurs du Pipeline.

---

# Versions futures

Les prochaines versions seront documentées selon le modèle suivant.

---

# Version X.Y.Z

## État

* En développement
* Publiée
* Maintenance

---

## Nouveautés

...

---

## Améliorations

...

---

## Corrections

...

---

## Breaking Changes

...

---

## Problèmes connus

...

---

# Politique de version

Le projet suit le principe du **Semantic Versioning (SemVer)**.

Format :

```text
MAJOR.MINOR.PATCH
```

* **MAJOR** : changements incompatibles.
* **MINOR** : nouvelles fonctionnalités compatibles.
* **PATCH** : corrections de bugs.

Exemple :

```text
3.0.1
```

---

# Références

Consulter également :

* `CHANGELOG.md`
* `Milestones.md`
* `Roadmap.md`
* `ProjectStatus.md`
* `Testing.md`
* `PostInstall.md`
* `Legacy.md`
