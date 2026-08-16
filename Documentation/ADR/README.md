# PimsOS Builder - Architecture Decision Records (ADR)

> Version technique : 3.0.0
>
> Statut : Référence
>
> Dernière mise à jour : 2026-08-16

---

# Objectif

Ce dossier contient les **Architecture Decision Records (ADR)** du projet **PimsOS Builder**.

Une ADR documente une décision importante concernant l'architecture du projet.

Contrairement à la documentation technique, une ADR explique principalement :

- pourquoi une décision a été prise ;
- quelles alternatives ont été étudiées ;
- quelles conséquences ont été acceptées ;
- quelles règles doivent être conservées.

Les ADR constituent la mémoire des décisions structurantes du projet.

---

# Quand créer une ADR ?

Une ADR doit être envisagée lorsqu'une décision :

- modifie l'architecture ;
- impacte plusieurs composants ;
- définit une convention durable ;
- introduit ou supprime un composant architectural important ;
- modifie un contrat entre plusieurs couches ;
- change le modèle de dépendances ;
- mérite d'être conservée pour faciliter la maintenance future.

Les corrections de bugs et les évolutions purement locales ne nécessitent généralement pas d'ADR.

Les décisions d'implémentation qui n'ont pas d'impact architectural peuvent être documentées dans :

```text
Documentation\TechnicalDecisions.md
```

---

# Cycle de vie

Chaque ADR possède un statut.

| Statut | Description |
|---------|-------------|
| Proposed | Proposition en cours d'étude |
| Accepted | Décision adoptée |
| Superseded | Décision remplacée par une autre ADR |
| Deprecated | Décision devenue obsolète sans remplacement direct |
| Rejected | Proposition refusée |

Une ADR adoptée constitue une référence historique.

Lorsqu'une décision évolue de manière importante, la nouvelle décision doit être documentée et référencer la décision précédente.

La conservation de l'historique est prioritaire sur la suppression d'une ancienne décision.

---

# Liste des ADR

| ADR | Sujet | Statut |
|------|--------|--------|
| ADR-0001 | Architecture modulaire | Accepted |
| ADR-0002 | BuildContext central | Accepted |
| ADR-0003 | Organisation des composants | Accepted |
| ADR-0004 | Pipeline de Build | Accepted |
| ADR-0005 | Journalisation centralisée | Accepted |
| ADR-0006 | Configuration JSON | Accepted |
| ADR-0007 | Stratégie de tests | Accepted |
| ADR-0008 | Gestion des erreurs | Accepted |
| ADR-0009 | Dépendances entre composants | Accepted |
| ADR-0010 | Cycle de vie du BuildContext | Accepted |
| ADR-0011 | Contrats d'interface entre composants | Accepted |
| ADR-0012 | Module PowerShell unique | Accepted |

---

# Relations entre les principales décisions

Les ADR ne doivent pas être considérées comme des décisions isolées.

Les principales relations sont :

```text
ADR-0001
Architecture modulaire
        │
        ▼
ADR-0003
Organisation des composants
        │
        ▼
ADR-0012
Module PowerShell unique
        │
        ├───────────────┐
        ▼               ▼
ADR-0009           ADR-0011
Dépendances        Contrats
        │               │
        └───────┬───────┘
                ▼
            Architecture
```

Le BuildContext possède également son propre ensemble de décisions :

```text
ADR-0002
BuildContext central
        │
        ▼
ADR-0010
Cycle de vie du BuildContext
        │
        ▼
ADR-0011
Contrats entre composants
```

Le fonctionnement du Build et sa qualité sont encadrés notamment par :

```text
ADR-0004
Pipeline
    │
    ├──► ADR-0005
    │    Journalisation
    │
    ├──► ADR-0008
    │    Gestion des erreurs
    │
    └──► ADR-0007
         Tests
```

---

# Convention de nommage

Les ADR suivent une numérotation séquentielle :

```text
ADR-0001
ADR-0002
ADR-0003
...
```

Le nom du fichier suit le modèle :

```text
ADR-NNNN-Sujet.md
```

Exemples :

```text
ADR-0001-ModularArchitecture.md
ADR-0002-BuildContext.md
ADR-0012-ModuleUnique.md
```

Le numéro d'une ADR n'est jamais réutilisé après suppression ou abandon d'un document.

---

# Conventions de rédaction

Chaque ADR doit normalement contenir :

- Statut ;
- Date ;
- Décideur ;
- Impact ;
- Contexte ;
- Décision ;
- Conséquences ;
- Alternatives étudiées ;
- Règles lorsque nécessaire ;
- Références.

Une ADR doit expliquer la décision de manière compréhensible sans reproduire toute la documentation technique du projet.

---

# Historique des décisions

Une ADR acceptée ne doit pas être réécrite pour faire disparaître son contexte historique.

Lorsque l'architecture évolue :

1. conserver la décision historique ;
2. documenter la nouvelle décision ;
3. indiquer la relation entre les ADR ;
4. mettre à jour les documents d'architecture concernés.

Les corrections purement éditoriales peuvent être réalisées sans créer une nouvelle ADR.

---

# Intégration avec la documentation

Les ADR doivent rester cohérentes avec :

```text
Documentation\Architecture.md
Documentation\ArchitectureRules.md
Documentation\TechnicalDecisions.md
Documentation\ProjectStatus.md
Documentation\Roadmap.md
Documentation\BuildContext.md
```

Une ADR ne remplace pas ces documents.

Elle explique la décision ; la documentation technique explique comment cette décision est matérialisée dans le projet.

---

# Intégration avec Git

Lorsqu'une décision architecturale est prise ou modifiée :

- ajouter ou mettre à jour l'ADR concernée ;
- mettre à jour la documentation impactée ;
- vérifier les tests concernés ;
- créer un commit Git cohérent.

Un changement architectural important doit être identifiable dans l'historique Git.

---

# Vérification avant acceptation

Avant d'accepter une nouvelle ADR, vérifier :

| Vérification | Oui | Non |
|--------------|:---:|:---:|
| Le problème est clairement décrit | ☐ | ☐ |
| La décision est explicite | ☐ | ☐ |
| Les alternatives sont étudiées | ☐ | ☐ |
| Les conséquences sont identifiées | ☐ | ☐ |
| Les composants impactés sont connus | ☐ | ☐ |
| Les règles nécessaires sont précisées | ☐ | ☐ |
| Les documents associés sont identifiés | ☐ | ☐ |
| Les tests nécessaires sont identifiés | ☐ | ☐ |
| La décision est cohérente avec les ADR existantes | ☐ | ☐ |

---

# Liste des documents ADR

```text
Documentation
└── ADR
    ├── ADR-0001-ModularArchitecture.md
    ├── ADR-0002-BuildContext.md
    ├── ADR-0003-FrameworkStructure.md
    ├── ADR-0004-BuildPipeline.md
    ├── ADR-0005-CentralizedLogging.md
    ├── ADR-0006-JsonConfiguration.md
    ├── ADR-0007-TestingStrategy.md
    ├── ADR-0008-ErrorHandling.md
    ├── ADR-0009-FrameworkDependencies.md
    ├── ADR-0010-BuildContextLifecycle.md
    ├── ADR-0011-FrameworkContracts.md
    ├── ADR-0012-ModuleUnique.md
    └── README.md
```

Les noms indiqués correspondent aux documents de référence. Les variantes de fichiers créées pendant des évolutions ou migrations de documentation doivent être harmonisées avec cette nomenclature avant intégration définitive.

---

# Références

Pour comprendre les décisions décrites dans ce dossier, consulter également :

- `Documentation\Architecture.md`
- `Documentation\ArchitectureRules.md`
- `Documentation\API.md`
- `Documentation\BuildContext.md`
- `Documentation\ModuleGuide.md`
- `Documentation\TechnicalDecisions.md`
- `Documentation\Testing.md`
