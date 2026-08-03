# Tests

> Version : 2.0.0
>
> Dernière mise à jour : 2026-08-03

---

# Objectif

Ce document décrit la stratégie de tests utilisée dans le projet **PimsOS Builder**.

L'objectif est de garantir que chaque évolution du moteur de build puisse être validée de manière reproductible avant son intégration, tout en respectant l'architecture du projet.

Les tests constituent un élément essentiel de la qualité du projet et permettent de prévenir les régressions tout au long du développement.

---

# Principes

Les tests permettent de :

- détecter les régressions ;
- valider les nouvelles fonctionnalités ;
- vérifier le comportement attendu ;
- sécuriser les évolutions du Builder ;
- documenter le comportement des composants.

Une fonctionnalité n'est pas considérée comme terminée tant que ses tests n'ont pas été validés.

---

# Framework de tests

PimsOS Builder utilise :

- PowerShell 7.6 ou supérieur ;
- Pester 5.x.

---

# Architecture des tests

PimsOS Builder repose sur un module PowerShell unique.

Tous les composants internes appartiennent au module :

```text
PimsOS
```

Les composants internes ne sont jamais exportés uniquement pour satisfaire les besoins des tests.

L'encapsulation du framework est conservée.

---

# Organisation

Les tests sont organisés selon la structure suivante :

```text
Tests
│
├── Unit
├── Integration
├── Fixtures
└── Legacy
```

## Unit

Les tests unitaires vérifient un composant isolé.

Ils couvrent notamment :

- BuildContext
- BuildState
- Configuration
- Profiles
- Tweaks
- ActionEngine
- RegistryEngine
- ServiceEngine
- PackageEngine
- DriverEngine
- Logger
- Recovery
- Pipeline

---

## Integration

Les tests d'intégration vérifient le fonctionnement global du Builder.

Ils couvrent notamment :

- l'initialisation du module ;
- l'initialisation du BuildContext ;
- le Pipeline ;
- le Workflow ;
- le Recovery ;
- les principaux scénarios de build.

---

## Fixtures

Les Fixtures regroupent les ressources utilisées pendant les tests :

- profils ;
- fichiers JSON ;
- définitions de Tweaks ;
- exemples de configuration ;
- objets simulés.

Les Fixtures sont considérées comme des données de référence et ne doivent jamais être modifiées pendant l'exécution des tests.

---

## Legacy

Les anciens tests issus des premiers outils de migration sont conservés dans :

```text
Tests\Legacy
```

Ils sont archivés à titre historique et ne participent plus à la validation du Builder.

---

# Stratégie de tests

Le projet distingue deux niveaux de validation.

## Tests unitaires

Les tests unitaires vérifient un composant de manière isolée.

Ils doivent être :

- indépendants ;
- rapides ;
- reproductibles.

Ils ne doivent dépendre ni :

- d'Internet ;
- du réseau ;
- d'une configuration utilisateur ;
- d'un environnement particulier.

Les tests unitaires peuvent accéder aux composants internes du framework.

Cette exception est réservée exclusivement aux tests.

---

## Tests d'intégration

Les tests d'intégration utilisent exclusivement l'API publique du module.

Ils valident notamment :

- le chargement du module ;
- l'initialisation du Builder ;
- la création du BuildContext ;
- le Pipeline complet ;
- le Workflow ;
- le Recovery ;
- les principaux scénarios de personnalisation Windows.

---

# Composants à tester

Chaque nouveau composant doit disposer d'une couverture adaptée.

Les composants critiques comprennent notamment :

- BuildContext ;
- BuildState ;
- Recovery ;
- Pipeline ;
- Workflow ;
- Configuration ;
- Profiles ;
- Tweaks ;
- ActionEngine ;
- RegistryEngine ;
- ServiceEngine ;
- PackageEngine ;
- DriverEngine ;
- FeatureEngine ;
- FileEngine ;
- FolderEngine ;
- Logger.

---

# Cas de test

Chaque composant doit être validé dans plusieurs situations :

- fonctionnement nominal ;
- paramètres invalides ;
- erreurs attendues ;
- cas limites ;
- scénarios de régression.

Lorsque cela est pertinent, les tests doivent également vérifier :

- les statistiques ;
- les états du BuildState ;
- les objets retournés ;
- les messages de journalisation.

---

# Validation du moteur de build

Le Pipeline doit être testé dans différents scénarios :

- environnement valide ;
- reprise de build (Recovery) ;
- absence de configuration ;
- profil invalide ;
- erreurs DISM ;
- erreurs de registre ;
- erreur d'un Engine ;
- nettoyage automatique des ressources.

Chaque étape du Pipeline doit mettre correctement à jour le BuildState.

---

# Validation des profils

Les profils doivent être testés afin de vérifier :

- le chargement ;
- la fusion avec les Tweaks ;
- l'activation des personnalisations ;
- la création des ConfigurationItems.

Les définitions de Tweaks ne doivent jamais être modifiées par le moteur de configuration.

---

# Validation des Tweaks

Chaque Tweak doit être testé afin de vérifier :

- sa construction ;
- ses métadonnées ;
- ses Actions ;
- son état Enabled ;
- son exécution ;
- ses statistiques ;
- son résultat final.

---

# Régression

Lorsqu'un bug est corrigé :

1. reproduire le bug par un test ;
2. corriger le code ;
3. vérifier que le test passe ;
4. conserver le test.

Cette règle permet d'éviter les régressions.

---

# Exécution

Exécution complète :

```powershell
Invoke-Pester
```

Exécution des tests du projet :

```powershell
Invoke-Pester .\Tests
```

Exécution d'un composant particulier :

```powershell
Invoke-Pester .\Tests\Unit\ServiceEngine.Tests.ps1
```

Pendant le développement, seuls les tests concernés doivent être exécutés.

Une validation complète est réalisée avant chaque jalon majeur.

---

# Intégration continue

À terme, chaque Build devra automatiquement :

- exécuter les tests ;
- vérifier les prérequis ;
- générer un rapport ;
- refuser toute publication en cas d'échec.

---

# Bonnes pratiques

Les tests doivent être :

- indépendants ;
- reproductibles ;
- rapides ;
- lisibles ;
- faciles à maintenir.

Chaque test doit vérifier un comportement unique.

Les tests ne doivent contenir aucune logique métier complexe.

---

# Philosophie

Les tests constituent une documentation vivante du comportement attendu du Builder.

Ils garantissent que les évolutions du moteur de build, des profils, des Tweaks, des Engines et du Pipeline ne provoquent pas de régression.

L'objectif n'est pas de maximiser le nombre de tests, mais de disposer d'une couverture fiable des composants critiques de **PimsOS Builder**.