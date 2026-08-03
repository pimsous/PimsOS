# ADR-0012 — Architecture à module PowerShell unique

**Statut :** Acceptée

**Date :** 2026-07-26

**Décideurs :** Équipe PimsOS

---

# Contexte

Les premières versions de PimsOS étaient organisées sous la forme de plusieurs sous-modules PowerShell (`.psm1`) indépendants.

Chaque composant fonctionnel (Logger, Report, Check, Workflow, Registry, etc.) était implémenté comme un module distinct puis chargé via `NestedModules` dans le manifeste `PimsOS.psd1`.

Cette approche présentait plusieurs avantages :

- séparation logique des composants ;
- organisation claire du code ;
- possibilité théorique de réutiliser certains modules.

Cependant, au fur et à mesure de l'évolution du projet, plusieurs limites sont apparues.

Les sous-modules possèdent chacun leur propre espace de noms (Module Scope).

Cette isolation entraîne notamment :

- des difficultés de visibilité entre composants ;
- une gestion complexe des dépendances internes ;
- des appels implicites difficiles à maintenir ;
- des problèmes liés à `Export-ModuleMember` ;
- une complexité croissante du chargement des modules.

Ces difficultés sont apparues notamment lors de l'intégration des composants :

- Logger
- Report
- Check
- BuildContext
- Workflow
- Registry

Le projet PimsOS n'a pas vocation à distribuer ces composants individuellement.

Ils constituent uniquement des briques internes d'un même framework.

---

# Décision

PimsOS adopte une architecture basée sur **un module PowerShell unique**.

Le module public est :

```
PimsOS
```

Il est composé de deux éléments principaux :

```
PimsOS.psd1
PimsOS.psm1
```

## PimsOS.psd1

Le manifeste décrit le module.

Il contient uniquement :

- les métadonnées ;
- la version ;
- les dépendances externes ;
- les informations de publication.

Il ne contient aucune logique métier.

Il ne réalise pas le chargement des composants internes.

---

## PimsOS.psm1

Le fichier `PimsOS.psm1` constitue le point d'entrée du framework.

Il est responsable :

- du chargement des composants internes ;
- de l'initialisation du framework ;
- de l'exposition de l'API publique.

Il représente l'unique façade du projet.

---

## Composants internes

Les dossiers :

```
Infrastructure/
Core/
Configuration/
Windows/
Image/
Actions/
```

contiennent des composants internes.

Ces composants :

- ne sont pas des modules publics ;
- ne doivent pas être importés individuellement ;
- partagent le même espace de noms.

Ils collaborent librement entre eux.

---

## API publique

L'ensemble des fonctions publiques est exporté exclusivement depuis :

```
PimsOS.psm1
```

Les composants internes ne doivent plus utiliser `Export-ModuleMember`.

---

# Conséquences

Cette décision apporte plusieurs avantages.

## Simplicité

Un seul point d'entrée.

Un seul mécanisme de chargement.

Une seule API publique.

---

## Cohérence

Tous les composants appartiennent au même framework.

Les responsabilités sont clairement séparées tout en partageant le même contexte d'exécution.

---

## Maintenabilité

Les dépendances deviennent explicites.

Les problèmes de portée (`Scope`) disparaissent.

Les composants peuvent collaborer naturellement.

---

## Évolutivité

L'ajout d'un nouveau composant ne nécessite pas la création d'un nouveau module PowerShell.

Il suffit de l'intégrer au framework.

---

## Testabilité

Les composants restent testables individuellement.

Le framework reste testable dans son ensemble.

---

# Alternatives étudiées

## Option 1 — Sous-modules indépendants

Chaque composant reste un module PowerShell autonome.

### Avantages

- séparation forte ;
- réutilisation théorique.

### Inconvénients

- complexité du chargement ;
- problèmes de portée ;
- dépendances difficiles à maintenir ;
- multiplication des exports.

Cette option a été abandonnée.

---

## Option 2 — Module unique (retenue)

Tous les composants appartiennent au module PimsOS.

### Avantages

- simplicité ;
- cohérence ;
- maintenance facilitée ;
- API unique.

Cette option est retenue.

---

# Migration

La migration sera réalisée progressivement.

Les étapes prévues sont :

1. mise à jour de la documentation ;
2. transformation de `PimsOS.psm1` en chargeur unique ;
3. suppression progressive des `NestedModules` ;
4. suppression des `Export-ModuleMember` internes ;
5. centralisation de l'API publique ;
6. simplification de `Build-PimsOS.ps1`.

---

# Impact sur l'architecture

Cette décision ne modifie pas l'organisation fonctionnelle du projet.

Les dossiers :

- Infrastructure
- Core
- Configuration
- Windows
- Image
- Actions

sont conservés.

Seule la stratégie de chargement évolue.

---

# Références

- Architecture.md
- BuildContext.md
- ADR-0002 — BuildContext central
- ADR-0005 — Journalisation centralisée
- ADR-0009 — Dépendances entre frameworks

---

# Statut

Cette ADR est applicable à toutes les nouvelles évolutions du projet.

Toute nouvelle fonctionnalité devra respecter cette architecture.