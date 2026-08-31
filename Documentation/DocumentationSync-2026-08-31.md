# PimsOS Builder — Synchronisation documentaire du 31/08/2026

## Objet

Cette note fixe l’état documentaire à retenir après la campagne de tests et le Build réel exécutés le 31/08/2026.

## État vérifié

- Version technique : **3.0.0**.
- Module unique `Modules\PimsOS.psm1` : `TweakCatalog.ps1` est chargé.
- Wizard : sélection de profil, configuration personnalisée et sélection de Tweaks par élément, liste ou plage ; `A` et `D` sont disponibles.
- Profils : racine `Profiles\`, avec prise en charge des sous-dossiers.
- Tweaks : **19 définitions JSON non vides** et **9 placeholders vides** dans l’archive fournie.
- Build réel : **succès, code retour 0**, Windows 11 Professionnel index 6.
- ISO : `Output\PimsOS_3.0.0_20260831_175702.iso`, taille annoncée 7,9 Go.
- WIM synchronisé : SHA256 `9CD448E4CE08C30E8A0912D4CD767335E7D53878736A19E678126109E0AA3B68`.
- Wizard tests : **15/15**.
- PostInstall/Unattend : **744 Passed, 0 Failed, 1 Skipped** sur la campagne communiquée.
- Résultat global communiqué : **971 Passed, 0 Failed, 1 Skipped**.
- `Tests\testResults.xml` dans l’archive : ancien résultat du 28/08 et non représentatif de la campagne finale.

## Documentation mise à jour

Les documents de statut, architecture, structure, modules, PostInstall, tests, backlog, roadmap, sprint et release notes ont été resynchronisés pour ne plus présenter comme « à faire » les éléments déjà validés dans le code et les tests du 31/08.

## Ce qui reste volontairement ouvert

- validation Hyper-V de la nouvelle ISO du 31/08 ;
- validation réelle FirstBoot/PostInstall après les dernières corrections ;
- validation physique/Rufus ;
- régénération du rapport XML Pester ;
- enrichissement des Tweaks et profils ;
- providers Chocolatey/Winget et Microsoft Store ;
- Recovery/Security et Reporting selon le backlog.

## Règle de référence

Le **code du dépôt** est la source de vérité technique. Les **résultats de tests communiqués** sont la source de vérité pour la campagne du jour. Les ADR et documents historiques ne sont pas réécrits lorsqu’ils décrivent une décision ou un état historique.
