# Changelog

Toutes les modifications importantes du projet **PimsOS Builder** sont documentées dans ce fichier.

Le format s'inspire de **Keep a Changelog** et respecte le versionnement sémantique (SemVer).

---

# [Unreleased]

## Added

### Moteur de build

- Création de l'objet `BuildState`.
- Intégration de `BuildState` dans le `BuildContext`.
- Suivi centralisé de l'état du moteur de build.
- Ajout des états :
  - Recovery ;
  - Environment ;
  - Pipeline ;
  - Image ;
  - Success ;
  - Completed.
- Gestion centralisée de l'état des montages ISO, WIM et du registre.

### BuildContext

- Enrichissement du `BuildContext`.
- Ajout des informations du projet :
  - Version ;
  - Auteur ;
  - Société ;
  - Dépôt Git ;
  - Version de Windows cible.
- Ajout des informations complètes du Workspace.
- Ajout des statistiques du moteur.
- Centralisation de la configuration du Builder.

### Versioning

- Nouveau fichier `version.json`.
- Lecture automatique des informations du projet.
- Support de :
  - Version ;
  - Auteur ;
  - Company ;
  - Repository ;
  - Windows.Release ;
  - Windows.Build.

### Configuration

- Nouveau moteur de `ConfigurationItem`.
- Fusion des profils sans modifier les définitions originales des Tweaks.
- Ajout des métadonnées de catégorie dans les `ConfigurationItem`.
- Séparation complète entre :
  - Tweaks ;
  - Profils ;
  - Configuration.

### Compatibilité Windows

- Préparation du Builder à la personnalisation de plusieurs versions officielles de Windows.
- Suppression de plusieurs dépendances à une version unique de Windows.
- Centralisation des informations de version dans `version.json`.

### Documentation

- Refonte complète de la documentation technique.
- Documentation du `BuildContext`.
- Documentation du `BuildState`.
- Documentation du Pipeline.
- Documentation de la configuration.
- Synchronisation de la documentation avec l'architecture actuelle.

---

## Changed

### Architecture

- Le `BuildContext` devient la source de vérité du moteur de build.
- `BuildState` centralise désormais l'état d'avancement du Builder.
- Le Pipeline se limite désormais à l'orchestration des étapes.
- Les décisions métier sont progressivement déplacées vers les moteurs spécialisés.

### Configuration

- Les Tweaks deviennent des définitions immuables.
- Les profils produisent désormais une `Configuration` composée de `ConfigurationItem`.
- Les personnalisations sont appliquées uniquement à partir de cette Configuration.

### Versioning

- Les informations du projet ne sont plus codées en dur.
- Elles sont chargées automatiquement depuis `version.json`.

---

## Improved

- Architecture du moteur de build simplifiée.
- Meilleure séparation entre les données et l'exécution.
- Préparation des futurs moteurs spécialisés.
- Amélioration de la lisibilité du Pipeline.
- Meilleure traçabilité des étapes du Build.
- Préparation du support de plusieurs versions de Windows.

---

## Fixed

- Correction de plusieurs incohérences du `BuildContext`.
- Correction du chargement de `version.json`.
- Correction de l'initialisation des informations du projet.
- Correction de la fusion des profils.
- Correction des `ConfigurationItem`.
- Correction des propriétés des objets métier.
- Correction de plusieurs états du Pipeline.
- Correction de la gestion des Tweaks activés.

---

## Tests

- Validation complète du nouveau `BuildContext`.
- Validation du nouveau `BuildState`.
- Validation du chargement de `version.json`.
- Validation du moteur de configuration.
- Validation de la fusion des profils.
- Validation de l'application des Tweaks.
- Validation d'un cycle complet de build :
  - Recovery ;
  - Environment ;
  - Pipeline ;
  - Configuration ;
  - Registry ;
  - Commit ;
  - Cleanup.

---

## Known issues

- Les moteurs spécialisés (Services, Packages, Drivers, Features, Files et Folders) sont encore en développement.
- La génération de l'image ISO finale n'est pas encore implémentée.
- Les rapports de build sont en cours d'évolution.

---

# [0.2.0] - 2026-07-12

## Added

- Module `Recovery.psm1`.
- Module `Dism.psm1`.
- Moteur de configuration.
- Moteur Registry.
- `BuildContext`.
- Pipeline de build.
- Résumé du build.
- Support des profils.
- Support des tweaks JSON.
- Support des actions Registry.

---

## Changed

- Architecture entièrement modularisée.
- Séparation des responsabilités.
- Centralisation du contexte.
- Journalisation homogène.
- Réorganisation du pipeline.

---

## Improved

- Préparation automatique de l'environnement.
- Vérification des montages DISM.
- Vérification des ruches Registry.
- Nettoyage automatique du Workspace.
- Validation après nettoyage.
- Factorisation des contrôles internes.
- Suppression des diagnostics `Write-Host`.
- Amélioration de la robustesse du montage WIM.

---

## Fixed

- Gestion des anciens montages DISM.
- Gestion des ruches Registry orphelines.
- Nettoyage automatique du Workspace.
- Correction de plusieurs erreurs liées au montage des images Windows.

---

## Known issues

- Gestion automatique des images ISO non encore implémentée.

---

# [0.1.0]

## Added

- `Core.psm1`
- `Logger.psm1`
- `Build-PimsOS.ps1`
- `config.json`

---

## Changed

- Première architecture du projet.

---

## Fixed

- Détection du projet.