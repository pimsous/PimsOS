# Politique de sécurité

Merci de contribuer à la sécurité de **PimsOS Builder**.

Ce document décrit les versions actuellement maintenues, la procédure de signalement d'une vulnérabilité ainsi que les bonnes pratiques de sécurité appliquées au projet.

---

# Versions supportées

| Version | Statut | Support sécurité |
|---------|--------|:----------------:|
| 1.x | Stable | ✅ |
| 0.4.x | Développement actif | 🚧 Meilleur effort |
| 0.3.x | Développement | ❌ |
| Versions antérieures | Obsolètes | ❌ |

Les versions en développement évoluent rapidement.

Aucune garantie de stabilité ou de rétrocompatibilité n'est assurée avant la publication de la version **1.0.0**.

---

# Signaler une vulnérabilité

Si vous découvrez une vulnérabilité :

- ne publiez pas immédiatement les détails ;
- décrivez précisément le problème ;
- fournissez les étapes permettant de reproduire le comportement ;
- indiquez la version concernée ;
- joignez les journaux utiles si nécessaire ;
- proposez une piste de correction si vous en avez une.

---

# Traitement des signalements

Chaque signalement suit le processus suivant :

1. Analyse.
2. Reproduction.
3. Évaluation de l'impact.
4. Développement d'un correctif.
5. Validation.
6. Publication d'une nouvelle version.
7. Mise à jour de la documentation si nécessaire.

---

# Correctifs

Les vulnérabilités sont traitées selon leur niveau de gravité.

Lorsque cela est possible :

- un correctif est développé rapidement ;
- les tests sont mis à jour ;
- les notes de version sont complétées ;
- le CHANGELOG est mis à jour.

---

# Bonnes pratiques

Le développement de PimsOS Builder suit les principes suivants :

- validation des données d'entrée ;
- utilisation du BuildContext plutôt que de variables globales ;
- journalisation systématique des erreurs ;
- gestion centralisée des exceptions ;
- séparation stricte entre logique métier et opérations techniques ;
- principe du moindre privilège lorsque cela est possible.

---

# Dépendances

Avant chaque publication :

- vérifier les dépendances PowerShell ;
- maintenir PowerShell et Pester à jour ;
- supprimer les dépendances inutilisées ;
- vérifier les composants externes utilisés par le Builder.

---

# Portée

Cette politique couvre l'ensemble du projet, notamment :

- le moteur de build ;
- le Pipeline ;
- le BuildContext ;
- le BuildState ;
- les Engines ;
- les modules PowerShell ;
- les profils ;
- les tweaks ;
- les fichiers JSON ;
- les scripts de build.

---

# Versions de Windows

PimsOS Builder personnalise exclusivement des images Windows officielles Microsoft.

Le Builder est conçu pour prendre en charge plusieurs versions de Windows 11.

La version de Windows ciblée est déterminée par la configuration du projet et non par le moteur lui-même.

---

# Références

Consulter également :

- CHANGELOG.md
- CONTRIBUTING.md
- Documentation/ReleaseNotes.md
- Documentation/TechnicalDecisions.md
- Documentation/ArchitectureRules.md