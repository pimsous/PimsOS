# ADR-0002 — Utilisation d'un BuildContext central

- **Statut** : Acceptée
- **Date** : 2026-07-19
- **Dernière mise à jour** : 2026-08-16
- **Décideur** : Pims
- **Impact** : Architecture du framework

---

# Contexte

PimsOS repose sur plusieurs composants collaborant au sein d'un même processus de Build.

Ces composants ont besoin d'accéder à des informations communes telles que :

- les paramètres du projet ;
- la configuration ;
- les profils ;
- les chemins de travail ;
- les informations relatives à l'image Windows ;
- les packages ;
- les pilotes ;
- les journaux ;
- les rapports ;
- les statistiques ;
- l'état courant du Build.

Sans mécanisme commun, ces informations devraient être transmises individuellement entre les fonctions et les composants, entraînant :

- une multiplication des paramètres ;
- un fort couplage ;
- des interfaces difficiles à maintenir ;
- une circulation de l'état plus complexe ;
- des difficultés supplémentaires pour les tests.

---

# Décision

Toutes les informations partagées nécessaires à l'exécution d'un Build sont regroupées dans un objet central nommé **BuildContext**.

Le `BuildContext` est créé au démarrage du Build puis enrichi progressivement pendant son cycle de vie.

Les différents composants reçoivent le contexte nécessaire à leur traitement et mettent à jour uniquement les propriétés relevant de leur responsabilité.

Le BuildContext constitue le contrat central de partage des données entre les couches du framework.

---

# Structure générale

Le `BuildContext` regroupe notamment les informations suivantes :

- `Project`
- `Build`
- `BuildState`
- `Configuration`
- `ConfigurationProfile`
- `ISO`
- `WIM`
- `Image`
- `Workspace`
- `Registry`
- `Packages`
- `Drivers`
- `Tweaks`
- `Services`
- `Features`
- `Report`
- `Logger`
- `Statistics`

La structure détaillée est documentée dans :

- `BuildContext.md`
- `Schema.md`

---

# BuildState

L'état d'exécution du Builder est séparé dans un objet dédié :

```text
BuildState
```

Le `BuildContext` contient ce BuildState.

Cette séparation permet de distinguer :

- les données du Build ;
- l'état courant de l'exécution.

Le BuildState permet notamment de suivre :

- l'initialisation ;
- le Recovery ;
- les vérifications d'environnement ;
- la progression du Pipeline ;
- l'état des ressources ;
- le chargement de la configuration ;
- l'application des personnalisations ;
- l'état final du Build.

---

# Principes d'utilisation

Le BuildContext doit être :

- créé une fois au début du Build ;
- enrichi progressivement ;
- partagé entre les composants concernés ;
- conservé pendant toute l'exécution.

Les composants doivent modifier uniquement les propriétés relevant de leur responsabilité.

Le BuildContext ne doit pas devenir un conteneur de logique métier : il transporte les données et l'état nécessaires au fonctionnement du framework.

---

# Conséquences

## Avantages

- réduction du nombre de paramètres ;
- échange d'informations simplifié ;
- cohérence entre les composants ;
- meilleure lisibilité des interfaces ;
- meilleure testabilité ;
- facilité d'extension ;
- centralisation de l'état partagé ;
- réduction des dépendances implicites.

## Inconvénients

- définition initiale plus importante ;
- nécessité de maintenir un contrat commun ;
- évolution de la structure nécessitant une coordination entre plusieurs composants ;
- risque d'ajouter inutilement des données au contexte si ses responsabilités ne sont pas respectées.

---

# Alternatives étudiées

## Transmission individuelle des paramètres

Rejetée.

Chaque fonction ou composant aurait nécessité un nombre croissant de paramètres, rendant les interfaces plus complexes et augmentant le couplage.

---

## Variables globales

Rejetée.

Les variables globales rendent l'état difficile à maîtriser, compliquent les tests et créent des dépendances implicites.

---

## États partagés séparés

Rejetés comme mécanisme général de communication du Build.

Multiplier les objets d'état indépendants rendrait plus difficile la compréhension du cycle d'exécution.

Le `BuildContext` reste le contrat central, avec `BuildState` comme représentation dédiée de l'état d'exécution.

---

# Règles

Les composants ne doivent pas modifier arbitrairement le BuildContext.

Chaque composant ne met à jour que les sections dont il est responsable.

Aucune variable globale ne doit être utilisée pour transporter l'état du Build entre les couches.

Les variables de portée `script:` peuvent exister pour un état interne limité à un composant, par exemple une table de providers, mais ne remplacent pas le BuildContext.

Toute nouvelle propriété doit être justifiée par un besoin réel de partage ou d'état.

Avant d'ajouter une propriété, vérifier qu'une propriété équivalente n'existe pas déjà.

---

# Conséquences sur le développement

Toutes les nouvelles fonctionnalités qui nécessitent de partager des informations entre plusieurs composants doivent utiliser le `BuildContext`.

Les interfaces internes doivent privilégier :

```text
Context + paramètres spécifiques
```

plutôt qu'une multiplication de paramètres représentant des informations déjà présentes dans le contexte.

Les nouveaux composants doivent respecter le contrat du BuildContext et du BuildState.

Toute évolution importante du modèle de contexte doit :

1. mettre à jour `BuildContext.md` ;
2. mettre à jour `Schema.md` si nécessaire ;
3. mettre à jour les tests concernés ;
4. mettre à jour une ADR lorsqu'elle modifie le contrat architectural.

---

# Relation avec les autres décisions

Cette décision est directement liée à :

- `ADR-0010 — Cycle de vie du BuildContext`
- `ADR-0011 — Contrats entre composants`
- `ADR-0012 — Module PowerShell unique`

Elle complète également :

- `Architecture.md`
- `ArchitectureRules.md`

---

# Décision finale

Le **BuildContext reste le contrat central de partage des informations du Build**.

Le framework ne doit pas introduire de mécanisme parallèle pour transporter l'état général du Build.

Les évolutions futures doivent préserver ce principe tout en évitant de transformer le BuildContext en un conteneur de responsabilités qui appartiennent aux autres composants.
