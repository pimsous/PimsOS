# PimsOS Builder - État du projet

> Version technique : 3.0.0
>
> Statut : Développement / architecture stabilisée
>
> Dernière mise à jour : 2026-08-29

---

# Informations générales

## Projet

PimsOS Builder

## Version

3.0.0

## Statut

🚧 Développement actif

## Statut de la version

Architecture stabilisée, développement fonctionnel en cours.

La version 3.0.0 représente l'état technique actuel du framework PimsOS Builder.

Elle ne constitue pas encore une release complète du produit.

## Objectif

Développer un framework modulaire capable de personnaliser différentes versions de Windows à partir de fichiers de configuration JSON, puis de produire une image Windows personnalisée.

Le Builder est conçu pour rester indépendant d'une version particulière de Windows afin de permettre l'évolution du projet et le support de futures versions compatibles.

L'objectif final est de produire automatiquement une image Windows personnalisée sous la forme d'une distribution PimsOS.

---

# État global

| Domaine               | État                                                            |
| --------------------- | --------------------------------------------------------------- |
| Architecture          | ✅ Stabilisée                                                    |
| Module PimsOS unique  | ✅ Implémenté                                                    |
| BuildContext          | ✅ Implémenté                                                    |
| BuildState            | ✅ Implémenté                                                    |
| Logger                | ✅ Implémenté                                                    |
| Validation            | ✅ Implémentée                                                   |
| Recovery              | 🟡 Implémenté, couverture à compléter                           |
| Workflow              | ✅ Implémenté et testé                                           |
| Wizard                | ✅ Implémenté et testé                                           |
| Pipeline              | ✅ Implémenté et testé                                           |
| Configuration         | ✅ Implémentée et testée                                         |
| Catégories            | ✅ Implémentées et testées                                       |
| Tweaks                | ✅ Implémentés et testés                                         |
| Profils               | ✅ Implémentés et testés                                         |
| Drivers               | ✅ Implémentés et testés                                         |
| ActionRegistry        | ✅ Implémenté et testé                                           |
| ActionEngine          | ✅ Implémenté et testé                                           |
| Engines spécialisés   | ✅ Implémentés et testés                                         |
| Managers              | ✅ Implémentés et testés                                         |
| Registry              | ✅ Implémenté et testé                                           |
| Image ISO             | ✅ Implémentée                                                   |
| Image WIM             | ✅ Implémentée                                                   |
| DISM                  | ✅ Implémenté                                                    |
| PostInstall           | 🟡 Implémenté et testé, validation FirstBoot réelle à compléter |
| FirstBoot             | 🟡 Préparé et testé, validation réelle à compléter              |
| Reporting             | 🟡 Implémenté, à enrichir                                       |
| Security              | 🟡 Implémenté, couverture à compléter                           |
| Converters            | ⬜ Non implémenté                                                |
| Chocolatey            | ⬜ Non implémenté                                                |
| Winget                | ⬜ Non implémenté                                                |
| Microsoft Store       | ⬜ Non intégré                                                   |
| Génération ISO finale | 🟡 En cours de finalisation                                     |
| Tests Pester          | ✅ 708 tests validés, 0 échec                                    |
| Documentation         | 🟡 Synchronisation en cours                                     |

---

# Validation actuelle

La campagne officielle Pester utilise les répertoires :

```text
Tests
├── Unit
└── Integration
```

Les tests historiques présents dans :

```text
Tests\Legacy
```

sont conservés séparément et ne font pas partie de la campagne officielle.

La campagne de référence actuelle comprend :

```text
Tests\Unit          : 684 tests
Tests\Integration   : 24 tests
```

Résultat global :

| Résultat           | Valeur |
| ------------------ | ------ |
| Tests réussis      | 708    |
| Tests échoués      | 0      |
| Tests ignorés      | 1      |
| Tests inconclusifs | 0      |
| Tests non exécutés | 0      |

Le test ignoré est conditionnel et concerne le comportement d'une catégorie sans groupes alors que les catégories actuellement définies dans `Config\Categories.json` possèdent toutes des groupes.

Ce `Skipped` est intentionnel et ne correspond pas à un échec fonctionnel.

---

# Architecture actuelle

PimsOS repose sur un module PowerShell unique :

```text
Modules\PimsOS.psm1
```

Ce module constitue l'API publique du framework.

Les composants internes sont organisés par domaines :

```text
Modules
│
├── Core
├── Configuration
├── Infrastructure
├── Image
├── Actions
├── Managers
├── Package
├── PostInstall
└── ...
```

Le module public orchestre les différents composants sans exposer inutilement leurs fonctions internes.

---

# BuildContext

Le `BuildContext` constitue le contexte central du Build.

Il contient notamment :

* la configuration du projet ;
* la configuration utilisateur ;
* les options du Build ;
* l'état du Build ;
* les informations liées à l'image ;
* les informations du workspace ;
* les statistiques ;
* les erreurs ;
* les avertissements.

Les options principales du Build comprennent notamment :

```text
CreateISO
CreateReport
DryRun
Interactive
```

Le contexte est initialisé avant le lancement du Wizard et du pipeline.

---

# Wizard

L'assistant de configuration est intégré au flux principal lorsque le contexte est interactif.

Le Wizard permet actuellement de configurer :

```text
[1] Choisir le profil
[2] Options du Build
[3] Configuration des drivers
[4] Afficher le résumé
[5] Valider et continuer
[0] Annuler
```

La configuration réalisée dans le Wizard est conservée dans le `BuildContext` et transmise au pipeline.

Les éléments suivants sont couverts par les tests :

* sélection du profil ;
* options du Build ;
* configuration des drivers ;
* résumé ;
* validation ;
* annulation ;
* transmission de la configuration au pipeline.

---

# Drivers

La configuration des drivers prend actuellement en charge trois sources :

```text
None
CurrentSystem
Folder
```

Le Wizard propose :

```text
[1] Aucun driver
[2] Importer les drivers du poste actuel
[3] Utiliser les drivers du dossier projet
[0] Retour
```

Pour la source `Folder`, le dossier racine du projet est utilisé :

```text
C:\Projets\PimsOS\Drivers
```

La recherche récursive des drivers est activée pour cette source.

Le pipeline transforme la configuration en action DISM appropriée.

Les tests couvrent notamment :

* source `None` ;
* source `Folder` ;
* source `CurrentSystem` ;
* génération des actions DISM ;
* enregistrement des actions ;
* propagation de `Recurse` ;
* propagation de `ForceUnsigned`.

---

# BuildPipeline

Le pipeline constitue la chaîne d'exécution principale du Build.

L'ordre actuellement validé comprend notamment :

```text
Montage du WIM
      ↓
Application des drivers
      ↓
Préparation PostInstall
      ↓
Configuration
      ↓
Étapes suivantes du Build
```

L'ordre précis des étapes reste défini par `Get-BuildPipeline`.

Les tests d'intégration couvrent actuellement :

* l'ajout d'étapes ;
* l'exécution des étapes ;
* les étapes réussies ;
* les étapes échouées ;
* la génération du rapport ;
* l'ordre des drivers ;
* la préparation PostInstall ;
* les différentes sources du runtime PostInstall ;
* la gestion des contextes invalides.

---

# PostInstall / FirstBoot

Le sous-système PostInstall et sa préparation FirstBoot sont implémentés.

Les composants suivants disposent de tests :

* State ;
* Network ;
* PostInstall ;
* Bootstrap ;
* FirstBoot ;
* Unattend ;
* Installer ;
* UI.

L'intégration avec le BuildPipeline est également testée.

Le runtime PostInstall installé dans le WIM comprend notamment :

```text
Bootstrap.ps1
Network.ps1
UI.ps1
PostInstall.ps1
State.ps1
```

Une validation réelle permet de vérifier l'injection du runtime dans un WIM temporaire ainsi que la présence et la structure de `unattend.xml`.

La validation du lancement réel du runtime lors de la première connexion Windows reste à compléter.

---

# Réseau PostInstall

Le module réseau vérifie notamment :

* la disponibilité du réseau ;
* l'utilisation de `Get-NetConnectionProfile` ;
* le repli vers `Get-NetAdapter` ;
* la disponibilité d'Internet ;
* l'attente de disponibilité du réseau ;
* le délai d'expiration.

L'interface UI PostInstall distingue également :

```text
Adaptateur réseau
        ↓
Connexion réseau
        ↓
Accès Internet
```

Lorsque le réseau local est disponible mais qu'Internet ne l'est pas, cette situation est signalée explicitement.

Les attentes temporelles sont simulées dans les tests afin d'éviter les délais réels inutiles pendant la campagne automatisée.

La suite dédiée Network ainsi que la suite UI sont actuellement validées.

---

# Configuration

Le système de configuration prend en charge :

* le chargement des définitions de tweaks ;
* leur validation ;
* le chargement des profils ;
* leur fusion avec les définitions ;
* la création de la configuration finale ;
* son intégration au `BuildContext`.

Les profils sont sélectionnés depuis :

```text
Config\Profiles
```

Le système conserve le profil sélectionné dans le contexte du Build.

---

# Catégories et Tweaks

Le système de catégories est implémenté et testé.

Les niveaux actuellement définis sont :

```text
Official
Advanced
Experimental
```

Les catégories actuellement présentes dans `Config\Categories.json` sont notamment :

```text
Privacy
Xbox
```

Le système permet également de récupérer les groupes associés aux catégories.

Le test concernant une catégorie sans groupes reste conditionnel afin de ne pas créer artificiellement une catégorie uniquement pour satisfaire la suite de tests.

---

# ActionRegistry et Engines

Les systèmes `ActionRegistry`, `ActionEngine` et les engines spécialisés sont implémentés et couverts par les tests.

Ils permettent d'isoler :

* l'enregistrement des actions ;
* leur validation ;
* leur exécution ;
* les handlers ;
* les erreurs d'exécution ;
* les contrats entre les différents composants.

---

# Managers

Les différents Managers constituent les couches spécialisées de gestion des opérations du framework.

Ils sont actuellement implémentés et couverts par les tests unitaires.

Le `CommandManager` notamment prend en charge plusieurs providers :

```text
Native
PowerShell
CMD
```

Les tests vérifient également le refus des providers ou handlers invalides.

---

# Image et DISM

Les composants Image prennent en charge :

* le montage WIM ;
* les opérations sur l'image ;
* la préparation des opérations DISM ;
* la gestion du cycle de vie de l'image ;
* la génération de l'ISO.

La génération finale de l'ISO reste en cours de finalisation.

---

# Reporting

Le reporting est implémenté.

Le pipeline peut enregistrer :

* les étapes exécutées ;
* leur état ;
* les erreurs ;
* les avertissements ;
* les informations nécessaires au rapport.

L'enrichissement du reporting reste prévu.

---

# Recovery

Le mécanisme de Recovery est implémenté.

La couverture de tests et certains scénarios avancés restent à compléter.

---

# Security

Le domaine Security est implémenté.

La couverture de tests reste à compléter avant de considérer ce domaine comme entièrement validé.

---

# Composants non finalisés

Les domaines suivants ne sont pas encore implémentés ou finalisés :

```text
Converters
Chocolatey
Winget
Microsoft Store
```

La génération complète de l'ISO finale reste également en cours de finalisation.

---

# Tests et qualité

La suite officielle Pester est exécutée avec Pester 5.8.0.

Résultat de référence actuel :

```text
684 Unit Passed
24 Integration Passed
708 Passed
0 Failed
1 Skipped
0 Inconclusive
0 NotRun
```

La durée de la campagne peut varier selon l'environnement et les tests exécutés.

Les tests `Legacy` sont volontairement exclus de cette campagne.

Toute nouvelle fonctionnalité importante doit être accompagnée des tests correspondants.

Une analyse statique des modules peut également être exécutée avec PSScriptAnalyzer :

```powershell
Invoke-ScriptAnalyzer `
    -Path .\Modules `
    -Recurse `
    -Severity Error
```

---

# Documentation

La documentation couvre notamment :

* l'architecture ;
* le BuildContext ;
* le pipeline ;
* les modules ;
* le PostInstall ;
* les prérequis ;
* la stratégie de tests ;
* les décisions d'architecture ;
* le cycle de vie ;
* les composants Legacy.

La documentation est actuellement en cours de synchronisation avec l'implémentation.

---

# Prochaine étape

Les prochaines étapes prioritaires sont :

1. finaliser la génération de l'ISO ;
2. compléter la validation réelle du cycle FirstBoot ;
3. valider la reprise réelle du PostInstall après perte puis disponibilité du réseau ;
4. compléter la couverture Recovery et Security ;
5. poursuivre l'implémentation des fonctionnalités de gestion des packages ;
6. enrichir le reporting ;
7. maintenir la documentation synchronisée avec l'implémentation ;
8. préparer une première release fonctionnelle du framework.
