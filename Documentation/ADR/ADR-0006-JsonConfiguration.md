# ADR-0006 — Configuration centralisée au format JSON

- **Statut** : Acceptée
- **Date** : 2026-07-19
- **Dernière mise à jour** : 2026-08-16
- **Décideur** : Pims
- **Impact** : Configuration du projet

---

# Contexte

PimsOS repose sur de nombreuses données de configuration :

- configuration générale ;
- métadonnées du projet ;
- profils de personnalisation ;
- Tweaks ;
- catégories ;
- Actions ;
- paramètres du Build.

Ces données doivent utiliser un format :

- lisible ;
- simple ;
- facilement modifiable ;
- compatible avec PowerShell ;
- extensible ;
- facilement validable.

---

# Décision

Les configurations persistantes du projet utilisent le format **JSON**.

Les données JSON constituent les sources déclaratives utilisées pour construire la configuration du Build.

Les fichiers JSON ne contiennent pas de logique PowerShell exécutable.

La configuration est ensuite chargée, validée et transformée par les composants `Configuration` avant d'être utilisée par le Pipeline et les Engines.

---

# Organisation

Les différentes données JSON sont organisées selon leur responsabilité dans l'arborescence du projet.

Exemples :

```text
Config/
Profiles/
Resources/
Tweaks/
version.json
```

Le fichier :

```text
version.json
```

contient les métadonnées générales du projet et constitue la source officielle des informations de version.

Les profils et les Tweaks restent séparés afin de distinguer :

- la sélection des personnalisations ;
- les définitions des personnalisations disponibles.

---

# Exemple de métadonnées du projet

Le fichier `version.json` suit actuellement une structure de ce type :

```json
{
    "Project": "PimsOS Builder",
    "Version": "3.0.0",
    "Windows": {
        "Release": "11 25H2",
        "Build": "26100"
    },
    "Author": "Pims",
    "Company": "PimsOS",
    "Repository": "https://github.com/Pims/PimsOS",
    "BuildDate": null
}
```

La structure exacte doit rester cohérente avec les contrats actuellement utilisés par le BuildContext.

---

# Principes

Les données JSON du projet doivent être :

- lisibles ;
- structurées ;
- indentées de manière cohérente ;
- encodées en UTF-8 sans BOM ;
- validées avant utilisation.

Les noms de propriétés doivent rester cohérents avec les contrats du projet.

Les définitions sources doivent rester séparées de la configuration générée pour l'exécution.

---

# Séparation des données et de la logique

Les fichiers JSON contiennent des données déclaratives.

Ils ne doivent pas contenir :

- de fonctions PowerShell ;
- de logique d'exécution ;
- de décisions d'orchestration ;
- d'appels directs aux API Windows.

La logique de traitement appartient au code du framework.

Le parcours général est :

```text
JSON
    │
    ▼
Configuration
    │
    ▼
Validation
    │
    ▼
Configuration finale
    │
    ▼
BuildContext
    │
    ▼
ActionEngine
```

---

# Profils et Tweaks

Les définitions de Tweaks constituent un catalogue de personnalisations.

Les profils déterminent les personnalisations sélectionnées.

Le moteur construit ensuite une configuration finale destinée à l'exécution.

Les définitions originales des Tweaks ne doivent pas être modifiées pendant cette opération.

Cette séparation permet :

- de conserver les définitions sources intactes ;
- de réutiliser les mêmes Tweaks dans plusieurs profils ;
- de tester séparément les données sources et la configuration générée.

---

# Validation

Avant d'utiliser une définition JSON, le framework doit vérifier les éléments nécessaires à son contrat.

Selon le type de fichier, les validations peuvent notamment porter sur :

- la présence du fichier ;
- la validité syntaxique du JSON ;
- les propriétés obligatoires ;
- les identifiants ;
- les catégories ;
- les groupes ;
- les tags ;
- les niveaux ;
- les Actions ;
- les contraintes de compatibilité ;
- les relations entre les éléments.

Une définition invalide ne doit pas atteindre les étapes d'exécution qui dépendent d'elle.

Les erreurs de validation doivent être explicites et exploitables pour le diagnostic.

---

# Compatibilité

Les évolutions des structures JSON doivent préserver la compatibilité lorsque cela est possible.

Une propriété renommée, supprimée ou dont la signification est modifiée doit être documentée.

Une évolution qui modifie un contrat important doit également être accompagnée :

- des tests nécessaires ;
- de la documentation correspondante ;
- d'une mise à jour des notes de version lorsque l'impact le justifie.

---

# Conséquences

## Avantages

- format largement adopté ;
- bonne intégration avec PowerShell ;
- lecture simple ;
- structure hiérarchique ;
- séparation claire entre données et code ;
- extensibilité ;
- validation automatisable ;
- facilité de test.

## Inconvénients

- absence de commentaires natifs ;
- validation nécessaire avant utilisation ;
- nécessité de maintenir les contrats de données ;
- migrations nécessaires lorsqu'une structure évolue de manière incompatible.

---

# Alternatives étudiées

## XML

Rejetée.

Le format est plus verbeux et moins pratique pour les structures de configuration utilisées par le projet.

---

## YAML

Rejetée.

Le projet ne repose pas sur un besoin nécessitant un second format déclaratif et souhaite conserver une chaîne de traitement homogène avec PowerShell.

---

## INI

Rejetée.

La structure ne convient pas suffisamment aux données hiérarchiques et aux objets complexes utilisés par le Builder.

---

# Règles

Les composants du framework ne doivent pas coder en dur les valeurs qui relèvent de la configuration métier.

Les informations configurables doivent provenir :

- des fichiers JSON ;
- des profils ;
- des paramètres utilisateur ;
- du BuildContext lorsqu'il représente un état ou une donnée déjà chargée.

Les valeurs techniques internes qui ne sont pas configurables peuvent rester définies dans le code lorsqu'elles relèvent du fonctionnement intrinsèque du framework.

Les définitions JSON ne doivent jamais devenir un mécanisme de logique exécutable.

---

# Tests

Les structures JSON doivent être couvertes par des tests adaptés.

Les tests doivent notamment vérifier, lorsque cela est pertinent :

- le chargement ;
- la validation ;
- les propriétés obligatoires ;
- les erreurs de structure ;
- les cas limites ;
- la construction de la configuration finale.

Une modification du contrat JSON doit entraîner la mise à jour des tests concernés.

---

# Évolution

Toute évolution importante de la configuration doit être évaluée avant implémentation.

Lorsque la structure de données change :

1. identifier les composants consommateurs ;
2. vérifier le BuildContext ;
3. mettre à jour les validations ;
4. mettre à jour les tests ;
5. mettre à jour la documentation ;
6. mettre à jour les notes de version si nécessaire.

Une modification de la configuration ne doit pas imposer une modification inutile de l'architecture du framework.

---

# Décision finale

Le format **JSON** reste le format déclaratif de référence pour les configurations persistantes de PimsOS Builder.

La configuration est traitée comme des données :

```text
JSON
  ↓
Configuration
  ↓
Validation
  ↓
Configuration finale
  ↓
BuildContext
  ↓
Actions
```

La logique métier et l'exécution restent exclusivement implémentées dans le framework PowerShell.

---

# Références

- `Architecture.md`
- `ArchitectureRules.md`
- `BuildContext.md`
- `Schema.md`
- `TechnicalDecisions.md`
- `Documentation\ADR\`
