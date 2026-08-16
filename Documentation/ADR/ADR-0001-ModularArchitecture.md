# ADR-0001 — Adoption d'une architecture modulaire

- **Statut** : Acceptée
- **Date** : 2026-07-19
- **Dernière mise à jour** : 2026-08-16
- **Décideur** : Pims
- **Impact** : Architecture globale

---

# Contexte

PimsOS est destiné à évoluer progressivement vers un framework complet de création et de personnalisation d'images Windows.

Le projet comprend de nombreux domaines fonctionnels et techniques :

- Builder ;
- Core ;
- Infrastructure ;
- Configuration ;
- Image ;
- Actions ;
- Managers ;
- Package ;
- Windows ;
- Pipeline ;
- Registry ;
- Reporting ;
- Tests.

Une architecture fortement monolithique au niveau du code rendrait ces responsabilités difficiles à isoler, tester et faire évoluer.

Le projet nécessite donc une organisation modulaire des composants tout en conservant une structure cohérente.

---

# Décision

Le projet adopte une **architecture modulaire interne organisée autour d'un module PowerShell unique**.

Les responsabilités sont séparées en composants spécialisés au sein du module PimsOS :

```text
PimsOS
│
├── Infrastructure
├── Core
├── Configuration
├── Image
├── Actions
├── Managers
├── Package
└── Windows
```

Le module public du projet est :

```text
PimsOS
```

avec :

```text
Modules\PimsOS.psd1
Modules\PimsOS.psm1
```

Les composants internes ne constituent pas des modules PowerShell indépendants.

Ils sont chargés et intégrés par :

```text
PimsOS.psm1
```

Cette organisation conserve la modularité au niveau des responsabilités et des composants tout en évitant de multiplier les modules PowerShell publics ou autonomes.

---

# Principes retenus

Chaque composant doit posséder une responsabilité clairement définie.

La séparation porte notamment sur :

- le Core ;
- l'Infrastructure ;
- la Configuration ;
- les Images ;
- les Actions ;
- les Managers ;
- les Providers ;
- les composants Windows.

Les dépendances doivent rester maîtrisées et descendantes.

Les composants internes doivent rester testables indépendamment lorsque cela est pertinent.

---

# Conséquences

## Avantages

- responsabilités clairement séparées ;
- faible couplage ;
- meilleure testabilité ;
- maintenance simplifiée ;
- évolution localisée ;
- réutilisation des composants internes ;
- API publique maîtrisée ;
- chargement centralisé.

## Inconvénients

- organisation plus stricte des composants ;
- davantage de fichiers internes ;
- nécessité de respecter l'ordre et les contrats de chargement ;
- distinction nécessaire entre composants internes et API publique.

---

# Alternatives étudiées

## Architecture monolithique

Rejetée.

Une organisation regroupant l'ensemble de la logique dans quelques composants centraux rendrait les responsabilités difficiles à isoler et limiterait la testabilité.

---

## Modules PowerShell indépendants pour chaque domaine

Rejetée comme architecture de référence actuelle.

Cette approche multiplierait les frontières de modules, les dépendances et la gestion des imports alors que le projet peut conserver une séparation claire des responsabilités à l'intérieur du module PimsOS unique.

---

## Scripts totalement indépendants

Rejetés.

Les dépendances et les contrats entre composants seraient difficiles à gérer et l'API du framework serait moins cohérente.

---

# Évolution depuis la décision initiale

La décision originale du 19/07/2026 prévoyait des frameworks indépendants, chacun pouvant disposer de son propre manifeste, module racine, ressources et tests.

L'architecture a depuis évolué vers un **module PowerShell unique**.

La modularité reste donc un principe architectural, mais elle s'applique désormais aux composants internes du module PimsOS plutôt qu'à une collection de modules PowerShell autonomes.

Cette évolution est cohérente avec :

- ADR-0012 — Module PowerShell unique ;
- `Architecture.md` ;
- `ArchitectureRules.md` ;
- `ModuleGuide.md`.

---

# Décision finale

Toute nouvelle fonctionnalité doit être intégrée au composant existant correspondant à sa responsabilité.

La création d'un nouveau composant est justifiée uniquement lorsqu'une responsabilité distincte apparaît.

La création d'un nouveau module PowerShell indépendant n'est pas le modèle de référence du projet actuel.

Toute évolution importante de cette décision doit être documentée dans une nouvelle ADR.

---

# Références

- `Architecture.md`
- `ArchitectureRules.md`
- `ModuleGuide.md`
- `TechnicalDecisions.md`
- `ADR-0012-ModuleUnique.md`
