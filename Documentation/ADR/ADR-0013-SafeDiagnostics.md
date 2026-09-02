# ADR-0013 — Diagnostic sécurisé avant exécution des tests

- **Statut : Accepted**
- **Date : 2026-09-01**
- **Version : 3.0.0**

## Contexte

PimsOS possède des tests unitaires et d'intégration dont certains peuvent appeler directement ou indirectement des opérations de Build, WIM, DISM ou ISO.

Un lancement aveugle de toute la suite peut donc provoquer un Build réel, un montage WIM ou une génération d'ISO alors qu'une simple validation de code était demandée.

La connexion du dépôt à GitHub et l'exécution CI renforcent également le besoin de distinguer clairement les tests automatisables des validations de Build réel.

## Décision

Le dépôt utilise `Tests\Tools\Invoke-PimsOSDiagnostics.ps1` comme garde-fou statique avant les campagnes ciblées.

Le diagnostic classe les fichiers en trois catégories :

- `SAFE` ;
- `BUILD-CAPABLE` ;
- `UNKNOWN`.

Les catégories `BUILD-CAPABLE` et `UNKNOWN` sont exclues des modes normaux `Unit` et `Integration`.

Une validation réelle du Build exige deux éléments explicites :

```powershell
-BuildValidation -AllowBuild
```

L'inventaire seul ne doit jamais exécuter de test.

## Raisons

- éviter un Build réel involontaire ;
- rendre le risque visible avant exécution ;
- conserver une séparation claire entre tests automatisés et validation destructive ;
- faciliter le diagnostic lorsqu'un test est classé comme dangereux ;
- permettre une reprise de session reproductible.

## Conséquences

### Positives

- réduction du risque de montage WIM/ISO accidentel ;
- distinction explicite entre validation de code et validation du produit ;
- rapports Markdown/JSON historisés ;
- méthode utilisable par le développeur et par ChatGPT.

### Acceptées

L'analyse est statique et conservatrice. Un test réellement sûr peut être classé `BUILD-CAPABLE` si le scanner ne dispose pas d'une preuve suffisante de neutralisation.

Cette prudence est volontaire : un faux positif est préférable à l'exécution involontaire d'un Build.

## Règle d'évolution

Toute amélioration du scanner doit réduire les faux positifs sans affaiblir la règle de sécurité. Une modification de classification doit être accompagnée d'un test démontrant que les opérations de Build restent bloquées lorsqu'elles ne sont pas explicitement autorisées.
