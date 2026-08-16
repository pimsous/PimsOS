# PimsOS Builder - Support

Merci d'utiliser **PimsOS Builder**.

Ce document explique comment obtenir de l'aide, signaler un problème ou proposer une amélioration du projet.

---

# Avant de demander de l'aide

Avant d'ouvrir une demande de support, consultez notamment :

- `README.md`
- `Documentation/GettingStarted.md`
- `Documentation/DeveloperGuide.md`
- `Documentation/API.md`
- `Documentation/Architecture.md`
- `Documentation/ProjectStatus.md`
- `Documentation/Testing.md`
- `Documentation/ReleaseNotes.md`
- `CHANGELOG.md`

La réponse à votre question s'y trouve peut-être déjà.

---

# Signaler un bug

Lors du signalement d'un problème, merci de fournir les informations suivantes.

## Environnement

- version technique de PimsOS Builder ;
- version et Build de Windows ;
- édition Windows utilisée ;
- version de PowerShell ;
- version de Git lorsque pertinente.

L'environnement de référence actuel du développement est :

```text
PimsOS Builder 3.0.0
Windows 11 25H2
Build 26100
PowerShell 7.6.x
```

---

## Configuration

Préciser si possible :

- le profil utilisé ;
- l'image Windows sélectionnée ;
- l'édition sélectionnée ;
- les fichiers de configuration concernés ;
- les éventuelles modifications locales.

Lorsque cela est utile, joindre les informations pertinentes de :

```text
version.json
```

Ne pas joindre de secrets, mots de passe, jetons ou autres données sensibles.

---

# Description

Décrire précisément :

- le comportement observé ;
- le comportement attendu ;
- les étapes permettant de reproduire le problème ;
- l'étape du Pipeline pendant laquelle le problème apparaît ;
- l'Engine ou le Manager concerné lorsque cela est connu.

---

# Journaux et diagnostics

Joindre si possible :

- le fichier de log généré dans `Logs/` ;
- les messages d'erreur PowerShell ;
- la stack trace lorsqu'elle est disponible ;
- les résultats des tests Pester concernés ;
- les captures d'écran utiles.

Lorsque le problème concerne l'état du Build, les éléments suivants peuvent également être utiles :

- `BuildContext` ;
- `BuildState` ;
- statistiques ;
- étape actuelle du Pipeline.

Ne pas publier d'informations sensibles présentes dans les logs.

---

# Vérifications utiles

Avant d'ouvrir une demande, vérifier notamment :

```powershell
$PSVersionTable.PSVersion
git --version
dism /?
```

Puis, lorsque cela est pertinent :

```powershell
Get-Module Pester -ListAvailable
Invoke-Pester -Path .\Tests\Unit
Invoke-Pester -Path .\Tests\Integration
git status
```

Ces commandes permettent de confirmer l'environnement et de déterminer si le problème est reproductible.

---

# Demande de fonctionnalité

Les propositions d'amélioration sont les bienvenues.

Merci de préciser :

- le besoin ;
- le contexte ;
- le comportement attendu ;
- les bénéfices apportés ;
- les éventuelles contraintes techniques ;
- l'impact éventuel sur l'architecture.

Une demande qui modifie l'architecture peut nécessiter une analyse et une ADR.

---

# Documentation

Si vous détectez une erreur dans la documentation :

- indiquez le document concerné ;
- décrivez précisément l'information incorrecte ;
- indiquez le comportement réel ;
- proposez la correction lorsque possible.

Les documents d'architecture doivent rester cohérents avec le code réel.

---

# Bonnes pratiques

Avant de demander de l'aide :

- vérifier que le problème est reproductible ;
- vérifier l'état actuel du dépôt ;
- consulter la documentation ;
- consulter les Release Notes ;
- consulter le CHANGELOG ;
- vérifier les tests concernés ;
- préciser les modifications locales qui pourraient influencer le résultat.

---

# Support des versions

Le développement actif concerne actuellement :

```text
PimsOS Builder 3.0.x
```

La version technique actuelle est :

```text
3.0.0
```

Le projet n'est pas encore une release finale stable du produit.

Les versions historiques ou obsolètes peuvent ne plus recevoir de correctifs.

Le calendrier de support dépend de l'état réel du projet et des releases publiées.

---

# Sécurité

Pour signaler une vulnérabilité de sécurité, consulter :

```text
SECURITY.md
```

Ne publiez pas publiquement les détails d'une vulnérabilité sensible avant qu'un traitement approprié ait été réalisé.

---

# Contribution

Si vous souhaitez proposer une correction ou une amélioration, consultez :

```text
CONTRIBUTING.md
```

Toute contribution doit respecter :

- l'architecture ;
- les conventions de développement ;
- les tests ;
- la documentation ;
- les contrats du BuildContext et du BuildState.

---

# Informations particulièrement utiles pour le moteur de Build

Lorsqu'un problème concerne le moteur de Build, les informations suivantes sont particulièrement utiles :

```text
Version PimsOS
Version / Build Windows
Édition sélectionnée
Profil utilisé
Étape du Pipeline
BuildState
BuildContext
Engine concerné
Manager concerné
Provider concerné
Erreur complète
Logs
Tests Pester concernés
```

Pour un problème d'Action, préciser lorsque c'est possible :

```text
Action
Provider
Engine
Manager
Paramètres pertinents
```

Ces informations permettent de reproduire plus facilement le problème et d'accélérer son diagnostic.

---

# Références

Consulter également :

- `README.md`
- `CONTRIBUTING.md`
- `SECURITY.md`
- `Documentation/GettingStarted.md`
- `Documentation/DeveloperGuide.md`
- `Documentation/Architecture.md`
- `Documentation/Testing.md`
- `Documentation/ReleaseNotes.md`
