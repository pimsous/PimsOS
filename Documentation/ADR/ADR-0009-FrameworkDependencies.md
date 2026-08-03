# ADR-0009 — Gestion des dépendances entre frameworks

- **Statut** : Acceptée
- **Date** : 2026-07-19
- **Décideur** : Pims
- **Impact** : Tous les frameworks

---

# Contexte

PimsOS repose sur une architecture composée de frameworks indépendants.

Au fil de l'évolution du projet, de nouvelles fonctionnalités seront ajoutées.

Sans règles concernant les dépendances, les frameworks pourraient progressivement dépendre les uns des autres de manière désordonnée.

Les conséquences seraient :

- dépendances circulaires ;
- chargement complexe ;
- faible testabilité ;
- maintenance difficile.

---

# Décision

Chaque framework possède une responsabilité clairement définie.

Les dépendances entre frameworks sont limitées et orientées.

Un framework ne peut dépendre que :

- des bibliothèques PowerShell ;
- des modules techniques internes ;
- du BuildContext ;
- des interfaces publiques d'un autre framework.

Il ne doit jamais accéder aux fonctions privées d'un autre framework.

---

# Principes

Les dépendances doivent être :

- explicites ;
- minimales ;
- unidirectionnelles ;
- documentées.

Chaque nouvelle dépendance doit être justifiée.

---

# Architecture

```text
                 Builder
                    │
                    ▼
                Pipeline
                    │
     ┌──────────────┼──────────────┐
     ▼              ▼              ▼
Configuration    Workspace      Validation
     │              │              │
     ▼              ▼              ▼
 Image         Packages       Drivers
     │              │              │
     └──────────────┼──────────────┘
                    ▼
                 Logger
```

Le Pipeline coordonne les frameworks.

Les frameworks ne se pilotent jamais directement entre eux.

---

# Dépendances autorisées

Les frameworks peuvent utiliser :

- le BuildContext ;
- les fonctions publiques d'un autre framework, lorsque cela est justifié ;
- les modules techniques partagés.

---

# Dépendances interdites

Les frameworks ne doivent jamais :

- appeler une fonction privée d'un autre framework ;
- modifier directement les données internes d'un autre framework ;
- créer une dépendance circulaire.

---

# Inversion de dépendance

Lorsqu'un framework doit collaborer avec un autre, il privilégie :

- une interface publique ;
- le BuildContext ;
- un contrat clairement documenté.

Cela réduit le couplage.

---

# Conséquences

## Avantages

- architecture plus lisible ;
- faible couplage ;
- meilleure réutilisabilité ;
- tests simplifiés ;
- évolution indépendante des frameworks.

## Inconvénients

- nécessité de concevoir des interfaces publiques stables ;
- discipline de développement plus stricte.

---

# Alternatives étudiées

## Dépendances libres

Rejetée.

Le projet deviendrait rapidement difficile à maintenir.

---

## Framework monolithique

Rejetée.

Elle contredit l'architecture modulaire adoptée.

---

# Règles

Toute nouvelle dépendance doit répondre aux critères suivants :

- apporte une réelle valeur ;
- ne crée pas de dépendance circulaire ;
- reste documentée ;
- est couverte par des tests.

---

# Impact

Cette décision garantit que les frameworks restent indépendants tout au long de la vie du projet.

Elle favorise une architecture modulaire, extensible et maintenable.

---

# Références

- ADR-0001 — Architecture modulaire
- ADR-0002 — BuildContext central
- ADR-0003 — Organisation des frameworks
- ADR-0004 — Pipeline de build
- Documentation/Architecture.md