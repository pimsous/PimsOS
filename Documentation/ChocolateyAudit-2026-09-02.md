# Audit Chocolatey — 2026-09-02

## Décision d'architecture

Chocolatey lui-même est traité comme un **composant bootstrap obligatoire du Build**. Le Build prépare `chocolatey.nupkg`, le valide et l'embarque dans le runtime PostInstall. Au premier démarrage, le Bootstrap attend `Network` et `DriverCheck`, puis installe Chocolatey depuis le cache local.

Les packages applicatifs ne sont pas automatiquement offline : `Mode=Offline` exige une validation complète des payloads et une installation sans Internet.

## Catalogue actuel

- 29 packages activés
- 28 `Online`
- 1 `Offline` : `chocolatey`
- 25 versions figées
- 4 versions non figées : `chocolatey`, `brave`, `treesizefree`, `yacreader`

## Contrôles ajoutés

`Prepare-ChocolateyCache` :

1. charge le catalogue ;
2. prépare uniquement les entrées `Mode=Offline` ;
3. exige la présence de `chocolatey.nupkg` ;
4. vérifie que le package est une archive `.nupkg` exploitable ;
5. vérifie la présence de `tools/chocolateyInstall.ps1` ;
6. inscrit `Chocolatey.BootstrapReady` dans le `BuildState` ;
7. seulement ensuite autorise `Prepare-PostInstall`.

## Validation réalisée le 02/09/2026

- Diagnostic sécurisé : 815 Passed / 0 Failed / 1 Skipped.
- Build réel avec bootstrap Chocolatey : OK.
- Installation runtime Chocolatey depuis le cache local : OK.
- `FailurePolicy=Continue` : OK en VM.
- `googlechrome` : échec checksum non bloquant ; `brave` et les packages suivants continuent.

## Suites à exécuter

- `Tests/Unit/Modules/ChocolateyCache.Tests.ps1`
- `Tests/Unit/Modules/Chocolatey.Tests.ps1`
- `Tests/Unit/Modules/PostInstall/Bootstrap.Tests.ps1`
- `Tests/Unit/Modules/PostInstall/PostInstall.Tests.ps1`
- `Tests/Integration/BuildPipeline.Tests.ps1`

## Règle de sécurité

Le Build réel et la VM ont maintenant fourni la preuve fonctionnelle. Les prochaines validations Chocolatey concernent l’audit Offline des packages applicatifs.
