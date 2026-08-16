# ADR-0004 — Pipeline de Build orienté orchestration

- **Statut** : Acceptée
- **Date** : 2026-07-19
- **Dernière mise à jour** : 2026-08-16
- **Décideur** : Pims
- **Impact** : Processus de Build

---

# Contexte

La création et la personnalisation d'une image Windows constituent un processus composé de nombreuses étapes techniques et fonctionnelles.

Parmi celles-ci :

- validation de l'environnement ;
- préparation du Workspace ;
- Recovery ;
- montage des ressources ;
- détection et préparation des images Windows ;
- chargement de la configuration ;
- application des personnalisations ;
- gestion du registre ;
- gestion des packages ;
- gestion des pilotes ;
- nettoyage ;
- finalisation ;
- génération des rapports.

Un traitement monolithique rendrait le projet difficile à maintenir et augmenterait le couplage entre les différentes responsabilités.

---

# Décision

Le Builder et le Pipeline sont responsables de l'**orchestration** du Build.

Les traitements spécialisés sont confiés aux composants responsables de leur domaine.

Le Pipeline exécute les étapes dans un ordre déterminé et transmet le BuildContext entre les composants.

La logique métier et les opérations techniques restent déléguées aux composants appropriés.

---

# Architecture

Le modèle actuel est :

```text
                 Build-PimsOS.ps1
                        │
                        ▼
                 PimsOS.psm1
                        │
                        ▼
                Initialize-PimsOS
                        │
                        ▼
                   BuildContext
                        │
                        ▼
                     Workflow
                        │
                        ▼
                     Pipeline
                        │
          ┌─────────────┼──────────────┐
          ▼             ▼              ▼
      Recovery     Environment    Configuration
          │             │              │
          └─────────────┼──────────────┘
                        ▼
                     Actions
                        │
                        ▼
                 ActionEngine
                        │
                        ▼
                 ActionRegistry
                        │
                        ▼
              Engine spécialisé
                        │
                        ▼
                     Manager
                        │
                        ▼
                Module technique
                        │
                        ▼
                     Windows
                        │
                        ▼
                 Complete-Build
```

---

# Responsabilités

## Builder

Le Builder :

- initialise le framework ;
- crée et initialise le BuildContext ;
- démarre le Workflow ;
- démarre le Pipeline ;
- finalise le Build.

Il ne contient pas la logique métier des personnalisations.

---

## Workflow

Le Workflow définit les grandes phases et leur ordre général.

Il reste principalement déclaratif.

Il ne doit pas contenir la logique technique détaillée des traitements.

---

## Pipeline

Le Pipeline :

- exécute les étapes définies par le Workflow ;
- contrôle leur ordre ;
- transmet le BuildContext ;
- suit l'état d'exécution ;
- gère les erreurs au niveau de l'orchestration ;
- journalise les étapes.

Le Pipeline ne doit pas dupliquer les décisions techniques centralisées dans d'autres composants.

---

## Composants spécialisés

Chaque composant spécialisé réalise la responsabilité qui lui est attribuée.

Selon le domaine, il peut s'agir de :

- Recovery ;
- Validation ;
- Configuration ;
- Image ;
- ActionEngine ;
- Engines spécialisés ;
- Managers ;
- modules techniques.

Tous ces composants appartiennent au module PimsOS unique.

Ils ne constituent pas des frameworks PowerShell indépendants.

---

# Ordre général du Build

L'ordre général est déterminé par le Workflow et exécuté par le Pipeline.

Le cycle comprend notamment :

1. Initialisation ;
2. Recovery ;
3. Vérification de l'environnement ;
4. Préparation des ressources ;
5. Gestion de l'ISO ;
6. Gestion du WIM ;
7. Gestion du registre ;
8. Chargement de la configuration ;
9. Validation de la configuration ;
10. Application des Actions ;
11. Commit des modifications ;
12. Démontage et nettoyage ;
13. Finalisation du Build ;
14. Reporting.

L'ordre exact peut évoluer si le processus technique du Builder évolue.

---

# Routage des Actions

Les Actions ne sont pas exécutées directement par le Pipeline.

Le routage suit :

```text
Action
    │
    ▼
ActionEngine
    │
    ▼
ActionRegistry
    │
    ▼
Engine spécialisé
    │
    ▼
Manager
    │
    ▼
Module technique
```

Le Pipeline orchestre le processus général mais ne connaît pas les détails d'exécution de chaque type d'Action.

---

# Gestion des erreurs

Une étape peut :

- réussir ;
- générer un avertissement ;
- échouer.

Le traitement d'une erreur est effectué au niveau approprié.

Le Pipeline doit :

- journaliser l'étape concernée ;
- maintenir l'état du Build ;
- arrêter la séquence lorsque l'erreur ne peut pas être traitée ;
- laisser le composant spécialisé effectuer une récupération lorsqu'il en est responsable.

Le Pipeline ne doit pas contenir une duplication des règles techniques de récupération.

Par exemple, la décision concernant la réutilisation d'un montage WIM est centralisée dans :

```powershell
Test-WimMountState()
```

---

# BuildContext

Le BuildContext constitue le mécanisme commun de transmission de l'état et des données du Build.

Le Pipeline transmet le même contexte aux étapes successives.

Les composants enrichissent le contexte dans les limites de leur responsabilité.

---

# Conséquences

## Avantages

- séparation claire entre orchestration et traitement ;
- Pipeline lisible ;
- faible couplage ;
- meilleure testabilité ;
- ajout de nouvelles étapes facilité ;
- ajout de nouveaux types d'Actions localisé ;
- décisions techniques centralisées.

## Inconvénients

- nombre de composants plus important ;
- nécessité de maintenir des contrats entre les différentes couches ;
- orchestration nécessitant une documentation claire.

---

# Alternatives étudiées

## Build monolithique

Rejetée.

Toute la logique aurait été concentrée dans un seul script ou une seule fonction, ce qui aurait augmenté le couplage et rendu les tests et la maintenance plus difficiles.

---

## Appels directs entre composants spécialisés

Rejetés comme mécanisme général.

Des dépendances directes entre les composants spécialisés auraient rendu l'architecture plus difficile à faire évoluer.

Les dépendances doivent suivre les couches définies par l'architecture.

---

## Décisions techniques dans le Pipeline

Rejetées.

Le Pipeline doit orchestrer et déléguer les décisions techniques aux composants responsables.

---

# Règles

Le Pipeline doit :

- orchestrer les étapes ;
- transmettre le BuildContext ;
- respecter l'ordre défini par le Workflow ;
- maintenir le suivi de l'exécution ;
- propager les erreurs de manière contrôlée ;
- utiliser le Logger officiel.

Le Pipeline ne doit pas :

- contenir la logique métier d'un domaine spécialisé ;
- appeler directement les API Windows ;
- contourner l'ActionRegistry ;
- dupliquer une décision technique déjà centralisée ;
- devenir un point de concentration de logique métier.

---

# Évolution

Toute évolution importante du cycle de Build doit préserver la séparation entre :

```text
Orchestration
      │
      ▼
Traitement spécialisé
      │
      ▼
Opérations techniques
```

Une évolution modifiant le rôle fondamental du Pipeline doit être évaluée au regard des Architecture Rules et, lorsque nécessaire, documentée dans une nouvelle ADR.

---

# Décision finale

Le **Workflow définit les grandes phases du Build** et le **Pipeline orchestre leur exécution**.

Les traitements métier et techniques restent délégués aux composants spécialisés.

Le Pipeline constitue donc le chef d'orchestre du Build, mais ne constitue pas un moteur métier monolithique.

---

# Références

- `Architecture.md`
- `ArchitectureRules.md`
- `BuildContext.md`
- `Lifecycle.md`
- `ModuleGuide.md`
- `ADR-0002-BuildContext.md`
- `ADR-0004-BuildPipeline.md`
