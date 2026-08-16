# Contribuer à PimsOS Builder

Merci de votre intérêt pour **PimsOS Builder**.

Ce document décrit les règles de contribution au projet afin de garantir un développement cohérent, maintenable, documenté et conforme à l'architecture du Builder.

---

# Avant de commencer

Avant toute contribution, lire les documents suivants :

- `Documentation/GettingStarted.md`
- `Documentation/DeveloperGuide.md`
- `Documentation/CodingStandards.md`
- `Documentation/Architecture.md`
- `Documentation/ArchitectureRules.md`
- `Documentation/BuildContext.md`
- `Documentation/ModuleGuide.md`
- `Documentation/ProjectStatus.md`
- `Documentation/Testing.md`
- `Documentation/Roadmap.md`

Ils constituent les principales références du projet.

Les décisions architecturales sont documentées dans :

```text
Documentation/ADR/
```

---

# Comprendre avant de modifier

Avant toute modification importante :

1. comprendre le fonctionnement actuel ;
2. identifier le composant concerné ;
3. vérifier qu'une solution similaire n'existe pas déjà ;
4. vérifier les ADR lorsqu'une décision d'architecture est concernée ;
5. vérifier les tests existants ;
6. identifier les documents qui devront être mis à jour.

Aucune modification importante ne doit être réalisée sans comprendre son impact sur le moteur de Build.

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
9. Valider le Build lorsque le changement le nécessite.
10. Vérifier l'état Git.
11. Effectuer un commit cohérent.

---

# Architecture

PimsOS Builder repose notamment sur les principes suivants :

- un module PowerShell unique (`PimsOS`) ;
- un `BuildContext` unique par Build ;
- un `BuildState` centralisé ;
- un Workflow et un Pipeline dédiés à l'orchestration ;
- un `ActionEngine` et un `ActionRegistry` pour le routage ;
- des Engines spécialisés responsables de la logique métier ;
- des Managers responsables des opérations techniques ;
- une séparation entre définitions, configuration et exécution ;
- une API publique minimale.

Toute contribution doit respecter cette architecture.

Les composants internes ne doivent pas créer de modules PowerShell indépendants sans décision architecturale explicite.

---

# BuildContext

Le `BuildContext` constitue le contrat central du Build.

Les contributions ne doivent pas :

- utiliser des variables globales pour transporter l'état du Build ;
- créer un second contexte pour le même Build ;
- dupliquer des informations déjà présentes dans le contexte ;
- modifier arbitrairement les propriétés appartenant à un autre domaine.

Toute nouvelle donnée partagée doit être ajoutée au BuildContext uniquement lorsqu'elle représente réellement une information ou un état partagé.

---

# BuildState

Le `BuildState` centralise l'état d'exécution du Build.

Les nouveaux indicateurs d'avancement ou d'état doivent être intégrés au mécanisme existant plutôt que dispersés dans plusieurs objets.

Un nouveau composant doit mettre à jour uniquement l'état relevant de sa responsabilité.

---

# Configuration

Les définitions de Tweaks restent séparées de leur utilisation.

Les profils déterminent les personnalisations sélectionnées.

Le moteur de configuration construit ensuite une configuration destinée à l'exécution.

Une contribution ne doit pas modifier directement les définitions originales des Tweaks lors de la fusion ou de l'application d'un profil.

Les fichiers JSON doivent rester déclaratifs et ne doivent pas contenir de logique PowerShell exécutable.

---

# Actions, Engines et Managers

Toute nouvelle Action doit respecter le flux :

```text
Action
    ↓
ActionEngine
    ↓
ActionRegistry
    ↓
Engine spécialisé
    ↓
Manager
    ↓
Module technique
```

Pour ajouter un nouveau type d'Action :

1. identifier la responsabilité ;
2. créer l'Engine spécialisé ;
3. créer ou adapter le Manager nécessaire ;
4. enregistrer le type dans `ActionRegistry` ;
5. ajouter les validations ;
6. ajouter les tests ;
7. mettre à jour la documentation.

Aucun composant ne doit contourner inutilement ce routage.

---

# Compatibilité Windows

PimsOS Builder a pour objectif de personnaliser différentes versions compatibles de Windows.

Les contributions doivent donc :

- éviter les versions Windows codées en dur lorsqu'elles représentent une configuration ;
- éviter les numéros de Build codés en dur lorsqu'ils doivent être découverts ;
- utiliser les informations disponibles dans le BuildContext ;
- respecter les contraintes de compatibilité déclarées par les Tweaks.

Une évolution ne doit pas introduire une dépendance inutile à une version particulière de Windows.

---

# Structure des commits

Les messages de commit doivent être courts, explicites et cohérents.

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

- `feat`
- `fix`
- `docs`
- `refactor`
- `test`
- `build`
- `chore`

Éviter les messages vagues comme :

```text
update
test
correction
modif
divers
```

Un commit doit représenter une évolution logique et compréhensible.

---

# Branches

Les conventions de branches doivent rester simples et cohérentes.

Exemples :

```text
main
develop

feature/...

fix/...

release/...
```

Exemples concrets :

```text
feature/buildstate
feature/package-engine
fix/profile-merge
```

La stratégie exacte de branches doit rester cohérente avec le dépôt et son workflow GitHub.

---

# Qualité du code

Chaque contribution doit :

- respecter les Coding Standards ;
- respecter les Architecture Rules ;
- rester lisible ;
- limiter les duplications ;
- gérer correctement les erreurs ;
- utiliser le Logger officiel ;
- rester testable ;
- documenter les décisions importantes.

La simplicité et la maintenabilité sont prioritaires sur la complexité inutile.

---

# Tests

Avant chaque commit important :

- exécuter les tests directement concernés ;
- élargir la validation lorsque l'impact du changement le justifie.

Exemple :

```powershell
Invoke-Pester -Path .\Tests\Unit
Invoke-Pester -Path .\Tests\Integration
```

Pour une suite ciblée :

```powershell
Invoke-Pester -Path .\Tests\Unit
```

Aucun test obligatoire ne doit rester en échec lors de l'intégration d'une évolution.

Pour une correction de bug, ajouter un test de régression lorsque cela est pertinent.

---

# Documentation

Toute évolution importante doit mettre à jour les documents concernés.

Selon le changement, cela peut inclure :

- `API.md`
- `BuildContext.md`
- `Architecture.md`
- `ArchitectureRules.md`
- `DeveloperGuide.md`
- `ModuleGuide.md`
- `TechnicalDecisions.md`
- `ReleaseNotes.md`
- `Roadmap.md`
- `ProjectStatus.md`
- `Testing.md`

Lorsqu'une décision modifie l'architecture, une ADR doit être créée ou mise à jour selon les règles du dossier `Documentation/ADR`.

La documentation doit décrire le comportement réel du Builder.

---

# Pull Requests

Chaque Pull Request doit :

- avoir un objectif clair ;
- contenir des changements cohérents ;
- respecter l'architecture du projet ;
- passer les tests concernés ;
- mettre à jour la documentation lorsque nécessaire ;
- expliquer les changements importants ;
- signaler les impacts éventuels sur l'architecture ou les contrats.

Une Pull Request importante doit être suffisamment ciblée pour rester facilement révisable.

---

# Revue de code

Avant validation, vérifier :

- la responsabilité du nouveau composant ;
- les dépendances introduites ;
- le respect du BuildContext ;
- le respect du BuildState ;
- le routage correct des Actions ;
- la gestion des erreurs ;
- la journalisation ;
- les tests ;
- la documentation ;
- les impacts éventuels sur les ADR.

---

# Git

Avant un commit :

```powershell
git status
```

Cette commande permet de vérifier les fichiers modifiés, ajoutés ou supprimés.

Après le commit :

```powershell
git log --oneline -5
```

Cette commande permet de vérifier l'historique récent.

Lorsque le changement est prêt à être partagé :

```powershell
git push
```

Les commits doivent rester cohérents et facilement compréhensibles plusieurs mois plus tard.

---

# Philosophie

PimsOS Builder privilégie :

- la simplicité ;
- la modularité ;
- la stabilité ;
- la maintenabilité ;
- la testabilité ;
- la reproductibilité ;
- la documentation.

Une contribution doit améliorer le projet sans augmenter inutilement sa complexité.

Chaque évolution doit, autant que possible, laisser le Builder dans un état meilleur qu'avant la modification.

---

# Références

Consulter également :

- `Documentation/Architecture.md`
- `Documentation/ArchitectureRules.md`
- `Documentation/BuildContext.md`
- `Documentation/CodingStandards.md`
- `Documentation/DeveloperGuide.md`
- `Documentation/ModuleGuide.md`
- `Documentation/Testing.md`
- `Documentation/TechnicalDecisions.md`
- `Documentation/ADR/`
