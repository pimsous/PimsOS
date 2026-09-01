# PimsOS Builder - Stratégie de tests

> Version technique : 3.0.0
>
> Statut : Développement / architecture stabilisée
>
> Dernière mise à jour : 2026-09-01

---

> Les références datées du 31/08/2026 conservées plus bas sont historiques ; l’état courant est celui du 01/09/2026.


# Objectif

Ce document décrit la stratégie de tests utilisée dans le projet **PimsOS Builder**.

L'objectif est de garantir que chaque évolution du framework puisse être vérifiée de manière reproductible avant d'être considérée comme stable.

Les tests constituent également une documentation vivante du comportement attendu des composants.

Une fonctionnalité importante ne doit pas être considérée comme terminée tant que son comportement n'a pas été validé par les tests appropriés.

---

# Framework de tests

PimsOS Builder utilise :

* PowerShell 7 ;
* Pester 5.x.

L'environnement de développement actuel utilise Pester 5.8.0.

---

# Principes

Les tests doivent permettre de :

* détecter les régressions ;
* valider les nouvelles fonctionnalités ;
* vérifier les comportements nominaux ;
* vérifier les comportements d'erreur ;
* documenter les contrats des composants ;
* sécuriser les évolutions du Builder.

Les tests doivent rester :

* reproductibles ;
* lisibles ;
* isolés lorsque cela est possible ;
* rapides pour les tests unitaires ;
* indépendants des services externes lorsqu'ils n'ont pas besoin de ceux-ci.

---

# Organisation

Les tests du projet sont organisés selon plusieurs répertoires ayant chacun
un rôle précis.

La campagne Pester officielle couvre actuellement :

```text
Tests
│
├── Unit
└── Integration
```

## Unit

Le répertoire `Tests\Unit` contient les tests unitaires des modules et
composants du framework.

Ces tests doivent vérifier le comportement d'un composant de manière isolée
lorsque cela est possible, notamment à l'aide de mocks Pester.

## Integration

Le répertoire `Tests\Integration` contient les tests d'intégration entre
les différents composants du framework.

Ils permettent notamment de vérifier :

* l'API publique PimsOS ;
* l'intégration du Wizard ;
* la transmission de la configuration au pipeline ;
* l'organisation et l'exécution du BuildPipeline.

## Fixtures

Le répertoire `Tests\Fixtures` contient les données utilisées par les tests.

Ces fichiers servent notamment à fournir des configurations ou des données
de test reproductibles sans dépendre de données de production.

## Manual

Le répertoire `Tests\Manual` contient les tests nécessitant une validation
manuelle ou un environnement qui ne peut pas être entièrement simulé par
Pester.

Ils ne font pas partie de la campagne Pester automatisée.

## Legacy

Le répertoire `Tests\Legacy` contient les tests historiques correspondant
à l'ancien système.

Ces tests sont conservés à des fins historiques et de référence.

Ils sont volontairement séparés de la suite officielle et **ne sont pas
inclus dans la campagne Pester officielle**.

La présence de tests dans `Tests\Legacy` ne signifie donc pas qu'ils doivent
être exécutés ou maintenus comme des tests actifs du framework actuel.

---

# Diagnostic sécurisé avant Pester

Depuis le 01/09/2026, `Tests\Tools\Invoke-PimsOSDiagnostics.ps1` constitue le garde-fou recommandé avant une campagne ciblée.

Il analyse statiquement les fichiers de tests et distingue :

| Classe | Signification | Exécution normale |
|---|---|---|
| `SAFE` | Aucun appel Build dangereux non neutralisé détecté | Oui |
| `BUILD-CAPABLE` | Opération de Build/WIM/ISO potentiellement réelle | Non |
| `UNKNOWN` | Neutralisation impossible à prouver statiquement | Non |

Commandes de référence :

```powershell
.\Tests\Tools\Invoke-PimsOSDiagnostics.ps1 -Unit -InventoryOnly -ExplainFailures
.\Tests\Tools\Invoke-PimsOSDiagnostics.ps1 -Integration -InventoryOnly -ExplainFailures
.\Tests\Tools\Invoke-PimsOSDiagnostics.ps1 -BuildValidation -AllowBuild -InventoryOnly -ExplainFailures
```

Le mode `-InventoryOnly` n'exécute aucun test. `-BuildValidation` exige explicitement `-AllowBuild` et reste réservé aux validations réelles volontairement autorisées.

L'analyse est volontairement conservatrice : un faux positif `BUILD-CAPABLE` est acceptable ; un faux négatif pouvant lancer un Build réel ne l'est pas.

---

# Campagne de validation officielle

La configuration Pester du projet est définie dans :

```text
PesterConfiguration.ps1
```

La campagne officielle cible explicitement :

```text
Tests\Unit
Tests\Integration
```

`Tests\Legacy` est donc exclu de cette campagne.

Cette séparation permet de conserver les tests historiques sans les mélanger
avec les tests correspondant à l'architecture actuelle de PimsOS Builder.

---

# Résultats de référence

La dernière campagne complète communiquée avant la reprise du 01/09 était :

```text
971 Passed (historical — 31/08/2026)
0 Failed
1 Skipped
```

Elle est historique et ne doit pas être présentée comme le résultat actuel de la branche après les modifications du 01/09.

Le 01/09, une campagne d'intégration ciblée a produit :

```text
20 Passed
0 Failed
0 Skipped
```

Le diagnostic statique a inventorié 63 fichiers Unit et 4 fichiers Integration. Ces nombres sont des fichiers, pas des cas de test Pester.

Le fichier XML historique doit être régénéré pour fournir une preuve machine-readable de la prochaine campagne complète.

Durée totale :

```text
5,69 secondes
```

## Interprétation

Les anciens sous-résultats détaillés conservés plus bas dans ce document sont historiques. Pour la référence actuelle, utiliser la section « Résultats de référence » ci-dessus et les rapports Pester générés par la CI.

### Tests échoués

Aucun test n'a échoué.

```text
Failed: 0
```

### Test ignoré

Un seul test est actuellement ignoré.

Il s'agit du test :

```text
Retourne une collection pour une catégorie sans groupes
```

dans :

```text
Tests\Unit\Modules\Categories.Tests.ps1
```

Ce test est conditionnel : il est ignoré lorsque les définitions actuelles
de `Categories.json` ne contiennent aucune catégorie dépourvue de groupes.

Les catégories actuellement définies possèdent toutes des groupes.

Ce `Skipped` est donc **intentionnel et lié aux données actuellement
présentes**, et ne correspond pas à un échec de fonctionnalité.

### Tests inconclusifs

Aucun test n'est inconclusif.

```text
Inconclusive: 0
```

### Tests non exécutés

Aucun test de la campagne officielle n'est resté non exécuté.

```text
NotRun: 0
```

---

# PostInstall

Le sous-système PostInstall possède actuellement des tests dédiés
pour :

* State ;
* Network ;
* PostInstall ;
* Bootstrap ;
* FirstBoot ;
* Unattend ;
* Installer ;
* UI.

Le pipeline possède également des tests d'intégration pour
`PreparePostInstall`.

Une validation réelle dans un WIM temporaire est utilisée pour
compléter les tests unitaires.

La suite PostInstall couvre également l'interface console `UI.ps1`,
notamment l'affichage de l'état réseau, l'aide réseau et l'attente
réseau avec reprise immédiate lorsque le réseau est disponible.

Les tests destructifs sur WIM doivent utiliser un montage temporaire
et `-Discard`.

---

# Tests réseau

Les tests du composant Network couvrent notamment :

* la détection d'une connexion réseau ;
* la détection d'une absence de connexion ;
* le mécanisme de repli vers `Get-NetAdapter` ;
* la détection de l'accès Internet ;
* l'attente de disponibilité du réseau ;
* la gestion du délai d'expiration ;
* la correction d'un intervalle inférieur à une seconde.

Les attentes temporelles sont simulées dans les tests afin d'éviter
des délais réels inutiles pendant la campagne automatisée.

---

# Tests du Wizard

Le Wizard possède des tests unitaires couvrant notamment :

* la sélection du profil ;
* les options du Build ;
* la configuration des drivers ;
* le retour au menu précédent ;
* l'annulation du Build ;
* la transmission des paramètres configurés au contexte.

L'intégration du Wizard est également vérifiée par les tests d'intégration
de l'API publique PimsOS.

---

# Tests du BuildPipeline

Les tests du pipeline vérifient notamment :

* l'ajout et l'exécution des étapes ;
* la gestion des étapes réussies ou échouées ;
* la génération des lignes de rapport ;
* l'ordre des étapes du pipeline ;
* l'application des drivers ;
* la préparation du runtime PostInstall ;
* l'utilisation du runtime du projet ;
* l'utilisation du Bootstrap installé dans `ProgramData` ;
* le refus d'un contexte dépourvu de montage WIM.

L'ordre fonctionnel actuellement validé place notamment :

```text
Montage WIM
    ↓
Application des drivers
    ↓
Préparation PostInstall
    ↓
Configuration / étapes suivantes
```

---

# Tests des drivers

La configuration des drivers est testée selon plusieurs sources :

```text
None
CurrentSystem
Folder
```

Les tests vérifient notamment :

* l'absence d'action lorsque la source est `None` ;
* l'application de drivers depuis un dossier ;
* la génération de l'action DISM correspondante ;
* l'enregistrement de l'action dans le contexte ;
* la transmission de `Recurse` ;
* la transmission de `ForceUnsigned` ;
* l'export des drivers du système actuel.

Le dossier projet utilisé pour la source `Folder` est :

```text
C:\Projets\PimsOS\Drivers
```

---

# CommandManager

Les tests du `CommandManager` vérifient notamment :

* les providers par défaut ;
* l'ordre des providers ;
* l'exécution des providers Native, PowerShell et CMD ;
* le refus d'un provider absent ;
* le refus d'une commande absente ;
* le refus d'un provider inconnu ;
* le refus d'un handler inexistant ;
* la transmission des arguments au handler ;
* l'enregistrement d'un nouveau provider ;
* la réinitialisation des providers.

Le test du handler inexistant fait partie de la suite active et est
actuellement validé.

---

# Catégories

Les tests du système de catégories vérifient notamment :

* le chargement des catégories ;
* le cache ;
* le rechargement explicite ;
* l'identification des catégories ;
* la récupération des groupes ;
* les niveaux `Official`, `Advanced` et `Experimental` ;
* la détection de l'existence d'une catégorie.

Le test concernant une catégorie sans groupes reste conditionnel afin
de ne pas introduire artificiellement une catégorie uniquement pour
satisfaire le test.

---

# Tests Legacy

Les tests situés dans :

```text
Tests\Legacy
```

ne font pas partie de la validation officielle du framework actuel.

Ils correspondent à l'ancien système de migration et à des composants
historiques conservés pour référence.

Ils peuvent donc contenir des dépendances, contrats ou comportements qui
ne correspondent plus à l'architecture actuelle.

Ils ne doivent pas être interprétés comme des échecs de la suite officielle
lorsqu'ils ne sont pas exécutés par `PesterConfiguration.ps1`.

---

# Exécution des tests

Pour exécuter la campagne officielle, utiliser :

```powershell
$config = & .\PesterConfiguration.ps1

Invoke-Pester -Configuration $config
```

Pour exécuter une suite particulière :

```powershell
Invoke-Pester .\Tests\Unit\Modules\Categories.Tests.ps1 -Output Detailed
```

ou :

```powershell
Invoke-Pester .\Tests\Integration\PimsOS.Tests.ps1 -Output Detailed
```

---

# Critère de validation

Une modification du framework est considérée comme validée par la suite
automatisée lorsque :

* aucun test applicable n'échoue ;
* aucun test ne reste inconclusif ;
* aucun test applicable ne reste non exécuté ;
* les tests conditionnels ignorés sont compris et justifiés ;
* les éventuelles validations manuelles nécessaires sont identifiées.

L'état de référence actuellement validé est :

```text
971 Passed (historical — 31/08/2026)
0 Failed
1 Skipped
0 Inconclusive
0 NotRun
```

---

# Validation du Build réel

Le diagnostic et les tests Pester ne remplacent pas la validation de production de l'image.

Le 01/09/2026, un Build réel complet a été exécuté avec succès :

- Windows 11 Professionnel, index 6 ;
- 27 Tweaks appliqués ;
- PostInstall validé ;
- WIM démonté et synchronisé vers la source ISO avec SHA256 vérifié ;
- ISO créée avec `oscdimg.exe` détecté via le Windows ADK ;
- code retour `0` ;
- aucun montage WIM résiduel.

La validation suivante doit porter sur l'artefact ISO lui-même et sur une installation Hyper-V/FirstBoot.

---

# Maintenance de la stratégie de tests

Toute nouvelle fonctionnalité importante doit être accompagnée des tests
appropriés.

Les tests unitaires doivent être ajoutés dans :

```text
Tests\Unit
```

Les tests couvrant plusieurs composants doivent être ajoutés dans :

```text
Tests\Integration
```

Les validations nécessitant une intervention ou un environnement particulier
doivent être placées dans :

```text
Tests\Manual
```

Les tests historiques ne doivent pas être réintroduits dans la suite
active simplement pour augmenter le nombre de tests exécutés.

Toute évolution de l'organisation des tests doit également être reflétée
dans `PesterConfiguration.ps1` et dans cette documentation.

# PimsOS Builder - Stratégie de tests

> Version technique : **3.0.0**
>
> Dernière mise à jour : **2026-09-01**

## Campagne officielle

La campagne officielle couvre :

```text
Tests\Unit
Tests\Integration
```

Les tests :

```text
Tests\Legacy
```

sont historiques et exclus volontairement.

## Dernier résultat de référence

```text
Passed      : 797
Failed      : 0
Skipped     : 1
Inconclusive: 0
NotRun      : 0
Total       : 798
```

## Tests ciblés validés

- `Tweak.Tests.ps1` : 13/13
- `Configuration.Tests.ps1` : 25/25
- `Wizard.Tests.ps1` : 18/18
- `Architecture.Tests.ps1` : 3/3

L'architecture confirme également le chargement de **27 Tweaks** avec des
Actions valides.

## Règles

- Un test Legacy ne doit pas faire échouer la campagne officielle.
- Les tests unitaires doivent rester isolés lorsque possible.
- Les tests d'intégration vérifient les contrats entre composants.
- Toute nouvelle fonctionnalité importante doit avoir ses tests.
- Les résultats communiqués après une modification doivent être privilégiés
  par rapport à un ancien XML Pester.

## Prochaine campagne utile

Après reconstruction d'une nouvelle ISO :

1. campagne Pester officielle ;
2. validation Hyper-V ;
3. validation FirstBoot/PostInstall ;
4. validation Tweaks réels ;
5. validation réseau ;
6. validation idempotence ;
7. validation Rufus/physique.

Le fichier `Tests\testResults.xml` doit être régénéré pour devenir la preuve
machine-readable de la nouvelle campagne.
