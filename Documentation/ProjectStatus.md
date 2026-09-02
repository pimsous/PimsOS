# PimsOS Builder - État du projet

> Version technique : 3.0.0
>
> Statut : Développement / architecture stabilisée
>
> Dernière mise à jour : 2026-09-02

---

> Les références antérieures au 02/09/2026 sont historiques ; l’état courant est celui du 02/09/2026.


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

## Référence actuelle — 02/09/2026

Le Build réel complet et sa validation fonctionnelle sont maintenant démontrés.

## Build réel validé

- Édition : Windows 11 Professionnel, index 6 ;
- 27 Tweaks appliqués ;
- source de drivers : `CurrentSystem` ;
- export des drivers du système hôte réussi ;
- injection DISM des drivers réussie ;
- aucun résidu de montage WIM ;
- cache Chocolatey Offline préparé ;
- bootstrap `chocolatey.nupkg` présent et validé ;
- PostInstall et FirstBoot préparés dans le WIM ;
- WIM sauvegardé et synchronisé vers la source ISO ;
- SHA256 WIM : `B6BA0B8E8474761380FCC26DB165DC786162EA916B8D35192A977C49E72E9941` ;
- ISO : `Output\PimsOS_3.0.0_20260902_141928.iso` ;
- taille : 11,29 Go ;
- code retour : `0` ;
- état final du Build : `Completed`.

La taille supérieure aux ISO précédentes est cohérente avec l'intégration réelle des drivers `CurrentSystem`.

## Diagnostic Pester sécurisé

Dernière campagne officielle sûre :

```text
Tests analysés : 66
Passed         : 815
Failed         : 0
Skipped        : 1
Inconclusive   : 0
NotRun         : 0
Total          : 816
```

Rapport : `Tests\Reports\Diagnostics\Diagnostics-20260902-141259.md`

Le test `Skipped` est conditionnel et reste intentionnel. Il ne constitue pas un échec fonctionnel.

## Validation VM du runtime

La nouvelle ISO a été exécutée dans la VM `PimsOS-Test sur localhost`. La chaîne suivante est validée :

```text
FirstLogon
  ↓
Bootstrap
  ↓
Network
  ↓
DriverCheck
  ↓
Chocolatey local
  ↓
Catalogue Chocolatey
  ↓
Applications
  ↓
Verification
  ↓
Cleanup différé
```

Le `state.json` final indique `Status=Completed`, `Completed=true`, `Failed=false`, `Verification.Verified=true` et aucune tâche manquante.

Le nettoyage a supprimé les scripts temporaires ainsi que `C:\Windows\Panther\unattend.xml`, tout en conservant `state.json`, `PostInstall.log` et le cache Chocolatey.

## Chocolatey

Le bootstrap Chocolatey est installé localement depuis le cache embarqué. Les packages `Online` sont exécutés après Network et DriverCheck.

La politique `FailurePolicy=Continue` est validée en VM : `googlechrome` échoue sur un problème de checksum externe, l'échec est conservé dans l'état, puis `brave` et les packages suivants continuent normalement. Aucun `--ignore-checksums` n'est utilisé.

Cet échec Chrome est actuellement considéré comme **non bloquant** pour PimsOS. Le package n'est pas un composant architectural obligatoire et le catalogue installe Firefox avec succès.

## Microsoft Store / Widgets

La base Windows conserve Microsoft Store et ses composants associés. En VM :

- Microsoft Store s'ouvre ;
- iCloud peut être installé depuis le Store ;
- Widgets (`Win+W`) fonctionnent ;
- le catalogue de Widgets est accessible ;
- un widget Météo a été installé et utilisé avec succès.

Aucune modification supplémentaire de l'intégration Microsoft Store n'est requise à ce stade.

# État global

| Domaine | État |
|---|---|
| Architecture | ✅ Stabilisée |
| Module PimsOS unique | ✅ Implémenté et export public limité à `Initialize-PimsOS` |
| BuildContext / BuildState | ✅ Implémentés |
| Workflow / Pipeline | ✅ Implémentés et testés |
| Configuration / Profils / Tweaks | ✅ Implémentés et testés |
| Drivers | ✅ Export et injection DISM validés en Build réel |
| Image WIM / ISO | ✅ Build réel validé |
| PostInstall / FirstBoot | ✅ Validés en VM |
| Finalization / Cleanup | ✅ Validés en VM |
| Chocolatey bootstrap | ✅ Validé en VM |
| Chocolatey FailurePolicy | ✅ `Continue` validé en VM |
| Microsoft Store / Widgets | ✅ Fonctionnels en VM, sans intégration PimsOS spécifique |
| Reporting | 🟡 À enrichir |
| Recovery | 🟡 Couverture à compléter |
| Security | 🟡 Couverture à compléter |
| Winget | ⬜ Non implémenté |
| Converters | ⬜ Non implémentés |
| Release produit | 🟡 À préparer |

# Validation actuelle

La campagne officielle couvre :

```text
Tests\Unit
Tests\Integration
```

`Tests\Legacy` est conservé séparément et exclu de la campagne officielle.

Dernier résultat de référence :

```text
815 Passed
0 Failed
1 Skipped
0 Inconclusive
0 NotRun
816 Total
```

Le diagnostic sécurisé a analysé 66 fichiers Unit : 66 SAFE, 0 BUILD-CAPABLE, 0 UNKNOWN.

Rapport : `Tests\Reports\Diagnostics\Diagnostics-20260902-141259.md`.

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

Le lancement réel du runtime lors de la première connexion Windows est validé en VM, y compris la finalisation et le nettoyage différé.

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

Un Build réel a généré une ISO PimsOS 3.0.0 le 02/09/2026. Cet artefact a été validé en VM sur le flux FirstBoot/PostInstall/Finalization.

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
Winget
```

Chocolatey est désormais fonctionnel dans le runtime PostInstall. Son audit Offline applicatif reste à poursuivre. Microsoft Store est fourni par Windows et a été validé en VM ; aucun provider PimsOS dédié n'est actuellement requis.

La génération de l’ISO est démontrée par le Build réel du 02/09 et l’artefact a été validé en VM.

---

# Tests et qualité

La suite officielle Pester est exécutée avec Pester 5.8.0.

Résultat de référence actuel :

```text
815 Passed
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

La documentation active a été resynchronisée avec l’implémentation, le Build et la validation VM au 02/09/2026. Les références antérieures restent historiques.

---

# Prochaine étape

La prochaine étape n'est plus de corriger le pipeline de base. Elle consiste à **figer l'état 3.0.0, synchroniser Git et préparer la suite du développement**.

1. Mettre à jour et relire la documentation synchronisée au 02/09/2026.
2. Vérifier l'état Git local, les fichiers modifiés et les éventuels artefacts à exclure.
3. Régénérer `Tests\testResults.xml` si une preuve XML officielle est souhaitée.
4. Créer le commit de synchronisation documentaire et technique.
5. Vérifier le push vers `origin/main`.
6. Ensuite seulement, reprendre le backlog : Winget, couverture Recovery/Security, reporting, audit Offline Chocolatey et validation physique/Rufus.
