## Reprise de session et diagnostic

Avant toute nouvelle séance de travail, suivre **[`Documentation/SessionChecklist.md`](Documentation/SessionChecklist.md)**.

La procédure impose notamment :

1. vérifier l'état Git et la synchronisation avec `origin/main` ;
2. lire la documentation et le fichier de reprise avant d'émettre des hypothèses ;
3. vérifier les derniers résultats de tests ;
4. utiliser `Tests/Tools/Invoke-PimsOSDiagnostics.ps1` pour classifier les tests ;
5. ne lancer une validation de Build réelle qu'avec une autorisation explicite ;
6. mettre à jour la passation et la documentation en fin de séance.

Le diagnostic distingue trois niveaux :

- **SAFE** — exécution normale autorisée ;
- **BUILD-CAPABLE** — peut déclencher un Build réel, donc réservé à `BuildValidation` ;
- **UNKNOWN** — neutralisation insuffisamment prouvée, donc bloqué par défaut.

Voir également [`Documentation/ADR/ADR-0014-SafeTestClassification.md`](Documentation/ADR/ADR-0014-SafeTestClassification.md).
