# PimsOS Builder — Catalogue des Tweaks

> **27 Tweaks fonctionnels** dans le catalogue actuel.

> Version technique : 3.0.0  
> Mise à jour : 2026-09-01

## Objectif

Les Tweaks PimsOS sont des réglages Windows décrits par des données JSON.
Chaque Tweak doit avoir un effet clairement défini, une description lisible,
un niveau de risque, une indication de réversibilité et des actions testables.

PimsOS privilégie les réglages documentés et réversibles plutôt que les
modifications agressives de composants Windows.

## Catalogue actuel

### Applications

- **Applications.DisableSuggestedApps** — désactive certaines suggestions
  d'applications dans le menu Démarrer.

### Edge

- **Edge.DisableBackgroundMode** — empêche Edge de maintenir ses applications
  et extensions en arrière-plan après fermeture.
- **Edge.DisableStartupBoost** — désactive Startup Boost.
- **Edge.HideFirstRunExperience** — masque l'expérience de première exécution.

### Explorer

- **Explorer.ShowFileExtensions** — affiche les extensions des fichiers connus.
- **Explorer.ShowHiddenFiles** — affiche les éléments ayant l'attribut Caché.
  Cela ne suffit pas à afficher les fichiers système protégés.
- **Explorer.ShowProtectedSystemFiles** — affiche également les fichiers ayant
  les attributs Système + Caché, par exemple `pagefile.sys`, `swapfile.sys`
  et certains `desktop.ini`. Ce réglage est volontairement séparé de
  `ShowHiddenFiles` et présente un risque plus élevé.
- **Explorer.ShowSecondsInSystemClock** — affiche les secondes dans l'horloge
  de la barre des tâches.

### Gaming

- **Xbox.DisableGameBar** — conserve son identifiant historique pour éviter
  de casser les profils existants, mais son libellé est maintenant
  **Désactiver l'enregistrement et la diffusion de jeux**. La stratégie
  `GameDVR\AllowGameDVR=0` ne doit pas être présentée comme la suppression
  complète de Xbox Game Bar.

### OneDrive

- **OneDrive.DisableSync** — désactive la synchronisation OneDrive selon la
  stratégie définie par le Tweak.

### Privacy

- **Privacy.DisableActivityHistory**
- **Privacy.DisableAdvertisingId**
- **Privacy.DisableSuggestions**
- **Privacy.DisableTelemetry**
- **Privacy.DisableTailoredExperiences** — empêche Windows d'utiliser les
  données de diagnostic pour personnaliser recommandations, conseils et
  offres.
- **Privacy.DisableThirdPartySpotlightSuggestions** — bloque les suggestions
  provenant d'éditeurs tiers dans Windows Spotlight sans désactiver Spotlight.

### Performance / Services

- **Services.DisableSysMain** — désactive le service SysMain lorsqu'il est
  explicitement sélectionné.
- **SERVICE_DIAGTRACK_DISABLE** — conserve son identifiant historique et
  désactive le service DiagTrack lorsqu'il est sélectionné.

### Windows — Search

- **Search.DisableSearchHighlights** — désactive les surbrillances et contenus
  dynamiques de Windows Search, sans désactiver la recherche elle-même.

### Windows — Menu Démarrer

- **Start.HideRecommendedPersonalizedSites** — retire uniquement les
  recommandations personnalisées de sites web de la section Recommandé.
- **Start.HideRecommendedSection** — masque toute la section Recommandé.
  Ce réglage est donc plus intrusif et reste optionnel.

### Widgets

- **Widgets.DisableTaskbarWidgets** — désactive l'accès aux Widgets depuis
  la barre des tâches.

### Windows

- **Windows.EnableNumLock** — active NumLock au démarrage.
- **Windows.DisableWindowsTips** — désactive les conseils Windows.
- **WindowsAI.DisableRecallSnapshots** — interdit l'enregistrement des
  instantanés d'écran utilisés par Recall.
- **WindowsAI.DisableRecall** — rend Recall indisponible et empêche son
  activation par l'utilisateur.

### Windows Update

- **WindowsUpdate.DisableAutoRestart** — empêche certains redémarrages
  automatiques de Windows Update lorsqu'un utilisateur est connecté.

## Tweaks volontairement non ajoutés

Les réglages suivants ne sont pas ajoutés au catalogue simplement parce qu'ils
sont souvent proposés par des scripts de debloat :

- suppression d'Edge ;
- suppression de Microsoft Store ;
- désactivation de Defender ;
- désactivation du pare-feu ;
- désactivation complète de Windows Update ;
- désactivation de Windows Search ;
- suppression arbitraire d'AppX ;
- désactivation massive de services Windows.

Ils nécessitent soit une décision de conception distincte, soit un mécanisme
plus spécialisé que le moteur de Tweaks.

## Particularité des ruches

PimsOS distingue explicitement :

- `DEFAULT` : modifications de `C:\Users\Default\NTUSER.DAT`, destinées à
  être héritées par les nouveaux profils utilisateurs ;
- `SOFTWARE` : modifications de `HKLM\SOFTWARE` dans l'image Windows.

Ainsi, les Tweaks utilisateur tels que les réglages Explorer ou les
expériences personnalisées sont placés dans `DEFAULT`, tandis que les
stratégies machine telles que Windows Search ou Recall utilisent `SOFTWARE`
lorsque Microsoft les définit au niveau appareil.

## Références Microsoft vérifiées

Les politiques suivantes ont été vérifiées dans la documentation Microsoft
consultée le 1er septembre 2026 :

- Start : `HideRecommendedPersonalizedSites`,
  `HideRecommendedSection`
- Search : `AllowSearchHighlights`
- Experience / Cloud Content :
  `DisableTailoredExperiencesWithDiagnosticData`
- Windows AI :
  `AllowRecallEnablement`,
  `DisableAIDataAnalysis`

Sources :

- https://learn.microsoft.com/fr-fr/windows/configuration/start/policy-settings
- https://learn.microsoft.com/fr-fr/windows/client-management/mdm/policy-csp-search
- https://learn.microsoft.com/fr-fr/windows/client-management/mdm/policy-csp-experience
- https://learn.microsoft.com/fr-fr/windows/client-management/mdm/policy-csp-windowsai
- https://learn.microsoft.com/fr-fr/windows/client-management/manage-recall
- https://learn.microsoft.com/fr-fr/answers/questions/5929669/activer-l-affichage-des-secondes-sur-l-horloge-de

## Règle d'évolution

Tout nouveau Tweak doit être accompagné de :

1. une définition JSON valide ;
2. une description compréhensible par un utilisateur ;
3. une description d'impact précise ;
4. un niveau de risque ;
5. une indication de réversibilité ;
6. au moins un test de définition ;
7. une mise à jour des profils concernés si nécessaire ;
8. une mise à jour de cette documentation lorsque son comportement est
   significatif.

Un Tweak ne doit pas être ajouté uniquement parce qu'une commande trouvée sur
Internet fonctionne : sa méthode d'application et son comportement Windows
doivent être suffisamment fiables pour être intégrés au Builder.

# PimsOS Builder — Catalogue des Tweaks

> Version technique : **3.0.0**
>
> Etat au 01/09/2026 : **27 Tweaks chargés**

## Contrat

Chaque Tweak est défini par JSON et peut contenir une ou plusieurs Actions.
Le catalogue fournit notamment :

- identifiant ;
- nom ;
- catégorie ;
- description ;
- risque ;
- réversibilité ;
- redémarrage ;
- état par défaut ;
- Actions.

Les JSON vides sont des placeholders et sont ignorés.

## Catalogue fonctionnel actuel

Le catalogue réel doit être considéré comme la source de vérité dans
`Tweaks\`. La dernière validation d'architecture confirme :

```text
27 Tweaks chargés
Actions valides
0 erreur d'architecture
```

Les principales familles actuellement présentes sont :

- Applications
- Edge
- Explorer
- Gaming
- OneDrive
- Privacy
- Search
- Services
- Start
- Widgets
- Windows
- WindowsAI
- WindowsUpdate

## Tweaks explicitement validés dans la documentation récente

- `Applications.DisableSuggestedApps`
- `Edge.DisableBackgroundMode`
- `Edge.DisableStartupBoost`
- `Edge.HideFirstRunExperience`
- `Explorer.ShowFileExtensions`
- `Explorer.ShowHiddenFiles`
- `Explorer.ShowProtectedSystemFiles`
- `Explorer.ShowSecondsInSystemClock`
- `Xbox.DisableGameBar`
- `OneDrive.DisableSync`
- `Privacy.DisableActivityHistory`
- `Privacy.DisableAdvertisingId`
- `Privacy.DisableSuggestions`
- `Privacy.DisableTailoredExperiences`
- `Privacy.DisableThirdPartySpotlightSuggestions`
- `Services.DisableSysMain`
- `Search.DisableSearchHighlights`
- `Start.HideRecommendedPersonalizedSites`
- `Start.HideRecommendedSection`
- `Widgets.DisableTaskbarWidgets`
- `Windows.EnableNumLock`
- `Windows.DisableWindowsTips`
- `WindowsAI.DisableRecall`
- `WindowsAI.DisableRecallSnapshots`
- `WindowsUpdate.DisableAutoRestart`

Le nombre total validé est supérieur à cette liste documentée si le catalogue
contient d'autres définitions ; ne pas inventer leur description ici.
Le JSON sous `Tweaks\` reste la source de vérité.

## Point important — fichiers cachés

`Explorer.ShowHiddenFiles` affiche les éléments ayant l'attribut Caché.

Il ne signifie pas que les fichiers système protégés deviennent visibles.

`Explorer.ShowProtectedSystemFiles` est distinct et permet d'afficher les
fichiers protégés par les attributs Système + Caché. Il doit rester séparé
car il expose des fichiers que Windows masque normalement.

Exemples possibles : `pagefile.sys`, `swapfile.sys` et certains
`desktop.ini`.

## Prochain travail

- Auditer les 27 définitions une par une.
- Vérifier leurs Actions réelles.
- Documenter précisément effet, risque, réversibilité et redémarrage.
- Enrichir le catalogue uniquement avec des Tweaks utiles et vérifiés.
