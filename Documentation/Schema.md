# Schémas

## Objectif

Ce document décrit les principaux modèles de données utilisés dans le projet **PimsOS Builder**.

Il constitue la référence des objets échangés entre les différents composants du moteur de build.

---

# Principes

Les modèles de données doivent être :

- simples ;
- cohérents ;
- documentés ;
- réutilisables ;
- extensibles.

Chaque structure possède une responsabilité unique.

---

# BuildContext

Le `BuildContext` est l'objet central du projet.

Il transporte toutes les informations nécessaires à l'exécution d'un build.

Toutes les couches du Builder utilisent le même BuildContext afin d'échanger leurs informations.

## Principales catégories

| Catégorie | Description |
|-----------|-------------|
| Project | Métadonnées du projet (nom, version, Windows, auteur...) |
| Build | Paramètres du build en cours |
| BuildState | État global du moteur de build |
| Configuration | Configuration active issue des profils |
| Workspace | Répertoires temporaires |
| ISO | Image ISO source |
| WIM | Image Windows détectée |
| Image | Édition Windows sélectionnée |
| Registry | Ruches du registre montées |
| Packages | Packages à intégrer |
| Drivers | Pilotes à intégrer |
| Tweaks | Personnalisations disponibles |
| Services | Services Windows |
| Features | Fonctionnalités Windows |
| Statistics | Statistiques d'exécution |
| Report | Rapport de build |
| Logger | Journalisation |

Voir également :

- BuildContext.md

---

# BuildState

Le `BuildState` représente l'état courant du moteur de build.

Il permet notamment de suivre :

- l'initialisation du Builder ;
- les vérifications de l'environnement ;
- la progression du Pipeline ;
- le montage des images Windows ;
- le chargement de la configuration ;
- l'application des personnalisations ;
- les opérations de Recovery.

Toutes les décisions d'exécution du Builder s'appuient sur cet objet.

---

# Configuration

Les fichiers de configuration sont stockés au format JSON.

Ils regroupent notamment :

- la configuration globale du Builder ;
- les métadonnées du projet ;
- les profils de personnalisation ;
- les définitions de tweaks.

Exemple de `version.json` :

```json
{
    "Project": "PimsOS Builder",
    "Version": "0.4.0",
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

Les propriétés doivent être documentées et conserver une rétrocompatibilité lorsque cela est possible.

---

# Journalisation

Les entrées de journal utilisent une structure homogène.

| Champ | Description |
|-------|-------------|
| Date | Date et heure |
| Niveau | Information, Warning, Error, Success |
| Module | Composant émetteur |
| Message | Description de l'événement |

---

# Rapports

Les rapports de build regroupent notamment :

- la durée d'exécution ;
- les opérations réalisées ;
- les avertissements ;
- les erreurs ;
- le résultat global.

Ils peuvent être produits dans plusieurs formats selon les besoins :

- JSON ;
- HTML ;
- PDF.

---

# États d'exécution

Les composants utilisent des états communs afin d'assurer un suivi cohérent.

Exemples :

- NotStarted
- Initialized
- Recovery
- Environment
- Pipeline
- ApplyingConfiguration
- ConfigurationApplied
- Completed
- Failed

Les noms des états doivent rester cohérents dans tout le projet.

---

# Flux de données

Les informations circulent entre les composants selon le principe suivant :

```text
version.json
      │
      ▼
Config.json
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
Pipeline
      │
      ▼
Engines
      │
      ▼
Rapport
```

Tous les composants du Builder échangent leurs informations exclusivement via le BuildContext et le BuildState.

Les échanges directs entre composants sont interdits afin de garantir une architecture modulaire et facilement testable.

---

# Évolution

Toute modification d'un modèle de données doit :

1. préserver la compatibilité lorsque c'est possible ;
2. être documentée ;
3. être validée par les tests ;
4. être reportée dans les notes de version si elle impacte l'API publique ;
5. conserver la cohérence avec le BuildContext et le BuildState.

---

# Références

Consulter également :

- Architecture.md
- BuildContext.md
- API.md
- Lifecycle.md