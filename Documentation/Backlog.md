# Mise à jour du backlog — 01/09/2026

## Priorité immédiate — Wizard / Tweaks

- [x] Charger `TweakCatalog.ps1` dans `PimsOS.psm1`.
- [x] Stabiliser le catalogue de présentation du Wizard.
- [x] Permettre la sélection individuelle, par liste et par plage.
- [x] Corriger la résolution des profils depuis `Profiles\`.
- [x] Ajouter les tests du flux de sélection Tweaks.
- [ ] Continuer l’enrichissement du catalogue et des profils.

## Tweaks / catégories

- [ ] Compléter les 9 fichiers JSON placeholders.
- [ ] Vérifier les 19 définitions existantes et leurs Actions.
- [ ] Harmoniser `Config\Categories.json` avec les `CategoryId` réellement utilisés.
- [ ] Ne pas considérer un placeholder comme un Tweak terminé.

## Validation

- [x] Régénérer/valider les campagnes ciblées Pester du sprint.
- [ ] Régénérer `Tests\testResults.xml`.
- [x] Générer une ISO PimsOS 3.0.0 avec le pipeline réel.
- [ ] Revalider Bootstrap/PostInstall/Write-Log dans Hyper-V sur la nouvelle ISO.
- [ ] Vérifier `state.json` et l’idempotence.

---

# PimsOS Builder - Backlog

> Version technique : 3.0.0
>
> Statut : Référence
>
> Dernière mise à jour : 2026-09-01

---

# Objectif

Ce document centralise les évolutions envisagées pour **PimsOS Builder** qui ne sont pas encore intégrées au développement courant.

Le Backlog permet de conserver les idées, améliorations et travaux futurs sans les considérer comme des engagements de réalisation.

Les éléments sont réévalués régulièrement en fonction des priorités du projet, des jalons et de l'état réel du framework.

---

# Priorité élevée

## Génération d'image

- [ ] Finaliser la reconstruction automatique de l'ISO.
- [ ] Valider automatiquement l'ISO générée.
- [ ] Réaliser un Build complet de bout en bout.
- [ ] Vérifier les artefacts de sortie.
- [ ] Finaliser le nettoyage après génération.
- [ ] Améliorer la gestion des erreurs pendant la production de l'image.

---

## Providers de packages

- [~] Stabiliser le provider/cache Chocolatey et son catalogue.
- [ ] Implémenter le provider Winget.
- [ ] Ajouter les tests des providers.
- [ ] Valider leur intégration avec `PackageManager`.

---

## Tests et qualité

- [ ] Compléter la couverture de `Recovery.ps1`.
- [ ] Compléter la couverture de `Security.ps1`.
- [ ] Ajouter ou compléter les tests d'intégration.
- [ ] Ajouter des scénarios de régression supplémentaires.
- [ ] Ajouter une couverture de code exploitable dans la CI.
- [x] Intégrer PSScriptAnalyzer dans la CI.
- [x] Vérifier automatiquement le chargement du module PimsOS dans la CI.
- [x] Publier les résultats Pester comme artefacts GitHub Actions.

---

# Priorité moyenne

## Recovery et diagnostic

- [ ] Améliorer `Test-WimMountState()`.
- [x] Ajouter un diagnostic statique sécurisé des tests.
- [ ] Ajouter un diagnostic détaillé de l'état des ressources.
- [ ] Améliorer la détection des ressources laissées par un Build précédent.
- [ ] Renforcer les scénarios de récupération.
- [ ] Ajouter des tests de reprise de Build.

---

## Reporting

- [ ] Enrichir les informations du rapport.
- [ ] Améliorer la restitution des statistiques.
- [ ] Ajouter des rapports plus détaillés pour les erreurs.
- [ ] Préparer les futurs formats de rapport.
- [ ] Évaluer les besoins d'un rapport HTML.

---

## Configuration

- [ ] Étendre la validation des profils.
- [ ] Étendre la validation des catégories.
- [ ] Renforcer la validation des Actions.
- [ ] Ajouter des contrôles de dépendances.
- [ ] Étendre les possibilités de configuration des profils.
- [ ] Ajouter de nouvelles catégories de personnalisation.

---

## Documentation

- [ ] Ajouter des diagrammes Mermaid lorsque cela apporte une réelle valeur.
- [ ] Générer automatiquement une partie de la documentation API.
- [ ] Ajouter des exemples de profils.
- [ ] Ajouter des exemples de configurations.
- [ ] Documenter les scénarios de personnalisation courants.
- [ ] Enrichir les guides utilisateur.

---

# Priorité faible

## Qualité et automatisation

- [ ] Ajouter un fichier `.editorconfig`.
- [ ] Renforcer les contrôles automatiques du dépôt.
- [ ] Ajouter des contrôles supplémentaires dans la CI.
- [ ] Automatiser davantage les validations avant release.

---

## Distribution

- [ ] Créer un workflow GitHub Actions dédié aux Releases.
- [ ] Publier automatiquement les artefacts.
- [ ] Signer automatiquement les artefacts lorsque la stratégie de distribution sera définie.
- [ ] Générer automatiquement les sommes SHA256.
- [ ] Automatiser la génération des notes de release.

---

## Interface

- [ ] Étudier un tableau de bord du Build.
- [ ] Étudier une interface graphique.
- [ ] Étudier un assistant de configuration.

Ces éléments ne sont pas prioritaires pour la version technique 3.0.0.

---

# Idées

Cette section conserve les idées qui pourront être étudiées ultérieurement.

Exemples :

- support de nouvelles versions de Windows ;
- nouveaux types d'Actions ;
- nouveaux Engines ;
- nouveaux providers ;
- nouvelles catégories de Tweaks ;
- optimisation du pipeline ;
- amélioration des diagnostics ;
- automatisation supplémentaire du Build.

Ces éléments ne constituent pas des engagements de réalisation.

---

# Éléments déjà réalisés

Les éléments suivants étaient présents dans l'ancien Backlog mais sont désormais considérés comme réalisés et ne doivent plus rester dans le Backlog actif :

- BuildState ;
- ActionEngine ;
- ServiceEngine ;
- FeatureEngine ;
- PackageEngine ;
- DriverEngine ;
- FileEngine ;
- FolderEngine ;
- EnvironmentEngine ;
- ScheduledTaskEngine ;
- ShortcutEngine ;
- Configuration ;
- ActionRegistry ;
- Managers spécialisés.

Ces éléments sont désormais suivis dans :

- `ProjectStatus.md` ;
- `Milestones.md` ;
- `ReleaseNotes.md`.

---

# PostInstall

## Terminé

Les composants suivants du PostInstall sont désormais implémentés et couverts par les tests :

- State ;
- Network ;
- PostInstall ;
- Bootstrap ;
- FirstBoot ;
- Unattend ;
- Installer ;
- UI ;
- intégration dans le pipeline ;
- validation du WIM réel.

La gestion de l'attente réseau avec interface utilisateur est également implémentée.

Le runtime PostInstall est préparé dans le WIM et installé dans :

```text
C:\ProgramData\PimsOS\PostInstall\
```

Le premier démarrage utilise `unattend.xml` pour lancer le Bootstrap.

---

## Restant

Les travaux PostInstall restant à réaliser sont :

- [ ] validation FirstBoot réelle sur une installation Windows ;
- [ ] implémentation des providers de paquets ;
- [ ] intégration de Chocolatey ;
- [ ] intégration de Winget ;
- [ ] intégration de Microsoft Store ;
- [ ] validation de bout en bout du processus PostInstall sur une image réellement installée.

---

# Gestion du Backlog

Le Backlog est réévalué :

- lors des jalons importants ;
- lors de la planification d'un nouveau cycle de développement ;
- lorsque l'état du projet change de manière significative.

Les éléments sélectionnés comme prioritaires sont ensuite intégrés dans :

- `Roadmap.md` ;
- `Milestones.md` ;
- les travaux de développement correspondants.

Le Backlog ne remplace pas la Roadmap et ne constitue pas une liste d'engagements.

---

# Philosophie

Le Backlog permet de conserver une vision à moyen et long terme du projet sans perturber les priorités immédiates.

Les éléments les plus importants doivent être déplacés vers la Roadmap ou un jalon avant leur réalisation.

Toute tâche terminée doit être retirée du Backlog actif et reflétée dans la documentation de statut du projet.

# PimsOS Builder - Backlog

> Version technique : **3.0.0**
>
> Dernière mise à jour : **2026-09-01**

## Priorité immédiate

### Validation ISO

- [ ] Reconstruire l'ISO depuis le commit 3bbaf73.
- [ ] Valider FirstBoot/PostInstall dans Hyper-V.
- [ ] Vérifier Bootstrap / Logger.
- [ ] Vérifier `state.json`.
- [ ] Vérifier l'idempotence.
- [ ] Tester la reprise après disponibilité réseau.
- [ ] Vérifier l'application réelle des Tweaks.
- [ ] Valider l'installation via Rufus.

### Packages

- [ ] Finaliser Chocolatey.
- [ ] Finaliser Winget.
- [ ] Définir le contrat des Providers.
- [ ] Tester les installations réelles en PostInstall.

### Microsoft Store

- [ ] Définir la stratégie Store.
- [ ] Implémenter son provider.
- [ ] Intégrer le provider au PackageManager.
- [ ] Ajouter les tests unitaires.
- [ ] Ajouter les tests d'intégration.

## Tweaks

- [ ] Enrichir le catalogue au-delà des 27 Tweaks actuels.
- [ ] Auditer les Tweaks existants.
- [ ] Compléter les placeholders réellement utiles.
- [ ] Harmoniser `Config/Categories.json`.
- [ ] Maintenir `Documentation/Tweaks.md`.

## Qualité

- [ ] Régénérer `Tests\testResults.xml`.
- [ ] Compléter Recovery.
- [ ] Compléter Security.
- [ ] Ajouter PSScriptAnalyzer.
- [ ] Renforcer la CI.
- [ ] Enrichir Reporting.
- [ ] Implémenter Converters.

## Règles

- `Tests\Legacy` reste hors campagne officielle.
- Les ADR historiques ne sont pas réécrits pour un simple changement d'état.
- Les nouveaux providers ne doivent pas être mélangés au moteur générique des
  Tweaks/Registry.
