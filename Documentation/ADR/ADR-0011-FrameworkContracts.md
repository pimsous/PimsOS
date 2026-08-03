# ADR-0011 — Contrats d'interface entre frameworks

- **Statut** : Acceptée
- **Date** : 2026-07-19
- **Décideur** : Pims
- **Impact** : Tous les frameworks

---

# Contexte

L'architecture de PimsOS repose sur des frameworks indépendants.

Chaque framework est susceptible d'évoluer au fil des versions.

Afin de limiter le couplage entre composants, les autres frameworks ne doivent dépendre que des interfaces publiques.

---

# Décision

Chaque framework expose une API publique clairement définie.

Les composants externes ne doivent utiliser que les fonctions présentes dans le dossier **Public**.

Les fonctions internes restent privées et peuvent évoluer librement.

---

# Architecture

```text
                Framework A
                     │
          Public Functions uniquement
                     │
                     ▼
                Framework B

        Private Functions
              ▲
              │
      accessibles uniquement
      au framework lui-même
```

---

# Principes

Les interfaces publiques doivent être :

- stables ;
- documentées ;
- versionnées ;
- testées.

Les fonctions privées ne constituent jamais un contrat.

---

# Évolution

Une fonction publique peut évoluer :

- en restant rétrocompatible ;
- ou via une nouvelle version majeure.

Les changements incompatibles doivent être documentés.

---

# Paramètres

Les paramètres publics doivent :

- utiliser des noms explicites ;
- être documentés ;
- être validés ;
- rester cohérents entre frameworks.

---

# Valeurs de retour

Les fonctions publiques doivent retourner :

- un type PowerShell clairement identifié lorsque cela est pertinent ;
- ou un objet métier documenté respectant le contrat du framework.

Les objets métier exposés par un framework doivent fournir les propriétés permettant leur identification et leur utilisation.

Éviter les tableaux anonymes ou les objets dynamiques non documentés.

---

# Exceptions

Les fonctions publiques doivent :

- lever des exceptions explicites ;
- documenter les erreurs possibles ;
- ne jamais masquer une erreur critique.

---

# Compatibilité

Les API publiques constituent un engagement envers les autres frameworks.
Les contrats d'interface sont indépendants de l'implémentation interne du framework.

Les modifications incompatibles doivent :

- être justifiées ;
- être documentées ;
- être annoncées dans les notes de version.

---

# Conséquences

## Avantages

- faible couplage ;
- API stable ;
- maintenance simplifiée ;
- évolution indépendante des frameworks ;
- meilleure testabilité.

## Inconvénients

- davantage de rigueur lors des évolutions ;
- nécessité de maintenir la documentation API.

---

# Alternatives étudiées

## Accès direct aux fonctions privées

Rejetée.

Elle créerait un fort couplage entre frameworks.

---

## Variables globales partagées

Rejetée.

Elles rendent les dépendances implicites et compliquent les tests.

---

# Règles

Les frameworks ne doivent jamais :

- appeler une fonction située dans `Private` d'un autre framework ;
- modifier directement les données internes d'un autre framework ;
- contourner l'API publique.

Toute communication entre frameworks passe par :

- les fonctions publiques ;
- le BuildContext.

---

# Impact

Cette décision garantit que chaque framework peut évoluer indépendamment tout en conservant une interface stable avec les autres composants.

---

# Références

- ADR-0002 — BuildContext central
- ADR-0003 — Organisation des frameworks
- ADR-0009 — Gestion des dépendances entre frameworks
- Documentation/API.md