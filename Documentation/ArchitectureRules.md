# Architecture Rules

> Version technique : 3.0.0
>
> Statut : Référence
>
> Dernière mise à jour : 2026-08-16

---

# Objectif

Ce document définit les règles d'architecture que tout composant de PimsOS Builder doit respecter.

Ces règles garantissent la cohérence, la maintenabilité et l'évolutivité du projet.

Elles complètent :

- `Architecture.md` ;
- `ModuleGuide.md` ;
- les Architecture Decision Records (ADR).

Le non-respect de ces règles doit être considéré comme une anomalie d'architecture.

---

# Règle 1 — Module PowerShell unique

Le projet repose sur un unique module PowerShell :

```text
PimsOS
```

Tous les composants internes appartiennent à ce module.

Aucun composant interne ne doit être publié comme module PowerShell indépendant.

Référence :

- Architecture.md
- ADR-0012

---

# Règle 2 — Point d'entrée unique

Le seul point d'entrée du framework est :

```text
PimsOS.psm1
```

Il est responsable :

- du chargement des composants internes ;
- de l'initialisation du framework ;
- de l'exposition de l'API publique.

---

# Règle 3 — API publique centralisée

Toutes les fonctions publiques doivent être exportées uniquement depuis :

```text
PimsOS.psm1
```

Les composants internes ne doivent jamais utiliser :

```powershell
Export-ModuleMember
```

---

# Règle 4 — Aucun Import-Module interne

Les composants internes ne doivent jamais charger un autre composant avec :

```powershell
Import-Module
```

Tous les composants sont chargés automatiquement par PimsOS.psm1.

---

# Règle 5 — Responsabilité unique

Chaque composant possède une responsabilité clairement définie.

Un composant ne doit réaliser qu'une seule tâche.

Toute responsabilité supplémentaire doit être confiée à un autre composant.

---

# Règle 6 — Architecture en couches

Les couches de PimsOS sont :

```text
Infrastructure
        │
        ▼
Core
        │
        ▼
Configuration
        │
        ▼
Image
        │
        ▼
Engine
        │
        ▼
ActionEngine
        │
        ▼
ActionRegistry
        │
        ▼
Engines spécialisés
        │
        ▼
Managers
        │
        ▼
Modules Windows
```

Chaque couche possède un rôle précis.

Une couche ne doit jamais contourner une autre couche.

---

# Règle 7 — Dépendances descendantes

Les dépendances suivent toujours la même direction.

```text
Build

↓

Workflow

↓

Pipeline

↓

Engine

↓

ActionEngine

↓

ActionRegistry

↓

Engine spécialisé

↓

Manager

↓

Module Windows
```

Les dépendances circulaires sont interdites.

---

# Règle 8 — BuildContext unique

Toutes les informations transitent par un BuildContext unique.

Le BuildContext constitue également le contrat entre tous les composants du framework.

Il contient notamment :

- les informations du projet ;
- la version du Builder ;
- les informations sur la version de Windows ciblée ;
- les chemins de travail ;
- le BuildState ;
- les statistiques ;
- les ressources montées ;
- la configuration fusionnée ;
- les objets Tweaks et Actions.

Les composants ne doivent jamais utiliser :

- variables globales ;
- états partagés ;
- échanges implicites.

Référence :

- BuildContext.md
- ADR-0002
- ADR-0010

---
# Règle 9 — Décisions centralisées

Toute décision importante du Builder doit être centralisée dans une fonction unique.

Le Pipeline et le Workflow ne doivent jamais contenir de logique de décision.

Exemples :

- validation d'un montage WIM → Test-WimMountState()
- validation de la configuration → Validation.ps1
- résolution du moteur → ActionRegistry
- exécution d'une Action → ActionEngine

Cette règle garantit qu'une décision métier ne possède qu'un seul point de maintenance.

# Règle 10 — Aucun état global

Aucune logique métier ne doit dépendre :

- d'une variable globale ;
- d'une variable script ;
- d'un singleton implicite.

Toutes les données doivent être contenues dans le BuildContext.

---
# Règle 10 bis — Routage des Actions

Toute Action doit être exécutée via le mécanisme suivant :

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
Module Windows

Aucun composant ne doit appeler directement un Engine spécialisé.

Tout nouveau type d'Action doit être enregistré dans l'ActionRegistry.

# Règle 11 — Logger obligatoire

Tous les composants doivent utiliser le système de journalisation officiel.

L'utilisation de :

```powershell
Write-Host
```

est interdite dans la logique métier.

Les messages doivent être journalisés via le Logger du projet.

Référence :

- ADR-0005

---

# Règle 12 — Gestion des erreurs

Toutes les erreurs doivent :

- être interceptées ;
- être journalisées ;
- être propagées de manière contrôlée.

Les blocs `catch` ne doivent jamais masquer une erreur sans justification.

Référence :

- ADR-0008

---

# Règle 13 — Configuration externe

Aucune valeur métier ne doit être codée en dur.

Toute configuration doit provenir :

- des fichiers JSON ;
- des paramètres utilisateur ;
- du BuildContext.

Les versions de Windows supportées ne doivent jamais être codées en dur.

Le Builder doit permettre de sélectionner dynamiquement l'image Windows à personnaliser à partir des métadonnées du WIM.

---

# Règle 14 — Séparation de la logique métier

Les modules techniques réalisent uniquement des opérations techniques.

Ils ne doivent jamais contenir :

- de logique métier ;
- de règles fonctionnelles ;
- de décisions d'architecture.

---
# Règle 14 bis — Séparation Engine / Manager

Les Engines contiennent exclusivement la logique métier.

Les Managers encapsulent les opérations techniques.

Un Engine ne doit jamais appeler directement une API Windows.

Toute interaction avec Windows doit être réalisée par un Manager ou un module technique.

# Règle 14 bis A — Indépendance de la version de Windows

Le moteur PimsOS Builder ne doit jamais dépendre d'une version spécifique de Windows.

Les informations relatives à la version ciblée (Release, Build, Édition) doivent être découvertes dynamiquement ou provenir de la configuration.

Le moteur doit pouvoir personnaliser toute image Windows compatible sans modification de son architecture.

# Règle 15 — Documentation obligatoire

Toute fonction publique doit être documentée.

Toute évolution importante de l'architecture doit être accompagnée :

- d'une mise à jour de la documentation ;
- d'une ADR si nécessaire.

---

# Règle 16 — Tests

Tout nouveau composant doit disposer de tests adaptés.

Les tests doivent vérifier :

- le comportement nominal ;
- les cas d'erreur ;
- les cas limites.

Référence :

- Testing.md
- ADR-0007

---

# Règle 17 — Conventions de nommage

Les composants doivent respecter les conventions définies dans :

- CodingStandards.md
- ModuleGuide.md

Les noms doivent être explicites et cohérents.

Les abréviations doivent être évitées.

---

# Règle 17 bis — Compatibilité Windows

Le Builder ne doit jamais être conçu pour une version unique de Windows.

La version de Windows ciblée doit être déterminée dynamiquement à partir :

- du fichier WIM ;
- du profil sélectionné ;
- de la configuration du projet.

Les Tweaks peuvent définir leurs propres contraintes de compatibilité via les propriétés Supported.

# Règle 18 — Évolutions

Toute nouvelle fonctionnalité doit respecter l'architecture existante.

L'architecture ne doit pas être contournée pour répondre à un besoin ponctuel.

Si une évolution nécessite une modification importante de l'architecture :

1. mettre à jour Architecture.md ;
2. créer une nouvelle ADR ;
3. implémenter la modification ;
4. mettre à jour les tests.

---

# Règle 19 — Revue d'architecture

Avant toute fusion importante, vérifier :

- la cohérence des dépendances ;
- le respect des couches ;
- le respect du BuildContext ;
- la documentation ;
- les ADR ;
- les tests.

---
# Règle 20 — Recovery

Toute reprise de build doit être validée avant d'être utilisée.

Le mécanisme de validation est centralisé dans :

Test-WimMountState()

Aucun autre composant ne doit décider si un build est réutilisable.

En cas de montage invalide, le Recovery doit :

- démonter les ressources concernées ;
- nettoyer l'environnement ;
- reconstruire le build.

Cette logique ne doit jamais être dupliquée dans le Pipeline ou le Workflow.

# Checklist de validation

Avant de valider une évolution, vérifier les points suivants :

| Vérification | Oui | Non |
|--------------|:---:|:---:|
| Respecte l'architecture | ☐ | ☐ |
| Respecte les couches | ☐ | ☐ |
| Utilise le BuildContext | ☐ | ☐ |
| N'utilise aucune variable globale | ☐ | ☐ |
| Utilise le Logger | ☐ | ☐ |
| Gère correctement les erreurs | ☐ | ☐ |
| Est documenté | ☐ | ☐ |
| Dispose de tests | ☐ | ☐ |
| Nécessite une ADR ? | ☐ | ☐ |
| Utilise l'ActionRegistry | ☐ | ☐ |
| Respecte la séparation Engine / Manager | ☐ | ☐ |
| Compatible avec les versions Windows supportées | ☐ | ☐ |
---

# Références

- Architecture.md
- BuildContext.md
- CodingStandards.md
- ModuleGuide.md
- Testing.md
- Documentation/ADR/

---

# Conclusion

Ce document constitue la référence normative de l'architecture de PimsOS.

Toute contribution au projet doit respecter les règles définies dans ce document.

En cas de conflit entre une implémentation et ces règles, l'architecture fait foi et l'implémentation doit être corrigée.