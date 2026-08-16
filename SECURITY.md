# PimsOS Builder - Politique de sécurité

> Version technique : 3.0.0
>
> Statut : Référence
>
> Dernière mise à jour : 2026-08-16

Merci de contribuer à la sécurité de **PimsOS Builder**.

Ce document décrit les versions actuellement maintenues, la procédure de signalement d'une vulnérabilité ainsi que les bonnes pratiques de sécurité appliquées au projet.

---

# Versions supportées

| Version | Statut | Support sécurité |
|---------|--------|:----------------:|
| 3.0.x | Développement actif | 🚧 Meilleur effort |
| Versions antérieures | Historiques / développement | ❌ |

La version technique actuelle est :

```text
3.0.0
```

PimsOS Builder n'est pas encore publié comme une version stable finale du produit.

Aucune garantie de stabilité ou de rétrocompatibilité complète ne doit être déduite du numéro de version technique actuel.

---

# Signaler une vulnérabilité

Si vous découvrez une vulnérabilité :

- ne publiez pas immédiatement les détails ;
- décrivez précisément le problème ;
- fournissez les étapes permettant de reproduire le comportement ;
- indiquez la version concernée ;
- joignez les journaux utiles si nécessaire ;
- indiquez les conditions nécessaires à la reproduction ;
- proposez une piste de correction si vous en avez une.

Pour les informations sensibles, utiliser le canal de signalement privé prévu par le dépôt lorsqu'il est disponible.

---

# Traitement des signalements

Chaque signalement suit le processus général suivant :

1. Analyse.
2. Reproduction.
3. Évaluation de l'impact.
4. Développement d'un correctif.
5. Validation.
6. Publication ou intégration du correctif.
7. Mise à jour de la documentation si nécessaire.

La procédure exacte peut être adaptée à la nature et à la gravité du problème.

---

# Correctifs

Les vulnérabilités sont traitées selon leur niveau de gravité et leur impact.

Lorsque cela est possible :

- un correctif est développé rapidement ;
- les tests sont ajoutés ou mis à jour ;
- les notes de version sont complétées ;
- le `CHANGELOG.md` est mis à jour ;
- les documents concernés sont synchronisés.

Une correction de sécurité importante doit être accompagnée d'une validation adaptée avant son intégration.

---

# Bonnes pratiques

Le développement de PimsOS Builder suit notamment les principes suivants :

- validation des données d'entrée ;
- utilisation du BuildContext plutôt que de variables globales pour les données du Build ;
- journalisation centralisée des erreurs ;
- gestion contrôlée des exceptions ;
- séparation entre logique métier et opérations techniques ;
- limitation des privilèges lorsque cela est possible ;
- limitation des dépendances inutiles ;
- validation des fichiers de configuration avant exécution.

---

# Gestion des secrets

Les secrets, mots de passe, jetons et autres informations sensibles ne doivent pas être stockés dans :

- le code source ;
- les fichiers JSON de configuration versionnés ;
- les logs ;
- les commits Git ;
- les tests.

Les informations sensibles nécessaires à un environnement particulier doivent utiliser un mécanisme approprié qui ne les expose pas dans le dépôt.

---

# Dépendances

Avant une publication ou une évolution importante :

- vérifier les dépendances PowerShell ;
- maintenir les dépendances à des versions supportées ;
- supprimer les dépendances inutilisées ;
- vérifier les composants externes utilisés par le Builder ;
- surveiller les alertes de dépendances du dépôt lorsque disponibles.

Les outils de sécurité du dépôt, notamment CodeQL et Dependabot lorsqu'ils sont activés, participent à cette surveillance.

---

# Portée

Cette politique couvre l'ensemble du projet, notamment :

- le moteur de Build ;
- le Workflow ;
- le Pipeline ;
- le BuildContext ;
- le BuildState ;
- les Engines ;
- les Managers ;
- les modules techniques ;
- les profils ;
- les Tweaks ;
- les fichiers JSON ;
- les scripts de Build ;
- les tests ;
- les outils de publication.

---

# Versions de Windows

PimsOS Builder est destiné à travailler avec des images Windows officielles compatibles avec les mécanismes techniques utilisés par le framework.

Le projet n'est pas limité à une seule version de Windows.

La version réellement ciblée doit être déterminée à partir de l'image traitée et des informations disponibles dans la configuration et le BuildContext.

L'environnement Windows 11 25H2 / Build 26100 constitue actuellement l'environnement de référence du développement.

---

# Journalisation et sécurité

Les logs peuvent contenir des informations utiles au diagnostic.

Les composants doivent donc éviter d'y écrire :

- mots de passe ;
- jetons ;
- secrets ;
- informations d'identification ;
- données sensibles inutiles au diagnostic.

Le Logger doit être utilisé pour les événements nécessaires au suivi du Build.

---

# Gestion des erreurs

Les erreurs de sécurité ou d'intégrité doivent :

- être détectées ;
- être journalisées de manière appropriée ;
- conserver suffisamment de contexte pour permettre leur analyse ;
- être propagées lorsqu'elles ne peuvent pas être traitées localement.

Les erreurs ne doivent pas être masquées afin de forcer un Build à continuer dans un état potentiellement incohérent.

---

# Références

Consulter également :

- `CHANGELOG.md`
- `CONTRIBUTING.md`
- `Documentation/ReleaseNotes.md`
- `Documentation/TechnicalDecisions.md`
- `Documentation/ArchitectureRules.md`
- `Documentation/Prerequisites.md`
- `Documentation/Testing.md`
