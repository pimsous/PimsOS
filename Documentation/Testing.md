# PimsOS Builder - Stratégie de tests

> Version technique : 3.0.0
>
> Statut : Développement / architecture stabilisée
>
> Dernière mise à jour : 2026-08-16

---

# Objectif

Ce document décrit la stratégie de tests utilisée dans le projet **PimsOS Builder**.

L'objectif est de garantir que chaque évolution du framework puisse être vérifiée de manière reproductible avant d'être considérée comme stable.

Les tests constituent également une documentation vivante du comportement attendu des composants.

Une fonctionnalité importante ne doit pas être considérée comme terminée tant que son comportement n'a pas été validé par les tests appropriés.

---

# Framework de tests

PimsOS Builder utilise :

- PowerShell 7 ;
- Pester 5.x.

L'environnement de développement actuel utilise Pester 5.8.0.

---

# Principes

Les tests doivent permettre de :

- détecter les régressions ;
- valider les nouvelles fonctionnalités ;
- vérifier les comportements nominaux ;
- vérifier les comportements d'erreur ;
- documenter les contrats des composants ;
- sécuriser les évolutions du Builder.

Les tests doivent rester :

- reproductibles ;
- lisibles ;
- isolés lorsque cela est possible ;
- rapides pour les tests unitaires ;
- indépendants des services externes lorsqu'ils n'ont pas besoin de ceux-ci.

---

# Organisation

Les tests du projet sont organisés principalement en deux niveaux :

```text
Tests
│
├── Unit
└── Integration
## PostInstall

Le sous-système PostInstall possède actuellement des tests dédiés
pour State, Network, PostInstall, Bootstrap, FirstBoot, Unattend
et Installer.

Le pipeline possède également des tests d'intégration pour
`PreparePostInstall`.

Une validation réelle dans un WIM temporaire est utilisée pour
compléter les tests unitaires.

Les tests destructive sur WIM doivent utiliser un montage temporaire
et `-Discard`.
