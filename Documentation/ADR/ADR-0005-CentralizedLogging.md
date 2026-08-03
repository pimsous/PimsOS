# ADR-0005 — Journalisation centralisée

- **Statut** : Acceptée
- **Date** : 2026-07-19
- **Décideur** : Pims
- **Impact** : Tous les frameworks

---

# Contexte

PimsOS est composé de nombreux frameworks qui exécutent des opérations indépendantes.

Afin de faciliter :

- le diagnostic ;
- le débogage ;
- les rapports ;
- le suivi des builds ;

une stratégie commune de journalisation est nécessaire.

L'utilisation de plusieurs mécanismes de journalisation rendrait les journaux difficiles à exploiter.

---

# Décision

Tous les composants utilisent exclusivement le framework **Logger**.

Aucun framework ne doit écrire directement dans un fichier de log.

Toutes les opérations passent par les fonctions publiques du Logger.

---

# Responsabilités du Logger

Le Logger est responsable de :

- créer les fichiers de journal ;
- gérer l'encodage ;
- écrire les messages ;
- gérer les niveaux de journalisation ;
- produire des sorties homogènes.

---

# Niveaux de journalisation

Les niveaux utilisés sont :

| Niveau | Description |
|---------|-------------|
| INFO | Information générale |
| SUCCESS | Opération réussie |
| WARNING | Situation inhabituelle |
| ERROR | Erreur bloquante |
| DEBUG | Informations de diagnostic |

Chaque niveau possède un format uniforme.

---

# Format

Chaque entrée de journal contient au minimum :

- date ;
- heure ;
- niveau ;
- framework ;
- message.

Exemple :

```text
[2026-07-19 15:42:08] [INFO] [Pipeline] Initialisation du BuildContext
```

---

# Encodage

Tous les journaux utilisent :

- UTF-8 ;
- sans BOM ;
- fin de ligne CRLF.

Cette règle garantit une lecture correcte sous Windows et dans les éditeurs modernes.

---

# Conséquences

## Avantages

- journaux homogènes ;
- maintenance simplifiée ;
- meilleure lisibilité ;
- diagnostic facilité ;
- possibilité de faire évoluer le Logger sans modifier les autres frameworks.

## Inconvénients

- dépendance commune au framework Logger.

---

# Alternatives étudiées

## Write-Host

Rejetée.

Les informations ne sont pas persistantes.

---

## Out-File

Rejetée.

Chaque framework aurait utilisé son propre format.

---

## Add-Content

Rejetée.

Ne permet pas de centraliser les règles de journalisation.

---

# Règles

Les frameworks ne doivent jamais :

- utiliser Write-Host pour journaliser ;
- écrire directement dans un fichier de log ;
- modifier le format des journaux.

Toute évolution du format doit être réalisée dans le Logger.

---

# Impact

Le Logger devient l'unique point d'entrée pour la journalisation.

Tous les frameworks bénéficient ainsi d'un comportement homogène et d'une maintenance simplifiée.