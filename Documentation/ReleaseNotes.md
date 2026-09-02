# PimsOS Builder — Notes de version

> Version technique : 3.0.0
>
> Dernière mise à jour : 2026-09-02

## Validation du 02/09/2026

- Build réel complet validé avec Windows 11 Professionnel index 6.
- Drivers `CurrentSystem` exportés et injectés avec DISM.
- 27 Tweaks appliqués.
- WIM sauvegardé, démonté et synchronisé avec SHA256 vérifié.
- ISO générée : `Output\PimsOS_3.0.0_20260902_141928.iso`.
- Taille ISO : 11,29 Go.
- Code retour Build : 0.
- Diagnostic sécurisé : 815 Passed / 0 Failed / 1 Skipped.
- PostInstall validé en VM.
- Chocolatey bootstrap local validé.
- `FailurePolicy=Continue` validé avec poursuite après échec Chrome.
- Microsoft Store, iCloud depuis le Store et Widgets validés en VM.
- Finalization et nettoyage différé validés en VM.

### Artefacts de référence

- WIM SHA256 : `B6BA0B8E8474761380FCC26DB165DC786162EA916B8D35192A977C49E72E9941`
- Diagnostic : `Tests\Reports\Diagnostics\Diagnostics-20260902-141259.md`
- État VM : `state.json` avec `Completed=true`, `Failed=false`, `Verification.Verified=true`.

### Anomalie connue non bloquante

`googlechrome` peut échouer sur un checksum lorsque l’installateur servi par Google évolue avant la mise à jour du package Chocolatey. `FailurePolicy=Continue` permet de poursuivre. Aucun contournement de checksum n’est utilisé.

---

# Mise à jour de validation — 01/09/2026

## Build réel

- Build complet PimsOS 3.0.0 validé avec code retour 0.
- Windows 11 Professionnel, index 6.
- 27 Tweaks appliqués.
- PostInstall préparé et validé.
- WIM synchronisé vers la source ISO avec SHA256 vérifié.
- ISO `Output\PimsOS_3.0.0_20260901_180342.iso` créée, 7,9 Go annoncés.

## Diagnostic sécurisé

- Ajout de `Tests\Tools\Invoke-PimsOSDiagnostics.ps1`.
- Séparation `SAFE` / `BUILD-CAPABLE` / `UNKNOWN`.
- Validation Build séparée par `-BuildValidation -AllowBuild`.
- Inventaire sans exécution avec `-InventoryOnly`.

## CI

- Ajout d'une concurrence par branche/ref dans PimsOS CI.
- Annulation des runs obsolètes lors des synchronisations rapides.
- Déclenchement limité aux chemins techniques pertinents afin que les changements purement documentaires ne déclenchent pas inutilement Pester.

---
