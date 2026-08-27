# PimsOS Builder - Structure du projet

> Version technique : 3.0.0
>
> Statut : Développement / architecture stabilisée
>
> Dernière mise à jour : 2026-08-16

---

# Objectif

Ce document décrit l'organisation réelle du projet **PimsOS Builder**.

Le projet est structuré autour d'un module PowerShell unique :

```text
Modules\PimsOS.psm1
## PostInstall

Le projet contient désormais :

Modules\PostInstall\
Tests\Unit\Modules\PostInstall\

Le dossier `Modules\PostInstall` contient le runtime,
et `Tests\Unit\Modules\PostInstall` contient ses tests dédiés.
