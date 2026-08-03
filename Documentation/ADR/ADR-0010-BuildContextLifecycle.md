# ADR-0010 — Cycle de vie du BuildContext

- **Statut** : Acceptée
- **Date** : 2026-07-19
- **Décideur** : Pims
- **Impact** : Tous les frameworks

---

# Contexte

Le `BuildContext` constitue l'objet central partagé entre les frameworks.

Tout au long d'un build, il est progressivement enrichi avec :

- la configuration ;
- les profils ;
- les informations système ;
- l'état du pipeline ;
- les résultats des frameworks.

Il est nécessaire de définir précisément son cycle de vie afin de garantir sa cohérence.

---

# Décision

Le `BuildContext` possède un cycle de vie unique.

Il est créé une seule fois au début du build.

Il est enrichi progressivement par les frameworks.

Il n'est jamais recréé pendant l'exécution.

---

# Cycle de vie

```text
Création
    │
    ▼
Initialisation
    │
    ▼
Validation
    │
    ▼
Enrichissement
    │
    ▼
Utilisation
    │
    ▼
Finalisation
    │
    ▼
Archivage / Rapport
```

---

# Création

Le Builder crée une nouvelle instance du `BuildContext`.

À ce stade seules les informations minimales sont présentes :

- version ;
- date ;
- paramètres de lancement.

---

# Initialisation

Les premiers frameworks complètent le contexte :

- Configuration
- Workspace
- Logger
- Check

Le contexte devient exploitable.

---

# Validation

Avant de poursuivre, le Pipeline vérifie que :

- toutes les sections obligatoires existent ;
- les données sont cohérentes ;
- aucune erreur critique n'est détectée.

En cas d'échec, le build est interrompu.

---

# Enrichissement

Chaque framework ajoute uniquement les informations dont il est responsable.

Exemples :

Image :

- index WIM ;
- éditions disponibles ;
- image montée.

Packages :

- packages sélectionnés ;
- packages installés.

Drivers :

- pilotes détectés ;
- pilotes injectés.

---

# Utilisation

Tous les frameworks lisent les informations déjà présentes dans le `BuildContext`.

Ils ne doivent modifier que leurs propres sections.

---

# Finalisation

À la fin du build :

- les statistiques sont ajoutées ;
- les résultats sont consolidés ;
- les erreurs éventuelles sont recensées.

Le contexte devient en lecture seule.

---

# Archivage

Le `BuildContext` peut être utilisé pour :

- générer un rapport ;
- produire des statistiques ;
- faciliter le diagnostic.

---

# Responsabilités

## Builder

- crée le contexte ;
- lance le pipeline.

---

## Pipeline

- transmet le contexte ;
- contrôle son état ;
- valide les transitions.

---

## Frameworks

Chaque framework :

- lit les informations nécessaires ;
- met à jour uniquement sa propre section ;
- ne modifie jamais les données appartenant à un autre framework.

---

# Conséquences

## Avantages

- cycle de vie clairement défini ;
- données cohérentes ;
- meilleure traçabilité ;
- maintenance simplifiée.

## Inconvénients

- validation supplémentaire ;
- discipline de développement.

---

# Alternatives étudiées

## Plusieurs BuildContext

Rejetée.

Elle compliquerait les échanges entre frameworks.

---

## Reconstruction du contexte

Rejetée.

Elle risquerait de provoquer des incohérences.

---

# Règles

Le `BuildContext` :

- est créé une seule fois ;
- circule dans tout le pipeline ;
- n'est jamais remplacé ;
- est validé avant chaque étape importante.

Toute modification de son cycle de vie nécessite une nouvelle ADR.

---

# Impact

Cette décision garantit un échange d'informations fiable entre tous les frameworks.

Elle fait du `BuildContext` le contrat principal de communication du projet.

---

# Références

- ADR-0002 — Utilisation d'un BuildContext central
- ADR-0004 — Pipeline de build orienté frameworks
- ADR-0009 — Gestion des dépendances entre frameworks
- Documentation/BuildContext.md
- Documentation/Lifecycle.md