# ADR-0007 — Stratégie de tests avec Pester

- **Statut** : Acceptée
- **Date** : 2026-07-19
- **Dernière mise à jour** : 2026-08-16
- **Décideur** : Pims
- **Impact** : Qualité et stabilité du projet

---

# Contexte

PimsOS est un framework PowerShell composé de nombreux composants internes.

Chaque évolution peut affecter plusieurs couches du framework, notamment :

- Core ;
- Configuration ;
- Actions ;
- Engines spécialisés ;
- Managers ;
- Infrastructure ;
- Image ;
- Windows.

Sans stratégie de tests homogène, le risque de régression augmente et les évolutions deviennent plus difficiles à valider.

Le projet doit donc disposer d'un système de validation automatisé et reproductible.

---

# Décision

PimsOS adopte **Pester 5** comme framework officiel de tests.

Les tests font partie intégrante du développement.

Les nouveaux composants importants doivent être accompagnés de tests adaptés.

Une fonctionnalité n'est considérée comme suffisamment validée que lorsque les tests requis pour son périmètre passent avec succès.

---

# Objectifs

Les tests permettent notamment de :

- valider le comportement attendu ;
- détecter les régressions ;
- sécuriser les refactorings ;
- documenter le comportement des composants ;
- vérifier les contrats entre composants ;
- améliorer la stabilité du Builder ;
- faciliter le diagnostic des erreurs.

---

# Organisation

Les tests du projet sont regroupés dans :

```text
Tests/
```

L'organisation peut notamment distinguer :

```text
Tests
│
├── Unit
├── Integration
└── Legacy
```

Les tests unitaires des composants actuels sont placés dans les sous-répertoires correspondants.

Les tests Legacy sont conservés séparément et ne participent pas à la validation courante du Builder.

---

# Types de tests

## Tests unitaires

Les tests unitaires vérifient un composant ou un comportement isolé.

Ils doivent être, autant que possible :

- rapides ;
- indépendants ;
- reproductibles ;
- déterministes.

Ils couvrent notamment :

- Core ;
- Configuration ;
- Engines ;
- Managers ;
- Registry ;
- Infrastructure lorsque le composant le nécessite.

Les opérations Windows réelles peuvent être simulées lorsque le comportement technique réel n'est pas nécessaire au test du contrat du composant.

---

## Tests d'intégration

Les tests d'intégration valident plusieurs composants fonctionnant ensemble.

Ils peuvent notamment couvrir :

- le chargement du module PimsOS ;
- l'initialisation du BuildContext ;
- le Workflow ;
- le Pipeline ;
- le Recovery ;
- la Configuration ;
- les scénarios principaux de Build.

Les tests d'intégration utilisent les contrats réels des composants concernés.

---

## Tests de régression

Lorsqu'un bug est corrigé, un test de régression doit être ajouté lorsque cela est pertinent.

Le processus recommandé est :

1. reproduire le problème ;
2. créer ou adapter le test ;
3. corriger le code ;
4. vérifier que le test échoue avant le correctif lorsque cela est possible ;
5. vérifier qu'il passe après le correctif ;
6. conserver le test pour éviter une régression future.

---

# Contrats à tester

Les tests doivent vérifier les contrats propres à chaque composant.

Selon le composant, cela peut inclure :

- paramètres obligatoires ;
- validation des entrées ;
- comportement nominal ;
- gestion des erreurs ;
- propagation des erreurs ;
- changements de BuildState ;
- mise à jour du BuildContext ;
- statistiques ;
- transmission de l'Action ;
- résolution des providers ;
- appel du handler attendu.

---

# Tests des Engines

Les Engines spécialisés doivent être testés sur leur contrat commun.

Un Engine reçoit notamment :

```text
Context + Action
```

et retourne le contexte mis à jour.

Les tests doivent vérifier, selon le domaine :

- l'exécution nominale ;
- le refus des paramètres invalides ;
- le comportement lorsqu'un provider est absent ;
- la transmission correcte de l'Action ;
- la gestion du succès ;
- la gestion de l'erreur ;
- la mise à jour des statistiques lorsque nécessaire.

Les tests existants couvrent notamment les Engines :

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

---

# Tests des Managers

Les Managers doivent être testés sur leurs contrats techniques.

Les tests couvrent notamment :

- les providers par défaut ;
- l'ordre des providers lorsque pertinent ;
- la présence ou l'absence d'un provider ;
- les paramètres obligatoires ;
- la résolution du handler ;
- le refus d'un handler inexistant ;
- la transmission de l'Action ;
- l'enregistrement d'un provider ;
- la réinitialisation des providers.

Les Managers actuellement concernés comprennent :

- CapabilityManager ;
- CommandManager ;
- DriverManager ;
- EnvironmentManager ;
- FeatureManager ;
- FileManager ;
- FolderManager ;
- PackageManager ;
- ScheduledTaskManager ;
- ShortcutManager.

---

# Tests de configuration

Les tests de configuration doivent notamment vérifier :

- le chargement des catégories ;
- le chargement des Tweaks ;
- le chargement des profils ;
- la fusion Profil + Tweaks ;
- la validation des définitions ;
- la construction de la configuration finale ;
- la conservation des définitions sources.

Les définitions originales des Tweaks ne doivent pas être modifiées par le moteur de configuration.

---

# Tests du BuildContext et du BuildState

Les tests doivent vérifier que :

- le BuildContext est correctement créé ;
- les propriétés obligatoires sont présentes ;
- le BuildState est initialisé correctement ;
- les composants mettent à jour les bonnes propriétés ;
- l'état est conservé correctement entre les étapes ;
- les statistiques sont mises à jour lorsque prévu.

---

# Tests du Pipeline et du Workflow

Les tests doivent vérifier :

- l'ordre des étapes ;
- la propagation du BuildContext ;
- les changements d'état ;
- la gestion des erreurs ;
- le comportement du Recovery ;
- la finalisation du Build ;
- le nettoyage des ressources lorsque cela est prévu.

Le Pipeline ne doit pas contenir de logique métier qui devrait être testée comme appartenant à un composant spécialisé.

---

# Tests du Recovery

Le Recovery doit disposer de tests couvrant notamment :

- la détection de ressources existantes ;
- la validation de l'état d'un montage ;
- la gestion d'un état invalide ;
- le nettoyage ;
- la préparation d'une reprise.

La décision concernant l'état d'un montage WIM est centralisée dans :

```powershell
Test-WimMountState()
```

Les tests doivent protéger cette responsabilité centralisée.

---

# Règles

Chaque nouveau composant important doit être accompagné de tests.

Les tests doivent couvrir, lorsque cela est pertinent :

- le fonctionnement nominal ;
- les paramètres invalides ;
- les erreurs attendues ;
- les cas limites ;
- les régressions connues.

Les tests ne doivent pas contenir de logique métier complexe.

Les tests doivent vérifier le comportement du composant plutôt que sa structure interne lorsque cela est possible.

---

# Exécution

Exécution de l'ensemble des tests :

```powershell
Invoke-Pester
```

Exécution des tests du projet :

```powershell
Invoke-Pester -Path .\Tests\Unit
Invoke-Pester -Path .\Tests\Integration
```

Exécution d'une suite particulière :

```powershell
Invoke-Pester -Path .\Tests\Unit\Modules\CapabilityManager.Tests.ps1 -Output Detailed
```

Pendant le développement, il est recommandé de commencer par les tests directement concernés puis d'élargir la validation lorsque l'impact du changement le justifie.

---

# Validation avant commit

Avant un commit important :

```text
Modification
    ↓
Tests ciblés
    ↓
Analyse des résultats
    ↓
Tests plus larges si nécessaire
    ↓
Validation
    ↓
Commit
```

Une fonctionnalité importante ne doit pas être considérée comme terminée lorsque les tests concernés sont en échec.

---

# Intégration continue

Le projet dispose d'une intégration avec GitHub Actions pour automatiser certaines validations.

La stratégie de tests doit progressivement permettre :

- l'exécution automatique des tests ;
- la détection des régressions ;
- la publication des résultats ;
- le refus d'une validation lorsque les tests obligatoires échouent.

L'intégration exacte dépend de la configuration du dépôt.

---

# Conséquences

## Avantages

- meilleure qualité du code ;
- détection rapide des régressions ;
- contrats mieux documentés ;
- refactoring facilité ;
- maintenance simplifiée ;
- validation reproductible ;
- meilleure confiance dans les nouveaux composants.

## Inconvénients

- temps de développement supplémentaire ;
- maintenance des tests ;
- nécessité de conserver les tests synchronisés avec les contrats du framework.

---

# Alternatives étudiées

## Tests manuels uniquement

Rejetée.

Les tests manuels sont utiles pour certains scénarios mais ne peuvent pas constituer le mécanisme principal de validation automatisée.

---

## Aucun framework de tests

Rejetée.

Le risque de régression serait trop important pour un framework en évolution continue.

---

## Autre framework PowerShell

Non retenu.

Pester constitue le framework de test de référence du projet.

---

# Évolution

La stratégie de tests doit évoluer avec l'architecture du projet.

Toute nouvelle couche ou nouveau contrat important doit être accompagné d'une stratégie de validation adaptée.

L'augmentation de la couverture doit rester orientée vers les composants critiques et les comportements utiles.

L'objectif n'est pas de maximiser le nombre de tests mais de disposer d'une validation fiable et maintenable.

---

# Décision finale

**Pester 5 constitue le framework officiel de tests de PimsOS Builder.**

Les tests sont une partie obligatoire du cycle de développement.

La couverture doit progressivement s'étendre aux composants critiques, aux scénarios d'intégration et aux cas de régression.

---

# Références

- `Testing.md`
- `Lifecycle.md`
- `Architecture.md`
- `ArchitectureRules.md`
- `ADR-0004-BuildPipeline.md`
