# PimsOS Builder - Feuille de route

> Version technique : 3.0.0
>
> Statut : Développement / architecture stabilisée
>
> Dernière mise à jour : 2026-08-16

---

# Objectif

Cette feuille de route présente les grandes orientations du projet **PimsOS Builder**.

Elle décrit les évolutions prévues pour le framework, le moteur de Build et les fonctionnalités permettant de construire des images Windows personnalisées.

Elle présente les objectifs à moyen et long terme sans remplacer le backlog technique détaillé.

Les évolutions importantes de l'architecture sont documentées dans les **Architecture Decision Records (ADR)**.

---

# Vision

PimsOS Builder a pour objectif de devenir un framework capable de construire automatiquement des images Windows personnalisées à partir d'images compatibles.

Le moteur doit rester indépendant d'une version spécifique de Windows et pouvoir évoluer avec les versions compatibles avec les mécanismes de déploiement utilisés.

Le projet repose notamment sur les principes suivants :

- modularité ;
- automatisation ;
- reproductibilité ;
- maintenabilité ;
- testabilité ;
- séparation claire des responsabilités.

À terme, la création d'une image PimsOS complète doit pouvoir être réalisée à partir d'un processus de Build automatisé et reproductible.

---

# État actuel

## Architecture

✅ Stabilisée

L'architecture 3.0.0 repose notamment sur :

- un module PowerShell unique ;
- un BuildContext centralisé ;
- un Workflow ;
- un Pipeline ;
- un ActionRegistry ;
- un ActionEngine ;
- des Engines spécialisés ;
- des Managers spécialisés ;
- des modules techniques ;
- une configuration pilotée par les données ;
- une couverture Pester importante.

---

## Développement

🚧 En cours

Les principales phases du framework sont maintenant en place :

- Recovery ;
- vérification de l'environnement ;
- gestion des ISO ;
- gestion des WIM ;
- sélection des images Windows ;
- gestion des ruches du registre ;
- chargement des catégories ;
- chargement des Tweaks ;
- chargement des profils ;
- fusion de la configuration ;
- validation ;
- routage des Actions ;
- Engines spécialisés ;
- Managers spécialisés ;
- reporting ;
- nettoyage et finalisation du Build.

Le développement se concentre désormais sur la finalisation de la chaîne de production et la validation complète du Build de bout en bout.

---

# Phases du projet

## Phase 1 — Fondations

### Objectifs

- [x] Définir l'architecture générale.
- [x] Mettre en place la documentation.
- [x] Définir les conventions de développement.
- [x] Mettre en place les ADR.
- [x] Construire les premiers composants techniques.

### Statut

✅ Terminée

---

## Phase 2 — Module PowerShell unique

### Objectifs

- [x] Créer `PimsOS.psm1`.
- [x] Créer `PimsOS.psd1`.
- [x] Centraliser le chargement des composants.
- [x] Centraliser l'API publique.
- [x] Introduire `Initialize-PimsOS`.
- [x] Supprimer le modèle à plusieurs modules indépendants.
- [x] Valider le module PowerShell unique.

### Statut

✅ Terminée

---

## Phase 3 — Framework de Build

### Objectifs

- [x] Finaliser le BuildContext.
- [x] Développer le BuildState.
- [x] Développer le Pipeline.
- [x] Développer le Workflow.
- [x] Mettre en place Recovery.
- [x] Gérer les images WIM.
- [x] Gérer les ISO.
- [x] Détecter les images Windows.
- [x] Permettre la sélection de l'image à personnaliser.
- [x] Gérer les ruches du registre.
- [x] Charger les définitions de Tweaks.
- [x] Charger les profils.
- [x] Fusionner profils et Tweaks.
- [x] Valider la configuration.
- [x] Mettre en place ActionRegistry.
- [x] Mettre en place ActionEngine.
- [x] Développer les Engines spécialisés.
- [x] Développer les Managers spécialisés.

### Statut

✅ Stabilisée

---

## Phase 4 — Génération d'images Windows

### Objectifs

- [x] Préparer les images ISO.
- [x] Manipuler les images WIM.
- [x] Effectuer les opérations DISM nécessaires.
- [ ] Finaliser la génération automatique de l'ISO.
- [ ] Valider automatiquement l'ISO générée.
- [ ] Valider un Build complet de bout en bout.
- [ ] Améliorer la gestion des erreurs de production.
- [ ] Optimiser les performances.

### Statut

🟡 En cours

---

## Phase 5 — Personnalisation

### Objectifs

- [x] Profils.
- [x] Tweaks.
- [x] RegistryEngine.
- [x] ServiceEngine.
- [x] FeatureEngine.
- [x] CapabilityEngine.
- [x] PackageEngine.
- [x] DriverEngine.
- [x] FileEngine.
- [x] FolderEngine.
- [x] EnvironmentEngine.
- [x] ScheduledTaskEngine.
- [x] ShortcutEngine.
- [ ] Implémenter le provider Chocolatey.
- [ ] Implémenter le provider Winget.
- [ ] Compléter les fonctionnalités de personnalisation restantes.

### Statut

🟡 En cours

---

## Phase 6 — Stabilisation et qualité

### Objectifs

- [x] Mettre en place une couverture Pester importante.
- [x] Tester les Engines spécialisés.
- [x] Tester les Managers.
- [x] Tester Configuration.
- [x] Tester Registry.
- [x] Tester Workflow et composants Core.
- [ ] Compléter les tests Recovery.
- [ ] Compléter les tests Security.
- [ ] Étendre les tests d'intégration.
- [ ] Valider les Builds complets.
- [ ] Finaliser la documentation technique.

### Statut

🟡 En cours

---

## Phase 7 — Première version stable

### Objectifs

- [ ] Pipeline validé de bout en bout.
- [ ] Génération ISO stable.
- [ ] Composants nécessaires finalisés.
- [ ] Tests validés.
- [ ] Documentation synchronisée.
- [ ] API publique stabilisée.
- [ ] Build reproductible.
- [ ] Absence d'anomalie bloquante.
- [ ] Publication d'une première version stable.

### Statut

⏳ À venir

---

# Composants restant à développer ou compléter

Les principaux éléments identifiés sont :

- `Converters.ps1` ;
- `Chocolatey.ps1` ;
- `Winget.ps1` ;
- couverture complémentaire de `Recovery.ps1` ;
- couverture complémentaire de `Security.ps1` ;
- enrichissement du Reporting ;
- finalisation de la génération ISO ;
- validation complète de bout en bout.

---

# Tests

Les objectifs actuels sont :

- maintenir la couverture des composants existants ;
- compléter les tests des composants encore partiellement couverts ;
- étendre les tests d'intégration ;
- ajouter des tests de régression ;
- automatiser progressivement l'exécution des tests.

Les tests Pester constituent la base de validation du framework.

---

# Documentation

Les objectifs actuels sont :

- maintenir la documentation synchronisée avec le code ;
- documenter l'API publique ;
- documenter l'architecture ;
- maintenir les règles d'architecture ;
- maintenir le statut du projet ;
- maintenir le backlog et les jalons ;
- documenter les décisions architecturales dans les ADR.

---

# Priorités actuelles

## Priorité 1 — Génération ISO

Finaliser la chaîne permettant de produire une ISO PimsOS complète.

---

## Priorité 2 — Validation de bout en bout

Réaliser et valider un Build complet depuis l'ISO source jusqu'à l'artefact final.

---

## Priorité 3 — Providers packages

Implémenter les providers :

- Chocolatey ;
- Winget.

---

## Priorité 4 — Couverture et stabilité

Compléter :

- Recovery ;
- Security ;
- reporting ;
- tests d'intégration ;
- tests de régression.

---

## Priorité 5 — Documentation et release

Maintenir la documentation synchronisée et préparer les conditions nécessaires à une première release stable.

---

# Prochain objectif technique

Le prochain objectif technique majeur est la **finalisation de la chaîne de production de l'image PimsOS**.

Les travaux prioritaires sont :

- finaliser le traitement du WIM ;
- finaliser la reconstruction de l'ISO ;
- valider le Build complet ;
- vérifier les artefacts générés ;
- compléter les rapports ;
- vérifier le nettoyage final ;
- documenter le processus de production.

---

# Hors périmètre actuel

À ce stade, les éléments suivants ne constituent pas une priorité du développement :

- interface graphique complète ;
- support d'autres systèmes d'exploitation ;
- déploiement distribué ;
- versions de Windows incompatibles avec les mécanismes techniques utilisés par le Builder.

Ces éléments pourront être réévalués ultérieurement.

---

# Suivi

La feuille de route est revue à chaque jalon majeur.

Les fonctionnalités terminées sont reportées dans :

- `ReleaseNotes.md` ;
- `Milestones.md` ;
- `ProjectStatus.md`.

Les évolutions architecturales importantes sont documentées dans les ADR.

---

# Documents associés

- `Architecture.md`
- `ArchitectureRules.md`
- `ProjectStatus.md`
- `ProjectStructure.md`
- `Lifecycle.md`
- `Milestones.md`
- `ReleaseNotes.md`
- `Testing.md`
- `Documentation\ADR\`