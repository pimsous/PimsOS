# PostInstall PimsOS

## Objectif

Le sous-système PostInstall exécute les actions nécessaires après
l'installation de Windows.

Il est séparé du processus de Build afin de permettre :

- l'exécution de tâches locales sans réseau ;
- l'attente de la disponibilité réseau ;
- la reprise après connexion ;
- la persistance de l'état ;
- l'installation ultérieure des applications.

## Architecture

Le runtime PostInstall est installé dans :

C:\ProgramData\PimsOS\PostInstall\

avec :

- Bootstrap.ps1
- Network.ps1
- PostInstall.ps1
- State.ps1

Le mécanisme FirstBoot génère :

C:\Windows\Panther\unattend.xml

Le document utilise le passage `oobeSystem` et
`Microsoft-Windows-Shell-Setup\FirstLogonCommands`.

La commande générée lance :

C:\ProgramData\PimsOS\PostInstall\Bootstrap.ps1

## Pipeline Build

L'étape PostInstall est exécutée après l'application des drivers
et avant le montage de la ruche SOFTWARE :

MountWim
    ↓
ApplyDrivers
    ↓
PreparePostInstall
    ↓
MountSoftwareHive

## État

Les états prévus sont :

- Pending
- Running
- WaitingForNetwork
- Completed
- Failed

## Réseau

Le module Network fournit :

- `Test-PostInstallNetwork`
- `Test-PostInstallInternet`
- `Wait-PostInstallNetwork`

Le PostInstall doit pouvoir effectuer les tâches locales sans
dépendre immédiatement d'Internet.

Lorsque le réseau est indisponible, le moteur peut passer à
`WaitingForNetwork`.

## FirstBoot

`FirstBoot.ps1` construit la configuration des commandes
FirstLogon.

`Unattend.ps1` génère le document XML Windows.

`Installer.ps1` :

1. installe le runtime dans le WIM ;
2. crée `Windows\Panther\unattend.xml`.

## Validation

Validé :

- tests State : 9/9 ;
- tests Network : 11/11 ;
- tests PostInstall : 10/10 ;
- tests Bootstrap : 6/6 ;
- tests FirstBoot : 14/14 ;
- tests Unattend : 16/16 ;
- tests Installer : 14/14 ;
- tests BuildPipeline : 17/17 ;
- injection réelle du runtime dans un WIM Windows 11 Professionnel ;
- présence réelle de `unattend.xml` ;
- namespace `urn:schemas-microsoft-com:unattend` ;
- `wcm:action="add"` ;
- commande réelle vers
  `C:\ProgramData\PimsOS\PostInstall\Bootstrap.ps1`.

## Non validé

Les éléments suivants restent à tester :

- exécution réelle de `FirstLogonCommands` lors de la première connexion ;
- reprise complète après perte puis disponibilité du réseau ;
- intégration finale de Chocolatey ;
- intégration finale de Winget ;
- intégration Microsoft Store.

## Principe

Le PostInstall orchestre les opérations.
Il ne doit pas implémenter directement le fonctionnement interne
des providers de paquets.

PackageManager reste la couche d'abstraction pour Chocolatey,
Winget et les futurs providers.
