# ADR-0008 — Gestion centralisée des erreurs et des exceptions

- **Statut** : Acceptée
- **Date** : 2026-07-19
- **Décideur** : Pims
- **Impact** : Tous les frameworks

---

# Contexte

Les frameworks PimsOS réalisent des opérations critiques :

- lecture de configuration ;
- montage d'images WIM ;
- modifications du registre ;
- installation de packages ;
- intégration de pilotes ;
- génération de rapports.

Chaque opération peut échouer.

Sans stratégie commune, chaque framework pourrait gérer les erreurs différemment, compliquant :

- le débogage ;
- les tests ;
- le pipeline ;
- la maintenance.

---

# Décision

La gestion des erreurs est centralisée.

Chaque framework est responsable :

- de détecter les erreurs ;
- de produire une exception explicite ;
- de journaliser l'événement.

Le Pipeline est responsable de décider de la suite de l'exécution.

---

# Principes

Les frameworks ne décident jamais :

- d'interrompre définitivement un build ;
- de relancer une opération ;
- d'ignorer une erreur critique.

Ils signalent simplement le problème.

Le Pipeline prend la décision appropriée.

---

# Types d'erreurs

Les erreurs sont classées en plusieurs catégories.

## Configuration

Exemples :

- fichier absent ;
- JSON invalide ;
- propriété obligatoire manquante.

---

## Environnement

Exemples :

- PowerShell incompatible ;
- DISM absent ;
- espace disque insuffisant.

---

## Exécution

Exemples :

- montage WIM impossible ;
- copie de fichier échouée ;
- package introuvable.

---

## Interne

Exemples :

- état incohérent ;
- BuildContext invalide ;
- erreur de programmation.

---

# Journalisation

Toute erreur doit être enregistrée par le framework Logger.

Les informations minimales sont :

- date ;
- niveau ERROR ;
- framework concerné ;
- message explicite ;
- exception éventuelle.

---

# Exceptions

Les exceptions doivent être :

- explicites ;
- contextualisées ;
- réutilisables.

Les messages doivent permettre de comprendre immédiatement :

- la cause ;
- l'opération concernée ;
- les conséquences.

---

# Récupération

Lorsqu'une erreur est détectée :

1. le framework la signale ;
2. le Pipeline l'analyse ;
3. le Pipeline décide :

- poursuite ;
- nouvelle tentative ;
- arrêt du build.

---

# Conséquences

## Avantages

- comportement homogène ;
- meilleure lisibilité ;
- débogage simplifié ;
- pipeline plus robuste ;
- meilleure testabilité.

## Inconvénients

- discipline de développement plus stricte ;
- définition de conventions communes.

---

# Alternatives étudiées

## Gestion indépendante par chaque framework

Rejetée.

Les comportements auraient été incohérents.

---

## Ignorer les erreurs mineures

Rejetée.

Le build pourrait produire un résultat incohérent.

---

# Règles

Les frameworks ne doivent jamais :

- masquer une exception ;
- utiliser des blocs `catch` vides ;
- poursuivre silencieusement après une erreur critique.

Toute exception doit être :

- journalisée ;
- propagée ou convertie en erreur métier selon le contexte.

---

# Impact

Cette décision garantit une gestion cohérente des erreurs dans tout le projet.

Le Pipeline reste le seul composant chargé de piloter le déroulement global d'un build.

---

# Références

- ADR-0004 — Pipeline de build
- ADR-0005 — Journalisation centralisée
- Documentation/Lifecycle.md
- Documentation/Testing.md