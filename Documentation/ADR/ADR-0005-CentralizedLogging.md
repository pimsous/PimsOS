# ADR-0005 — Journalisation centralisée

- **Statut** : Acceptée
- **Date** : 2026-07-19
- **Dernière mise à jour** : 2026-08-16
- **Décideur** : Pims
- **Impact** : Ensemble du framework

---

# Contexte

PimsOS contient de nombreux composants qui exécutent des opérations différentes au cours d'un même Build.

Afin de faciliter :

- le diagnostic ;
- le débogage ;
- le suivi des Builds ;
- l'analyse des erreurs ;
- la génération des rapports ;

une stratégie commune de journalisation est nécessaire.

L'utilisation de plusieurs mécanismes de journalisation rendrait les journaux difficiles à exploiter et compliquerait leur interprétation.

---

# Décision

Tous les composants du framework utilisent le système de journalisation centralisé fourni par :

```text
Modules\Infrastructure\Logger.ps1
```

La fonction principale de journalisation utilisée par les composants est :

```powershell
Write-Log
```

Les composants ne doivent pas écrire directement dans les fichiers de log.

Le Logger constitue le point central de la journalisation du framework.

---

# Responsabilités du Logger

Le Logger est responsable notamment de :

- créer et gérer le fichier de journal ;
- gérer l'encodage ;
- écrire les messages ;
- gérer les niveaux de journalisation ;
- produire un format homogène ;
- fournir les mécanismes nécessaires au diagnostic.

Les composants appelants ne doivent pas réimplémenter ces responsabilités.

---

# Niveaux de journalisation

Le projet utilise notamment les niveaux suivants :

| Niveau | Description |
|---------|-------------|
| INFO | Information générale |
| SUCCESS | Opération réussie |
| WARNING | Situation inhabituelle ou non bloquante |
| ERROR | Erreur |
| DEBUG | Information de diagnostic |

Les composants doivent utiliser le niveau correspondant à la nature réelle du message.

---

# Journalisation des composants

Les composants importants doivent journaliser les opérations utiles au suivi du Build.

Les informations doivent permettre notamment d'identifier :

- le composant ;
- l'opération ;
- le provider utilisé lorsque cela est pertinent ;
- les ressources concernées ;
- les erreurs rencontrées ;
- le résultat de l'opération lorsque cela est pertinent.

Exemple :

```text
[INFO] Command Provider : Native
[INFO] Commande : ...
```

Le format exact des entrées est défini par le Logger.

---

# Encodage

Les journaux du projet utilisent :

- UTF-8 ;
- sans BOM.

Les paramètres de fin de ligne doivent rester cohérents avec les conventions du projet et de l'environnement Windows.

La gestion de l'encodage est centralisée dans le Logger.

---

# Conséquences

## Avantages

- journaux homogènes ;
- diagnostic simplifié ;
- meilleure lisibilité ;
- maintenance centralisée ;
- possibilité de faire évoluer le format sans modifier chaque composant ;
- informations cohérentes entre les différentes couches.

## Inconvénients

- dépendance commune au Logger ;
- nécessité de charger l'Infrastructure avant les composants qui l'utilisent.

---

# Alternatives étudiées

## Write-Host

Rejetée comme mécanisme de journalisation.

`Write-Host` est destiné à l'affichage direct et ne fournit pas le mécanisme centralisé, persistant et homogène requis par le framework.

---

## Écriture directe dans un fichier

Rejetée.

Chaque composant aurait pu produire son propre format et contourner les règles communes du projet.

---

## Out-File / Add-Content

Rejetées comme mécanisme de journalisation des composants.

Ces commandes peuvent être utilisées par l'implémentation interne du Logger si nécessaire, mais les composants métier et techniques ne doivent pas les utiliser directement pour écrire leurs journaux.

---

# Règles

Les composants du framework ne doivent jamais :

- utiliser `Write-Host` comme mécanisme de journalisation ;
- écrire directement dans un fichier de log ;
- réimplémenter le format de journalisation ;
- créer un second système de journalisation parallèle.

Les composants doivent utiliser :

```powershell
Write-Log
```

Les informations de diagnostic complémentaires peuvent utiliser `Write-Verbose` ou `Write-Debug` lorsque cela est approprié.

Toute évolution du format, de l'encodage ou du stockage des journaux doit être réalisée dans le Logger.

---

# Intégration avec le BuildContext

Le Logger utilise les informations nécessaires fournies par le contexte du Build lorsque cela est pertinent.

Les composants ne doivent pas utiliser le Logger pour transporter des données métier entre eux.

Le journal constitue une trace d'exécution et non un mécanisme de communication entre composants.

---

# Tests

Le Logger doit disposer de tests couvrant notamment :

- le démarrage ;
- l'écriture d'une entrée ;
- les niveaux de journalisation ;
- l'encodage ;
- la gestion du fichier ;
- les erreurs d'écriture lorsque cela est pertinent.

Les tests des autres composants peuvent vérifier que les opérations importantes sont journalisées lorsque le comportement attendu le nécessite.

---

# Évolution

Toute évolution importante du mécanisme de journalisation doit préserver :

- le point d'accès commun ;
- la cohérence des niveaux ;
- la lisibilité des journaux ;
- la compatibilité avec les composants existants lorsque cela est possible.

Une évolution modifiant l'architecture générale de la journalisation doit être documentée dans une nouvelle ADR lorsque nécessaire.

---

# Décision finale

Le Logger constitue l'unique mécanisme officiel de journalisation de **PimsOS Builder**.

Tous les composants utilisent le système centralisé et aucune logique de journalisation parallèle ne doit être introduite dans les composants métier ou techniques.

---

# Références

- `Architecture.md`
- `ArchitectureRules.md`
- `CodingStandards.md`
- `ModuleGuide.md`
- `TechnicalDecisions.md`
