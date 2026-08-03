# Legacy

> Version : 0.4.0
>
> Architecture : 2.x

---

# Objectif

Ce document décrit les composants historiques conservés dans le dépôt **PimsOS Builder**.

Ces composants ne font plus partie de l'architecture active du Builder mais sont conservés pour :

- préserver l'historique du projet ;
- conserver certaines implémentations utiles ;
- faciliter les comparaisons entre les anciennes et les nouvelles architectures.

Ils ne participent pas au fonctionnement du pipeline actuel.

---

# Historique

Les premières versions de PimsOS étaient constituées d'un ensemble d'outils PowerShell indépendants développés pour automatiser différentes opérations.

Au fil du développement, le projet a évolué vers un framework unique reposant sur :

- un BuildContext centralisé ;
- une Build Pipeline ;
- un ActionEngine ;
- un ActionRegistry ;
- des Engines spécialisés ;
- des Managers techniques.

Cette évolution a rendu une partie des anciens outils obsolète.

Ils ont été déplacés dans l'espace **Legacy**.

---

# Contenu du Legacy

Les composants historiques sont principalement regroupés dans :

```text
Tools/
```

et

```text
Tests/
└── Legacy
```

Ces dossiers sont volontairement conservés dans le dépôt.

---

# Tools

Le dossier :

```text
Tools/
```

contient principalement :

- l'ancien framework Migration ;
- les scripts de publication ;
- les outils de qualité ;
- diverses utilitaires historiques.

Ces outils ne sont pas chargés par **PimsOS.psm1**.

Ils ne participent pas au Build actuel.

---

# Migration

Le framework **Migration** est désormais considéré comme un projet historique.

Il est conservé pour :

- comprendre certaines décisions d'architecture ;
- réutiliser ponctuellement certains algorithmes ;
- maintenir la compatibilité avec d'anciens travaux.

Il ne constitue plus une dépendance du Builder.

---

# Tests Legacy

Les anciens tests ont été isolés dans :

```text
Tests/
└── Legacy/
```

Cette séparation permet de distinguer clairement :

- les tests du Builder actuel ;
- les tests des anciens outils.

Les tests Legacy ne participent plus à la validation du framework.

Seuls les tests situés hors de ce dossier sont exécutés lors du développement courant.

---

# Développement actif

Le développement est désormais concentré sur les composants suivants :

```text
Build
Classes
Config
Documentation
Modules
Profiles
Resources
Tests
Tweaks
Workspace
```

Ces dossiers constituent la base officielle du framework.

---

# Interdictions

Aucune nouvelle fonctionnalité ne doit être développée dans :

```text
Tools/
```

ou

```text
Tests/Legacy/
```

Sauf nécessité exceptionnelle de maintenance.

Toute nouvelle fonctionnalité doit être intégrée au framework principal.

---

# Politique de maintenance

Les composants Legacy sont considérés comme figés.

Les corrections éventuelles doivent :

- être exceptionnelles ;
- être documentées ;
- ne jamais introduire de nouvelles fonctionnalités.

Toute évolution fonctionnelle doit être réalisée dans les composants actifs.

---

# Réutilisation

Il est autorisé de réutiliser une implémentation provenant du Legacy à condition de :

- l'adapter à l'architecture actuelle ;
- respecter les Architecture Rules ;
- utiliser le BuildContext ;
- écrire de nouveaux tests ;
- documenter la migration si nécessaire.

Le code ne doit jamais être copié sans adaptation.

---

# Suppression

Les composants Legacy pourront être supprimés lorsqu'ils n'apporteront plus de valeur.

Avant toute suppression, il convient de vérifier :

- qu'aucun composant actif ne les utilise ;
- que leur contenu est devenu obsolète ;
- que leur suppression est documentée.

---

# Conclusion

Le dépôt conserve volontairement certains composants historiques.

Ils constituent une archive technique permettant de retracer l'évolution du projet.

Le développement actif est désormais entièrement centré sur **PimsOS Builder** et son architecture modulaire (BuildContext, Pipeline, ActionRegistry, Engines et Managers).

Les composants Legacy ne servent plus qu'à des fins de référence, d'archivage ou d'analyse historique.