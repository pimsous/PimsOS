# Support

Merci d'utiliser **PimsOS Builder**.

Ce document explique comment obtenir de l'aide, signaler un problème ou proposer une amélioration du projet.

---

# Avant de demander de l'aide

Avant d'ouvrir une demande de support, consultez la documentation officielle :

- README.md
- Documentation/GettingStarted.md
- Documentation/DeveloperGuide.md
- Documentation/API.md
- Documentation/Architecture.md
- Documentation/ReleaseNotes.md

La réponse à votre question s'y trouve peut-être déjà.

---

# Signaler un bug

Lors du signalement d'un problème, merci de fournir les informations suivantes.

## Environnement

- Version de PimsOS Builder
- Version de Windows
- Édition Windows utilisée
- Build Windows (ex. 26100)
- Version de PowerShell
- Version de Git

---

## Configuration

Préciser si possible :

- le profil utilisé ;
- la version de Windows personnalisée ;
- le fichier `version.json` ;
- les éventuelles modifications apportées à `Config.json`.

---

## Description

Décrire précisément :

- le comportement observé ;
- le comportement attendu ;
- les étapes permettant de reproduire le problème.

---

## Journaux

Joindre si possible :

- le fichier de log généré dans `Logs/` ;
- les messages d'erreur PowerShell ;
- la pile d'appel (Stack Trace) ;
- les captures d'écran utiles.

Ces informations permettent généralement d'identifier rapidement l'origine du problème.

---

# Demande de fonctionnalité

Les propositions d'amélioration sont les bienvenues.

Merci de préciser :

- le besoin ;
- le contexte ;
- le comportement attendu ;
- les bénéfices apportés ;
- les éventuelles contraintes techniques.

---

# Documentation

Si vous détectez une erreur dans la documentation :

- indiquez le document concerné ;
- décrivez la correction souhaitée ;
- proposez une amélioration si nécessaire.

---

# Bonnes pratiques

Avant de demander de l'aide :

- vérifier que le problème est reproductible ;
- utiliser la dernière version du dépôt ;
- lancer le build avec PowerShell 7.6 ou supérieur ;
- consulter les Release Notes ;
- consulter le CHANGELOG.

---

# Support des versions

Le développement actif concerne actuellement :

- PimsOS Builder v0.4.x

Les versions antérieures peuvent ne plus recevoir de correctifs.

La première version stable sera publiée sous la version **1.0.0**.

---

# Sécurité

Pour signaler une vulnérabilité de sécurité, consulter :

- SECURITY.md

Merci de ne jamais publier publiquement une vulnérabilité avant qu'un correctif soit disponible.

---

# Contribution

Si vous souhaitez proposer une correction ou une amélioration, consultez :

- CONTRIBUTING.md

Toute contribution respectant l'architecture du projet est la bienvenue.

---

# Informations utiles

Lorsqu'un problème concerne le moteur de build, les informations suivantes sont particulièrement utiles :

- version de Windows ciblée ;
- édition Windows sélectionnée ;
- BuildContext utilisé ;
- BuildState au moment de l'erreur ;
- étape du Pipeline en cours ;
- Engine concerné (Registry, Service, Package, etc.).

Ces informations permettent de reproduire plus facilement le problème et d'accélérer son diagnostic.