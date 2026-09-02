# PimsOS — Gestion des échecs Chocolatey

## 2026-09-02

Ajout de `FailurePolicy` au catalogue Chocolatey :

- `Stop` : comportement historique, arrêt sur erreur.
- `Continue` : journalise l'échec et poursuit les packages suivants.

Le contrôle de checksum Chocolatey reste obligatoire. Aucun `--ignore-checksums` n'est utilisé.

`googlechrome` est configuré en `Continue` afin qu'une indisponibilité ou désynchronisation temporaire du package n'empêche pas les autres applications de s'installer.

Les échecs sont conservés dans `ChocolateyResults`, `ChocolateyFailures` et `state.json`.

## Validation VM du 02/09/2026

`googlechrome` a échoué sur un checksum Chocolatey, avec `FailurePolicy=Continue`. Le PostInstall a continué immédiatement avec `brave`, puis les autres packages ont poursuivi leur installation. Le `state.json` final est `Completed`, avec une seule entrée dans `ChocolateyFailures`.

Cet échec est classé **connu et non bloquant**. Aucun `--ignore-checksums` n'est utilisé.
