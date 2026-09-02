# PimsOS — Matrice des 29 packages Chocolatey

**Date de référence : 2026-09-02**
**Objectif :** rendre le catalogue PimsOS reproductible et déterminer, package par package, s'il peut réellement être installé hors ligne.

## Légende

- **VALIDÉ** : informations de package vérifiées sur Chocolatey Community ; pas encore synonyme d'OfflineReady.
- **À AUDITER** : package identifié et version de référence connue, mais le contenu du `.nupkg` / script d'installation doit encore être inspecté avant de déclarer OfflineReady.
- **CONDITIONNEL** : dépend d'une ressource Windows/ISO ou d'un composant externe ; l'installation peut être rendue offline par PimsOS, mais pas avec le `.nupkg` seul.
- **EXCLU / À REVOIR** : package inadapté au profil de base, ancien, non officiel ou présentant un intérêt discutable.

> **Règle PimsOS :** un package n'est jamais marqué `OfflineReady=true` simplement parce que son `.nupkg` existe. Il faut démontrer que toutes les charges utiles nécessaires à l'installation sont présentes dans le cache PimsOS ou fournies par Windows/ISO.

## Matrice

| # | Package | Catégorie | Version de référence | Source | OfflineReady | Statut PimsOS | Motif / prochaine vérification |
|---:|---|---|---|---|---|---|---|
| 1 | `vcredist140` | Prerequisite | `14.51.36247` | Chocolatey Community | À auditer | VALIDÉ | Vérifier si l'EXE VC++ est embarqué ou téléchargé par le script. |
| 2 | `DoNet3.5` → `dotnet3.5` | Prerequisite | `3.5.20260626` | Chocolatey Community | CONDITIONNEL | CONDITIONNEL | Sur Windows < 28000, s'appuie sur DISM/Windows Component Store ; le média source doit être disponible pour garantir l'offline. |
| 3 | `chocolatey` | Chocolatey | Bootstrap | Chocolatey | Oui* | VALIDÉ | Le bootstrap PimsOS doit embarquer le `.nupkg` de Chocolatey ; ne pas dépendre de Community au premier démarrage. |
| 4 | `chocolateygui` | Chocolatey | `3.2.0` | Chocolatey Community | À auditer | VALIDÉ | Vérifier dépendances et payload réellement embarqué. |
| 5 | `chocolatey-core.extension` | Chocolatey | `1.4.0` | Chocolatey Community | Oui probable | VALIDÉ | Extension de fonctions Chocolatey ; confirmer absence de téléchargement externe. |
| 6 | `choco-package-list-backup` | Chocolatey | `2023.6.28` | Community / unofficial | Non retenu | EXCLU / À REVOIR | Package explicitement présenté comme unofficial et ancien ; inutile au fonctionnement de PimsOS. |
| 7 | `googlechrome` | Browser | `153.0.8010.12` | Chocolatey Community | À auditer | **Échec checksum non bloquant** | Validation VM : checksum mismatch, `FailurePolicy=Continue`, poursuite normale. Ne pas utiliser `--ignore-checksums`. |
| 8 | `brave` | Browser | À figer | Chocolatey Community | À auditer | À REVOIR | La page actuelle renvoie une version Beta ; PimsOS doit imposer une version stable explicite. |
| 9 | `firefox` | Browser | `154.0.1`* | Chocolatey Community | À auditer | VALIDÉ | Une `155.0.0` existe depuis le 01/09/2026 mais était encore Pending Automated Review ; ne pas la figer tant qu'elle n'est pas approuvée. |
| 10 | `tor-browser` | Browser | `15.0.20` | Chocolatey Community | À auditer | VALIDÉ | Inspecter le script et le bundle téléchargé. |
| 11 | `winrar` | Utility | `7.23.0` | Chocolatey Community | À auditer | VALIDÉ | Vérifier payload et politique de licence ; version trial/nagware. |
| 12 | `keepass` | Utility | `2.61.1` | Chocolatey Community | À auditer | VALIDÉ | Le package principal dépend de `keepass.install`; les dépendances doivent être incluses dans le cache. |
| 13 | `notepadplusplus` | Utility | `8.9.8` | Chocolatey Community | À auditer | VALIDÉ | Inspecter package/installateur et checksum. |
| 14 | `vlc` | Multimedia | `3.0.23` | Chocolatey Community | À auditer | VALIDÉ | Version Community actuelle vérifiée ; inspecter le payload externe éventuel. |
| 15 | `teamviewer` | Remote | `15.81.5` | Chocolatey Community | À auditer | VALIDÉ | Vérifier installateur et conditions d'utilisation ; pas forcément adapté au profil Minimal. |
| 16 | `iCloud` | Cloud | `7.21.0.23` | Chocolatey Community | À auditer | À REVOIR | Package très ancien côté publication et installateur Apple externe ; intérêt à confirmer. |
| 17 | `everything` | Utility | `1.4.11032` | Chocolatey Community | À auditer | VALIDÉ | Package approuvé ; vérifier que les EXE présents dans le package/cache sont réellement conservés par PimsOS. |
| 18 | `rufus` | Utility | `4.15.0` | Chocolatey Community | À auditer | VALIDÉ | Package approuvé ; vérifier payload et éventuelles dépendances. |
| 19 | `filezilla` | Network | `3.71.1` | Community | À auditer | VALIDÉ | Version actuelle vérifiée ; inspecter URL/payload. |
| 20 | `treesizefree` | Utility | À figer | Community | À auditer | VALIDÉ | Version actuelle à relever automatiquement puis figer dans le catalogue. |
| 21 | `bluescreenview` | Diagnostic | `1.55` | Community | À auditer | À REVOIR | Package inchangé depuis 2015 ; utile en dépannage mais trop ancien pour un profil de base. |
| 22 | `powertoys` | Utility | `0.101.2362` | Chocolatey Community | À auditer | VALIDÉ | Package approuvé ; vérifier que l'installateur est bien disponible localement dans le cache. |
| 23 | `rainmeter` | Desktop | `4.5.26` | Community | Non avec `.nupkg` seul | VALIDÉ | Le script utilise directement un EXE GitHub : l'EXE doit être ajouté au cache PimsOS. |
| 24 | `XnViewMP` | Graphics | `1.11.5` | Community | À auditer | VALIDÉ | Package principal avec dépendance `xnviewmp.install`; résoudre la chaîne complète. |
| 25 | `yacreader` | Reading | À figer | Community | À auditer | VALIDÉ | Inspecter le script et les URLs de téléchargement. |
| 26 | `razer-synapse-4` | Hardware | `2.5.0.882` | Community | À auditer | VALIDÉ | Package tiers maintenu par un mainteneur Community ; vérifier installateur Razer et dépendances. |
| 27 | `autohotkey` | Utility | `2.0.26` | Chocolatey Community | À auditer | VALIDÉ | Package principal de type meta/install ; résoudre `autohotkey.install`. |
| 28 | `powershell-core` | Development | `7.6.5` | Community | À auditer | VALIDÉ | Package d'installation ; vérifier MSI/EXE et comportement si PowerShell est déjà présent. |
| 29 | `soundblaster-command` | Hardware | `3.5.10` | Community | À auditer | À REVOIR | Package ancien (2024) ; vérifier compatibilité avec le matériel ciblé avant inclusion par défaut. |

\* **Firefox :** au 02/09/2026, `155.0.0` existe mais est encore en attente de revue automatisée ; `154.0.1` est la dernière version approuvée utilisée comme référence sûre.
\* **Chocolatey :** `OfflineReady` signifie « bootstrap local PimsOS », pas « package Community garanti offline ».

## Priorités d'audit

### P0 — bloquants pour le mode Offline

1. `chocolatey`
2. `vcredist140`
3. `dotnet3.5`
4. `googlechrome`
5. `firefox`
6. `brave`
7. `notepadplusplus`
8. `vlc`

### P1 — packages courants à rendre reproductibles

`keepass`, `everything`, `powertoys`, `filezilla`, `rufus`, `winrar`, `tor-browser`, `teamviewer`, `rainmeter`, `XnViewMP`, `autohotkey`, `powershell-core`.

### P2 — à revoir avant intégration au profil Default

`choco-package-list-backup`, `iCloud`, `bluescreenview`, `soundblaster-command`, `brave` tant qu'une version stable n'est pas explicitement figée.

## Procédure de validation d'un package

Pour passer `OfflineReady` de `À auditer` à `true`, PimsOS doit :

1. figer `Id` + `Version` ;
2. télécharger le `.nupkg` exact ;
3. calculer et conserver son SHA-256 ;
4. extraire le package dans un espace temporaire ;
5. inspecter `.nuspec`, dépendances et `tools\chocolateyInstall.ps1` ;
6. extraire toutes les URLs externes et fichiers attendus ;
7. télécharger les payloads nécessaires dans le cache PimsOS ;
8. vérifier les checksums ;
9. construire le manifeste du package ;
10. installer en VM **sans Internet** ;
11. vérifier le code de sortie et l'état final ;
12. seulement alors déclarer `OfflineReady=true`.

## Règle de versionnement

Le catalogue PimsOS ne doit plus contenir uniquement :

```json
{"Id":"firefox","Enabled":true}
```

mais à terme :

```json
{
  "Id": "firefox",
  "Version": "154.0.1",
  "Enabled": true,
  "OfflineReady": false,
  "Category": "Browser"
}
```

La matrice est la source de décision humaine ; le catalogue JSON reste la source d'exécution du build.
