# ADR-0007 — Stratégie de tests avec Pester

- **Statut** : Acceptée
- **Date** : 2026-07-19
- **Décideur** : Pims
- **Impact** : Qualité du projet

---

# Contexte

PimsOS est un projet modulaire composé de nombreux frameworks.

Chaque évolution peut impacter plusieurs composants.

Sans stratégie de tests homogène, les risques de régression augmentent rapidement.

Le projet doit disposer d'un système de validation automatique fiable.

---

# Décision

PimsOS adopte **Pester 5** comme framework officiel de tests.

Tous les frameworks doivent être accompagnés de tests automatisés.

Les tests font partie intégrante du développement.

Une fonctionnalité n'est considérée comme terminée que lorsque ses tests sont validés.

---

# Objectifs

Les tests permettent de :

- valider le comportement attendu ;
- détecter les régressions ;
- faciliter les refactorings ;
- documenter le fonctionnement des composants ;
- améliorer la stabilité du projet.

---

# Organisation

Chaque framework possède son propre dossier :

```text
Framework
│
└── Tests
```

Les tests globaux du projet sont regroupés dans :

```text
Tests/
```

---

# Types de tests

Le projet distingue plusieurs catégories :

## Tests unitaires

Ils vérifient un composant isolé.

Ils doivent être :

- rapides ;
- indépendants ;
- reproductibles.

---

## Tests d'intégration

Ils valident plusieurs frameworks fonctionnant ensemble.

Exemples :

- Pipeline complet ;
- BuildContext ;
- Configuration ;
- Journalisation.

---

## Tests de régression

Chaque correction de bug doit être accompagnée d'un test reproduisant le problème.

Le correctif n'est validé que lorsque ce test passe avec succès.

---

# Règles

Chaque nouvelle fonctionnalité doit être accompagnée de tests.

Les tests doivent couvrir :

- le fonctionnement nominal ;
- les erreurs attendues ;
- les paramètres invalides ;
- les cas limites.

---

# Exécution

Les tests sont exécutés avec :

```powershell
Invoke-Pester
```

À terme, ils seront intégrés à une chaîne d'intégration continue (CI).

---

# Conséquences

## Avantages

- meilleure qualité du code ;
- détection rapide des régressions ;
- documentation du comportement attendu ;
- refactoring facilité ;
- maintenance simplifiée.

## Inconvénients

- temps de développement légèrement plus important ;
- maintenance des tests.

---

# Alternatives étudiées

## Tests manuels uniquement

Rejetée.

Ils sont difficiles à reproduire et peu fiables sur le long terme.

---

## Aucun framework de tests

Rejetée.

Le risque de régression deviendrait trop important.

---

# Impact

Les tests deviennent une étape obligatoire du cycle de développement.

Aucun composant ne doit être intégré sans validation par les tests automatisés.

---

# Références

- Documentation/Testing.md
- Documentation/Lifecycle.md
- ADR-0004 — Pipeline de build