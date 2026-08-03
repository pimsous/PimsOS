# ADR-0004 — Pipeline de build orienté frameworks

- **Statut** : Acceptée
- **Date** : 2026-07-19
- **Décideur** : Pims
- **Impact** : Processus de build

---

# Contexte

La création d'une image Windows est un processus complexe composé de nombreuses étapes.

Parmi celles-ci :

- validation de l'environnement ;
- chargement de la configuration ;
- préparation de l'espace de travail ;
- montage des images WIM ;
- intégration des personnalisations ;
- installation des packages ;
- intégration des pilotes ;
- nettoyage ;
- génération des rapports.

Un traitement monolithique rendrait le projet difficile à maintenir.

---

# Décision

Le Builder est responsable uniquement de l'orchestration.

Chaque étape du build est réalisée par un framework spécialisé.

Le pipeline exécute les étapes dans un ordre déterminé.

---

# Architecture

```text
          Build-PimsOS.ps1
                  │
                  ▼
         Initialize-Build
                  │
                  ▼
         BuildContext
                  │
                  ▼
      ┌────────────────────┐
      │ Pipeline Framework │
      └────────────────────┘
                  │
     ┌────────────┼────────────┐
     ▼            ▼            ▼
 Configuration  Workspace   Validation
     │            │            │
     ▼            ▼            ▼
     Image     Packages    Drivers
     │            │            │
     └────────────┼────────────┘
                  ▼
             Finalisation
                  │
                  ▼
               Rapport
```

---

# Responsabilités

## Builder

Le Builder :

- initialise le projet ;
- crée le BuildContext ;
- démarre le pipeline ;
- termine le build.

Il ne contient pas la logique métier des différentes étapes.

---

## Pipeline

Le Pipeline :

- exécute les étapes ;
- contrôle leur ordre ;
- gère les erreurs ;
- transmet le BuildContext.

---

## Frameworks

Chaque framework :

- réalise une tâche précise ;
- reçoit le BuildContext ;
- retourne un résultat ;
- journalise ses opérations.

Les frameworks sont indépendants les uns des autres.

---

# Ordre général

L'ordre recommandé est :

1. Vérifications
2. Configuration
3. Workspace
4. Montage WIM
5. Packages
6. Tweaks
7. Registre
8. Pilotes
9. Nettoyage
10. Validation
11. Rapport

Cet ordre peut évoluer selon les besoins du projet.

---

# Gestion des erreurs

Une étape peut :

- réussir ;
- générer un avertissement ;
- échouer.

Le Pipeline décide :

- d'arrêter le build ;
- de continuer ;
- de tenter une récupération.

Les frameworks ne prennent pas cette décision.

---

# Conséquences

## Avantages

- pipeline extensible ;
- faible couplage ;
- meilleure testabilité ;
- exécution plus lisible ;
- ajout de nouvelles étapes facilité.

## Inconvénients

- orchestration plus complexe ;
- davantage de composants.

---

# Alternatives étudiées

## Build monolithique

Rejetée.

Toute la logique aurait été concentrée dans un seul script.

La maintenance serait devenue difficile.

## Appels directs entre frameworks

Rejetée.

Les dépendances auraient fortement augmenté.

---

# Règles

Les frameworks ne doivent jamais appeler directement un autre framework.

Toute coordination entre composants passe par le Pipeline.

Le BuildContext est le seul objet partagé.

---

# Impact

Cette décision fait du Pipeline le chef d'orchestre du projet.

Elle garantit que chaque framework reste indépendant tout en participant à un processus cohérent et reproductible.