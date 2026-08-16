# ADR-0012 — Architecture à module PowerShell unique

- **Statut** : Acceptée
- **Date** : 2026-07-26
- **Dernière mise à jour** : 2026-08-16
- **Décideur** : Pims
- **Impact** : Architecture globale du framework

---

# Contexte

Les premières versions de PimsOS étaient organisées sous la forme de plusieurs sous-modules PowerShell (`.psm1`) indépendants.

Chaque composant fonctionnel pouvait être implémenté comme un module distinct puis chargé via `NestedModules` dans le manifeste `PimsOS.psd1`.

Cette approche présentait plusieurs avantages :

- séparation logique des composants ;
- organisation claire du code ;
- possibilité théorique de réutiliser certains composants indépendamment.

Cependant, au fur et à mesure de l'évolution du projet, plusieurs limites sont apparues.

Les sous-modules possèdent chacun leur propre espace de noms et leur propre portée de module.

Cette isolation entraînait notamment :

- des difficultés de visibilité entre composants ;
- une gestion complexe des dépendances internes ;
- des problèmes liés à `Export-ModuleMember` ;
- une complexité croissante du chargement ;
- des contrats internes difficiles à maintenir.

Ces difficultés ont notamment concerné l'intégration de composants tels que :

- Logger ;
- Report ;
- Check ;
- BuildContext ;
- Workflow ;
- Registry.

Le projet PimsOS n'a pas vocation à distribuer ces composants individuellement.

Ils constituent des briques internes d'un même framework de Build.

---

# Décision

PimsOS adopte une architecture basée sur **un module PowerShell unique**.

Le module public est :

```text
PimsOS
```

Il repose principalement sur :

```text
Modules\PimsOS.psd1
Modules\PimsOS.psm1
```

Les composants internes sont chargés par `PimsOS.psm1`.

---

# PimsOS.psd1

Le manifeste décrit le module.

Il contient notamment :

- les métadonnées ;
- la version du module ;
- la compatibilité PowerShell ;
- les fonctions exportées ;
- les informations nécessaires à l'identification du module.

Il ne contient pas la logique métier du Builder.

Il ne constitue pas le mécanisme de chargement des composants internes.

---

# PimsOS.psm1

Le fichier `PimsOS.psm1` constitue le point d'entrée du framework.

Il est responsable notamment :

- du chargement des composants internes ;
- du respect de leur ordre de chargement ;
- de l'initialisation du framework ;
- de l'exposition de l'API publique.

L'API publique actuelle est volontairement minimale :

```powershell
Initialize-PimsOS
```

`PimsOS.psm1` constitue la façade unique du framework.

---

# Composants internes

Les composants sont organisés par responsabilité dans les sous-répertoires de `Modules` :

```text
Modules
│
├── Actions
├── Configuration
├── Core
├── Image
├── Infrastructure
├── Managers
├── Package
├── Windows
├── PimsOS.psd1
└── PimsOS.psm1
```

Ces composants :

- ne sont pas des modules PowerShell publics indépendants ;
- ne doivent pas être importés individuellement ;
- font partie du module PimsOS ;
- peuvent collaborer selon les dépendances définies par l'architecture.

---

# API publique

L'ensemble des fonctions publiques est exporté exclusivement depuis :

```text
PimsOS.psm1
```

Les composants internes ne doivent pas utiliser `Export-ModuleMember` pour créer leur propre API publique.

Une fonction interne n'est publique que si elle est explicitement exportée par le module principal.

L'API actuelle est :

```powershell
Initialize-PimsOS
```

---

# Espace d'exécution commun

L'un des objectifs du module unique est de permettre aux composants internes de collaborer dans le même espace d'exécution du module.

Cette organisation simplifie notamment :

- le partage des fonctions internes ;
- le respect des contrats internes ;
- le chargement des dépendances ;
- le diagnostic ;
- les tests.

Le module unique ne supprime pas la séparation des responsabilités.

La modularité reste assurée par l'organisation des composants et des couches.

---

# BuildContext

Le modèle du module unique s'appuie sur le BuildContext comme contrat central de données du Build.

Le BuildContext est créé au début du processus puis transmis aux composants concernés.

Le module unique ne remplace donc pas le BuildContext et ne doit pas être utilisé pour créer un état global implicite.

Le BuildContext reste la structure de référence pour partager les informations et l'état du Build.

---

# Conséquences

Cette décision apporte plusieurs avantages.

## Simplicité

- un seul module public ;
- un seul point d'entrée ;
- un seul mécanisme de chargement ;
- une seule API publique ;
- moins de frontières de modules à gérer.

---

## Cohérence

Tous les composants appartiennent au même framework.

Les responsabilités restent séparées, tout en utilisant les mêmes contrats internes et le même contexte d'exécution du module.

---

## Maintenabilité

Les dépendances internes sont gérées dans le module principal.

La suppression des multiples frontières de modules réduit notamment les problèmes liés aux imports, aux exports et aux portées de modules.

---

## Évolutivité

L'ajout d'un nouveau composant ne nécessite pas automatiquement la création d'un nouveau module PowerShell.

Il suffit de l'intégrer dans la couche appropriée et de le charger depuis `PimsOS.psm1`.

---

## Testabilité

Les composants peuvent continuer à être testés individuellement.

Le framework complet peut également être testé via son API publique.

L'encapsulation du module n'a pas besoin d'être cassée uniquement pour permettre les tests.

---

# Alternatives étudiées

## Option 1 — Sous-modules indépendants

Chaque composant reste un module PowerShell autonome.

### Avantages

- séparation forte ;
- réutilisation théorique des composants ;
- frontières de module explicites.

### Inconvénients

- complexité du chargement ;
- problèmes de portée ;
- dépendances difficiles à maintenir ;
- multiplication des exports ;
- coordination plus complexe des composants internes.

Cette option a été abandonnée comme architecture de référence du Builder.

---

## Option 2 — Module unique

Tous les composants appartiennent au module PimsOS.

### Avantages

- simplicité ;
- cohérence ;
- chargement centralisé ;
- API unique ;
- collaboration interne simplifiée ;
- maintenance facilitée.

Cette option est retenue.

---

# Migration historique

La migration vers le module unique a été réalisée progressivement.

Les principales étapes ont été :

1. centralisation du point d'entrée ;
2. adaptation de `PimsOS.psm1` pour charger les composants ;
3. suppression progressive des `NestedModules` ;
4. suppression des `Export-ModuleMember` internes ;
5. centralisation de l'API publique ;
6. adaptation du Build ;
7. validation du chargement du module ;
8. ajout et renforcement des tests Pester.

La migration n'est plus considérée comme une fonctionnalité future : le module unique constitue désormais l'architecture de référence.

---

# Impact sur l'architecture

Cette décision ne supprime pas l'organisation fonctionnelle du projet.

Les domaines restent séparés :

- Infrastructure ;
- Core ;
- Configuration ;
- Image ;
- Actions ;
- Managers ;
- Package ;
- Windows.

La décision porte sur la **stratégie de modularisation PowerShell et de chargement**, pas sur la suppression de la modularité fonctionnelle.

---

# Règles

Tout nouveau composant doit :

- appartenir au module PimsOS ;
- être placé dans le domaine fonctionnel approprié ;
- respecter les dépendances définies par l'architecture ;
- être chargé par `PimsOS.psm1` ;
- rester interne sauf décision explicite d'exposition publique ;
- disposer des tests nécessaires.

Les composants internes ne doivent pas :

- créer un nouveau module PowerShell indépendant sans décision architecturale ;
- utiliser `Import-Module` pour charger un autre composant interne ;
- définir leur propre API publique ;
- utiliser `Export-ModuleMember` pour contourner l'API centrale.

---

# Chargement des composants

Le chargement des composants internes est centralisé par :

```text
Modules\PimsOS.psm1
```

L'ordre de chargement doit respecter les dépendances nécessaires au fonctionnement du module.

Le modèle attendu est :

```text
Infrastructure
        │
        ▼
Core
        │
        ▼
Configuration
        │
        ▼
Managers / Package / Windows / Image
        │
        ▼
Actions
```

L'ordre exact est défini par les appels présents dans `PimsOS.psm1`.

---

# Évolution future

Toute proposition visant à revenir à plusieurs modules PowerShell indépendants doit être considérée comme une évolution architecturale majeure.

Elle doit :

1. démontrer un besoin réel ;
2. comparer les bénéfices et les coûts ;
3. analyser l'impact sur l'API ;
4. analyser l'impact sur le BuildContext ;
5. analyser l'impact sur les tests ;
6. faire l'objet d'une nouvelle décision architecturale lorsque nécessaire.

Le module unique reste le modèle de référence de PimsOS Builder 3.0.0.

---

# Décision finale

**PimsOS Builder utilise un module PowerShell unique.**

Les composants fonctionnels restent séparés par responsabilité mais sont chargés et exposés depuis le module principal.

Le modèle de référence est :

```text
PimsOS.psd1
      │
      ▼
PimsOS.psm1
      │
      ├── Infrastructure
      ├── Core
      ├── Configuration
      ├── Image
      ├── Managers
      ├── Package
      ├── Windows
      └── Actions
```

L'API publique est centralisée et minimale :

```powershell
Initialize-PimsOS
```

Toute nouvelle évolution doit respecter cette architecture tant qu'une nouvelle décision architecturale ne vient pas la remplacer.

---

# Références

- `Architecture.md`
- `ArchitectureRules.md`
- `BuildContext.md`
- `ModuleGuide.md`
- `API.md`
- `ADR-0001-ModularArchitecture.md`
- `ADR-0002-BuildContext.md`
- `ADR-0003-FrameworkStructure.md`
- `ADR-0009-FrameworkDependencies.md`
