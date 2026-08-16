# PimsOS Builder - Notes de version

## Objectif

Ce document présente les principales évolutions de chaque version de **PimsOS Builder**.

Les notes de version mettent en avant les changements importants pour les utilisateurs et les développeurs.

Contrairement au `CHANGELOG.md`, qui recense les modifications techniques détaillées, ce document présente les évolutions majeures, les améliorations, les corrections et les changements importants.

---

# Format

Chaque version documente, lorsque cela est pertinent :

- nouveautés ;
- améliorations ;
- corrections ;
- changements incompatibles (Breaking Changes) ;
- problèmes connus.

---

# Version 3.0.0

## État

🚧 Développement / architecture stabilisée

La version 3.0.0 représente l'état technique actuel du framework.

Elle ne constitue pas encore une release complète du produit.

---

## Nouveautés

### Architecture

- Stabilisation du modèle de module PowerShell unique.
- Centralisation du chargement des composants dans `PimsOS.psm1`.
- Centralisation de l'API publique.
- Renforcement du BuildContext comme contrat central.
- Mise en place et stabilisation de l'ActionRegistry.
- Routage centralisé des Actions par `ActionEngine`.

### Configuration

- Stabilisation du chargement des catégories.
- Stabilisation du chargement des Tweaks.
- Stabilisation du chargement des profils.
- Fusion des profils et des Tweaks.
- Validation des définitions de configuration.
- Construction de la configuration finale dans le BuildContext.

### Engines

Les Engines suivants sont désormais implémentés :

- `RegistryEngine`
- `ServiceEngine`
- `PackageEngine`
- `DriverEngine`
- `FeatureEngine`
- `CapabilityEngine`
- `CommandEngine`
- `FileEngine`
- `FolderEngine`
- `EnvironmentEngine`
- `ScheduledTaskEngine`
- `ShortcutEngine`

### Managers

Les Managers suivants sont désormais implémentés :

- `PackageManager`
- `DriverManager`
- `FeatureManager`
- `CapabilityManager`
- `CommandManager`
- `FileManager`
- `FolderManager`
- `EnvironmentManager`
- `ScheduledTaskManager`
- `ShortcutManager`

### Tests

- Extension importante de la couverture Pester.
- Ajout de tests dédiés aux Engines.
- Ajout de tests dédiés aux Managers.
- Renforcement des tests du système de configuration.
- Renforcement des tests du module Registry.
- Ajout de tests de régression sur plusieurs comportements corrigés.

---

## Améliorations

### Core

- Stabilisation du BuildContext.
- Stabilisation du BuildState.
- Stabilisation du Workflow.
- Stabilisation du Pipeline.
- Amélioration de la finalisation du Build.

### Actions

- Routage centralisé via `ActionRegistry`.
- Séparation plus stricte entre Engines et Managers.
- Gestion homogène des états `Success`, `Duration` et `Error`.
- Amélioration de la gestion des erreurs des Actions.

### Managers

- Normalisation des mécanismes de sélection des providers.
- Validation systématique des paramètres.
- Amélioration de la gestion des handlers.
- Correction de plusieurs problèmes liés aux dictionnaires ordonnés PowerShell.

### Configuration

- Meilleure propagation de l'état dans le BuildContext.
- Mise à jour des indicateurs de chargement de la configuration.
- Validation renforcée des définitions.
- Tests de régression ajoutés.

### Documentation

- Synchronisation progressive de la documentation avec l'état réel du code.
- Mise à jour de l'architecture documentée.
- Mise à jour des règles d'architecture.
- Mise à jour du statut, des jalons et de la roadmap.
- Mise à jour de la stratégie de tests.

---

## Corrections

Les tests et la stabilisation de la version 3.0.0 ont notamment permis de corriger :

- la propagation incorrecte du BuildContext ;
- la mise à jour de l'état de chargement de la configuration ;
- la création de clés Registry ;
- plusieurs problèmes de détection des providers ;
- l'utilisation incorrecte de `ContainsKey()` avec des dictionnaires ordonnés ;
- la propagation des erreurs dans les Engines ;
- plusieurs incohérences de gestion des statistiques ;
- des incohérences entre les contrats des Managers et leurs tests.

---

## Breaking Changes

La version 3.0.0 poursuit et stabilise les changements introduits par l'architecture du module unique.

Principes importants :

- `PimsOS.psm1` constitue le module central.
- `Initialize-PimsOS` constitue le point d'entrée public fonctionnel.
- Les composants internes ne sont pas des modules PowerShell indépendants.
- Les fonctions internes ne constituent pas automatiquement une API publique.
- Le BuildContext constitue le contrat central entre les composants.

Les anciennes architectures basées sur plusieurs modules indépendants ne constituent plus le modèle de référence.

---

## Problèmes connus

Les éléments suivants restent en développement :

- finalisation complète de la génération de l'ISO ;
- validation complète d'un Build de bout en bout ;
- implémentation du provider Chocolatey ;
- implémentation du provider Winget ;
- implémentation de `Converters.ps1` ;
- couverture complémentaire de `Recovery.ps1` ;
- couverture complémentaire de `Security.ps1` ;
- enrichissement du Reporting.

La version 3.0.0 ne doit donc pas encore être considérée comme une release stable finale.

---

# Historique

## Version 0.3.0-dev

### État

🚧 Historique

Cette version correspond à une étape précédente du développement du Builder.

### Principales évolutions

- migration vers un module PowerShell unique ;
- introduction de `Initialize-PimsOS` ;
- restructuration du Pipeline ;
- introduction du mécanisme Recovery ;
- gestion des images WIM ;
- gestion des images ISO ;
- gestion des ruches du registre ;
- chargement de la configuration ;
- chargement des profils ;
- fusion des profils et des Tweaks ;
- validation de la configuration ;
- sélection interactive de l'image Windows ;
- introduction de `Test-WimMountState()` ;
- premiers tests Pester ;
- centralisation des informations du projet dans `version.json`.

### Corrections historiques

- correction de la gestion des montages DISM invalides ;
- amélioration de la logique de reprise ;
- amélioration de la copie du WIM ;
- amélioration de la gestion des erreurs du Pipeline.

---

# Versions futures

Les prochaines versions seront documentées selon le modèle suivant.

---

# Version X.Y.Z

## État

- En développement
- Publiée
- Maintenance

---

## Nouveautés

...

---

## Améliorations

...

---

## Corrections

...

---

## Breaking Changes

...

---

## Problèmes connus

...

---

# Politique de version

Le projet suit le principe du **Semantic Versioning (SemVer)**.

Format :

```text
MAJOR.MINOR.PATCH
```

- **MAJOR** : changements incompatibles.
- **MINOR** : nouvelles fonctionnalités compatibles.
- **PATCH** : corrections de bugs.

Exemple :

```text
3.0.1
```

---

# Références

Consulter également :

- CHANGELOG.md
- Milestones.md
- Roadmap.md
- ProjectStatus.md
- Testing.md