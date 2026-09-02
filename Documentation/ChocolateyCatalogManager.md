# Gestion du catalogue Chocolatey

## Objectif

L'Assistant PimsOS permet désormais de modifier le catalogue `Config/Packages/Chocolatey.json` sans éditer directement le JSON.

Depuis le menu principal :

`[5] Gérer les packages Chocolatey`

Le gestionnaire permet de :

- afficher les packages ;
- ajouter un package ;
- supprimer un package.

## Ajout

Lors d'un ajout, l'utilisateur fournit :

- ID Chocolatey ;
- version facultative ;
- catégorie facultative ;
- mode `Online` ou `Offline`.

Un package ajouté n'est pas téléchargé immédiatement. Le Build reste responsable de la préparation du cache `Offline`.

## Sécurité

Le package `chocolatey` est réservé au bootstrap PimsOS et ne peut pas être supprimé via l'Assistant.

Un package `Offline` ne doit être choisi comme tel qu'après validation de son payload, de ses dépendances et d'une installation réelle sans Internet.

## Suppression

La suppression retire réellement l'entrée du catalogue. Elle ne supprime pas automatiquement d'éventuels fichiers déjà présents dans un cache de travail ; le cache est reconstruit selon le catalogue lors du Build.

> **Architecture publique :** les fonctions `Read-ChocolateyCatalog`, `Add-ChocolateyCatalogPackage` et `Remove-ChocolateyCatalogPackage` sont des fonctions internes du gestionnaire de catalogue. Elles ne font pas partie de l’API publique du module `PimsOS` et ne sont donc pas exportées par `PimsOS.psm1`/`PimsOS.psd1`.
