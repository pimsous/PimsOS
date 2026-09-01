# PimsOS Diagnostics Tool v8

Outil de diagnostic statique et sécurisé des tests Pester de PimsOS. Il permet d'inventorier les tests avant exécution et de séparer les tests normaux des tests susceptibles de déclencher un Build réel.

## Objectif

Le diagnostic ne remplace pas Pester. Il constitue un **garde-fou avant Pester**.

Classes :

- `SAFE` : aucun appel Build dangereux non neutralisé détecté par l'analyse statique ;
- `BUILD-CAPABLE` : appel potentiellement réel à une opération Build/WIM/ISO/DISM ;
- `UNKNOWN` : preuve insuffisante de neutralisation.

L'analyse est volontairement conservatrice.

## Sécurité

- Le mode par défaut est `Unit`.
- `-InventoryOnly` n'exécute aucun test.
- `-Unit` et `-Integration` n'exécutent que les fichiers classés `SAFE`.
- Les fichiers `BUILD-CAPABLE` et `UNKNOWN` restent exclus des modes normaux.
- `-BuildValidation` ne sélectionne que les fichiers `BUILD-CAPABLE`.
- `-BuildValidation` exige explicitement `-AllowBuild`.
- Un Build réel n'est jamais déclenché par un inventaire.

## Commandes de référence

### Inventaire Unit sans exécution

```powershell
.\Tests\Tools\Invoke-PimsOSDiagnostics.ps1 -Unit -InventoryOnly -ExplainFailures
```

### Diagnostic Unit

```powershell
.\Tests\Tools\Invoke-PimsOSDiagnostics.ps1 -Unit -ExplainFailures
```

### Inventaire Integration sans exécution

```powershell
.\Tests\Tools\Invoke-PimsOSDiagnostics.ps1 -Integration -InventoryOnly -ExplainFailures
```

### Diagnostic Integration

```powershell
.\Tests\Tools\Invoke-PimsOSDiagnostics.ps1 -Integration -ExplainFailures
```

### Inventaire BuildValidation — autorisation explicite

```powershell
.\Tests\Tools\Invoke-PimsOSDiagnostics.ps1 -BuildValidation -AllowBuild -InventoryOnly -ExplainFailures
```

### Validation Build réelle

```powershell
.\Tests\Tools\Invoke-PimsOSDiagnostics.ps1 -BuildValidation -AllowBuild -ExplainFailures
```

**Attention : cette dernière commande peut sélectionner des tests capables d'exécuter des opérations WIM/ISO/Build.** Elle ne doit être utilisée qu'après décision volontaire.

## Règles de séance

Avant chaque nouvelle séance :

1. lire la note `Documentation\DocumentationSync-*.md` la plus récente ;
2. vérifier `git status` et les derniers commits ;
3. exécuter l'inventaire du mode souhaité ;
4. examiner les `BUILD-CAPABLE` et `UNKNOWN` avant toute exécution ;
5. ne jamais présenter une hypothèse comme un diagnostic.

## Rapports

Les rapports sont écrits dans :

```text
Tests\Reports\Diagnostics\
```

Ils comprennent des rapports Markdown et JSON horodatés. Le répertoire de rapports générés n'est pas une source de vérité du code.
