# PimsOS Builder - État du projet

> Version technique : 3.0.0
>
> Statut : Développement / architecture stabilisée
>
> Dernière mise à jour : 2026-09-01

---

> Les références datées du 31/08/2026 conservées plus bas sont historiques ; l’état courant est celui du 01/09/2026.


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

## Référence actuelle — 01/09/2026

Le Build réel complet est **validé techniquement** :

- Edition : Windows 11 Professionnel, index 6 ;
- 27 Tweaks appliqués ;
- PostInstall préparé et validé ;
- WIM sauvegardé et démonté ;
- synchronisation WIM → source ISO validée par SHA256 ;
- ISO `Output\PimsOS_3.0.0_20260901_180342.iso` créée ;
- taille annoncée : 7,9 Go ;
- code retour : 0 ;
- état final : `Completed` ;
- aucun montage WIM résiduel.

Le pipeline de production ne doit donc pas être modifié sur la base du faux problème observé après éjection manuelle de l'ISO : le Build réel monte d'abord l'ISO, copie son contenu, puis travaille sur la source préparée.

Le diagnostic sécurisé est maintenant disponible dans `Tests\Tools`.

- 63 fichiers Unit inventoriés ;
- 4 fichiers Integration inventoriés ;
- 3 fichiers classés Build-capable ;
- 0 Unknown après correction de `Complete-Build.Tests.ps1`.

Une campagne d'intégration ciblée a validé **20/20 tests**.

La campagne complète `971/0/1` du 31/08 reste historique jusqu'à la prochaine exécution complète.

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
| Chocolatey            | 🟡 Provider/cache en cours de stabilisation (01/09)              |
| Winget                | ⬜ Non implémenté                                                |
| Microsoft Store       | ⬜ Non intégré                                                   |
| Génération ISO         | ✅ Build réel réussi le 01/09 ; validation de l’artefact restante |
| Tests Pester          | 🟡 Dernière campagne complète communiquée : 971/0/1 (historique) |
| Documentation         | 🟢 Synchronisée au 01/09/2026                                 |

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

Les derniers résultats communiqués pendant la session sont :

```text
971 Passed (historical — 31/08/2026)
0 Failed
1 Skipped
```

La campagne ciblée du Wizard est à `15 Passed / 0 Failed / 0 Skipped`. La campagne PostInstall/Unattend communiquée est à `744 Passed / 0 Failed / 1 Skipped`.

Le seul test ignoré signalé dans ces campagnes est conditionnel. Le fichier `Tests\testResults.xml` présent dans l’archive reste historique et doit être régénéré.

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
Profiles\
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

Un Build réel a généré une ISO PimsOS 3.0.0 le 01/09/2026. La validation fonctionnelle de cet artefact reste à effectuer.

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

La génération de l’ISO est démontrée par le Build réel du 01/09 ; la validation Hyper-V de l’artefact reste à effectuer.

---

# Tests et qualité

La suite officielle Pester est exécutée avec Pester 5.8.0.

Résultat de référence actuel :

```text
971 Passed (historical — 31/08/2026)
0 Failed
1 Skipped
0 Inconclusive
0 NotRun

> Résultat communiqué pendant la session ; à régénérer dans `testResults.xml`.
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

La documentation active a été resynchronisée avec l’implémentation et l’état du Build au 01/09/2026. Les références au 31/08 restent historiques.

---

# Prochaine étape

Les prochaines étapes prioritaires sont :

1. valider l’ISO générée le 01/09/2026 ;
2. compléter la validation réelle du cycle FirstBoot ;
3. valider la reprise réelle du PostInstall après perte puis disponibilité du réseau ;
4. compléter la couverture Recovery et Security ;
5. poursuivre l'implémentation des fonctionnalités de gestion des packages ;
6. enrichir le reporting ;
7. maintenir la documentation synchronisée avec l'implémentation ;
8. préparer une première release fonctionnelle du framework.

# PimsOS Builder - État du projet

> Version technique : **3.0.0**
>
> Statut : **Développement actif / architecture stabilisée**
>
> Dernière mise à jour : **2026-09-01**

## Etat global

| Domaine | Etat |
|---|---|
| Architecture | ✅ Stabilisée |
| Module PimsOS unique | ✅ Implémenté |
| API publique `Initialize-PimsOS` | ✅ Validée |
| BuildContext / BuildState | ✅ Implémentés |
| Workflow / Pipeline | ✅ Implémentés et testés |
| Configuration | ✅ Implémentée et testée |
| Profils | ✅ Implémentés et testés |
| Tweaks | ✅ Implémentés et testés |
| Catalogue Tweaks | ✅ 27 Tweaks chargés avec Actions valides |
| Wizard | ✅ Implémenté et testé |
| ActionRegistry / ActionEngine | ✅ Implémentés et testés |
| Engines spécialisés | ✅ Implémentés et testés |
| Managers | ✅ Implémentés et testés |
| Registry | ✅ Implémenté et testé |
| ISO / WIM / DISM | ✅ Implémentés |
| Drivers | ✅ Implémentés et testés |
| PostInstall / FirstBoot | 🟡 Implémentés ; nouvelle validation ISO réelle requise |
| Reporting | 🟡 A enrichir |
| Recovery | 🟡 A compléter |
| Security | 🟡 A compléter |
| Converters | ⬜ A implémenter |
| Chocolatey | ⬜ A finaliser |
| Winget | ⬜ A finaliser |
| Microsoft Store | ⬜ A intégrer |
| CI / qualité | 🟡 A renforcer |

## Tests

Campagne officielle :

```text
Tests\Unit
Tests\Integration
```

`Tests\Legacy` est exclu.

Dernier résultat de référence :

```text
797 Passed
0 Failed
1 Skipped
798 Total
```

Le chiffre 971 présent dans d'anciens documents est obsolète.

## Git

```text
Commit : 3bbaf73
Message : feat: finalize tweak configuration and test architecture
Branche : main
Remote : origin/main
Etat : propre et synchronisé
```

## Prochaine validation

Avant d'ajouter de nouveaux providers, reconstruire une ISO depuis ce commit
et effectuer une validation Hyper-V complète du flux réel :

```text
ISO
 ↓
Installation Windows
 ↓
FirstBoot
 ↓
Bootstrap
 ↓
réseau
 ↓
PostInstall
 ↓
Tweaks
 ↓
state.json / idempotence
```

Une validation physique/Rufus doit ensuite compléter cette validation.

## Prochains chantiers

1. Validation ISO réelle.
2. Chocolatey.
3. Winget.
4. Microsoft Store.
5. Enrichissement et documentation des Tweaks.
6. Recovery / Security / Reporting.
7. CI et qualité.
