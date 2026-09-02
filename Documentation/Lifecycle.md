# PimsOS Builder - Feuille de route

> Version technique : 3.0.0
>
> Statut : Développement / architecture stabilisée
>
> Dernière mise à jour : 2026-09-02

---

> Les références antérieures au 02/09/2026 sont historiques ; l’état courant est celui du 02/09/2026.


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

* modularité ;
* automatisation ;
* reproductibilité ;
* maintenabilité ;
* testabilité ;
* séparation claire des responsabilités.

À terme, la création d'une image PimsOS complète doit pouvoir être réalisée à partir d'un processus de Build automatisé et reproductible.

---

# État actuel

## Architecture

✅ **Stabilisée**

L'architecture 3.0.0 repose notamment sur :

* un module PowerShell unique ;
* un BuildContext centralisé ;
* un BuildState ;
* un Workflow ;
* un Pipeline ;
* un ActionRegistry ;
* un ActionEngine ;
* des Engines spécialisés ;
* des Managers spécialisés ;
* des composants techniques organisés par domaine ;
* une configuration pilotée par les données ;
* une API publique centralisée ;
* une couverture Pester importante.

Le point d'entrée public principal est :

```text id="v6d0zp"
Initialize-PimsOS
```

---

## Développement

🚧 **En cours**

Les principales fondations du framework sont maintenant en place :

* Recovery ;
* vérification de l'environnement ;
* vérification des prérequis ;
* gestion des ISO ;
* gestion des WIM ;
* sélection des images Windows ;
* gestion des ruches du registre ;
* chargement des catégories ;
* chargement des Tweaks ;
* chargement des profils ;
* fusion de la configuration ;
* validation ;
* routage des Actions ;
* Engines spécialisés ;
* Managers spécialisés ;
* Wizard ;
* configuration des drivers ;
* préparation PostInstall ;
* préparation FirstBoot ;
* reporting ;
* nettoyage et finalisation du Build.

Le Build réel de bout en bout et la validation VM de FirstBoot/PostInstall sont désormais démontrés. Le développement se concentre sur la synchronisation Git, la validation physique/Rufus, l’audit Offline des packages et les fonctions encore au backlog.

---

# Phases du projet

## Phase 1 — Fondations

### Objectifs

* [x] Définir l'architecture générale.
* [x] Mettre en place la documentation.
* [x] Définir les conventions de développement.
* [x] Mettre en place les ADR.
* [x] Construire les premiers composants techniques.
* [x] Définir le BuildContext.
* [x] Définir le BuildState.

### Statut

✅ **Terminée**

---

## Phase 2 — Module PowerShell unique

### Objectifs

* [x] Créer `PimsOS.psm1`.
* [x] Créer `PimsOS.psd1`.
* [x] Centraliser le chargement des composants.
* [x] Centraliser l'API publique.
* [x] Introduire `Initialize-PimsOS`.
* [x] Supprimer le modèle à plusieurs modules indépendants.
* [x] Valider le module PowerShell unique.
* [x] Valider l'exposition de l'API publique.

### Statut

✅ **Terminée**

---

## Phase 3 — Framework de Build

### Objectifs

* [x] Finaliser le BuildContext.
* [x] Développer le BuildState.
* [x] Développer le Pipeline.
* [x] Développer le Workflow.
* [x] Mettre en place Recovery.
* [x] Vérifier les prérequis de l'environnement.
* [x] Gérer les images WIM.
* [x] Gérer les ISO.
* [x] Détecter les images Windows.
* [x] Permettre la sélection de l'image à personnaliser.
* [x] Gérer les ruches du registre.
* [x] Charger les définitions de Tweaks.
* [x] Charger les profils.
* [x] Fusionner profils et Tweaks.
* [x] Valider la configuration.
* [x] Mettre en place ActionRegistry.
* [x] Mettre en place ActionEngine.
* [x] Développer les Engines spécialisés.
* [x] Développer les Managers spécialisés.
* [x] Intégrer le Wizard.
* [x] Intégrer la configuration des drivers.
* [x] Intégrer la préparation PostInstall au pipeline.

### Statut

✅ **Stabilisée**

Le moteur d'orchestration est suffisamment structuré et testé pour poursuivre la finalisation de la production d'image.

---

## Phase 4 — Génération d'images Windows

### Objectifs

* [x] Préparer les images ISO.
* [x] Manipuler les images WIM.
* [x] Effectuer les opérations DISM nécessaires.
* [x] Préparer les drivers dans le pipeline.
* [x] Préparer le runtime PostInstall dans le WIM.
* [x] Générer `unattend.xml`.
* [ ] Finaliser la génération automatique de l'ISO.
* [ ] Valider automatiquement l'ISO générée.
* [ ] Valider un Build complet de bout en bout.
* [ ] Améliorer la gestion des erreurs de production.
* [ ] Optimiser les performances.
* [ ] Valider l'artefact ISO final.

### Statut

🟡 **En cours**

---

## Phase 5 — Personnalisation

### Objectifs

* [x] Profils.
* [x] Tweaks.
* [x] Catégories.
* [x] RegistryEngine.
* [x] ServiceEngine.
* [x] FeatureEngine.
* [x] CapabilityEngine.
* [x] PackageEngine.
* [x] DriverEngine.
* [x] FileEngine.
* [x] FolderEngine.
* [x] EnvironmentEngine.
* [x] ScheduledTaskEngine.
* [x] ShortcutEngine.
* [x] PackageManager.
* [x] DriverManager.
* [x] Managers spécialisés.
* [ ] Implémenter le provider Chocolatey.
* [ ] Implémenter le provider Winget.
* [ ] Intégrer Microsoft Store.
* [ ] Compléter les fonctionnalités de personnalisation restantes.

### Statut

🟡 **En cours**

---

## Phase 6 — PostInstall / FirstBoot

### Objectifs

* [x] Implémenter State.
* [x] Implémenter Network.
* [x] Implémenter le moteur PostInstall.
* [x] Implémenter Bootstrap.
* [x] Implémenter FirstBoot.
* [x] Implémenter Unattend.
* [x] Implémenter Installer.
* [x] Implémenter UI PostInstall.
* [x] Intégrer `PreparePostInstall` au BuildPipeline.
* [x] Valider l'injection du runtime dans un WIM temporaire.
* [x] Valider la génération de `unattend.xml`.
* [x] Valider le namespace `urn:schemas-microsoft-com:unattend`.
* [x] Valider `wcm:action="add"`.
* [x] Valider la commande vers `Bootstrap.ps1`.
* [x] Ajouter l'affichage réseau du premier démarrage.
* [x] Ajouter l'attente réseau avec interface console.
* [ ] Valider l'exécution réelle de `FirstLogonCommands`.
* [ ] Valider le premier démarrage réel de Windows.
* [ ] Valider la reprise réseau réelle.
* [x] Intégrer le provider Chocolatey.
* [ ] Intégrer Winget.
* [ ] Intégrer Microsoft Store.

### Statut

🟡 **Implémenté et testé — validation réelle FirstBoot restante**

Le sous-système PostInstall est fonctionnel au niveau de la préparation et de l'intégration au Build.

La validation réelle de `FirstLogonCommands`, Bootstrap, PostInstall et Finalization est maintenant effectuée en VM.

---

## Phase 7 — Stabilisation et qualité

### Objectifs

* [x] Mettre en place Pester 5.x.
* [x] Mettre en place une couverture importante des composants.
* [x] Tester les Engines spécialisés.
* [x] Tester les Managers.
* [x] Tester Configuration.
* [x] Tester Registry.
* [x] Tester Workflow et composants Core.
* [x] Tester Wizard.
* [x] Tester les drivers.
* [x] Tester PostInstall.
* [x] Tester FirstBoot.
* [x] Tester Network.
* [x] Tester l'intégration du BuildPipeline.
* [x] Séparer les tests officiels des tests Legacy.
* [ ] Compléter les tests Recovery.
* [ ] Compléter les tests Security.
* [ ] Étendre les tests d'intégration.
* [ ] Valider les Builds complets.
* [ ] Finaliser la documentation technique.

### Résultat actuel

La dernière campagne officielle de tests donne :

```text id="fny8oe"
815 Passed / 0 Failed / 1 Skipped (reference — 02/09/2026)
0 Failed
1 Skipped
0 Inconclusive
0 NotRun
```

Le seul test ignoré est conditionnel et concerne le cas d'une catégorie sans groupes alors que toutes les catégories actuellement définies possèdent des groupes.

Les tests historiques présents dans :

```text id="pydg7a"
Tests\Legacy
```

sont conservés séparément et ne font pas partie de la campagne officielle.

### Statut

🟡 **En cours**

---

## Phase 8 — Première version stable

### Objectifs

* [ ] Pipeline validé de bout en bout.
* [ ] Génération ISO stable.
* [ ] Composants nécessaires finalisés.
* [ ] PostInstall validé sur un environnement Windows réel.
* [ ] FirstBoot validé.
* [ ] Tests validés.
* [ ] Documentation synchronisée.
* [ ] API publique stabilisée.
* [ ] Build reproductible.
* [ ] Absence d'anomalie bloquante.
* [ ] Artefact ISO final validé.
* [ ] Publication d'une première version stable.

### Statut

⏳ **À venir**

---

# Composants restant à développer ou compléter

Les principaux éléments identifiés sont :

* finalisation de la génération ISO ;
* validation complète du Build de bout en bout ;
* validation réelle FirstBoot ;
* validation de la reprise réseau réelle ;
* `Converters.ps1` ;
* provider Chocolatey ;
* provider Winget ;
* intégration Microsoft Store ;
* couverture complémentaire de `Recovery.ps1` ;
* couverture complémentaire de `Security.ps1` ;
* enrichissement du Reporting ;
* validation de l'artefact ISO final.

---

# Tests

Les objectifs actuels sont :

* maintenir la couverture des composants existants ;
* compléter les tests des composants encore partiellement couverts ;
* étendre les tests d'intégration ;
* ajouter des tests de régression ;
* automatiser progressivement l'exécution des tests ;
* conserver une séparation stricte entre les tests actifs et les tests historiques.

Les tests Pester constituent la base de validation du framework.

## Campagne officielle

La campagne officielle utilise :

```text id="7kyx7n"
Tests\Unit
Tests\Integration
```

Les tests historiques sont conservés dans :

```text id="j31c2d"
Tests\Legacy
```

Ils ne sont pas inclus dans la campagne officielle.

---

# Documentation

Les objectifs actuels sont :

* maintenir la documentation synchronisée avec le code ;
* documenter l'API publique ;
* documenter l'architecture ;
* maintenir les règles d'architecture ;
* maintenir le statut du projet ;
* maintenir le backlog et les jalons ;
* maintenir la feuille de route ;
* documenter les décisions architecturales dans les ADR ;
* documenter le fonctionnement du PostInstall et de FirstBoot.

---

# Priorités actuelles

## Priorité 1 — Génération ISO

Finaliser la chaîne permettant de produire une ISO PimsOS complète.

---

## Priorité 2 — Validation de bout en bout

Réaliser et valider un Build complet depuis l'ISO source jusqu'à
l'artefact final.

Cette validation doit notamment vérifier :

* la préparation du WIM ;
* l'application des Tweaks ;
* l'application des drivers ;
* la préparation PostInstall ;
* la reconstruction de l'ISO ;
* la génération de l'artefact final ;
* la cohérence du résultat.

---

## Priorité 3 — Validation FirstBoot

Valider le comportement réel de :

```text id="cprqdr"
unattend.xml
    ↓
FirstLogonCommands
    ↓
Bootstrap.ps1
    ↓
PostInstall
```

Cette validation doit être effectuée sur un environnement Windows réel.

---

## Priorité 4 — Providers packages

Implémenter les providers :

* Chocolatey ;
* Winget ;
* Microsoft Store.

---

## Priorité 5 — Couverture et stabilité

Compléter :

* Recovery ;
* Security ;
* Reporting ;
* tests d'intégration ;
* tests de régression ;
* validation des Builds complets.

---

## Priorité 6 — Documentation et release

Maintenir la documentation synchronisée et préparer les conditions nécessaires à une première release stable.

---

# Prochain objectif technique

Le prochain objectif technique majeur est la **finalisation de la chaîne de production de l'image PimsOS**.

Les travaux prioritaires sont :

1. finaliser le traitement du WIM ;
2. finaliser la reconstruction de l'ISO ;
3. valider le Build complet ;
4. vérifier les artefacts générés ;
5. valider le cycle FirstBoot réel ;
6. compléter les rapports ;
7. vérifier le nettoyage final ;
8. documenter le processus de production.

---

# Hors périmètre actuel

À ce stade, les éléments suivants ne constituent pas une priorité du développement :

* interface graphique complète ;
* support d'autres systèmes d'exploitation ;
* déploiement distribué ;
* versions de Windows incompatibles avec les mécanismes techniques utilisés par le Builder.

Ces éléments pourront être réévalués ultérieurement.

---

# Suivi

La feuille de route est revue à chaque jalon majeur.

Les fonctionnalités terminées sont reportées dans :

* `ReleaseNotes.md` ;
* `Milestones.md` ;
* `ProjectStatus.md`.

Les évolutions architecturales importantes sont documentées dans les ADR.

---

# Documents associés

* `Architecture.md`
* `ArchitectureRules.md`
* `ProjectStatus.md`
* `ProjectStructure.md`
* `Lifecycle.md`
* `Milestones.md`
* `ReleaseNotes.md`
* `Testing.md`
* `PostInstall.md`
* `Prerequisites.md`
* `Documentation\ADR\`
