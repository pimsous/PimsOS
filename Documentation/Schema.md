# PimsOS Builder — Schémas de configuration

> Version technique : 3.0.0
>
> Dernière mise à jour : 2026-09-02

Ce document décrit les structures de données réellement utilisées par PimsOS Builder. Les fichiers JSON restent la source de vérité opérationnelle.

## `Config/config.json`

### Logging

```json
{
  "Logging": {
    "KeepLogs": 20,
    "Level": "INFO",
    "Encoding": "UTF8"
  }
}
```

### Paths / Workspace

Les chemins de projet sont relatifs à la racine PimsOS. Le Workspace contient les copies de travail et les caches Build.

Principaux chemins : `Workspace`, `Workspace\ISO`, `Workspace\ISOSource`, `Workspace\Sources`, `Workspace\Mount\WIM`, `Workspace\Drivers`, `Workspace\Packages`, `Workspace\Packages\Chocolatey`.

### Requirements

- `MinimumFreeSpaceGB` : espace disque minimal.
- `PowerShellMajor` : version minimale du moteur Build.
- `WindowsADK` : présence, version, chemin, fonctionnalité et paramètres de téléchargement de l’ADK.

Le Build actuel attend PowerShell 7 côté environnement de construction. Le runtime PostInstall est explicitement compatible PowerShell 5.1+.

### Image

```json
{
  "Edition": null,
  "Language": "fr-FR"
}
```

`Edition=null` permet la sélection de l’image lors du Build.

### Drivers

```json
{
  "Source": "None|CurrentSystem|Folder",
  "Path": null,
  "Recurse": true,
  "ForceUnsigned": false
}
```

`CurrentSystem` exporte les pilotes du poste hôte avant injection DISM. `Folder` utilise le dossier indiqué et sa recherche récursive si `Recurse=true`.

### Build

```json
{
  "Id": "Development",
  "CreateISO": true,
  "CreateReport": true
}
```

## `Config/PackageProviders.json`

Les providers déclarent leur activation, handler et cache. Le moteur générique reste séparé des providers spécialisés.

Providers actuellement présents : `Chocolatey`, `Winget`, `MicrosoftStore`. Chocolatey est le seul provider réellement opérationnel dans la chaîne actuelle.

## `Config/Packages/Chocolatey.json`

Chaque entrée contient notamment :

```json
{
  "Id": "firefox",
  "Enabled": true,
  "Category": "Browser",
  "Mode": "Online",
  "Version": "154.0.1",
  "FailurePolicy": "Stop"
}
```

Champs :

- `Id` : identifiant Chocolatey ;
- `Enabled` : activation ;
- `Category` : catégorie fonctionnelle ;
- `Mode` : `Offline`, `Online` ou `Disabled` ;
- `Version` : version demandée ou `null` ;
- `FailurePolicy` : `Stop` ou `Continue`, avec `Stop` par défaut.

### Règle spéciale `chocolatey`

Le package `chocolatey` est obligatoire en `Offline` : il constitue le bootstrap local du moteur Chocolatey. Son `.nupkg` doit être présent et exploitable dans `Workspace\Packages\Chocolatey` avant la génération de l’image.

## `Config/ActionTemplates`

Les templates disponibles couvrent :

`Capability`, `Command`, `Driver`, `Environment`, `Feature`, `File`, `Folder`, `Package`, `PowerShell`, `Registry`, `ScheduledTask`, `Service`, `Shortcut`.

Ils décrivent les formes attendues des Actions et servent de référence documentaire pour la configuration.

## États PostInstall

Le `state.json` runtime contient notamment :

- `Status` ;
- `Started` ;
- `Completed` ;
- `Failed` ;
- `WaitingForNetwork` ;
- `CurrentPhase` ;
- `CompletedTasks` ;
- `PendingTasks` ;
- `Errors` ;
- `Verification` ;
- `Cleanup` ;
- `ChocolateyResults` ;
- `ChocolateyFailures`.

La validation finale exige `Status=Completed`, `Completed=true`, `Failed=false`, aucune tâche manquante et `Verification.Verified=true`.

## Références

- `Documentation/Architecture.md` pour l’architecture ;
- `Documentation/ChocolateyArchitecture.md` pour le provider ;
- `Documentation/PostInstall.md` pour le runtime ;
- `Documentation/Testing.md` pour les preuves de validation ;
- `Documentation/ADR/` pour les décisions normatives.
