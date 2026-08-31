# PimsOS Builder - Legacy

> Version technique : 3.0.0
>
> Statut : Référence historique
>
> Dernière mise à jour : 2026-08-31

---

# Objectif

Ce document décrit les composants historiques conservés dans le dépôt **PimsOS Builder**.

Ces composants ne font pas partie de l'architecture active du Builder.

Ils sont conservés lorsqu'ils présentent encore une valeur historique, documentaire ou technique.

Ils ne participent pas au fonctionnement normal du Pipeline actuel.

---

# Historique

Les premières versions de PimsOS étaient constituées d'un ensemble d'outils PowerShell indépendants destinés à automatiser différentes opérations.

Au fil du développement, le projet a évolué vers un framework unique reposant notamment sur :

- un BuildContext centralisé ;
- un BuildState ;
- un Workflow ;
- un Pipeline ;
- un ActionEngine ;
- un ActionRegistry ;
- des Engines spécialisés ;
- des Managers techniques.

Cette évolution a rendu certains anciens composants obsolètes ou hors du chemin d'exécution actuel.

---

# Contenu historique

Les composants historiques peuvent notamment se trouver dans :

```text
Tools/
```

et :

```text
Tests/
└── Legacy/
```

Ces emplacements doivent être considérés comme hors du chemin d'exécution normal de PimsOS.

---

# Tools

Le dossier :

```text
Tools/
```

peut contenir des outils historiques ou auxiliaires qui ne sont pas chargés par :

```text
Modules\PimsOS.psm1
```

Ces outils ne constituent pas des composants du framework actif.

Avant toute utilisation, vérifier leur statut et leur documentation propres.

---

# Migration

Le framework ou les outils **Migration** sont considérés comme historiques.

Ils peuvent être conservés afin de :

- comprendre certaines décisions prises au cours du développement ;
- analyser l'évolution de l'architecture ;
- réutiliser ponctuellement une approche technique après adaptation ;
- conserver une trace des travaux antérieurs.

Ils ne constituent pas une dépendance du Builder actuel.

Tout code réutilisé doit être adapté à l'architecture actuelle avant intégration.

---

# Tests Legacy

Les anciens tests peuvent être isolés dans :

```text
Tests/
└── Legacy/
```

Ils ne participent pas à la validation courante du framework.

Les tests du Builder actif sont exécutés depuis les répertoires de tests dédiés au framework actuel.

Les tests Legacy doivent être considérés comme des archives de test et non comme une référence du comportement actuel.

---

# Architecture active

Le développement actif est désormais centré sur les composants du framework principal, notamment :

```text
Modules
│
├── Actions
├── Configuration
├── Core
├── Image
├── Infrastructure
├── Managers
├── Package
└── Windows
```

Le point d'entrée du framework est :

```text
Modules\PimsOS.psm1
```

Les composants Legacy ne sont pas chargés par ce module.

---

# Interdictions

Aucune nouvelle fonctionnalité du Builder ne doit être développée dans les composants Legacy.

En particulier :

```text
Tools/
Tests/Legacy/
```

ne doivent pas être utilisés pour introduire une nouvelle fonctionnalité du framework principal.

Une maintenance exceptionnelle peut être réalisée lorsqu'elle est nécessaire à la conservation ou à l'analyse d'un composant historique.

---

# Politique de maintenance

Les composants Legacy sont considérés comme figés fonctionnellement.

Les corrections éventuelles doivent :

- rester exceptionnelles ;
- être limitées à la maintenance nécessaire ;
- ne pas introduire de nouvelle fonctionnalité dans l'architecture Legacy ;
- être documentées lorsque leur impact est significatif.

Toute nouvelle fonctionnalité doit être développée dans l'architecture active.

---

# Réutilisation

Une implémentation Legacy peut être étudiée ou réutilisée lorsqu'elle présente une valeur technique.

Avant intégration dans le Builder actif, elle doit :

- être adaptée à l'architecture actuelle ;
- respecter les Architecture Rules ;
- utiliser les contrats actuels du BuildContext ;
- disposer de tests adaptés ;
- être documentée si nécessaire.

Le code Legacy ne doit pas être copié directement dans l'architecture active sans adaptation.

---

# Suppression

Les composants historiques pourront être supprimés lorsqu'ils n'apporteront plus de valeur.

Avant toute suppression, vérifier :

- qu'aucun composant actif ne les utilise ;
- qu'ils ne sont plus nécessaires à la maintenance historique ;
- qu'ils ne contiennent pas une information utile à la compréhension du projet ;
- que leur suppression est documentée lorsque nécessaire.

---

# Conclusion

Le dépôt conserve volontairement certains composants historiques afin de préserver la mémoire technique du projet.

Ces composants permettent notamment de retracer l'évolution de PimsOS et de comprendre certaines décisions prises au cours du développement.

Le développement actif est désormais centré sur **PimsOS Builder** et son architecture modulaire :

```text
BuildContext
    ↓
Workflow
    ↓
Pipeline
    ↓
ActionEngine
    ↓
ActionRegistry
    ↓
Engines spécialisés
    ↓
Managers
    ↓
Modules techniques
```

Les composants Legacy sont utilisés uniquement comme références historiques ou techniques et ne font pas partie du chemin d'exécution normal du Builder.
