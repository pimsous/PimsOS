# ADR-0011 — Contrats d'interface entre composants

- **Statut** : Acceptée
- **Date** : 2026-07-19
- **Dernière mise à jour** : 2026-08-16
- **Décideur** : Pims
- **Impact** : Contrats internes et API publique

---

# Contexte

L'architecture initiale de PimsOS reposait sur plusieurs frameworks indépendants.

L'architecture actuelle a évolué vers un **module PowerShell unique** contenant des composants internes organisés par responsabilité.

Cette évolution ne supprime pas la nécessité de définir des contrats clairs entre les composants.

Afin de limiter le couplage, chaque composant doit utiliser uniquement les interfaces et contrats correspondant à sa responsabilité.

L'API publique du module PimsOS reste volontairement minimale.

---

# Décision

Les composants de PimsOS utilisent des contrats clairement définis.

Ces contrats peuvent concerner :

- les paramètres des fonctions ;
- le BuildContext ;
- le BuildState ;
- les Actions ;
- l'ActionRegistry ;
- les Managers ;
- les résultats d'exécution ;
- l'API publique du module.

Les composants internes ne constituent pas automatiquement des API publiques.

L'API publique actuellement exposée par `PimsOS.psm1` est :

```powershell
Initialize-PimsOS
```

Les autres fonctions restent internes au framework sauf décision explicite d'exportation.

---

# Architecture des contrats

Le fonctionnement normal des Actions repose sur :

```text
Action
    │
    ▼
ActionEngine
    │
    ▼
ActionRegistry
    │
    ▼
Engine spécialisé
    │
    ▼
Manager
    │
    ▼
Module technique
```

Chaque frontière possède un contrat défini par le composant concerné.

Le BuildContext constitue le contrat central de partage des informations du Build.

---

# Principes

Les contrats doivent être :

- clairs ;
- cohérents ;
- documentés ;
- testables ;
- aussi stables que nécessaire ;
- indépendants des détails d'implémentation lorsque cela est possible.

Une fonction interne peut évoluer sans devenir un engagement public.

Une API publique, lorsqu'elle existe, doit être considérée comme un contrat plus strict.

---

# BuildContext

Le BuildContext constitue l'un des principaux contrats internes du framework.

Les composants utilisent le contexte pour partager les informations et l'état du Build.

Les composants doivent :

- utiliser le contexte existant ;
- respecter sa structure ;
- modifier uniquement les propriétés relevant de leur responsabilité ;
- ne pas créer de contexte parallèle pour le même Build.

Toute évolution importante du contrat du BuildContext doit être documentée et testée.

---

# BuildState

Le BuildState représente l'état d'exécution du Build.

Les composants doivent utiliser ses propriétés et états conformément à leur responsabilité.

Ils ne doivent pas créer des indicateurs parallèles lorsqu'une information équivalente existe déjà dans le BuildState.

---

# Actions

Les Actions possèdent un contrat commun permettant leur traitement par les Engines.

Un Engine spécialisé reçoit notamment :

```text
Context + Action
```

et retourne le contexte mis à jour.

Selon le type d'Action, celle-ci peut également contenir des propriétés telles que :

- `Provider` ;
- `Name` ;
- `Path` ;
- `Source` ;
- `Destination` ;
- `Target`.

Les propriétés exactes dépendent du domaine traité.

---

# Engines spécialisés

Les Engines spécialisés doivent respecter leur contrat d'entrée et de sortie.

Ils doivent notamment :

- recevoir le BuildContext ;
- recevoir l'Action ;
- valider les propriétés nécessaires ;
- effectuer leur traitement métier ;
- déléguer les opérations techniques aux Managers ;
- retourner le contexte mis à jour ;
- propager les erreurs selon les règles du framework.

Un Engine spécialisé ne doit pas devenir une API publique uniquement parce qu'il est utilisé par un autre composant interne.

---

# Managers

Les Managers exposent des contrats techniques aux Engines qui les utilisent.

Ces contrats comprennent notamment :

- les paramètres obligatoires ;
- le Provider ;
- l'Action ;
- le contexte ;
- le résultat ;
- la gestion des erreurs.

Les Managers peuvent utiliser leurs propres tables de providers et handlers sans exposer ces détails à l'API publique du module.

---

# Paramètres

Les paramètres des fonctions doivent :

- utiliser des noms explicites ;
- être cohérents avec les contrats existants ;
- être validés lorsqu'ils sont obligatoires ;
- conserver un comportement compréhensible.

Exemples :

```powershell
-Context
-Action
-Provider
-Source
-Destination
```

Une modification d'un paramètre d'une API publique doit être évaluée comme une évolution de contrat.

---

# Valeurs de retour

Les fonctions doivent retourner des valeurs cohérentes avec leur responsabilité.

Lorsqu'un composant manipule le BuildContext, le contexte mis à jour constitue le contrat de retour attendu lorsque cela correspond à son interface.

Les objets métier doivent utiliser les constructeurs et contrats officiels du projet lorsqu'ils existent.

Les valeurs de retour ambiguës ou non documentées doivent être évitées.

---

# Exceptions

Les composants doivent :

- produire des erreurs explicites ;
- préserver le contexte utile au diagnostic ;
- propager les erreurs lorsqu'elles ne peuvent pas être traitées localement ;
- ne pas masquer une erreur critique.

Les contrats publics et internes importants doivent documenter les conditions d'erreur pertinentes.

---

# Compatibilité

Les contrats internes peuvent évoluer avec l'implémentation du framework lorsqu'ils ne constituent pas une API publique.

Les contrats publics doivent être traités avec davantage de stabilité.

Les modifications incompatibles d'une API publique doivent :

- être justifiées ;
- être documentées ;
- être couvertes par les tests concernés ;
- être reportées dans les notes de version lorsque l'impact le justifie.

---

# API publique

L'API publique du module PimsOS est volontairement minimale.

La fonction actuellement exportée est :

```powershell
Initialize-PimsOS
```

Les composants internes :

- Core ;
- Configuration ;
- Actions ;
- Engines ;
- Managers ;
- Infrastructure ;
- Image ;
- Windows ;

ne constituent pas automatiquement des API publiques.

Toute nouvelle fonction publique doit être explicitement exportée et documentée.

---

# Communication entre composants

Les composants ne doivent pas utiliser :

- des variables globales ;
- des états implicites ;
- des accès cachés aux données internes d'un autre composant.

Les échanges doivent respecter les contrats définis par l'architecture.

Le BuildContext est utilisé pour les données réellement partagées du Build.

L'ActionRegistry est utilisé pour le routage des Actions.

Les Managers servent d'interface technique pour les opérations spécialisées.

---

# Conséquences

## Avantages

- faible couplage ;
- interfaces plus lisibles ;
- meilleure testabilité ;
- évolution interne facilitée ;
- API publique maîtrisée ;
- responsabilités mieux séparées.

## Inconvénients

- nécessité de maintenir les contrats ;
- rigueur supplémentaire lors des évolutions ;
- documentation et tests nécessaires pour les contrats importants.

---

# Alternatives étudiées

## Accès direct aux fonctions internes d'un autre composant

Rejeté comme pratique générale.

Il augmente le couplage et rend les évolutions plus risquées.

---

## Variables globales partagées

Rejetées.

Elles créent des dépendances implicites et compliquent les tests.

---

## Exposer tous les composants comme API publique

Rejeté.

Cela créerait des contrats publics inutiles et limiterait la capacité à faire évoluer l'implémentation interne.

---

# Règles

Les composants ne doivent jamais :

- contourner leurs contrats définis ;
- accéder à des données internes sans nécessité architecturale ;
- exposer une fonction interne comme API publique sans décision explicite ;
- créer des dépendances implicites ;
- modifier arbitrairement les structures partagées.

Toute évolution importante d'un contrat doit être :

- analysée ;
- testée ;
- documentée ;
- répercutée dans les documents concernés.

---

# Tests

Les contrats doivent être protégés par des tests lorsque cela est pertinent.

Les tests doivent notamment vérifier :

- les paramètres ;
- les valeurs de retour ;
- la propagation du contexte ;
- la validation ;
- les erreurs ;
- le routage des Actions ;
- les comportements des Managers ;
- l'API publique.

Une modification de contrat importante doit être accompagnée des tests correspondants.

---

# Évolution

Lorsqu'un nouveau contrat est nécessaire :

1. vérifier qu'un contrat existant ne répond pas déjà au besoin ;
2. définir clairement sa responsabilité ;
3. déterminer sa portée interne ou publique ;
4. ajouter les validations nécessaires ;
5. ajouter les tests ;
6. mettre à jour la documentation ;
7. créer ou mettre à jour une ADR si l'impact est architectural.

---

# Décision finale

PimsOS repose sur des contrats explicites entre ses composants plutôt que sur des accès directs et implicites.

Le **BuildContext** constitue le contrat central de données du Build.

L'**ActionRegistry** constitue le mécanisme central de résolution des Engines.

Les **Managers** fournissent les contrats techniques nécessaires aux Engines spécialisés.

L'API publique du module reste volontairement minimale et limitée à :

```powershell
Initialize-PimsOS
```

Cette organisation permet de conserver une implémentation interne évolutive tout en maintenant des contrats clairs et maîtrisés.

---

# Références

- `ADR-0002-BuildContext.md`
- `ADR-0003-FrameworkStructure.md`
- `ADR-0009-FrameworkDependencies.md`
- `ADR-0012-ModuleUnique.md`
- `Architecture.md`
- `ArchitectureRules.md`
- `API.md`
- `BuildContext.md`
- `ModuleGuide.md`
