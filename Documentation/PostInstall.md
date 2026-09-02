# État de validation au 02/09/2026

Le cycle PostInstall/Chocolatey a été validé en VM sur une ISO PimsOS 3.0.0 générée le 02/09/2026. Le réseau et le contrôle des pilotes fonctionnent, Chocolatey est installé localement depuis le cache embarqué et les packages Online peuvent être installés.

La politique `FailurePolicy=Continue` a également été validée en conditions réelles : l'échec de Google Chrome sur son checksum est signalé sans bloquer le PostInstall et le package suivant est exécuté. Aucun `--ignore-checksums` n'est utilisé.

Le Microsoft Store est également validé en VM : il s'ouvre normalement, iCloud peut être installé depuis le Store et les Widgets peuvent être ouverts, installés et utilisés.

La finalisation après Bootstrap est maintenant implémentée dans `Finalize.ps1`. Elle vérifie l'état final avant de programmer un nettoyage différé. La validation VM de cette nouvelle étape est maintenant réussie : les scripts temporaires et `C:\Windows\Panther\unattend.xml` sont supprimés après la fin du Bootstrap, tandis que `state.json`, `PostInstall.log` et le cache Chocolatey sont conservés.

---

# PostInstall PimsOS

> Dernière mise à jour : 2026-09-02

## Objectif

Le sous-système PostInstall exécute les actions nécessaires après
l'installation de Windows.

Il est séparé du processus de Build afin de permettre :

* l'exécution de tâches locales sans réseau ;
* l'attente de la disponibilité réseau ;
* la reprise après connexion ;
* la persistance de l'état ;
* l'installation ultérieure des applications.

Le PostInstall constitue une phase d'exécution distincte du Build.
Le Build prépare les composants nécessaires dans l'image Windows tandis
que le runtime PostInstall exécute les opérations prévues après
l'installation du système.

---

## Architecture

Le runtime PostInstall est installé dans :

```text
C:\ProgramData\PimsOS\PostInstall\
```

Il comprend notamment :

```text
Bootstrap.ps1
Network.ps1
UI.ps1
PostInstall.ps1
State.ps1
Finalize.ps1
```

Le mécanisme FirstBoot génère :

```text
C:\Windows\Panther\unattend.xml
```

Le document utilise le passage `oobeSystem` et :

```text
Microsoft-Windows-Shell-Setup\FirstLogonCommands
```

La commande générée lance :

```text
C:\ProgramData\PimsOS\PostInstall\Bootstrap.ps1
```

---

## Préparation pendant le Build

La préparation du runtime PostInstall est réalisée pendant le Build
afin que les composants nécessaires soient présents dans l'image avant
sa génération.

Le pipeline utilise l'étape :

```text
PreparePostInstall
```

Cette étape est exécutée après l'application des drivers et avant
le montage de la ruche `SOFTWARE`.

---

## Pipeline Build

L'ordre actuellement validé est :

```text
MountWim
    ↓
ApplyDrivers
    ↓
PreparePostInstall
    ↓
MountSoftwareHive
```

Les tests d'intégration du BuildPipeline vérifient notamment :

* la présence de l'étape d'application des drivers ;
* son positionnement après le montage du WIM ;
* le positionnement de `PreparePostInstall` après les drivers ;
* le positionnement de `PreparePostInstall` avant `MountSoftwareHive` ;
* la préparation du runtime PostInstall ;
* l'utilisation du runtime présent dans le projet ;
* l'utilisation du Bootstrap installé dans `ProgramData` ;
* le refus d'un contexte ne possédant pas de montage WIM.

---

## Sources du runtime

La préparation PostInstall peut utiliser le runtime provenant du projet.

Elle prend également en compte le Bootstrap installé dans :

```text
C:\ProgramData\PimsOS\PostInstall\
```

Les tests du pipeline vérifient les différentes situations de sélection
du runtime.

---

## État

Les états prévus sont :

```text
Pending
Running
WaitingForNetwork
Completed
Failed
```

La persistance de l'état est assurée par le sous-système `State`.

L'état permet au runtime de suivre l'avancement des opérations et de
préparer les mécanismes de reprise nécessaires.

---

## Réseau

Le module Network fournit :

```text
Test-PostInstallNetwork
Test-PostInstallInternet
Wait-PostInstallNetwork
```

### Test du réseau

`Test-PostInstallNetwork` utilise en priorité :

```text
Get-NetConnectionProfile
```

Si cette méthode échoue, le module utilise :

```text
Get-NetAdapter
```

pour déterminer si un adaptateur réseau est actif.

### Test Internet

`Test-PostInstallInternet` vérifie d'abord la disponibilité du réseau
puis teste la connectivité Internet.

### Attente réseau

`Wait-PostInstallNetwork` permet d'attendre que le réseau devienne
disponible.

Le mécanisme prend en charge :

* un intervalle configurable ;
* un délai maximal configurable ;
* la correction d'un intervalle inférieur à une seconde ;
* l'arrêt immédiat lorsque le réseau devient disponible.

Les tests automatisés utilisent des mocks afin d'éviter les attentes
réelles pendant la campagne Pester.

---

## Interface réseau du premier démarrage

Le fichier `UI.ps1` fournit l'interface console utilisée par le runtime
PostInstall lors de la vérification et de l'attente réseau.

Il expose notamment :

```text
Show-PostInstallNetworkStatus
Show-PostInstallNetworkHelp
Wait-PostInstallNetworkUI
```

`Show-PostInstallNetworkStatus` affiche l'état de l'adaptateur réseau,
de la connexion réseau et de l'accès Internet.

`Show-PostInstallNetworkHelp` affiche les indications nécessaires
lorsqu'une connexion réseau est requise.

`Wait-PostInstallNetworkUI` assure l'attente avec affichage de l'état
et vérifie périodiquement la disponibilité du réseau.

La couche UI reste séparée de la logique métier et peut utiliser les
fonctions du module Network.

---

## Fonctionnement sans réseau

Le PostInstall doit pouvoir effectuer les tâches locales sans dépendre
immédiatement d'Internet.

Lorsque le réseau est indisponible, le moteur peut passer à :

```text
WaitingForNetwork
```

L'interface utilisateur indique alors la situation et fournit les
informations nécessaires pour permettre la reconnexion.

Les opérations nécessitant une connexion peuvent ainsi être exécutées
ultérieurement lorsque les conditions nécessaires sont réunies.

---

## FirstBoot

Le sous-système FirstBoot prépare l'exécution du PostInstall lors de la
première connexion Windows.

`FirstBoot.ps1` construit la configuration des commandes FirstLogon.

`Unattend.ps1` génère le document XML Windows.

`Installer.ps1` :

1. installe le runtime dans le WIM ;
2. crée `Windows\Panther\unattend.xml`.

Le document `unattend.xml` utilise :

```text
oobeSystem
└── Microsoft-Windows-Shell-Setup
    └── FirstLogonCommands
```

La commande configurée pointe vers :

```text
C:\ProgramData\PimsOS\PostInstall\Bootstrap.ps1
```

---

## Bootstrap

`Bootstrap.ps1` constitue le point d'entrée du runtime PostInstall.

Il est installé dans :

```text
C:\ProgramData\PimsOS\PostInstall\Bootstrap.ps1
```

Le Bootstrap charge les composants nécessaires du runtime, notamment :

```text
State.ps1
Network.ps1
UI.ps1
PostInstall.ps1
Finalize.ps1
```

Le mécanisme FirstBoot s'appuie sur ce Bootstrap pour démarrer le
runtime après l'installation de Windows.

---

## Installation dans le WIM

`Installer.ps1` prépare les composants PostInstall directement dans
l'image Windows montée.

La préparation comprend notamment :

```text
C:\ProgramData\PimsOS\PostInstall\
```

et :

```text
C:\Windows\Panther\unattend.xml
```

Les fichiers du runtime actuellement installés comprennent :

```text
Bootstrap.ps1
Network.ps1
UI.ps1
PostInstall.ps1
State.ps1
```

Les opérations d'injection sont couvertes par les tests du sous-système
PostInstall et par les tests d'intégration du pipeline.

---

## Validation automatisée

Le sous-système PostInstall dispose actuellement de tests dédiés pour :

```text
State
Network
PostInstall
Bootstrap
FirstBoot
Unattend
Installer
UI
```

Le BuildPipeline possède également des tests d'intégration couvrant :

```text
PreparePostInstall
```

La campagne officielle utilise :

```text
Tests\Unit
Tests\Integration
```

Les tests historiques sont conservés séparément dans :

```text
Tests\Legacy
```

Ils ne font pas partie de la campagne officielle.

---

## Validation PostInstall détaillée

Les sous-suites PostInstall actuellement validées comprennent :

* State : 9/9 ;
* Network : 11/11 ;
* PostInstall : 10/10 ;
* Bootstrap : 6/6 ;
* FirstBoot : 14/14 ;
* Unattend : 16/16 ;
* Installer : 14/14 ;
* UI : 5/5 ;
* BuildPipeline : 17/17.

La validation automatisée couvre également l'intégration du PostInstall
dans le pipeline.

Ces validations sont complétées par une validation réelle dans un WIM
temporaire.

Les éléments suivants ont notamment été vérifiés :

* injection réelle du runtime dans un WIM Windows 11 Professionnel ;
* présence réelle de `unattend.xml` ;
* namespace `urn:schemas-microsoft-com:unattend` ;
* présence de `wcm:action="add"` ;
* commande réelle vers
  `C:\ProgramData\PimsOS\PostInstall\Bootstrap.ps1`.

---

## Validation réseau

La suite `Network.Tests.ps1` contient actuellement 11 tests.

Elle couvre :

* la disponibilité du réseau ;
* l'absence de réseau ;
* le repli vers `Get-NetAdapter` ;
* l'échec des deux méthodes de détection ;
* la disponibilité d'Internet ;
* l'absence de réseau avant le test Internet ;
* l'échec de `Test-Connection` ;
* le retour immédiat lorsque le réseau est disponible ;
* l'attente jusqu'à disponibilité ;
* l'expiration du délai ;
* la correction d'un intervalle inférieur à une seconde.

La suite `UI.Tests.ps1` contient actuellement 5 tests.

Elle couvre :

* l'affichage et le retour positif lorsque le réseau et Internet sont
  disponibles ;
* le retour négatif lorsque le réseau est indisponible ;
* le retour négatif lorsque le réseau local est disponible mais
  qu'Internet est indisponible ;
* l'exécution sans erreur de l'aide réseau ;
* le retour immédiat de l'attente UI lorsque le réseau est disponible.

Les attentes temporelles sont simulées pendant les tests.

La suite s'exécute ainsi sans attendre réellement une minute lors du test
d'expiration.

---

## Non validé

Les éléments suivants restent à valider :

* exécution réelle de `FirstLogonCommands` lors de la première connexion ;
* reprise complète après perte puis disponibilité du réseau ;
* intégration finale de Chocolatey ;
* intégration finale de Winget ;
* intégration Microsoft Store.

La validation de l'injection dans un WIM et de la génération de
`unattend.xml` ne constitue donc pas encore une validation complète
du comportement réel lors du premier démarrage de Windows.

---

## Packages

Le PostInstall orchestre les opérations.

Il ne doit pas implémenter directement le fonctionnement interne
des providers de paquets.

`PackageManager` reste la couche d'abstraction pour :

```text
Chocolatey
Winget
Microsoft Store
```

ainsi que pour les futurs providers.

L'intégration finale de ces providers reste à compléter.

---

## Principe d'architecture

Le PostInstall est responsable de l'orchestration des opérations
exécutées après l'installation de Windows.

Les responsabilités sont séparées :

```text
PostInstall
    ↓
orchestration
    ↓
PackageManager
    ↓
providers de paquets
```

Cette séparation permet de conserver un runtime PostInstall indépendant
des implémentations spécifiques des gestionnaires de paquets.

---

## Tests destructifs sur WIM

Les tests nécessitant la modification d'un WIM doivent utiliser un
montage temporaire.

Lorsque le résultat du test ne doit pas être conservé, le démontage
doit utiliser :

```text
-Discard
```

L'objectif est d'éviter qu'un test ne modifie une image de travail
utilisée par le développement.

---

## État actuel

Le sous-système PostInstall est **implémenté et fortement testé**.

La préparation du runtime dans le WIM, la génération de
`unattend.xml`, le Bootstrap, la gestion de l'état, la détection réseau,
l'interface réseau du premier démarrage, la préparation FirstBoot et
l'intégration au BuildPipeline sont couvertes par les tests actuels.

La chaîne `FirstLogonCommands → Bootstrap → Network → DriverCheck → Chocolatey → Finalize` est validée en VM. La reprise après perte puis disponibilité du réseau reste un scénario de validation dédié à compléter, distinct de la validation d’un démarrage avec réseau disponible.

---
