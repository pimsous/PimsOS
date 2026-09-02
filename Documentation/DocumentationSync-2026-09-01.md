# PimsOS Builder — Synchronisation documentaire du 01/09/2026

## Objet

Cette note fixe l’état de référence du projet après la reprise du 01/09/2026. Elle complète la note historique du 31/08 et ne réécrit pas les faits historiques.

## Source de vérité

L’ordre de priorité est désormais explicite :

1. **Code réellement présent dans le dépôt** pour le comportement technique.
2. **Tests réellement exécutés et résultats observables** pour la validation.
3. **Documentation active** pour expliquer l’état et la méthode de travail.
4. **ADR et notes historiques** pour conserver les décisions et les états passés.

Une documentation ancienne ne doit jamais être utilisée pour conclure qu'un comportement existe encore sans vérifier le code et les tests.

## État technique vérifié

- Version technique : **3.0.0**.
- PowerShell local : **7.6.5**.
- Pester local : **5.8.0**.
- Le pipeline réel complet a été exécuté avec succès le **01/09/2026**.
- Edition construite : **Windows 11 Professionnel, index 6**.
- 27 Tweaks ont été appliqués dans le Build réel.
- Le PostInstall a été préparé puis validé dans le WIM.
- Le WIM a été démonté et sauvegardé sans montage résiduel.
- La synchronisation `Workspace\Sources\install.wim` → `Workspace\ISO\Source\sources\install.wim` a été effectuée avec vérification SHA256.
- `oscdimg.exe` a été découvert automatiquement par `Get-PimsOSOsCdImgPath` depuis le Windows ADK installé ; aucune modification du pipeline n'a été nécessaire pour ce point.
- ISO produite : `Output\PimsOS_3.0.0_20260901_180342.iso`.
- Taille annoncée : **7,9 Go**.
- Code retour du Build réel : **0**.
- Etat final : **Completed**.
- Aucun montage WIM restant après le Build.

## Validation des tests du 01/09

Le diagnostic statique du dépôt a été utilisé avant exécution :

- Unit : **63 fichiers de tests** inventoriés.
- Integration : **4 fichiers de tests** inventoriés.
- Build-capable : **3 fichiers** classés comme potentiellement capables de lancer une opération de Build.
- Unknown : **0** après correction du test `Complete-Build`.

Une campagne d'intégration ciblée a ensuite produit :

```text
20 Passed
0 Failed
0 Skipped
```

Ce résultat concerne la campagne exécutée et ne doit pas être confondu avec le nombre de fichiers inventoriés.

La dernière campagne complète communiquée avant cette reprise reste celle du 31/08 : **971 Passed / 0 Failed / 1 Skipped**. Elle doit être considérée comme historique tant qu'une nouvelle campagne complète n'a pas été exécutée et enregistrée.

## Diagnostic sécurisé

Le nouvel outil `Tests\Tools\Invoke-PimsOSDiagnostics.ps1` est désormais la première étape de la méthode de validation.

Il distingue :

- `SAFE` : aucun appel Build dangereux non neutralisé détecté par l'analyse statique ;
- `BUILD-CAPABLE` : présence d'un appel pouvant lancer une opération réelle ;
- `UNKNOWN` : preuve insuffisante de neutralisation.

Règles :

- `-InventoryOnly` n'exécute aucun test ;
- `-Unit` et `-Integration` n'exécutent que les tests `SAFE` ;
- `-BuildValidation` exige explicitement `-AllowBuild` ;
- les tests `UNKNOWN` restent bloqués automatiquement ;
- un Build réel n'est jamais une conséquence implicite d'un diagnostic normal.

## CI GitHub

La connexion GitHub/ChatGPT a entraîné une succession de commits rapides et donc une accumulation de runs PimsOS CI.

Le workflow `.github/workflows/pester.yml` a été durci le 01/09/2026 :

- ajout d'un groupe `concurrency` par workflow/ref ;
- `cancel-in-progress: true` pour conserver le run le plus récent ;
- ajout de filtres `paths` afin que les modifications purement documentaires ne déclenchent pas inutilement la CI.

Le but est de permettre les synchronisations rapides sans empiler des dizaines de runs identiques.

## Synchronisation dépôt local / GitHub

Le contrôle du 01/09 a montré que le principe « local = GitHub » ne doit pas être supposé :

- le dépôt GitHub contenait la note historique `Documentation/DocumentationSync-2026-08-31.md` qui n'était pas dans l'archive fournie ;
- l'outil `Tests\Tools\Invoke-PimsOSDiagnostics.ps1` présent dans l'archive locale n'était pas encore présent dans `main` sur GitHub au moment du contrôle ;
- le workflow CI a depuis été mis à jour directement dans GitHub.

Cette divergence est précisément la raison pour laquelle le contrôle Git/GitHub doit précéder toute nouvelle séance.

## Validation ISO restante

Le Build réel est maintenant démontré. La prochaine validation est celle de l'artefact :

1. vérifier le SHA256 de l'ISO produite ;
2. monter/tester l'ISO produite sans modifier le pipeline ;
3. vérifier `sources\install.wim` ;
4. vérifier l'image Windows et les modifications attendues ;
5. réaliser une installation Hyper-V ;
6. valider FirstBoot/PostInstall ;
7. valider ensuite Rufus/physique si nécessaire.

## Règle de continuité

Aucune nouvelle modification du pipeline ne doit être proposée simplement parce qu'un test manuel a été exécuté dans un contexte différent du Build réel.

Exemple validé le 01/09 : après éjection de l'ISO, `I:` n'existait plus ; appeler manuellement la fonction de copie avec `I:` absent produisait logiquement une erreur. Le Build réel, lui, montait l'ISO sur `I:` puis copiait correctement son contenu. Le comportement réel du pipeline a donc été confirmé sans modification.
