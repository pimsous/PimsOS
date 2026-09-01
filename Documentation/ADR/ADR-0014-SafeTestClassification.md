# ADR-0014 — Classification et sécurité des tests PimsOS

- **Statut :** Accepté
- **Date :** 2026-09-01
- **Décision :** classification explicite des tests selon leur capacité à déclencher un Build réel

---

## Contexte

PimsOS possède des tests unitaires et des tests d'intégration qui peuvent référencer des opérations sensibles du Builder.

Certaines opérations peuvent modifier, monter, démonter ou générer des ressources réelles :

- `Initialize-PimsOS`
- `Invoke-BuildPipeline`
- `Complete-Build`
- `Mount-Wim`
- `Mount-WindowsImage`
- `Dismount-Wim`
- `oscdimg`

Une simple recherche textuelle ne permet pas toujours de déterminer si un appel est réellement neutralisé par Pester, TestDrive, un faux outil ou un mode DryRun.

Il est donc nécessaire de distinguer la sécurité d'exécution des tests de leur nature fonctionnelle.

---

## Décision

Le diagnostic PimsOS classe chaque fichier de test dans trois catégories.

### SAFE

Un test est `SAFE` lorsque le diagnostic ne détecte aucun appel Build réel non neutralisé.

Il peut être exécuté dans les campagnes Unit et Integration normales.

`SAFE` signifie que le scanner possède suffisamment de preuves pour considérer les opérations dangereuses comme neutralisées ou absentes.

### BUILD-CAPABLE

Un test est `BUILD-CAPABLE` lorsqu'il contient un appel qui peut réellement déclencher une opération Build.

Exemples :

- un test d'intégration appelant réellement `Initialize-PimsOS` ;
- un test appelant réellement `Invoke-BuildPipeline`.

Cette classification ne signifie pas que le test est mauvais.

Elle signifie que son exécution doit être explicitement contrôlée.

Les tests `BUILD-CAPABLE` ne sont sélectionnés que par le mode :

```powershell
-BuildValidation -AllowBuild
```

### UNKNOWN

Un test est `UNKNOWN` lorsque le diagnostic détecte une opération potentiellement dangereuse mais ne dispose pas de preuves suffisantes pour établir sa neutralisation.

`UNKNOWN` est donc une catégorie de sécurité conservatrice.

Un test `UNKNOWN` est bloqué par défaut, y compris lors d'une BuildValidation.

Il doit être analysé et reclassé avant de pouvoir devenir exécutable.

---

## Règles d'exécution

| Mode | SAFE | BUILD-CAPABLE | UNKNOWN |
|---|---:|---:|---:|
| Unit | Oui | Non | Non |
| Integration | Oui | Non | Non |
| BuildValidation | Non | Oui | Non |

`-AllowBuild` autorise le mode BuildValidation, mais ne transforme pas automatiquement les tests `UNKNOWN` en tests exécutables.

---

## Principe de sécurité

Le diagnostic doit préférer une classification trop prudente à une classification trop permissive.

En cas de doute :

```text
UNKNOWN
```

plutôt que :

```text
SAFE
```

Cela protège contre l'exécution accidentelle d'un Build réel depuis une campagne de tests normale.

---

## Cas particulier : Initialize-PimsOS

`Initialize-PimsOS` constitue l'API publique du Builder et peut déclencher le pipeline réel.

Un test d'intégration qui l'appelle réellement est donc `BUILD-CAPABLE`.

Un Mock Pester explicite permettant de neutraliser l'appel peut toutefois maintenir le test dans une classification sûre lorsque le diagnostic peut l'établir.

Cette distinction évite de confondre :

- test de l'API ;
- test d'intégration réel ;
- exécution accidentelle du Build.

---

## Outil de diagnostic

La classification est produite par :

```text
Tests/Tools/Invoke-PimsOSDiagnostics.ps1
```

L'outil produit également des rapports Markdown et JSON permettant de conserver une trace de l'inventaire et des décisions de classification.

---

## Conséquences

### Positives

- réduit le risque de lancer un Build réel par erreur ;
- rend explicite le niveau de danger des tests ;
- permet de séparer les tests ordinaires des validations réelles ;
- fournit un inventaire reproductible ;
- facilite la reprise de session et le diagnostic.

### Contraintes

- un nouveau test utilisant une opération sensible peut apparaître `UNKNOWN` ou `BUILD-CAPABLE` ;
- il faut alors examiner le test plutôt que désactiver arbitrairement la protection ;
- les tests réellement intégratifs doivent rester identifiables comme tels.

---

## Alternatives rejetées

### Exécuter tous les tests sans distinction

Rejeté : un test d'intégration peut déclencher une opération Build réelle.

### Autoriser automatiquement les appels détectés

Rejeté : la détection seule ne constitue pas une preuve de sécurité.

### Classer tous les tests suspects comme SAFE

Rejeté : cela rendrait le garde-fou inutile.

---

## Références

- `Documentation/Testing.md`
- `Documentation/ChatGPT-Workflow.md`
- `Documentation/SessionChecklist.md`
- `Tests/Tools/Invoke-PimsOSDiagnostics.ps1`
