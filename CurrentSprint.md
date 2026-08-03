# PimsOS Builder

# Sprint 6 — Moteur de Build

> Version cible : **0.4.x**

---

# Objectif du sprint

Finaliser le cœur du moteur de build afin de disposer d'un pipeline fiable permettant de personnaliser plusieurs versions de Windows à partir d'une ISO officielle Microsoft.

---

# Infrastructure

- [x] Dépôt Git
- [x] Architecture du projet
- [x] Module PowerShell unique
- [x] BuildContext
- [x] BuildState
- [x] Configuration centralisée
- [x] version.json
- [x] Logger
- [x] Recovery

---

# Pipeline

- [x] Vérification de l'environnement
- [x] Préparation du Workspace
- [x] Montage ISO
- [x] Détection du WIM
- [x] Copie du WIM
- [x] Lecture des éditions Windows
- [x] Sélection automatique de l'édition
- [x] Sélection interactive de l'édition
- [x] Montage du WIM
- [x] Montage des ruches du registre
- [x] Chargement de la configuration
- [x] Validation des tweaks
- [x] Chargement des profils
- [x] Fusion Profil → Configuration
- [x] Application des actions
- [x] Commit du WIM
- [x] Démontage des ruches
- [x] Démontage du WIM
- [x] Démontage de l'ISO
- [x] Nettoyage automatique

---

# Configuration

- [x] Tweaks JSON
- [x] Profils
- [x] Catégories
- [x] Validation
- [x] Sélection des tweaks
- [x] BuildConfiguration

---

# Registry Engine

- [x] Chargement des ruches
- [x] Création des clés
- [x] Création des valeurs
- [x] Gestion des types
- [x] Validation
- [x] Journalisation

---

# Action Engine

- [x] Architecture
- [x] Dispatch des actions
- [x] Registry Engine

À développer :

- [ ] Service Engine
- [ ] Feature Engine
- [ ] Package Engine
- [ ] Driver Engine
- [ ] File Engine
- [ ] Folder Engine
- [ ] ScheduledTask Engine
- [ ] Shortcut Engine
- [ ] Environment Engine
- [ ] Command Engine

---

# Support Windows

- [x] Windows 11 24H2
- [x] Windows 11 25H2
- [x] Sélection de l'édition
- [x] Version centralisée dans `version.json`

À venir :

- [ ] Support de nouvelles versions de Windows
- [ ] Validation automatique de compatibilité

---

# Génération d'image

- [ ] Reconstruction complète de l'ISO
- [ ] Optimisation WIM
- [ ] Génération SHA256
- [ ] Rapport de build
- [ ] Export HTML
- [ ] Export JSON

---

# Documentation

- [x] Architecture
- [x] BuildContext
- [x] BuildState
- [x] API
- [x] Roadmap
- [x] Release Notes
- [x] Coding Standards
- [x] Technical Decisions
- [x] Documentation développeur

---

# Tests

- [x] Validation du pipeline complet
- [x] Validation Recovery
- [x] Validation Configuration
- [x] Validation Registry Engine

À développer :

- [ ] Tests BuildContext
- [ ] Tests BuildState
- [ ] Tests ActionEngine
- [ ] Tests ServiceEngine
- [ ] Tests PackageEngine
- [ ] Tests DriverEngine
- [ ] Tests Pipeline complets

---

# Objectif de la version 0.5

- Finaliser les Engines spécialisés
- Ajouter les Packages
- Ajouter les Services
- Ajouter les Features
- Générer une première image Windows entièrement personnalisée

---

# Objectif de la version 1.0

- Pipeline totalement automatisé
- Multi-version Windows
- Architecture stabilisée
- Documentation complète
- Couverture de tests élevée
- Première version stable de **PimsOS Builder**