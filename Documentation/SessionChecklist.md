# PimsOS — Session Checklist

> Procédure obligatoire de début et de fin de séance.
>
> Objectif : reprendre le projet à partir de son état réel, sans reconstruire le contexte par hypothèse.

---

## 1. Début de séance — synchroniser le contexte

### 1.1 Vérifier Git

```powershell
Set-Location "C:\Projets\PimsOS"
git fetch origin
git status
git log -5 --oneline --decorate
```

Vérifier :
- branche courante ;
- synchronisation avec `origin/main` ;
- modifications locales ;
- nouveaux fichiers ;
- suppressions volontaires.

Ne jamais supposer que le dépôt local ou GitHub est à jour sans le vérifier.

### 1.2 Lire la documentation avant toute modification

Lire en priorité :

1. `CurrentSprint.md`
2. `PimsOS_Reprise_*.txt` le plus récent
3. `Documentation/ProjectStatus.md`
4. `Documentation/Architecture.md`
5. `Documentation/ArchitectureRules.md`
6. `Documentation/Testing.md`
7. `Documentation/ChatGPT-Workflow.md`
8. `Documentation/SessionChecklist.md`
9. `Documentation/Backlog.md`
10. `Documentation/Roadmap.md`

Puis consulter les documents spécialisés concernés par la tâche.

**Règle : la documentation décrit l'état connu ; le code du dépôt reste la source de vérité technique.**

Si une information est contradictoire, ne pas inventer de solution : vérifier le code, les tests, Git et les derniers résultats réels.

### 1.3 Vérifier les derniers tests connus

Identifier :
- dernier nombre de tests ;
- Passed / Failed / Skipped ;
- tests récemment ajoutés ou déplacés ;
- problèmes connus ;
- validations réelles déjà effectuées.

Les anciens résultats (`testResults.xml`, anciens rapports, logs historiques) ne doivent pas être présentés comme des résultats actuels sans nouvelle exécution.

---

## 2. Avant de modifier du code

1. Identifier le fichier réellement responsable.
2. Lire le code concerné avant de proposer une correction.
3. Rechercher les appels et dépendances.
4. Vérifier les tests associés.
5. Vérifier la documentation associée.
6. Déterminer si le changement est :
   - correction ;
   - évolution ;
   - documentation ;
   - nettoyage volontaire ;
   - changement architectural.

### Interdiction de spéculer

Ne pas modifier une partie fonctionnelle uniquement parce qu'un test manuel isolé semble incohérent.

Avant toute modification :
- reproduire ;
- localiser ;
- comparer avec le code actuel ;
- vérifier les logs ;
- vérifier le pipeline réel si nécessaire.

---

## 3. Tests PimsOS

Le diagnostic officiel est :

```powershell
.\Tests\Tools\Invoke-PimsOSDiagnostics.ps1
```

### Unit

```powershell
.\Tests\Tools\Invoke-PimsOSDiagnostics.ps1 `
    -Unit `
    -InventoryOnly `
    -ExplainFailures
```

Puis, lorsque l'inventaire est propre :

```powershell
.\Tests\Tools\Invoke-PimsOSDiagnostics.ps1 -Unit
```

### Integration

```powershell
.\Tests\Tools\Invoke-PimsOSDiagnostics.ps1 `
    -Integration `
    -InventoryOnly `
    -ExplainFailures
```

Le mode Integration normal ne sélectionne que les tests `SAFE`.

### BuildValidation

À utiliser uniquement lorsque l'exécution réelle du Build est explicitement voulue :

```powershell
.\Tests\Tools\Invoke-PimsOSDiagnostics.ps1 `
    -BuildValidation `
    -AllowBuild `
    -InventoryOnly `
    -ExplainFailures
```

`UNKNOWN` reste bloqué par défaut.

**Ne jamais combiner `-Unit`, `-Integration` et `-BuildValidation`.**

---

## 4. Classification de sécurité des tests

| Classe | Signification | Exécution par défaut |
|---|---|---|
| `SAFE` | Aucun appel Build réel non neutralisé détecté | Autorisée |
| `BUILD-CAPABLE` | Le test peut réellement déclencher une opération Build | Bloquée hors BuildValidation |
| `UNKNOWN` | Le diagnostic ne peut pas prouver la neutralisation | Toujours bloquée |

Un test `BUILD-CAPABLE` n'est pas forcément défectueux. Il signifie que son exécution doit être volontaire et contrôlée.

---

## 5. Avant un Build réel

Ne jamais lancer directement un Build complet après une modification importante.

Ordre recommandé :

1. Syntaxe PowerShell.
2. Diagnostic `-Unit -InventoryOnly`.
3. Tests Unit.
4. Diagnostic `-Integration -InventoryOnly`.
5. Tests Integration.
6. Diagnostic `-BuildValidation -AllowBuild -InventoryOnly`.
7. Vérification des prérequis.
8. Vérification de l'ISO source.
9. Vérification de `oscdimg`.
10. Vérification de DISM et de l'espace disque.
11. Vérification des montages WIM/ISO.
12. Build réel seulement après validation.

Le Build réel doit rester explicitement autorisé par l'utilisateur.

---

## 6. Après un Build ou une validation réelle

Consigner :
- résultat ;
- code retour ;
- durée ;
- ISO produite ;
- WIM utilisé ;
- étapes réussies/échouées ;
- logs ;
- tests exécutés ;
- validations Hyper-V éventuelles ;
- anomalies restantes.

Une annulation volontaire par l'utilisateur ne doit pas être présentée comme une panne du pipeline.

---

## 7. Fin de séance — passation

Mettre à jour la documentation pertinente et, lorsque nécessaire, créer/actualiser le fichier de reprise.

La passation doit contenir au minimum :

- objectif de la séance ;
- état précis atteint ;
- branche Git ;
- dernier commit ;
- modifications réalisées ;
- tests validés avec leurs résultats ;
- problèmes connus ;
- décisions prises ;
- prochaines étapes concrètes ;
- commandes utiles pour reprendre.

**Ne jamais laisser une prochaine session deviner où reprendre.**

---

## 8. Règle fondamentale

> **Pas de théorie avant lecture de la documentation, vérification du code et observation des résultats réels.**

Le workflow ChatGPT doit suivre cette procédure à chaque nouvelle séance.
