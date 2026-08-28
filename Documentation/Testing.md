# PimsOS Builder - Stratégie de tests

> Version technique : 3.0.0
>
> Statut : Développement / architecture stabilisée
>
> Dernière mise à jour : 2026-08-28

---

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

# Résultat de la dernière validation

La dernière exécution complète de la campagne officielle a produit :

```text
Tests Passed: 701
Tests Failed: 0
Tests Skipped: 1
Tests Inconclusive: 0
Tests NotRun: 0
```

Durée totale :

```text
5,69 secondes
```

## Interprétation

### Tests réussis

**701 tests** ont été exécutés avec succès.

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
* Installer.

Le pipeline possède également des tests d'intégration pour
`PreparePostInstall`.

Une validation réelle dans un WIM temporaire est utilisée pour
compléter les tests unitaires.

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
701 Passed
0 Failed
1 Skipped
0 Inconclusive
0 NotRun
```

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
