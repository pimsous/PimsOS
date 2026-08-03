# Architecture Decision Records (ADR)

## Objectif

Ce dossier contient les **Architecture Decision Records (ADR)** du projet **PimsOS**.

Une ADR documente une décision importante concernant l'architecture ou le fonctionnement du projet.

Contrairement à la documentation technique, une ADR explique **pourquoi** une décision a été prise, les alternatives étudiées et ses conséquences.

---

# Quand créer une ADR ?

Une ADR est créée lorsqu'une décision :

- modifie l'architecture ;
- impacte plusieurs frameworks ;
- définit une convention durable ;
- introduit un nouveau composant majeur ;
- mérite d'être conservée pour faciliter la maintenance du projet.

Les corrections de bugs ou les évolutions mineures ne nécessitent généralement pas d'ADR.

---

# Cycle de vie

Chaque ADR possède un statut.

| Statut | Description |
|---------|-------------|
| Proposed | Proposition en cours de discussion |
| Accepted | Décision adoptée |
| Superseded | Remplacée par une autre ADR |
| Deprecated | Obsolète |
| Rejected | Refusée |

Une ADR ne doit jamais être supprimée.

Si une décision évolue, une nouvelle ADR est créée et référence l'ancienne.

---

# Liste des ADR

| ADR | Sujet | Statut |
|------|--------|--------|
| ADR-0001 | Architecture modulaire | Accepted |
| ADR-0002 | BuildContext central | Accepted |
| ADR-0003 | Organisation des frameworks | Accepted |
| ADR-0004 | Pipeline de build | Accepted |
| ADR-0005 | Journalisation centralisée | Accepted |
| ADR-0006 | Configuration JSON | Accepted |
| ADR-0007 | Stratégie de tests | Accepted |
| ADR-0008 | Gestion des erreurs | Accepted |
| ADR-0009 | Dépendances entre frameworks | Accepted |
| ADR-0010 | Cycle de vie du BuildContext | Accepted |
| ADR-0011 | Contrats d'interface entre frameworks | Accepted |
| ADR-0012 | Module PowerShell unique | Accepted |
---

# Conventions

Les ADR suivent les règles suivantes :

- une décision par document ;
- numérotation séquentielle (`ADR-0001`, `ADR-0002`, etc.) ;
- un titre explicite ;
- un historique conservé ;
- une décision ne doit pas être modifiée après son adoption, sauf pour corriger des erreurs mineures (orthographe, mise en forme).

Une évolution importante doit faire l'objet d'une nouvelle ADR.

---

# Structure d'une ADR

Chaque ADR utilise le modèle suivant :

- Statut
- Date
- Décideur
- Impact
- Contexte
- Décision
- Conséquences
- Alternatives étudiées
- Règles (si nécessaire)
- Références

---

# Références

Pour mieux comprendre les décisions décrites dans ce dossier, consulter également :

- `Documentation/Architecture.md`
- `Documentation/API.md`
- `Documentation/BuildContext.md`
- `Documentation/Lifecycle.md`