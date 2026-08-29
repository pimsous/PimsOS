# PimsOS Builder - ChatGPT Workflow

> Version technique : 3.0.0
>
> Statut : Référence de travail
>
> Dernière mise à jour : 2026-08-29

---

# Objectif

Nous développons le projet **PimsOS Builder**.

PimsOS Builder est un framework PowerShell permettant de construire et personnaliser des images Windows à partir de données de configuration et de composants spécialisés.

Le développement du projet constitue également un support d'apprentissage de PowerShell.

L'objectif est de construire un projet :

- propre ;
- stable ;
- maintenable ;
- documenté ;
- testable ;
- compréhensible ;
- reproductible.

Les explications sont importantes au même titre que le résultat technique.

---

# Principe de développement

Toujours privilégier :

```text
Documentation
    ↓
Architecture
    ↓
Développement
    ↓
Tests
    ↓
Validation
    ↓
Git
    ↓
GitHub
```

Ne pas inverser cet ordre sans raison justifiée.

---

# Compatibilité Windows

PimsOS Builder ne doit pas être limité à une seule version de Windows.

Le Builder doit pouvoir traiter les versions Windows compatibles avec les mécanismes techniques utilisés par le projet.

Toute nouvelle fonctionnalité doit donc :

- éviter les valeurs de version codées en dur lorsqu'elles sont configurables ;
- éviter les numéros de Build codés en dur lorsqu'ils doivent être découverts ;
- utiliser le BuildContext et les données de configuration ;
- respecter les contraintes de compatibilité des Tweaks ;
- préserver l'architecture générale du Builder.

---

# Début de chaque nouvelle session

Lorsque ce document est utilisé au début d'une nouvelle conversation :

1. Lire `Documentation/ProjectStatus.md`.
2. Lire `Documentation/Roadmap.md`.
3. Lire `Documentation/Backlog.md` si nécessaire.
4. Lire les ADR nécessaires à la tâche.
5. Respecter les Architecture Rules.
6. Vérifier le contexte réel du dépôt avant toute modification.
7. Vérifier l'état Git lorsque cela est possible.

Ne jamais commencer directement à modifier du code sans comprendre le contexte.

---

# Lecture obligatoire

Avant de proposer une modification ou un diagnostic :

- lire la documentation nécessaire au sujet traité ;
- vérifier les décisions d'architecture déjà actées ;
- identifier les contraintes déjà validées ;
- vérifier le code réel concerné ;
- vérifier les tests existants lorsque nécessaire ;
- ne jamais proposer une solution qui contredit une décision documentée sans le signaler explicitement.

---

# Reprise du contexte

Au début d'une séance de travail, fournir un résumé très court indiquant :

- où nous en sommes ;
- ce qui a été terminé ;
- ce qui reste à faire ;
- l'objectif de la séance.

Le résumé ne doit pas remplacer la vérification du contexte réel du projet.

---

# Architecture

L'architecture de PimsOS Builder 3.0.0 est considérée comme stabilisée.

Le framework repose notamment sur :

- un module PowerShell unique ;
- un BuildContext central ;
- un BuildState ;
- un Workflow ;
- un Pipeline ;
- un ActionRegistry ;
- un ActionEngine ;
- des Engines spécialisés ;
- des Managers ;
- des modules techniques.

Ne proposer une évolution de l'architecture que si :

- un problème réel apparaît ;
- plusieurs solutions sont étudiées lorsque cela est utile ;
- le bénéfice est démontré ;
- l'impact est compris ;
- la décision est documentée.

Toute modification architecturale importante doit :

1. être discutée ;
2. être justifiée ;
3. être validée ;
4. être documentée dans une ADR lorsque nécessaire ;
5. être implémentée après validation.

---

# PostInstall

Le PostInstall constitue désormais une partie intégrée du workflow de PimsOS Builder.

Le développement du PostInstall doit respecter la même méthode que le reste du projet :

```text
Architecture
    ↓
Composants
    ↓
Tests unitaires
    ↓
Tests d'intégration
    ↓
Validation
    ↓
Documentation
    ↓
Git
```

## État actuel

Les composants suivants sont implémentés :

- `State.ps1`
- `Network.ps1`
- `UI.ps1`
- `PostInstall.ps1`
- `Bootstrap.ps1`
- `FirstBoot.ps1`
- `Unattend.ps1`
- `Installer.ps1`

Le runtime PostInstall est préparé dans le WIM par le Build et installé dans :

```text
C:\ProgramData\PimsOS\PostInstall\
```

Le premier démarrage utilise `unattend.xml` pour lancer le Bootstrap.

## Gestion réseau

La vérification réseau distingue :

- la présence d'un adaptateur réseau ;
- la disponibilité du réseau local ;
- l'accès réel à Internet.

Lorsque le réseau ou Internet n'est pas disponible, le PostInstall peut entrer dans l'état `WaitingForNetwork` et attendre la disponibilité nécessaire avant de reprendre.

La couche UI fournit notamment :

```powershell
Show-PostInstallNetworkStatus
Show-PostInstallNetworkHelp
Wait-PostInstallNetworkUI
```

La logique métier du PostInstall doit rester séparée de l'interface utilisateur.

## Tests

Toute évolution du PostInstall doit être accompagnée des tests nécessaires.

Les validations actuellement utilisées comprennent :

- tests unitaires des composants PostInstall ;
- tests d'intégration du BuildPipeline ;
- tests d'intégration de l'API publique PimsOS ;
- analyse PSScriptAnalyzer.

Une modification du PostInstall n'est considérée comme stable qu'après validation des tests concernés et, lorsque l'impact le justifie, de la suite d'intégration.

## Documentation

Toute évolution importante du PostInstall doit synchroniser les documents concernés, notamment :

- `Architecture.md`
- `ArchitectureRules.md`
- `BuildContext.md`
- `Backlog.md`
- `ProjectStatus.md`
- `Testing.md`
- `ReleaseNotes.md` lorsque nécessaire.

# Documentation

La documentation constitue une référence du projet.

Les documents principaux comprennent notamment :

- `Architecture.md`
- `ArchitectureRules.md`
- `BuildContext.md`
- `CodingStandards.md`
- `DeveloperGuide.md`
- `ModuleGuide.md`
- `ProjectStatus.md`
- `ProjectStructure.md`
- `Roadmap.md`
- `Milestones.md`
- `ReleaseNotes.md`
- `Testing.md`
- `TechnicalDecisions.md`
- `API.md`

La documentation doit décrire le comportement réel du projet.

Avant de considérer une évolution comme terminée, vérifier :

- que les documents concernés sont à jour ;
- que les exemples correspondent au code ;
- que les anciennes informations obsolètes ont été supprimées.

---

# Gestion du projet

Avant de commencer un nouveau développement, identifier où le travail doit être suivi.

Utiliser :

- `Backlog.md` pour les idées et travaux futurs ;
- `Milestones.md` pour les jalons ;
- `Roadmap.md` pour les orientations à moyen et long terme ;
- `ProjectStatus.md` pour l'état actuel du projet.

Le Backlog ne doit pas être traité comme un engagement immédiat de développement.

---

# Synchronisation

Après une étape importante :

1. vérifier l'état des fichiers modifiés ;
2. vérifier les tests ;
3. mettre à jour la documentation ;
4. vérifier `git status` ;
5. créer un commit cohérent lorsque l'étape est stable ;
6. vérifier l'historique récent ;
7. pousser vers GitHub lorsque l'évolution est prête.

---

# Ma façon de travailler

Je suis débutant en PowerShell.

Toutes les explications doivent être adaptées à ce niveau.

Toujours expliquer :

- ce que nous faisons ;
- pourquoi nous le faisons ;
- ce que cela change ;
- ce que nous allons vérifier ;
- le résultat attendu.

Ne jamais supposer qu'un concept est déjà connu.

---

# Méthode de travail

Toujours travailler dans cet ordre :

1. Comprendre le problème.
2. Vérifier avec des preuves.
3. Identifier précisément la cause.
4. Proposer une seule correction à la fois.
5. Tester.
6. Analyser le résultat.
7. Continuer uniquement lorsque le résultat est validé.

Ne pas effectuer plusieurs modifications importantes simultanément.

La priorité est la stabilité et la limitation des régressions.

---

# Choix des solutions

Lorsqu'il existe plusieurs solutions, privilégier :

- la plus simple ;
- la moins risquée ;
- la plus facile à maintenir ;
- la plus cohérente avec l'architecture existante.

Une solution plus complexe doit être proposée seulement lorsqu'elle apporte un bénéfice démontrable.

Lorsqu'un choix important est proposé, expliquer :

- pourquoi il est retenu ;
- ses avantages ;
- ses inconvénients ;
- les raisons pour lesquelles les autres solutions ne sont pas retenues.

---

# Justification des décisions

Les propositions importantes doivent être justifiées par des arguments techniques vérifiables.

Privilégier :

- réduction de la complexité ;
- amélioration de la maintenabilité ;
- meilleure testabilité ;
- compatibilité ;
- performances ;
- réduction des risques ;
- cohérence avec l'architecture existante.

Éviter les justifications purement stylistiques.

---

# Vérifications

Ne jamais supposer lorsqu'une vérification est possible.

Toujours privilégier les preuves issues du dépôt et de l'environnement.

Commandes utiles :

```powershell
Get-Command
Get-Content
Select-String
Import-Module
Invoke-Pester
git status
git log --oneline -5
```

Toujours expliquer brièvement ce que chaque commande permet de vérifier.

---

# Qualité

Avant de terminer une fonctionnalité, vérifier :

- PSScriptAnalyzer lorsqu'il est disponible dans le workflow ;
- Pester ;
- `git status` ;
- la documentation ;
- `ReleaseNotes.md` lorsque le changement le justifie ;
- `TechnicalDecisions.md` lorsque la décision doit être conservée.

Une fonctionnalité n'est considérée comme terminée que lorsque les éléments nécessaires sont cohérents.

---

# Modules PowerShell

En cas de comportement inattendu :

1. vérifier le contenu réel du fichier ;
2. vérifier les fonctions réellement chargées ;
3. vérifier les doublons éventuels ;
4. vérifier les exports du module ;
5. vérifier l'ordre de chargement dans `PimsOS.psm1`.

Ne jamais conclure avant d'avoir comparé le fichier source et le module chargé.

Rappel : dans un même scope, une définition ultérieure peut remplacer une définition précédente.

---

# Objets métier

Les objets métier utilisent les constructeurs officiels du projet lorsqu'ils existent.

Exemples :

- `New-BuildContext`
- `New-BuildState`
- `New-Tweak`
- `New-Action`
- `New-ConfigurationItem`

Ne pas construire directement un `PSCustomObject` lorsqu'un constructeur officiel existe déjà.

Les constructeurs constituent les contrats de création des objets concernés.

---

# Recovery

Le projet PimsOS dispose d'un mécanisme de reprise de Build.

Avant de créer un nouveau montage DISM, vérifier si les ressources d'un Build précédent doivent être traitées par Recovery.

La validation de l'état d'un montage WIM est centralisée dans :

```powershell
Test-WimMountState()
```

Cette décision ne doit pas être dupliquée dans le Pipeline ou le Workflow.

Lorsqu'un état invalide est détecté, le Recovery doit :

- traiter les ressources concernées ;
- démonter ce qui doit l'être ;
- nettoyer l'environnement ;
- permettre de repartir sur une base cohérente.

---

# BuildContext

Le BuildContext constitue le contrat central du Build.

Avant de proposer une modification :

1. identifier la propriété concernée ;
2. vérifier si elle existe déjà ;
3. ne pas créer une nouvelle propriété lorsqu'une propriété équivalente existe déjà ;
4. vérifier si l'information doit réellement être partagée.

Toute donnée d'état du Build qui doit être partagée entre plusieurs composants doit être intégrée au contrat approprié du BuildContext ou du BuildState.

---

# BuildState

Le BuildState représente l'état courant de l'exécution.

Lorsqu'une nouvelle fonctionnalité modifie l'état du Build :

- utiliser le BuildState ;
- ne pas créer des indicateurs dispersés dans plusieurs objets ;
- conserver une convention d'état cohérente.

Les changements d'état doivent rester centralisés et compréhensibles.

---

# Configuration

Les Tweaks constituent les définitions des personnalisations.

Ils ne doivent pas être modifiés lors de la fusion d'un profil.

Les profils permettent de sélectionner les personnalisations.

Le moteur construit ensuite une configuration destinée à l'exécution.

Les définitions sources doivent rester intactes.

---

# Débogage

Toujours commencer par observer.

Ne jamais proposer une correction avant d'avoir identifié précisément la cause.

Toujours expliquer :

- ce qui est recherché ;
- pourquoi ;
- comment interpréter le résultat.

---

# Analyse

Toujours analyser, lorsque disponible :

- les sorties PowerShell ;
- les erreurs ;
- les logs ;
- les résultats Pester ;
- l'état Git ;
- le contenu réel des fichiers concernés.

Une conclusion doit reposer sur une preuve.

Si une information manque, demander ou effectuer la vérification nécessaire.

Ne jamais présenter une hypothèse comme une conclusion.

---

# Refactoring

Ne proposer un refactoring que s'il apporte un bénéfice réel.

Par exemple :

- suppression d'une duplication ;
- simplification importante ;
- correction d'un défaut ;
- amélioration de la maintenabilité ;
- amélioration de la testabilité.

Ne pas refactorer uniquement pour modifier le style d'un code qui fonctionne correctement.

---

# Nouvelles technologies

Avant de proposer :

- une nouvelle bibliothèque ;
- une nouvelle dépendance ;
- un nouveau framework ;
- une nouvelle architecture ;

vérifier si le besoin peut être couvert par les composants déjà présents dans le projet.

Toute nouvelle dépendance doit être justifiée.

---

# Modifications du code

Toujours fournir :

- le fichier concerné ;
- l'emplacement exact de la modification ;
- le bloc complet à remplacer lorsque cela est nécessaire ;
- une explication adaptée au niveau de compréhension ;
- les commandes permettant de vérifier le résultat.

La modification doit être réalisable avec un copier/coller fiable lorsque le contexte s'y prête.

---

# Vérification d'architecture

Avant chaque proposition de modification :

1. identifier le composant concerné ;
2. vérifier que la modification respecte l'architecture actuelle ;
3. vérifier qu'elle ne contredit pas une décision documentée ;
4. en cas de contradiction, signaler la décision concernée avant toute modification ;
5. vérifier si une logique similaire existe déjà ;
6. centraliser les décisions importantes dans une fonction ou un composant responsable.

Exemple :

```text
validation d'un montage DISM
        ↓
Test-WimMountState()
```

Le Pipeline doit principalement orchestrer les étapes et ne pas dupliquer les décisions centralisées.

---

# Tests

Après chaque modification :

- lancer d'abord les tests directement concernés ;
- analyser leur résultat ;
- lancer une validation plus large lorsque l'impact le justifie.

Toujours expliquer ce que les tests permettent de vérifier.

Une correction de bug doit être accompagnée d'un test de régression lorsque cela est pertinent.

---

# Qualité du dépôt

Chaque modification doit laisser le projet dans un état au moins aussi propre qu'avant.

Éviter :

- le code mort ;
- les TODO oubliés ;
- les fonctions inutilisées ;
- les duplications ;
- les avertissements ignorés ;
- la documentation obsolète.

---

# GitHub

Lorsque le projet évolue significativement, vérifier également :

- `README.md` ;
- `CHANGELOG.md` ;
- `ReleaseNotes.md` ;
- GitHub Issues ;
- GitHub Actions.

Toute nouvelle fonctionnalité importante doit rester compatible avec le mode de publication du projet.

---

# Git

Git constitue le filet de sécurité du projet.

Chaque étape importante doit pouvoir être retrouvée facilement dans l'historique.

## Commits

Avant une modification importante, créer si nécessaire un commit de sécurité.

Après chaque étape stable, créer un commit cohérent.

Un commit doit représenter une seule évolution logique du projet.

Éviter les commits mélangeant plusieurs sujets.

---

## Convention des messages

Utiliser les préfixes suivants :

| Préfixe | Utilisation |
|----------|-------------|
| feat | Nouvelle fonctionnalité |
| fix | Correction d'un bug |
| refactor | Refactoring sans modification du comportement |
| test | Ajout ou modification de tests |
| docs | Documentation |
| build | Scripts de Build et Pipeline |
| chore | Maintenance et nettoyage |

Exemples :

```text
feat: ajout d'un nouvel Engine
fix: correction du routage d'une Action
refactor: simplification d'un Manager
test: ajout des tests du PackageManager
docs: mise à jour de l'architecture
build: évolution du script de Build
chore: nettoyage du dépôt
```

Les messages de type :

```text
update
test
correction
modif
divers
```

doivent être évités.

Chaque commit doit rester compréhensible plusieurs mois plus tard.

---

## Vérifications Git

Avant un commit important :

```powershell
git status
```

Cette commande permet de vérifier les fichiers modifiés, ajoutés ou supprimés.

Après le commit :

```powershell
git log --oneline -5
```

Cette commande permet de vérifier l'historique récent.

---

# Documentation du projet

Lorsqu'une décision technique importante est prise, vérifier si elle doit être ajoutée à :

```text
Documentation\TechnicalDecisions.md
```

Lorsqu'une fonctionnalité importante est terminée, mettre à jour si nécessaire :

```text
Documentation\ProjectStatus.md
```

Si la planification évolue, mettre à jour :

```text
Documentation\Roadmap.md
Documentation\Backlog.md
Documentation\Milestones.md
```

Lorsqu'une décision modifie l'architecture, créer ou mettre à jour une ADR.

---

# Fin d'une fonctionnalité

Lorsqu'une fonctionnalité est terminée :

- vérifier les tests ;
- nettoyer le code ;
- supprimer les commentaires temporaires ;
- mettre à jour la documentation nécessaire ;
- vérifier les fichiers modifiés ;
- proposer ou effectuer un commit Git cohérent.

---

# Explications

À chaque réponse technique :

Toujours expliquer :

- ce que nous faisons ;
- pourquoi ;
- ce que nous allons vérifier ;
- le résultat attendu.

Adapter le niveau d'explication à un débutant.

---

# Si une information manque

Ne jamais deviner.

Dire clairement lorsqu'une information manque.

Effectuer ou demander les vérifications nécessaires.

Une hypothèse n'est jamais une conclusion.

Une conclusion doit être appuyée par une preuve observable.

---

# Fin de séance

Lorsque la séance se termine, vérifier :

- les tests sont au vert ;
- `git status` est compris ;
- un commit est effectué si une étape stable est terminée ;
- l'historique récent est vérifié ;
- `ProjectStatus.md` est mis à jour si nécessaire ;
- `TechnicalDecisions.md` est mis à jour si nécessaire ;
- `Roadmap.md` et `Backlog.md` sont mis à jour si nécessaire ;
- une ADR est créée si l'architecture a changé ;
- les documents concernés sont synchronisés ;
- les changements importants sont sauvegardés.

---

# Clôture obligatoire

Avant de considérer une session comme terminée, vérifier que :

- la documentation technique est à jour ;
- les décisions d'architecture prises pendant la session sont documentées ;
- les changements de workflow importants sont documentés ;
- les TODO et la roadmap sont mis à jour si nécessaire ;
- les fichiers documentaires concernés sont synchronisés avec le code.

---

# Philosophie

Nous privilégions toujours :

- la compréhension avant la rapidité ;
- les preuves avant les suppositions ;
- les petites corrections avant les grandes réécritures ;
- la stabilité avant les nouvelles fonctionnalités ;
- le développement avant les refontes inutiles.

Chaque étape doit laisser le projet dans un meilleur état qu'avant.

---

# Objectif final

L'objectif n'est pas uniquement de produire un logiciel fonctionnel.

Le projet doit également permettre de :

- comprendre PowerShell ;
- comprendre l'architecture ;
- appliquer de bonnes pratiques de développement ;
- construire un projet professionnel ;
- limiter les régressions ;
- documenter correctement le projet ;
- améliorer progressivement les compétences de développement.

Le développement de PimsOS doit rester méthodique, reproductible, durable et agréable à maintenir.

