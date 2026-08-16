# ADR-0010 — Cycle de vie du BuildContext

- **Statut** : Acceptée
- **Date** : 2026-07-19
- **Dernière mise à jour** : 2026-08-16
- **Décideur** : Pims
- **Impact** : Architecture du Build

---

# Contexte

Le `BuildContext` constitue l'objet central partagé entre les composants du framework.

Tout au long d'un Build, il est progressivement enrichi avec :

- les informations du projet ;
- la configuration ;
- les profils et les Tweaks sélectionnés ;
- les informations système ;
- les ressources du Build ;
- l'état du Pipeline ;
- les résultats des composants ;
- les statistiques ;
- les rapports.

L'évolution du projet a également introduit un objet `BuildState` dédié à l'état courant de l'exécution.

Il est donc nécessaire de définir précisément le cycle de vie du BuildContext et de distinguer les données du Build de son état d'exécution.

---

# Décision

Le `BuildContext` possède un cycle de vie unique.

Il est :

- créé une seule fois au début du Build ;
- initialisé avant l'exécution du Pipeline ;
- enrichi progressivement pendant le traitement ;
- transmis aux composants concernés ;
- finalisé à la fin du Build ;
- utilisé ensuite pour le reporting et le diagnostic.

Le `BuildContext` n'est jamais recréé ou remplacé pendant l'exécution normale du Build.

Le `BuildState` contenu dans le contexte représente spécifiquement l'état courant du Build.

---

# Cycle de vie

```text
Création
    │
    ▼
Initialisation
    │
    ▼
Recovery
    │
    ▼
Validation de l'environnement
    │
    ▼
Workflow / Pipeline
    │
    ▼
Enrichissement progressif
    │
    ▼
Exécution des Actions
    │
    ▼
Finalisation
    │
    ▼
Reporting / Diagnostic
```

---

# Création

Le Builder crée une nouvelle instance du `BuildContext` au début du processus.

Cette étape est réalisée par :

```powershell
New-BuildContext
```

Le contexte initial contient les informations nécessaires à son initialisation.

Il ne doit pas être reconstruit ultérieurement pour remplacer l'état courant.

---

# Initialisation

Le Builder initialise le contexte avec les informations et services nécessaires au démarrage.

Cette phase comprend notamment :

- les métadonnées du projet ;
- les paramètres du Build ;
- les chemins de travail ;
- le Logger ;
- le BuildState ;
- les informations initiales de configuration.

L'initialisation détaillée est réalisée par les composants prévus à cet effet.

---

# Recovery

Le Recovery intervient avant l'exécution normale du Pipeline afin de traiter les ressources éventuellement laissées par un Build précédent.

Le contexte conserve les informations nécessaires à cette phase.

La décision relative à l'état d'un montage WIM est centralisée dans :

```powershell
Test-WimMountState()
```

Le Pipeline ne doit pas recréer cette décision ailleurs.

---

# Validation de l'environnement

Une fois le contexte initialisé, les prérequis nécessaires au Build sont vérifiés.

Les contrôles peuvent notamment concerner :

- PowerShell ;
- les privilèges nécessaires ;
- Git ;
- DISM ;
- les ressources d'entrée ;
- l'espace disque ;
- l'état de l'environnement de travail.

L'état des vérifications est conservé dans le contexte et son BuildState.

---

# Enrichissement

Chaque composant enrichit le `BuildContext` avec les informations relevant de sa responsabilité.

Exemples :

## Image

- ISO ;
- WIM ;
- éditions disponibles ;
- image sélectionnée ;
- état du montage.

## Registry

- ruches montées ;
- informations relatives aux opérations Registry.

## Configuration

- profil sélectionné ;
- configuration finale ;
- éléments de configuration.

## Actions

- Actions traitées ;
- résultats ;
- statistiques ;
- erreurs éventuelles.

Chaque composant ne doit pas modifier arbitrairement les sections appartenant à un autre domaine.

---

# BuildState

Le `BuildState` est contenu dans le BuildContext mais possède une responsabilité spécifique : représenter l'état d'exécution.

Il permet notamment de suivre :

- l'initialisation ;
- le Recovery ;
- l'environnement ;
- la progression du Pipeline ;
- l'état des ressources ;
- le chargement de la configuration ;
- l'application des personnalisations ;
- l'état final du Build.

Le BuildState ne doit pas être remplacé par une collection d'indicateurs dispersés dans plusieurs objets.

---

# Utilisation

Pendant l'exécution du Build, les composants lisent les informations déjà présentes dans le BuildContext et mettent à jour les propriétés relevant de leur responsabilité.

Le même contexte est transmis aux différentes étapes.

Le BuildContext constitue donc le contrat central de partage des données du Build.

---

# Finalisation

À la fin du Build, le contexte contient notamment :

- l'état final du Build ;
- les résultats des opérations ;
- les erreurs éventuelles ;
- les avertissements ;
- les statistiques ;
- les informations nécessaires au reporting.

La finalisation est assurée par le mécanisme de fin de Build :

```powershell
Complete-Build
```

Le contexte reste exploitable pour le reporting et le diagnostic.

Il n'est pas nécessaire de le transformer en objet distinct simplement pour produire ces informations.

---

# Archivage et reporting

Le BuildContext peut être utilisé pour :

- générer les rapports ;
- produire les statistiques ;
- faciliter le diagnostic ;
- analyser le déroulement d'un Build.

Les informations du contexte constituent une source importante pour le reporting.

---

# Responsabilités

## Builder

Le Builder :

- crée le BuildContext ;
- initialise le contexte ;
- démarre le processus de Build ;
- déclenche la finalisation.

---

## Workflow

Le Workflow :

- définit les grandes phases ;
- organise l'ordre général du traitement.

---

## Pipeline

Le Pipeline :

- transmet le BuildContext ;
- exécute les étapes ;
- suit l'état du Build ;
- ne remplace jamais le contexte ;
- ne duplique pas les décisions centralisées.

---

## Composants spécialisés

Chaque composant :

- lit les informations nécessaires ;
- met à jour uniquement les données dont il est responsable ;
- respecte les contrats du BuildContext et du BuildState ;
- ne remplace pas le contexte par un nouvel objet.

---

# Conséquences

## Avantages

- cycle de vie clairement défini ;
- données cohérentes ;
- état d'exécution centralisé ;
- meilleure traçabilité ;
- interfaces plus simples ;
- meilleure testabilité ;
- diagnostic facilité.

## Inconvénients

- structure du contexte plus importante ;
- nécessité de maintenir les contrats ;
- discipline nécessaire pour éviter d'ajouter inutilement des données.

---

# Alternatives étudiées

## Plusieurs BuildContext

Rejetée.

Plusieurs contextes compliqueraient la circulation des données et pourraient produire des états divergents.

---

## Reconstruction du contexte

Rejetée.

Remplacer le contexte en cours d'exécution risquerait de perdre des informations ou de créer des incohérences entre les composants.

---

## État global séparé

Rejeté comme mécanisme général.

Des variables globales ou des objets d'état parallèles rendraient le suivi du Build plus difficile et augmenteraient les dépendances implicites.

Le `BuildState` intégré au BuildContext constitue le mécanisme de référence pour l'état d'exécution.

---

# Règles

Le `BuildContext` :

- est créé une seule fois ;
- est transmis pendant tout le cycle du Build ;
- n'est jamais remplacé dans l'exécution normale ;
- est enrichi progressivement ;
- reste cohérent avec le BuildState.

Les composants ne doivent pas :

- créer un second contexte pour le même Build ;
- utiliser un état global pour contourner le contexte ;
- remplacer le contexte par une copie locale persistante ;
- modifier arbitrairement les propriétés appartenant à d'autres domaines.

Toute nouvelle propriété doit être justifiée par un besoin réel de données ou d'état partagé.

Avant d'ajouter une propriété, vérifier si une propriété équivalente existe déjà.

---

# Tests

Les tests doivent vérifier notamment :

- la création du BuildContext ;
- son initialisation ;
- l'existence du BuildState ;
- la conservation du même contexte entre les étapes ;
- la mise à jour des propriétés attendues ;
- la progression du BuildState ;
- la conservation des statistiques ;
- la finalisation du Build.

Toute modification du cycle de vie doit être protégée par des tests adaptés.

---

# Évolution

Toute évolution importante du cycle de vie doit :

1. être analysée ;
2. préserver le principe du contexte unique ;
3. mettre à jour `BuildContext.md` ;
4. mettre à jour `Schema.md` si nécessaire ;
5. mettre à jour les tests ;
6. mettre à jour les documents concernés ;
7. faire l'objet d'une nouvelle ADR lorsque le contrat architectural change.

---

# Décision finale

Le `BuildContext` reste le **contexte unique du Build**.

Il est créé au démarrage, enrichi progressivement, transmis aux composants et finalisé à la fin du processus.

Le `BuildState`, contenu dans le BuildContext, centralise l'état d'exécution.

Cette organisation constitue le modèle de référence de PimsOS Builder 3.0.0.

---

# Références

- `ADR-0002-BuildContext.md`
- `ADR-0004-BuildPipeline.md`
- `ADR-0009-FrameworkDependencies.md`
- `BuildContext.md`
- `Lifecycle.md`
- `Schema.md`
- `Architecture.md`
