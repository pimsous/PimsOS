# Finalisation PostInstall — 2026-09-02

## Objectif

Le cycle PostInstall dispose désormais d'une étape de vérification finale suivie d'un nettoyage différé des artefacts de démarrage.

La finalisation intervient **après le retour de `Invoke-PostInstall` dans `Bootstrap.ps1`**. Elle ne remplace pas les contrôles de chaque phase.

## Vérification finale

`Test-PimsOSPostInstallCompletion` vérifie :

- `Status = Completed` ;
- `Completed = true` ;
- `Failed = false` ;
- aucune phase courante résiduelle ;
- présence des tâches obligatoires :
  - `Initialize` ;
  - `Network` ;
  - `DriverCheck` ;
  - `Chocolatey` ;
  - `Applications` ;
  - `MicrosoftStore` ;
  - `Configuration` ;
  - `Cleanup`.

Le résultat est enregistré dans `state.json` sous `Verification`.

## Nettoyage différé

Le nettoyage est lancé dans un processus PowerShell séparé avec un délai par défaut de 10 secondes. Cette séparation est volontaire : elle permet de supprimer `Bootstrap.ps1` après la fin du processus qui l'exécute.

Les artefacts de lancement supprimés sont :

- `Bootstrap.ps1` ;
- `Finalize.ps1` ;
- `Logger.ps1` ;
- `Network.ps1` ;
- `UI.ps1` ;
- `DriverCheck.ps1` ;
- `Chocolatey.ps1` ;
- `PostInstall.ps1` ;
- `State.ps1` ;
- `C:\Windows\Panther\unattend.xml` lorsqu'il existe encore.

### Ressources conservées

Le nettoyage ne supprime volontairement pas :

- `state.json` ;
- `PostInstall.log` ;
- le dossier `Chocolatey`, notamment son cache.

Cette décision conserve les éléments utiles au diagnostic et aux installations Chocolatey déjà effectuées.

## Échec du nettoyage

La vérification finale est bloquante. En revanche, l'impossibilité de programmer le nettoyage ne transforme pas un PostInstall déjà terminé en échec.

Dans ce cas, `state.json` conserve :

- `Cleanup.Status = Failed` ;
- l'erreur rencontrée ;
- les ressources conservées.

Le Bootstrap journalise alors un avertissement.

## Séquence

```text
FirstLogon
    ↓
Bootstrap.ps1
    ↓
Invoke-PostInstall
    ↓
Status = Completed
    ↓
Vérification finale
    ↓
state.json sauvegardé
    ↓
processus de nettoyage différé
    ↓
Bootstrap / scripts runtime supprimés
    ↓
state.json + PostInstall.log + cache Chocolatey conservés
```

## Validation automatisée et VM — 02/09/2026

Les tests automatisés couvrent :

1. état complet accepté ;
2. tâche obligatoire manquante détectée ;
3. état non terminé refusé ;
4. lancement du processus de nettoyage ;
5. conservation de l'état, du journal et du cache ;
6. chargement de `Finalize.ps1` par le Bootstrap.

La validation réelle en VM est également réussie sur l'ISO `PimsOS_3.0.0_20260902_141928.iso`. Le `state.json` final indique `Status=Completed`, `Verification.Verified=true`, `Cleanup.Scheduled=true` et aucune erreur. Les scripts runtime et `C:\Windows\Panther\unattend.xml` ont effectivement disparu après le délai de nettoyage.
