# PimsOS Builder — Décisions techniques

> Version technique : 3.0.0
>
> Dernière mise à jour : 2026-09-02

Ce document est l’index des décisions techniques actuellement retenues. Les décisions architecturales normatives sont conservées dans `Documentation/ADR/`.

## Décisions structurantes

| Décision | État | Référence |
|---|---|---|
| Module PowerShell unique | ✅ Retenue | ADR-0001, ADR-0012 |
| BuildContext centralisé | ✅ Retenue | ADR-0002, ADR-0010 |
| Pipeline séquentiel et explicite | ✅ Retenue | ADR-0004 |
| Logging centralisé | ✅ Retenue | ADR-0005 |
| Configuration JSON | ✅ Retenue | ADR-0006 |
| Tests officiels séparés des tests Legacy | ✅ Retenue | ADR-0007 |
| Gestion des erreurs centralisée | ✅ Retenue | ADR-0008 |
| Dépendances du framework explicites | ✅ Retenue | ADR-0009 |
| Contrats Engines/Managers/Actions | ✅ Retenue | ADR-0011 |
| Diagnostic sécurisé avant Pester | ✅ Retenue | ADR-0013, ADR-0014 |

## Décisions récentes — 02/09/2026

### Drivers

- `Drivers` est la source utilisateur.
- `Workspace\Drivers` est l’espace de préparation Build.
- `CurrentSystem` exporte les pilotes du système hôte puis les injecte dans le WIM via DISM.
- Une action Driver créée dynamiquement doit être normalisée avant exécution afin de fournir `Success`, `Duration` et `Error`.

### Chocolatey

- Un seul moteur Chocolatey est utilisé.
- `Mode=Offline` signifie préparation Build et cache local runtime.
- `Mode=Online` signifie téléchargement runtime après `Network` et `DriverCheck`.
- `chocolatey.nupkg` est un bootstrap Offline obligatoire du Build.
- Aucun package applicatif n’est déclaré Offline sans audit de ses dépendances et payloads.
- `FailurePolicy=Stop` est la valeur par défaut. `Continue` permet de poursuivre après un échec tout en conservant l’échec dans l’état.
- Les contrôles de checksum restent obligatoires ; aucun `--ignore-checksums`.

### PostInstall / Finalization

- Le runtime est installé dans `C:\ProgramData\PimsOS\PostInstall`.
- `FirstLogonCommands` lance `Bootstrap.ps1`.
- Après succès de toutes les tâches, `Finalize.ps1` vérifie l’état puis programme un nettoyage différé dans un processus séparé.
- Les scripts temporaires et `unattend.xml` sont supprimés ; `state.json`, `PostInstall.log` et le cache Chocolatey sont conservés.

### Microsoft Store

- Microsoft Store reste fourni par l’image Windows source.
- PimsOS ne remplace pas Store par un provider applicatif.
- La validation VM du 02/09/2026 confirme Store, iCloud installé depuis Store et Widgets fonctionnels.

## Preuves de validation

- Build ISO : `Output\PimsOS_3.0.0_20260902_141928.iso` ; code retour 0.
- WIM SHA256 : `B6BA0B8E8474761380FCC26DB165DC786162EA916B8D35192A977C49E72E9941`.
- Pester sécurisé : 815 Passed / 0 Failed / 1 Skipped / 0 Inconclusive / 0 NotRun.
- Rapport : `Tests\Reports\Diagnostics\Diagnostics-20260902-141259.md`.
- Validation VM : `state.json` final `Completed`, `Verification.Verified=true`, Cleanup programmé et sans erreur.

## Règle de maintenance

Toute modification de l’architecture doit être ajoutée à un ADR lorsqu’elle change un contrat, une responsabilité ou une règle structurante. Ce document reste un index de décisions et ne doit pas devenir un second système de spécification.
