# PimsOS Builder - Changelog

Toutes les modifications importantes du projet **PimsOS Builder** sont documentées dans ce fichier.

Le format s'inspire de **Keep a Changelog** et respecte le versionnement sémantique (**SemVer**).

---

# [Unreleased]

## Added

### Engines et Managers

- Ajout et stabilisation progressive des Engines spécialisés :
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
- Ajout et stabilisation progressive des Managers :
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
- Ajout des contrats de providers pour les Managers concernés.
- Ajout de tests unitaires dédiés aux Managers et Engines.

### Tests

- Extension importante de la couverture Pester.
- Ajout de tests spécifiques aux Engines spécialisés.
- Ajout de tests spécifiques aux Managers.
- Ajout de tests de régression pour plusieurs comportements corrigés.

### Documentation

- Synchronisation de la documentation avec l'architecture technique 3.0.0.
- Mise à jour des documents d'architecture, BuildContext, configuration, tests et développement.
- Mise à jour des ADR pour refléter le module PowerShell unique et l'architecture actuelle.

---

## Changed

### Architecture

- Stabilisation du modèle de **module PowerShell unique**.
- `PimsOS.psm1` constitue le point d'entrée interne du framework.
- L'API publique est centralisée et limitée aux fonctions explicitement exportées.
- `Initialize-PimsOS` constitue l'entrée publique fonctionnelle actuelle.
- Les composants internes ne sont plus considérés comme des modules PowerShell indépendants.
- Les responsabilités restent séparées entre :
  - Core ;
  - Infrastructure ;
  - Configuration ;
  - Image ;
  - Actions ;
  - Managers ;
  - Package ;
  - Windows.

### BuildContext / BuildState

- `BuildContext` reste le contrat central du Build.
- `BuildState` centralise désormais l'état d'exécution.
- Les informations du Build et son état d'exécution sont mieux séparés.
- Les composants enrichissent le contexte sans créer de contexte parallèle.

### Actions

- Routage centralisé des Actions via `ActionEngine` et `ActionRegistry`.
- Séparation renforcée entre :
  - logique métier des Engines ;
  - opérations techniques des Managers.
- Standardisation progressive du contrat `Context + Action → Context`.

### Configuration

- Les définitions de Tweaks restent séparées des profils.
- Les profils produisent une configuration destinée à l'exécution.
- Les définitions sources des Tweaks ne sont pas modifiées lors de la fusion.
- Validation renforcée des données de configuration.

### Providers

- Standardisation de la résolution :
  - `Provider`
  - `Handler`
- Ajout de mécanismes d'enregistrement et de réinitialisation des providers pour les Managers qui le prévoient.

### Versioning

- `version.json` reste la source officielle des métadonnées générales du projet.
- La version technique actuelle du framework est `3.0.0`.

---

## Improved

### Build

- Amélioration de la circulation du BuildContext.
- Meilleur suivi de l'état du Build.
- Amélioration de la propagation des erreurs.
- Amélioration de la traçabilité des étapes.
- Stabilisation du Workflow et du Pipeline.
- Amélioration de la finalisation du Build.

### Actions et Managers

- Validation plus homogène des paramètres.
- Meilleure gestion des erreurs des Actions.
- Meilleure homogénéité des résultats d'exécution.
- Meilleure gestion des providers et handlers.
- Renforcement des statistiques lorsque les composants concernés les utilisent.

### Tests

- Validation systématique des scénarios nominaux.
- Validation des paramètres obligatoires.
- Validation des erreurs attendues.
- Renforcement des tests de régression.
- Détection et correction d'un problème lié à l'utilisation de `ContainsKey()` sur des dictionnaires ordonnés PowerShell.

### Documentation

- Synchronisation progressive avec le code réel.
- Suppression des anciennes références à l'architecture multi-modules dans les documents actifs.
- Mise à jour des conventions de développement.
- Mise à jour de la stratégie de tests.
- Mise à jour des ADR.

---

## Fixed

- Correction de la propagation incorrecte du `BuildContext`.
- Correction de la mise à jour de l'état de chargement de la configuration.
- Correction de la création de clés Registry.
- Correction de la détection de certains providers.
- Correction de l'utilisation de `ContainsKey()` avec des `OrderedDictionary`.
- Correction de plusieurs incohérences dans la propagation des erreurs des Engines.
- Correction de plusieurs incohérences dans la gestion des statistiques.
- Correction de plusieurs écarts entre les contrats des Managers et leurs tests.
- Correction de diverses incohérences documentaires héritées des versions précédentes.

---

## Tests

Les validations actuelles couvrent notamment :

- BuildContext ;
- BuildState ;
- Configuration ;
- ActionRegistry ;
- ActionEngine ;
- Engines spécialisés ;
- Managers ;
- Registry ;
- chargement et comportement du module PimsOS.

Les suites de tests des Managers suivantes ont notamment été validées :

- `CapabilityManager`
- `CommandManager`
- `DriverManager`
- `EnvironmentManager`
- `FeatureManager`
- `FileManager`
- `FolderManager`
- `PackageManager`
- `ScheduledTaskManager`
- `ShortcutManager`

---

## Known issues

Les éléments suivants restent en cours de finalisation :

- génération complète de l'ISO finale ;
- validation complète d'un Build de bout en bout ;
- provider Chocolatey ;
- provider Winget ;
- implémentation complète de `Converters.ps1` ;
- couverture complémentaire de `Recovery.ps1` ;
- couverture complémentaire de `Security.ps1` ;
- enrichissement du Reporting ;
- extension des scénarios d'intégration.

La version technique `3.0.0` ne constitue pas encore une release finale stable du produit.

---

# [3.0.0] - 2026-08-16

## Added

### Architecture

- Stabilisation de l'architecture autour d'un module PowerShell unique.
- Centralisation du chargement des composants dans `PimsOS.psm1`.
- Centralisation de l'API publique.
- Renforcement du BuildContext comme contrat central.
- Introduction et stabilisation de `BuildState`.

### Configuration

- Stabilisation du chargement des catégories.
- Stabilisation du chargement des Tweaks.
- Stabilisation du chargement des profils.
- Fusion des profils et des Tweaks.
- Validation des définitions de configuration.
- Construction de la configuration finale.

### Actions

- `ActionRegistry`.
- `ActionEngine`.
- Engines spécialisés pour les principaux types d'Actions.

### Managers

- Managers spécialisés pour les domaines pris en charge.
- Providers techniques et handlers associés.

### Tests

- Extension importante de la couverture Pester.
- Tests unitaires dédiés aux Engines.
- Tests unitaires dédiés aux Managers.
- Tests de régression.

---

## Changed

### Architecture

- Abandon du modèle de plusieurs modules PowerShell indépendants comme architecture de référence.
- Les composants internes appartiennent désormais au module PimsOS unique.
- Les fonctions internes ne constituent pas automatiquement une API publique.

### Build

- Séparation renforcée entre orchestration et traitement métier.
- Workflow et Pipeline mieux séparés.
- Routage des Actions centralisé.

### Configuration

- Séparation entre définitions de Tweaks, profils et configuration finale.

---

## Improved

- Cohérence des contrats entre les couches.
- Propagation du BuildContext.
- Gestion des erreurs.
- Gestion des providers.
- Couverture de tests.
- Documentation technique.

---

## Fixed

- Problèmes liés aux dictionnaires ordonnés et `ContainsKey()`.
- Plusieurs incohérences de propagation du contexte.
- Plusieurs incohérences des statistiques et des états.
- Plusieurs écarts entre les contrats des Managers et leur implémentation.

---

## Known issues

- Génération finale de l'ISO encore en finalisation.
- Providers Chocolatey et Winget à compléter.
- `Converters.ps1` à implémenter.
- Couverture supplémentaire de Recovery et Security à prévoir.
- Reporting à enrichir.

---

# Historique antérieur

## [0.2.0] - 2026-07-12

### Added

- Module `Recovery.psm1`.
- Module `Dism.psm1`.
- Moteur de configuration.
- Moteur Registry.
- `BuildContext`.
- Pipeline de Build.
- Résumé du Build.
- Support des profils.
- Support des Tweaks JSON.
- Support des Actions Registry.

### Changed

- Première modularisation importante de l'architecture.
- Séparation progressive des responsabilités.
- Centralisation du contexte.
- Journalisation homogène.
- Réorganisation du Pipeline.

### Improved

- Préparation automatique de l'environnement.
- Vérification des montages DISM.
- Vérification des ruches Registry.
- Nettoyage automatique du Workspace.
- Validation après nettoyage.
- Factorisation des contrôles internes.
- Suppression progressive des diagnostics `Write-Host`.
- Amélioration de la robustesse du montage WIM.

### Fixed

- Gestion des anciens montages DISM.
- Gestion des ruches Registry orphelines.
- Nettoyage automatique du Workspace.
- Correction de plusieurs erreurs liées au montage des images Windows.

### Known issues

- Gestion automatique complète des images ISO non encore finalisée.

---

## [0.1.0]

### Added

- `Core.psm1`.
- `Logger.psm1`.
- `Build-PimsOS.ps1`.
- `config.json`.

### Changed

- Première architecture du projet.

### Fixed

- Détection initiale du projet.

---

# Politique de version

Le projet suit **Semantic Versioning (SemVer)** :

```text
MAJOR.MINOR.PATCH
```

- `MAJOR` : changement incompatible ;
- `MINOR` : nouvelle fonctionnalité compatible ;
- `PATCH` : correction compatible.

Les versions de développement peuvent également utiliser un suffixe explicite lorsque cela est nécessaire, par exemple :

```text
3.0.0-dev
```

---

# Références

- `ReleaseNotes.md`
- `ProjectStatus.md`
- `Roadmap.md`
- `Milestones.md`
- `TechnicalDecisions.md`
- `Documentation\ADR\`

## [Unreleased]

### Added

- Ajout du sous-système PostInstall.
- Ajout de la gestion d'état PostInstall.
- Ajout de la gestion réseau et de l'attente réseau.
- Ajout du Bootstrap FirstBoot.
- Ajout de la génération `unattend.xml`.
- Ajout de l'installation du runtime PostInstall dans le WIM.
- Ajout de l'étape `PreparePostInstall` au pipeline.
- Ajout des tests unitaires et d'intégration correspondants.

### Validation

- 80 tests PostInstall/FirstBoot/Installer verts.
- 17 tests BuildPipeline verts.
- validation réelle de l'injection dans un WIM Windows 11 Professionnel.

### Not yet validated

- exécution réelle de FirstLogonCommands lors de la première connexion ;
- reprise réseau complète ;
- finalisation Chocolatey, Winget et Microsoft Store.
