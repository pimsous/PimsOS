# ADR-0003 — Organisation interne des frameworks

- **Statut** : Acceptée
- **Date** : 2026-07-19
- **Décideur** : Pims
- **Impact** : Structure de tous les frameworks

---

# Contexte

PimsOS est composé de plusieurs frameworks PowerShell.

Sans convention commune, chaque framework pourrait adopter une organisation différente, rendant le projet difficile à maintenir et à faire évoluer.

Il est donc nécessaire de définir une structure unique applicable à tous les frameworks.

---

# Décision

Tous les frameworks PimsOS utilisent la même organisation.

```text
Framework
│
├── Framework.psd1
├── Framework.psm1
│
├── Classes
├── Modules
├── Private
├── Public
├── Resources
└── Tests
```

Chaque framework respecte cette structure, quel que soit son rôle.

---

# Description des composants

## Manifest (.psd1)

Le manifeste décrit :

- la version ;
- les dépendances ;
- les fonctions exportées ;
- les métadonnées du framework.

---

## Module racine (.psm1)

Le module racine :

- charge les classes ;
- charge les modules techniques ;
- charge les fonctions privées ;
- charge les fonctions publiques ;
- exporte uniquement les fonctions publiques.

Il ne contient aucune logique métier.

---

## Classes

Le dossier `Classes` contient les classes PowerShell.

Règles :

- une classe par fichier ;
- aucun code exécutable ;
- responsabilité unique.

---

## Modules

Le dossier `Modules` contient les composants techniques réutilisables.

Ils peuvent être utilisés par plusieurs fonctions du framework.

Ils ne doivent pas contenir de logique métier.

---

## Private

Le dossier `Private` contient les fonctions internes.

Ces fonctions :

- ne sont jamais exportées ;
- peuvent évoluer sans impact sur l'API publique.

---

## Public

Le dossier `Public` contient les fonctions accessibles aux autres frameworks.

Chaque fonction :

- possède son propre fichier ;
- est documentée ;
- est exportée par le manifeste.

---

## Resources

Le dossier `Resources` contient les ressources utilisées par le framework :

- modèles ;
- fichiers JSON ;
- scripts ;
- données statiques.

---

## Tests

Chaque framework possède ses propres tests.

Les tests sont placés dans le dossier `Tests`.

---

# Conséquences

## Avantages

- architecture homogène ;
- navigation facilitée ;
- meilleure maintenabilité ;
- réutilisation des composants ;
- tests plus simples.

## Inconvénients

- nombre de fichiers plus important ;
- structure plus rigoureuse.

---

# Alternatives étudiées

## Organisation libre

Rejetée.

Chaque framework aurait adopté une structure différente.

La maintenance serait devenue difficile.

## Toutes les fonctions dans un seul fichier

Rejetée.

Les fichiers seraient devenus trop volumineux.

Les conflits Git auraient été plus fréquents.

---

# Règles

Tous les nouveaux frameworks devront respecter cette organisation.

Toute exception devra être justifiée par une nouvelle ADR.

---

# Impact

Cette décision garantit une architecture uniforme sur l'ensemble du projet.

Elle facilite :

- la maintenance ;
- la revue de code ;
- les tests ;
- la montée en compétence des nouveaux contributeurs.