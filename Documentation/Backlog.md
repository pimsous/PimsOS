# Backlog

> Version : 1.0.0
>
> Dernière mise à jour : 2026-08-06

---

# Objectif

Ce document centralise les évolutions envisagées pour **PimsOS Builder** qui ne font pas partie du sprint en cours.

Il permet de conserver les idées d'amélioration sans perturber le développement en cours.

Les éléments présents dans ce document ne constituent pas des engagements de réalisation.

Ils sont réévalués à chaque nouveau sprint.

---

# Priorité élevée

## GitHub

- [X] Mettre en place un workflow GitHub Actions (CI).
- [ ] Créer un workflow Release.
- [X] Ajouter CodeQL.
- [X] Configurer Dependabot.
- [X] Ajouter les badges GitHub dans README.
- [X] Ajouter les modèles Issue.
- [X] Ajouter le modèle Pull Request.

---

## Qualité

- [ ] Ajouter un fichier `.editorconfig`.
- [ ] Intégrer PSScriptAnalyzer dans la CI.
- [ ] Publier les résultats Pester dans GitHub Actions.
- [ ] Vérifier automatiquement le chargement du module PimsOS.
- [ ] Ajouter une couverture de code.

---

## Documentation

- [ ] Ajouter des diagrammes Mermaid.
- [ ] Générer automatiquement la documentation API.
- [ ] Créer un Wiki GitHub.
- [ ] Ajouter des captures d'écran.
- [ ] Documenter les Engines.

---

# Priorité moyenne

## Build

- [ ] Finaliser BuildState.
- [ ] Recovery V2.
- [ ] Diagnostic complet de Test-WimMountState().
- [ ] Validation avancée du Pipeline.
- [ ] Journalisation enrichie.

---

## Engines

- [ ] ServiceEngine.
- [ ] FeatureEngine.
- [ ] PackageEngine.
- [ ] DriverEngine.
- [ ] FileEngine.
- [ ] FolderEngine.
- [ ] EnvironmentEngine.
- [ ] ScheduledTaskEngine.
- [ ] ShortcutEngine.

---

## Configuration

- [ ] Validation avancée des profils.
- [ ] Validation des catégories.
- [ ] Validation des actions.
- [ ] Vérification des dépendances.

---

# Priorité faible

## Interface

- [ ] Tableau de bord de Build.
- [ ] Interface graphique.
- [ ] Assistant de configuration.

---

## Distribution

- [ ] Génération automatique des Releases GitHub.
- [ ] Publication automatique des artefacts.
- [ ] Signature automatique des builds.
- [ ] Génération des sommes SHA256.

---

## Documentation

- [ ] FAQ.
- [ ] Tutoriels.
- [ ] Exemples de profils.
- [ ] Guide de personnalisation.

---

# Idées

Cette section permet de conserver les idées qui pourront être étudiées ultérieurement.

Exemples :

- Support de nouvelles versions de Windows.
- Nouveaux moteurs de personnalisation.
- Optimisations du pipeline.
- Nouvelles catégories de Tweaks.

Ces éléments ne sont pas planifiés à ce stade.

---

# Gestion

Le Backlog est revu :

- au début de chaque sprint ;
- à la fin de chaque sprint ;
- avant chaque jalon important.

Les éléments retenus sont ensuite intégrés dans :

- CurrentSprint.md
- Roadmap.md
- Milestones.md

selon leur importance.

---

# Philosophie

Toutes les idées sont les bienvenues.

Le Backlog permet de conserver une vision à long terme du projet sans perturber le développement en cours.

Le sprint reste toujours prioritaire sur le Backlog.