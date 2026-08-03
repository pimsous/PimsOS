# Contribuer à PimsOS Builder

Merci de votre intérêt pour **PimsOS Builder**.

Ce document décrit les règles de contribution au projet afin de garantir un développement cohérent, maintenable, documenté et conforme à l'architecture du Builder.

---

# Avant de commencer

Avant toute contribution, lire les documents suivants :

- Documentation/GettingStarted.md
- Documentation/DeveloperGuide.md
- Documentation/CodingStandards.md
- Documentation/Architecture.md
- Documentation/ArchitectureRules.md
- Documentation/BuildContext.md
- Documentation/ProjectStatus.md
- Documentation/Roadmap.md

Ils constituent la référence officielle du projet.

---

# Comprendre avant de modifier

Avant toute modification :

1. comprendre le fonctionnement actuel ;
2. identifier le composant concerné ;
3. vérifier qu'une solution similaire n'existe pas déjà ;
4. vérifier les ADR si une décision d'architecture est concernée.

Aucune modification importante ne doit être réalisée sans comprendre son impact sur le moteur de build.

---

# Workflow

Le développement suit les étapes suivantes :

1. Identifier le besoin.
2. Vérifier l'architecture existante.
3. Concevoir la solution.
4. Développer.
5. Écrire ou mettre à jour les tests.
6. Mettre à jour la documentation.
7. Vérifier que les tests passent.
8. Effectuer une revue du code.
9. Valider le Build.
10. Effectuer le commit.

---

# Architecture

PimsOS Builder repose sur plusieurs principes :

- un module PowerShell unique (`PimsOS`) ;
- un BuildContext unique ;
- un BuildState unique ;
- un Pipeline chargé uniquement d'orchestrer les étapes ;
- des Engines spécialisés responsables de la logique métier ;
- une séparation stricte entre les définitions (Tweaks) et la Configuration appliquée.

Toute contribution doit respecter cette architecture.

---

# BuildContext

Toutes les données transitent par le BuildContext.

Les contributions ne doivent pas :

- utiliser de variables globales ;
- créer d'état partagé ;
- dupliquer des informations déjà présentes dans le BuildContext.

Toute nouvelle donnée persistante doit être intégrée au BuildContext.

---

# BuildState

Le BuildState centralise l'état du moteur de build.

Les nouveaux indicateurs d'avancement doivent être ajoutés dans BuildState plutôt que dispersés dans plusieurs objets.

---

# Configuration

Les définitions de Tweaks sont immuables.

Les profils produisent une Configuration composée de ConfigurationItems.

Le moteur applique uniquement cette Configuration.

Une contribution ne doit jamais modifier directement les définitions originales des Tweaks.

---

# Compatibilité Windows

PimsOS Builder a pour objectif de personnaliser plusieurs versions officielles de Windows.

Les contributions doivent donc :

- éviter les chemins codés en dur ;
- éviter les numéros de build codés en dur ;
- utiliser les informations disponibles dans BuildContext et version.json.

---

# Structure des commits

Les messages de commit doivent être courts et explicites.

Format recommandé :

```text
type(scope): description
```

Exemples :

```text
feat(BuildState): add pipeline state tracking

fix(Configuration): preserve tweak definitions

docs(BuildContext): document Windows metadata

refactor(Pipeline): simplify workflow

test(Registry): add registry engine tests
```

Types recommandés :

- feat
- fix
- docs
- refactor
- test
- build
- chore

---

# Branches

Convention recommandée :

```text
main
develop

feature/...

fix/...

release/...
```

Exemples :

```text
feature/buildstate

feature/package-engine

fix/profile-merge
```

---

# Qualité du code

Chaque contribution doit :

- respecter les Coding Standards ;
- respecter l'architecture ;
- rester lisible ;
- être documentée ;
- être testée ;
- éviter les duplications.

Le code doit privilégier la simplicité et la maintenabilité.

---

# Tests

Avant chaque commit :

- exécuter les tests concernés ;
- exécuter l'ensemble des tests uniquement lorsque cela est nécessaire.

Exemple :

```powershell
Invoke-Pester
```

Aucun test ne doit échouer.

---

# Documentation

Toute évolution importante doit mettre à jour la documentation concernée.

Selon les cas :

- API.md
- BuildContext.md
- Architecture.md
- ArchitectureRules.md
- TechnicalDecisions.md
- ReleaseNotes.md
- Roadmap.md
- ProjectStatus.md

La documentation doit toujours décrire le comportement réel du Builder.

---

# Pull Requests

Chaque Pull Request doit :

- avoir un objectif clair ;
- contenir des commits cohérents ;
- respecter l'architecture du projet ;
- passer tous les tests ;
- mettre à jour la documentation si nécessaire.

---

# Philosophie

PimsOS Builder privilégie :

- la simplicité ;
- la modularité ;
- la stabilité ;
- la maintenabilité ;
- la testabilité ;
- la reproductibilité.

Une contribution doit toujours améliorer le projet sans augmenter inutilement sa complexité.

Chaque évolution doit laisser le Builder dans un meilleur état qu'avant.

Merci de contribuer à **PimsOS Builder**.