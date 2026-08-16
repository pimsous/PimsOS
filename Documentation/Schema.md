# PimsOS Builder - Schémas

> Version technique : 3.0.0
>
> Statut : Référence
>
> Dernière mise à jour : 2026-08-16

---

# Objectif

Ce document décrit les principaux modèles de données utilisés dans le projet **PimsOS Builder**.

Il constitue une référence pour les objets et structures échangés entre les différents composants du moteur de Build.

---

# Principes

Les modèles de données doivent être :

- simples ;
- cohérents ;
- documentés ;
- réutilisables ;
- extensibles.

Chaque structure possède une responsabilité clairement définie.

Les modèles doivent rester alignés avec les contrats réels du code et du BuildContext.

---

# BuildContext

Le `BuildContext` est l'objet central du projet.

Il transporte les informations nécessaires à l'exécution d'un Build et constitue le contrat partagé entre les composants concernés.

Toutes les couches du Builder utilisent le même BuildContext afin de partager les informations du Build.

## Principales catégories

| Catégorie | Description |
|-----------|-------------|
| Project | Métadonnées du projet, version et informations Windows |
| Build | Informations relatives au Build courant |
| BuildState | État d'exécution du Build |
| Configuration | Configuration active issue des données de configuration et du profil |
| ConfigurationProfile | Profil sélectionné |
| Workspace | Répertoires et ressources temporaires |
| ISO | Informations relatives à l'ISO source |
| WIM | Informations relatives à l'image WIM |
| Image | Image Windows sélectionnée |
| Registry | Informations relatives aux ruches et opérations Registry |
| Packages | Packages sélectionnés ou traités |
| Drivers | Pilotes sélectionnés ou traités |
| Tweaks | Personnalisations sélectionnées |
| Services | Services Windows concernés |
| Features | Fonctionnalités Windows concernées |
| Report | Rapport d'exécution |
| Logger | Informations du système de journalisation |
| Statistics | Statistiques d'exécution |

Voir également :

- `BuildContext.md`

---

# BuildState

Le `BuildState` représente l'état courant de l'exécution du Build.

Il permet notamment de suivre :

- l'initialisation du Builder ;
- les vérifications de l'environnement ;
- la progression du Pipeline ;
- l'état des ressources montées ;
- le chargement de la configuration ;
- l'application des personnalisations ;
- les opérations de Recovery ;
- l'état global du Build.

Les composants doivent utiliser le BuildState pour représenter l'état d'exécution relevant de leur responsabilité.

---

# Configuration

Les données de configuration utilisent notamment le format JSON.

Elles regroupent les définitions nécessaires à la construction de la configuration du Build, notamment :

- les catégories ;
- les Tweaks ;
- les profils ;
- les métadonnées du projet lorsque définies dans `version.json`.

Exemple actuel de `version.json` :

```json
{
    "Project": "PimsOS Builder",
    "Version": "3.0.0",
    "Windows": {
        "Release": "11 25H2",
        "Build": "26100"
    },
    "Author": "Pims",
    "Company": "PimsOS",
    "Repository": "https://github.com/Pims/PimsOS",
    "BuildDate": null
}
```

Les structures de configuration doivent rester documentées et évoluer de manière contrôlée.

---

# Journalisation

Les événements de journalisation utilisent une structure homogène au niveau du système de logging.

Les informations associées à une entrée peuvent notamment comprendre :

| Champ | Description |
|-------|-------------|
| Date | Date et heure de l'événement |
| Niveau | Niveau de journalisation |
| Module | Composant émetteur |
| Message | Description de l'événement |

Les valeurs exactes et le format de stockage sont définis par le composant `Logger`.

---

# Rapports

Les rapports de Build regroupent notamment :

- la durée d'exécution ;
- les opérations réalisées ;
- les informations ;
- les avertissements ;
- les erreurs ;
- le résultat global.

Les formats de rapport futurs ou complémentaires sont pilotés par le composant Reporting.

---

# États d'exécution

Les composants utilisent des états permettant de suivre le cycle d'exécution du Build.

Les valeurs doivent correspondre aux états réellement définis par le `BuildState`.

Exemples de catégories d'état :

```text
NotStarted
Initialized
Recovery
Environment
Pipeline
ApplyingConfiguration
ConfigurationApplied
Completed
Failed
```

Les noms des états doivent rester cohérents dans l'ensemble du projet.

---

# Actions

Les Actions représentent les opérations de personnalisation à exécuter.

Une Action est traitée selon le flux :

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

Une Action peut notamment contenir :

- un identifiant ;
- un type ;
- un provider lorsque nécessaire ;
- les paramètres nécessaires à son traitement ;
- son état d'exécution ;
- sa durée ;
- son erreur éventuelle.

Les propriétés exactes dépendent du type d'Action.

---

# Tweaks

Les Tweaks représentent les personnalisations disponibles dans le framework.

Un Tweak peut notamment contenir :

- un identifiant ;
- une catégorie ;
- des métadonnées ;
- un état d'activation ;
- des Actions ;
- des contraintes de compatibilité.

Les Tweaks constituent des données de configuration et ne contiennent pas de logique PowerShell exécutable.

---

# Profils

Les profils déterminent les personnalisations sélectionnées pour un scénario de Build.

Ils permettent de sélectionner et d'activer les Tweaks sans modifier leurs définitions sources.

Le moteur de configuration produit ensuite une configuration finale destinée à l'exécution.

---

# Statistiques

Les statistiques sont centralisées dans le BuildContext.

Elles peuvent notamment comprendre :

- `ActionsProcessed`
- `PackagesProcessed`
- `DriversProcessed`
- `FeaturesProcessed`
- `CapabilitiesProcessed`
- `CommandsProcessed`
- `FilesProcessed`
- `FoldersProcessed`
- `EnvironmentProcessed`
- `ScheduledTasksProcessed`
- `ShortcutsProcessed`
- `ServicesProcessed`
- `RegistryActionsProcessed`
- `TweaksApplied`
- `Errors`
- `Warnings`

Les statistiques sont mises à jour par les composants responsables de leur domaine.

---

# Flux de données

Le flux général des données peut être représenté ainsi :

```text
version.json
      │
      ▼
Configuration
      │
      ▼
Profils
      │
      ▼
Tweaks
      │
      ▼
BuildContext
      │
      ▼
BuildState
      │
      ▼
Workflow / Pipeline
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
Modules techniques
```

Le BuildContext constitue le contrat central de partage de l'état et des données du Build.

Les composants ne doivent pas utiliser un état global pour transporter les informations d'exécution.

---

# Évolution des modèles

Toute modification d'un modèle de données doit :

1. préserver la compatibilité lorsque cela est possible ;
2. être documentée ;
3. être validée par les tests ;
4. mettre à jour les documents concernés ;
5. conserver la cohérence avec le BuildContext et le BuildState.

Une modification affectant un contrat architectural doit également être évaluée au regard des Architecture Rules et des ADR.

---

# Références

Consulter également :

- `API.md`
- `Architecture.md`
- `ArchitectureRules.md`
- `BuildContext.md`
- `Lifecycle.md`
- `ModuleGuide.md`
- `Testing.md`
- `Documentation\ADR\`
