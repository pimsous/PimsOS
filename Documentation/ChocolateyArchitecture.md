# PimsOS — Architecture Chocolatey Offline / Online

## Principe

PimsOS utilise un moteur Chocolatey unique avec deux sources d'installation déterminées par le catalogue :

- `Mode = Offline` : le package `.nupkg` est téléchargé pendant le **Build**, vérifié puis embarqué dans l'ISO. Au premier démarrage, Chocolatey installe ce package exclusivement depuis le cache local.
- `Mode = Online` : aucun package n'est embarqué par défaut. Après `DriverCheck`, le Bootstrap utilise Chocolatey et Community pour télécharger puis installer le package.
- `Mode = Disabled` : le package est ignoré.

## Séquence Build

```text
Build
  -> ApplyDrivers
  -> PrepareChocolateyCache
       -> catalogue
       -> sélection Mode=Offline
       -> téléchargement des .nupkg
       -> cache Workspace\Packages\Chocolatey
  -> PreparePostInstall
       -> copie du catalogue
       -> copie du cache Offline dans ProgramData\PimsOS\PostInstall\Chocolatey\Cache
  -> ISO
```

Le build ne télécharge donc pas les packages `Online`.

## Séquence FirstLogon

```text
FirstLogonCommands
  -> Bootstrap
  -> Network
  -> DriverCheck
  -> Chocolatey Bootstrap local
  -> packages Offline depuis le cache
  -> packages Online depuis Community
```

Les téléchargements Internet de packages ont donc lieu **après le contrôle des pilotes**, conformément à l'architecture PimsOS retenue.

## Règle Offline

Un package n'est placé en `Mode=Offline` qu'après validation de son `.nupkg`, de ses dépendances et de ses éventuelles charges utiles externes. Le simple téléchargement du `.nupkg` ne suffit pas à garantir une installation hors ligne. Chocolatey recommande une source locale sous forme de dossier contenant les `.nupkg`; l'installation doit utiliser `--source` sur ce dossier plutôt que pointer directement vers un fichier `.nupkg`. citeturn0search2turn0search4

## Bootstrap Chocolatey

`chocolatey.nupkg` est toujours traité comme un artefact Offline spécial. Le runtime le décompresse et exécute `tools\chocolateyInstall.ps1` localement avant d'utiliser `choco.exe`. Cette méthode est documentée par Chocolatey pour une installation complètement offline. citeturn0search0

## Conséquence pour la matrice

La matrice conserve l'état d'audit (`OfflineReady`), tandis que `Config/Packages/Chocolatey.json` porte la décision d'exécution (`Mode`). Tant qu'un package n'est pas validé offline, son mode reste `Online`.

## Bootstrap Chocolatey — règle de Build

Chocolatey est un **pré-requis obligatoire du runtime PostInstall**. Le Build ne doit donc jamais dépendre d'une installation Internet de Chocolatey au premier démarrage.

Le pipeline suit cette séquence :

```text
Build
  ↓
PrepareChocolateyCache
  ↓
Téléchargement de chocolatey.nupkg
  ↓
Validation de tools/chocolateyInstall.ps1
  ↓
Preuve BootstrapReady dans BuildState
  ↓
PreparePostInstall
  ↓
Copie du cache + catalogue dans l'image
  ↓
FirstLogon / Bootstrap
  ↓
Network
  ↓
DriverCheck
  ↓
Installation locale de Chocolatey
  ↓
Exécution du catalogue
```

### Garantie

Le Build échoue volontairement si `chocolatey.nupkg` est absent ou inexploitable dans `Workspace\Packages\Chocolatey`.

Le champ `Mode=Offline` de l'entrée `chocolatey` signifie ici **bootstrap local du moteur Chocolatey**. Il ne signifie pas que les autres packages Community sont disponibles hors ligne.

Les packages applicatifs `Offline` ne pourront être ajoutés qu'après validation de leur `.nupkg`, de leurs dépendances, de leurs payloads et d'une installation réelle sans Internet.


## Gestion des échecs de packages Online

Le catalogue peut définir `FailurePolicy` :

- `Stop` (valeur par défaut) : un échec arrête la phase Chocolatey.
- `Continue` : l'échec est conservé dans `ChocolateyResults` / `ChocolateyFailures`, journalisé en `WARNING`, puis les packages suivants continuent.

Cette politique ne désactive jamais les contrôles de checksum et n'utilise jamais `--ignore-checksums`.

`googlechrome` utilise actuellement `FailurePolicy = Continue` afin qu'un problème temporaire du package Community n'empêche pas les autres installations. Son résultat reste `Status = Failed` et l'échec est conservé dans `state.json`.

### Validation réelle

Le scénario a été validé en VM le 02/09/2026 : Chrome échoue sur son checksum, le résultat est conservé, puis `brave` et les packages suivants sont exécutés normalement. Le PostInstall reste `Completed`. Aucun contournement de checksum n'est utilisé.
