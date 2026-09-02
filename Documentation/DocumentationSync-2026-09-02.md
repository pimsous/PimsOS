# PimsOS Builder — Synchronisation documentaire du 02/09/2026

## Objet

Cette note synchronise la documentation avec l’état réel du code, du Build et de la validation VM au 02/09/2026. Elle constitue la nouvelle référence de reprise avant les opérations Git.

## État technique

Version technique : **3.0.0**

Le framework est architecturalement stabilisé. La chaîne de production est fonctionnelle de bout en bout sur Windows 11 25H2 avec le scénario de drivers `CurrentSystem`.

## Build de référence

```text
ISO : Output\PimsOS_3.0.0_20260902_141928.iso
Taille : 11,29 Go
Edition : Windows 11 Professionnel
Index : 6
Build ID : 6302b96b-2cd1-4ba7-b66e-dc8b9980eebe
Code retour : 0
WIM SHA256 : B6BA0B8E8474761380FCC26DB165DC786162EA916B8D35192A977C49E72E9941
```

### Drivers

- export `CurrentSystem` réussi ;
- préparation dans `Workspace\Drivers\CurrentSystem` ;
- injection DISM réussie ;
- aucune erreur de propriété `Success` sur les actions dynamiques ;
- phase Drivers terminée avec succès.

## Tests

Dernière campagne diagnostic sûre :

```text
66 fichiers analysés
66 SAFE
0 BUILD-CAPABLE
0 UNKNOWN

815 Passed
0 Failed
1 Skipped
0 Inconclusive
0 NotRun
816 Total
```

Rapport : `Tests\Reports\Diagnostics\Diagnostics-20260902-141259.md`.

Le `Skipped` est conditionnel et intentionnel.

## PostInstall / Finalization VM

La VM de test confirme :

- Network disponible ;
- DriverCheck réussi ;
- Chocolatey installé localement depuis le cache PimsOS ;
- packages Online installés ;
- `FailurePolicy=Continue` fonctionnelle ;
- PostInstall `Completed=true` et `Failed=false` ;
- `Verification.Verified=true` ;
- Cleanup programmé et sans erreur ;
- scripts de démarrage supprimés après sortie du Bootstrap ;
- `unattend.xml` supprimé ;
- `state.json`, `PostInstall.log` et cache Chocolatey conservés.

## Chocolatey

Le modèle retenu reste :

```text
Build
  ↓
chocolatey.nupkg obligatoire Offline
  ↓
cache PimsOS
  ↓
ISO
  ↓
FirstLogon
  ↓
Network
  ↓
DriverCheck
  ↓
bootstrap Chocolatey local
  ↓
Offline local / Online Community
```

`googlechrome` est le seul échec fonctionnel observé sur la campagne VM. Il est enregistré avec `FailurePolicy=Continue`. L’échec de checksum n’est pas contourné. Les packages suivants continuent normalement.

## Microsoft Store

Store reste fourni par Windows. La VM confirme l’ouverture du Store, l’installation d’iCloud depuis Store et le fonctionnement des Widgets. Aucun changement de l’intégration Store PimsOS n’est nécessaire.

## Documentation mise à jour

Les documents centraux ont été synchronisés ou nettoyés :

- `ProjectStatus.md` ;
- `PostInstall.md` ;
- `Testing.md` ;
- `ReleaseNotes.md` ;
- `Backlog.md` ;
- `Roadmap.md` ;
- `Lifecycle.md` ;
- `TechnicalDecisions.md` ;
- `Schema.md` ;
- `CurrentSprint.md` ;
- `ChocolateyArchitecture.md` ;
- `ChocolateyFailurePolicy-2026-09-02.md` ;
- `ChocolateyPackageMatrix.md` ;
- documentation générale dont les dates de mise à jour actives.

Les doublons documentaires accidentels présents dans plusieurs fichiers ont été supprimés.

## Prochaine étape

**Git est maintenant la prochaine opération immédiate.**

Avant tout commit : vérifier `git status`, le diff, le remote, la branche et les artefacts ignorés.
