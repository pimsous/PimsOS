# ADR-0008 — Gestion centralisée des erreurs et des exceptions

- **Statut** : Acceptée
- **Date** : 2026-07-19
- **Dernière mise à jour** : 2026-08-16
- **Décideur** : Pims
- **Impact** : Ensemble du framework

---

# Contexte

Les composants PimsOS réalisent des opérations critiques, notamment :

- lecture et validation de la configuration ;
- préparation et montage des images WIM ;
- opérations sur le registre ;
- traitement des packages ;
- intégration des pilotes ;
- exécution des Actions ;
- génération des rapports ;
- nettoyage et finalisation du Build.

Chaque opération peut produire une erreur.

Sans stratégie commune, les composants pourraient gérer ces erreurs de manière différente, ce qui compliquerait :

- le diagnostic ;
- les tests ;
- le Pipeline ;
- le Recovery ;
- la maintenance ;
- la compréhension de l'état final du Build.

---

# Décision

La gestion des erreurs suit une stratégie commune à l'ensemble du framework.

Chaque composant est responsable de :

- détecter les erreurs relevant de son domaine ;
- produire une erreur explicite et contextualisée ;
- journaliser l'événement lorsque cela est pertinent ;
- propager l'erreur lorsqu'il ne peut pas la traiter localement.

Le niveau d'orchestration supérieur est responsable de décider de la suite du processus lorsque plusieurs comportements sont possibles.

Le composant qui détecte l'erreur ne doit pas masquer silencieusement le problème.

---

# Principes

Les composants spécialisés ne doivent pas prendre arbitrairement la décision de modifier le déroulement global du Build.

Ils signalent le problème et fournissent le contexte nécessaire.

Le traitement global peut alors déterminer :

- la poursuite du Build lorsque l'erreur est réellement récupérable ;
- la récupération lorsqu'un composant spécialisé en est responsable ;
- l'arrêt du Build lorsqu'une erreur critique empêche de continuer.

Le Pipeline ne doit pas réimplémenter les règles techniques propres aux composants spécialisés.

---

# Types d'erreurs

Les erreurs peuvent notamment être regroupées dans les catégories suivantes.

## Configuration

Exemples :

- fichier absent ;
- JSON invalide ;
- propriété obligatoire manquante ;
- définition incohérente ;
- Action invalide.

---

## Environnement

Exemples :

- version de PowerShell incompatible ;
- DISM indisponible ;
- privilèges insuffisants ;
- espace disque insuffisant ;
- ressource nécessaire indisponible.

---

## Exécution

Exemples :

- montage WIM impossible ;
- opération de fichier échouée ;
- erreur Registry ;
- provider introuvable ;
- package introuvable ;
- opération Windows échouée.

---

## Recovery

Exemples :

- ressource laissée par un Build précédent ;
- montage invalide ;
- nettoyage incomplet ;
- état de reprise incohérent.

Les décisions spécifiques à l'état d'un montage sont centralisées dans le composant approprié, notamment :

```powershell
Test-WimMountState()
```

---

## Interne

Exemples :

- état incohérent ;
- BuildContext invalide ;
- propriété attendue absente ;
- erreur de programmation ;
- contrat interne violé.

Les erreurs internes doivent être considérées comme des erreurs techniques nécessitant un diagnostic.

---

# Journalisation

Les erreurs importantes doivent être journalisées via le système centralisé du projet :

```powershell
Write-Log
```

Les informations de diagnostic doivent être suffisamment contextualisées pour permettre l'identification :

- du composant ;
- de l'opération ;
- de la ressource concernée lorsque pertinente ;
- du message d'erreur ;
- de l'exception lorsque disponible.

Le Logger constitue la trace d'exécution.

Il ne doit pas servir de mécanisme de communication entre les composants.

---

# Exceptions

Les exceptions doivent être :

- explicites ;
- contextualisées ;
- cohérentes avec le contrat du composant ;
- propagées lorsqu'elles ne peuvent pas être traitées localement.

Un message d'erreur doit permettre de comprendre autant que possible :

- ce qui a échoué ;
- sur quelle opération ;
- sur quelle ressource ;
- pourquoi l'opération ne peut pas continuer.

Une exception ne doit pas être remplacée par un message générique qui ferait perdre le contexte utile au diagnostic.

---

# Propagation des erreurs

Le comportement attendu est généralement :

```text
Composant
    │
    ▼
Détection
    │
    ▼
Journalisation / enrichissement
    │
    ▼
Propagation
    │
    ▼
Composant appelant
    │
    ▼
Orchestration du Build
```

Un composant peut traiter localement une erreur uniquement lorsqu'il possède réellement la responsabilité de cette récupération.

Lorsqu'il ne peut pas la traiter, l'erreur doit être propagée.

---

# Gestion des erreurs dans les Engines

Les Engines spécialisés doivent :

- valider leurs paramètres ;
- détecter les erreurs de leur domaine ;
- mettre à jour l'état approprié lorsqu'ils en sont responsables ;
- journaliser les informations pertinentes ;
- propager les erreurs non récupérées.

Lorsqu'une Action possède des propriétés de résultat appropriées, son état peut notamment refléter :

- `Success` ;
- `Duration` ;
- `Error`.

Les erreurs ne doivent pas être masquées afin de forcer artificiellement une Action à apparaître comme réussie.

---

# Gestion des erreurs dans les Managers

Les Managers doivent signaler explicitement les problèmes liés à leur contrat technique.

Exemples :

- provider inconnu ;
- handler inexistant ;
- paramètre obligatoire absent ;
- opération technique impossible.

Les Managers ne doivent pas décider seuls du déroulement global du Build.

Ils doivent laisser le niveau d'orchestration approprié décider de la suite lorsque l'erreur est remontée.

---

# Récupération

Lorsqu'une erreur est détectée :

1. le composant responsable la détecte ;
2. il fournit un message explicite et le contexte nécessaire ;
3. il journalise lorsque nécessaire ;
4. il traite localement l'erreur uniquement lorsqu'il en possède la responsabilité ;
5. sinon, il la propage ;
6. le niveau d'orchestration détermine ensuite la suite du Build.

La récupération technique ne doit jamais être dupliquée entre plusieurs composants.

---

# Cas particulier : Recovery

Le Recovery possède une responsabilité spécifique dans la préparation et la remise en état de l'environnement.

Il peut notamment :

- détecter des ressources existantes ;
- vérifier l'état d'un montage ;
- démonter des ressources invalides ;
- nettoyer l'environnement ;
- préparer une reprise cohérente.

La décision concernant l'état d'un montage WIM est centralisée dans :

```powershell
Test-WimMountState()
```

Le Pipeline ne doit pas dupliquer cette logique.

---

# Conséquences

## Avantages

- comportement homogène ;
- meilleure lisibilité ;
- diagnostic simplifié ;
- tests plus fiables ;
- propagation cohérente des erreurs ;
- séparation entre traitement local et orchestration globale ;
- meilleure maintenabilité.

## Inconvénients

- discipline de développement plus stricte ;
- nécessité de conserver des contrats d'erreur cohérents ;
- nécessité de choisir correctement le niveau auquel une erreur doit être traitée.

---

# Alternatives étudiées

## Gestion totalement indépendante par chaque composant

Rejetée.

Des comportements différents auraient rendu les erreurs difficiles à analyser et les tests moins cohérents.

---

## Ignorer automatiquement les erreurs considérées comme mineures

Rejetée.

Un composant ne doit pas masquer un problème simplement parce qu'il semble non bloquant sans respecter son contrat.

La décision de poursuivre doit être prise dans le contexte approprié du traitement.

---

## Gestion de toutes les erreurs dans le Pipeline

Rejetée.

Le Pipeline ne dispose pas de suffisamment de connaissances techniques pour traiter directement les erreurs propres à chaque domaine.

Les composants spécialisés doivent conserver la connaissance de leurs erreurs techniques.

---

# Règles

Les composants ne doivent jamais :

- masquer silencieusement une exception ;
- utiliser un bloc `catch` vide ;
- signaler un succès après une opération réellement échouée ;
- utiliser `exit` pour interrompre arbitrairement le processus appelant ;
- dupliquer une logique de récupération appartenant à un autre composant.

Toute exception doit être :

- journalisée lorsque cela est pertinent ;
- traitée localement uniquement si le composant en est responsable ;
- propagée lorsqu'elle ne peut pas être résolue localement.

---

# Tests

Les tests doivent vérifier, lorsque cela est pertinent :

- les erreurs attendues ;
- les messages d'erreur ;
- la propagation des exceptions ;
- la mise à jour de l'état ;
- l'enregistrement des erreurs dans les résultats d'Action ;
- le comportement du composant appelant.

Toute correction d'un comportement d'erreur important doit être protégée par un test de régression lorsque cela est pertinent.

---

# Évolution

Toute évolution importante de la stratégie de gestion des erreurs doit préserver :

- la propagation contrôlée ;
- la journalisation centralisée ;
- la séparation entre traitement local et orchestration ;
- la cohérence du BuildState ;
- la capacité à diagnostiquer un échec.

Une évolution modifiant le rôle architectural du Pipeline, du Recovery ou du Logger doit être évaluée au regard des ADR concernées.

---

# Décision finale

La gestion des erreurs de **PimsOS Builder** repose sur une responsabilité distribuée mais cohérente :

```text
Détection par le composant responsable
            │
            ▼
Journalisation / enrichissement
            │
            ▼
Traitement local si possible
            │
            ▼
Propagation
            │
            ▼
Orchestration du Build
```

Les composants spécialisés connaissent leurs erreurs techniques.

Le Pipeline orchestre le déroulement global sans dupliquer les règles techniques.

Le Recovery gère les opérations de récupération qui relèvent de sa responsabilité.

Le Logger constitue le mécanisme centralisé de traçabilité.

---

# Références

- `ADR-0004-BuildPipeline.md`
- `ADR-0005-CentralizedLogging.md`
- `BuildContext.md`
- `Architecture.md`
- `ArchitectureRules.md`
- `Lifecycle.md`
- `Testing.md`
