# ADR-0006 — Configuration centralisée au format JSON

- **Statut** : Acceptée
- **Date** : 2026-07-19
- **Décideur** : Pims
- **Impact** : Configuration du projet

---

# Contexte

PimsOS repose sur de nombreux paramètres :

- configuration générale ;
- profils de personnalisation ;
- options de build ;
- packages ;
- tweaks ;
- pilotes ;
- paramètres des frameworks.

Il est nécessaire de disposer d'un format de configuration :

- lisible ;
- simple ;
- facilement modifiable ;
- compatible avec PowerShell ;
- extensible.

---

# Décision

Toutes les configurations persistantes utilisent le format **JSON**.

Chaque framework peut disposer de son propre fichier JSON, mais tous suivent les mêmes conventions.

---

# Organisation

Les fichiers sont regroupés dans le dossier :

```text
Config/
```

Les profils utilisateur sont stockés dans :

```text
Profiles/
```

Les ressources statiques peuvent être placées dans :

```text
Resources/
```

---

# Exemple

```json
{
    "Project": {
        "Name": "PimsOS",
        "Version": "0.1.0"
    },
    "Build": {
        "DryRun": false,
        "Verbose": true
    }
}
```

---

# Principes

Les fichiers JSON doivent être :

- lisibles ;
- indentés avec 4 espaces ;
- encodés en UTF-8 sans BOM ;
- validés avant utilisation.

Les clés utilisent une convention de nommage cohérente.

---

# Validation

Avant d'utiliser un fichier JSON, le framework concerné doit vérifier :

- sa présence ;
- sa validité syntaxique ;
- la présence des propriétés obligatoires.

En cas d'erreur, une exception explicite est levée.

---

# Compatibilité

Les évolutions des fichiers JSON doivent préserver la compatibilité lorsque cela est possible.

Les propriétés supprimées ou renommées doivent être documentées dans les notes de version.

---

# Conséquences

## Avantages

- format largement adopté ;
- bonne intégration avec PowerShell ;
- lecture simple ;
- structure hiérarchique ;
- extensibilité.

## Inconvénients

- absence de commentaires natifs ;
- validation nécessaire avant utilisation.

---

# Alternatives étudiées

## XML

Rejetée.

Format plus verbeux et moins lisible.

---

## YAML

Rejetée.

Support moins homogène dans PowerShell.

---

## INI

Rejetée.

Structure insuffisante pour les besoins du projet.

---

# Règles

Les frameworks ne doivent jamais contenir de configuration codée en dur.

Toute valeur configurable doit être externalisée dans un fichier JSON ou intégrée au BuildContext.

---

# Impact

L'utilisation d'un format unique simplifie :

- la maintenance ;
- les tests ;
- la validation ;
- la migration des configurations entre versions.