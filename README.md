# Briefing Enhanced

**Briefing Enhanced** extends the PAYDAY 2 mission briefing with a central `BUILD` menu. Configure skills, perk decks, outfits, gloves and weapons without leaving the lobby, then modify owned weapons through a briefing-safe 2D interface.

Version: **1.10.0**  
Author: **CptTroufion**  
Required: **PAYDAY 2 + SuperBLT**
Optional: **BeardLib for automatic update checks and installation**

- [English](#english)
- [Français](#français)
- [Developer documentation](TECHNICAL_DOCUMENTATION_Briefing_Build_Menu.md)

---

# English

## Features

- Open the vanilla skill tree and perk deck screens from `BUILD`.
- Open the vanilla player-style and glove grids from `BUILD`.
- Right-click the briefing primary or secondary slot to open its inventory or modify it.
- Right-click the briefing armor slot to open Gloves, Outfit or Armor.
- Equip, buy and sell weapons through the vanilla BlackMarket actions.
- Right-click an owned weapon in the briefing BlackMarket to sell or modify that exact slot.
- Browse weapon-part categories and pages in a dedicated 2D screen.
- Inspect part availability, ownership, price, description and achievement locks.
- Install, replace or remove parts through vanilla confirmations and transactions.
- Compare vanilla `TOTAL / BASE / MOD / SKILL` weapon statistics.
- Use optional integrations with Drag and Drop Inventory, More Weapon Stats and PD2Builder loader.
- Keep briefing chat accessible while custom screens are open, and temporarily hide EHI's overlapping XP panel before restoring it on close.

## Why a 2D weapon modification screen?

The vanilla workshop requires the BlackMarket 3D scene. That scene is not guaranteed in the mission briefing and may crash when workshop or inventory mods expect `managers.menu_scene`.

Briefing Enhanced therefore reuses vanilla weapon data, compatibility rules, prices, confirmations and transactions without opening the 3D preview.

## Installation

1. Install [SuperBLT](https://superblt.znix.xyz/).
2. Install [BeardLib](https://modworkshop.net/mod/14924) if you want in-game update checks.
3. Copy `Briefing Build Menu` into `PAYDAY 2/mods/`.
4. Ensure `mod.txt` and `main.xml` are directly inside that folder.
5. Start or restart PAYDAY 2.

SuperBLT displays the installed mod as **Briefing Enhanced**.

When BeardLib is installed, it checks the official [ModWorkshop page](https://modworkshop.net/mod/57999) from the main menu. Updates are shown in the BeardLib Mods Manager and remain user-confirmed; restart PAYDAY 2 after installation.

## Usage

### BUILD

Open the mission briefing and select `BUILD`. The menu provides:

- `SKILL TREE`;
- perk deck selection;
- player styles;
- gloves;
- `WEAPON MODIFICATIONS`;
- `IMPORT BUILD` and `EXPORT BUILD` when PD2Builder loader is available.

### Loadout context menus

- Right-click the primary or secondary weapon: `OPEN INVENTORY`, `MODIFY WEAPON`, `CANCEL`.
- Right-click the armor slot: `GLOVES`, `OUTFIT`, `ARMOR`, `CANCEL`.

In the briefing weapon inventory, the vanilla context menu retains weapon sale and routes weapon modification to the safe 2D component. The last usable weapon in a category cannot be sold.

### Weapon modifications

1. Open `BUILD` → `WEAPON MODIFICATIONS`, or right-click a specific owned weapon.
2. Select a part category and page.
3. Select a part to inspect its state, price, description and stat preview.
4. Confirm `INSTALL` or `REMOVE`.

`BUILD` targets the equipped weapon. The BlackMarket context action targets the exact selected inventory slot. Achievement and milestone locks are checked before confirmation and again before the transaction.

## Optional integrations

Optional mods are detected at runtime and are not bundled.

| Integration | When available | Fallback |
|---|---|---|
| Drag and Drop Inventory | Enables weapon move and swap behavior in briefing grids | Vanilla equip, purchase and sale |
| More Weapon Stats | Adds its extended statistic rows | Vanilla weapon statistics |
| PD2Builder loader | Adds build import and export entries | Entries are hidden |
| Market Favorites | Its hooks decorate the reused weapon, outfit and glove grids automatically | Unmodified vanilla grids |
| BeardLib | Checks ModWorkshop for newer semantic versions and installs the selected update | The mod runs normally without automatic updates |

## Limitations

- No 3D weapon preview.
- No weapon skin, custom-color or skin-editor management.
- PD2Builder controls its own import scope and does not replace weapons.
- Compatibility with mods that override the same PAYDAY 2 menu classes can depend on their load order and chaining behavior.

## Development

The code follows one feature per folder. Runtime hooks are kept separate from controllers, game rules, rendering and optional-mod adapters.

See [the technical documentation](TECHNICAL_DOCUMENTATION_Briefing_Build_Menu.md) for architecture, trigger maps, runtime flows, compatibility rules, extension tutorials and the minimum in-game test matrix.

## Patch notes

### v1.10.0

#### Added

- Weapon purchase and sale from briefing BlackMarket grids.
- Optional Drag and Drop Inventory integration for moving and swapping weapons.
- Right-click menus for primary and secondary briefing weapon slots.
- Right-click armor menu with Gloves, Outfit and Armor routes.
- Safe modification of the exact weapon selected in the briefing BlackMarket.
- Paginated weapon-part categories.
- Contextual part descriptions resolved through vanilla weapon-factory data.
- Achievement and milestone lock validation before weapon-part transactions.
- Large right-side vanilla weapon statistics with optional More Weapon Stats rows.
- Optional PD2Builder import and export.
- Automatic compatibility with Market Favorites on reused vanilla grids.
- BeardLib update checks and user-confirmed installation from the official ModWorkshop page.

#### Improved

- Weapon-part images now preserve their aspect ratio.
- Weapon modification status, price, ownership and stat comparisons.
- Outfit and glove selection through guarded vanilla loadout nodes.
- Custom screens now hide EHI's overlapping XP panel and restore its previous visibility on close, while briefing chat remains accessible.
- Weapon modification no longer enters the vanilla BlackMarket 3D workshop, preventing briefing crashes and reducing conflicts with inventory/workshop mods.

#### Fixed

- Missing weapon-part descriptions no longer display `ERROR: <localization_id>`.
- Locked achievement parts can no longer be installed through the custom screen.
- Closing or failing to open a custom screen no longer leaves BUILD or outfit updates blocked.
- Unsafe briefing preview and customization actions are removed from reused grids.

### v1.8.1

- Added outfit selection.
- Added menu selection.

### v1.7.1

- Removed legacy files.

### v1.7.0

- Refactored the codebase.

---

# Français

## Description

**Briefing Enhanced** enrichit le briefing de mission avec un menu central `BUILD`. Il permet de gérer les compétences, le perk deck, les tenues, les gants et les armes sans quitter le lobby, puis de modifier les armes possédées dans une interface 2D sûre.

## Fonctionnalités

- Ouverture des écrans vanilla de compétences et de perk decks.
- Sélection vanilla des tenues et des gants.
- Menus contextuels sur les armes et l'armure du briefing.
- Équipement, achat et vente d'armes avec les actions BlackMarket vanilla.
- Modification de l'arme équipée ou du slot d'inventaire précisément sélectionné.
- Catégories et pages de pièces, descriptions, prix, quantités et verrous.
- Installation, remplacement et retrait avec les confirmations et transactions vanilla.
- Statistiques `TOTAL / BASE / MOD / SKILL`.
- Intégrations optionnelles avec Drag and Drop Inventory, More Weapon Stats et PD2Builder loader.
- Mise à jour intégrée optionnelle avec BeardLib.
- Compatibilité avec le chat du briefing, EHI et les grilles décorées par Market Favorites.

## Pourquoi une interface 2D ?

L'atelier vanilla dépend de la scène 3D BlackMarket, qui n'est pas garantie dans le briefing et peut provoquer un crash lorsque `managers.menu_scene` est absent.

Le mod réutilise donc les données, règles de compatibilité, prix, confirmations et transactions vanilla sans ouvrir cette scène.

## Installation

1. Installer [SuperBLT](https://superblt.znix.xyz/).
2. Installer [BeardLib](https://modworkshop.net/mod/14924) pour bénéficier de la vérification des mises à jour.
3. Copier `Briefing Build Menu` dans `PAYDAY 2/mods/`.
4. Vérifier que `mod.txt` et `main.xml` se trouvent directement dans ce dossier.
5. Démarrer ou redémarrer PAYDAY 2.

SuperBLT affiche le mod sous le nom **Briefing Enhanced**.

Avec BeardLib, la page officielle [ModWorkshop](https://modworkshop.net/mod/57999) est vérifiée depuis le menu principal. Le téléchargement reste confirmé par l'utilisateur dans le gestionnaire BeardLib. Redémarrer PAYDAY 2 après l'installation.

## Utilisation

- Ouvrir `BUILD` pour accéder aux compétences, perk decks, tenues, gants, modifications d'armes et, si disponible, PD2Builder.
- Faire un clic droit sur l'arme principale ou secondaire du briefing pour ouvrir son inventaire ou la modifier.
- Faire un clic droit sur l'armure pour ouvrir Gants, Tenue ou Armure.
- Dans l'inventaire d'armes du briefing, employer les actions vanilla pour équiper, acheter ou vendre, et l'action de modification pour ouvrir le composant 2D.

L'entrée `BUILD` cible l'arme équipée. Le menu BlackMarket cible le slot possédé sélectionné. Les verrous de succès et de milestone sont revérifiés avant toute transaction.

## Intégrations optionnelles

| Intégration | Si disponible | Repli |
|---|---|---|
| Drag and Drop Inventory | Déplacement et permutation des armes | Équipement, achat et vente vanilla |
| More Weapon Stats | Lignes de statistiques étendues | Statistiques vanilla |
| PD2Builder loader | Import et export de build | Entrées masquées |
| Market Favorites | Décoration automatique des grilles vanilla réutilisées | Grilles vanilla inchangées |
| BeardLib | Vérification des versions sémantiques et installation depuis ModWorkshop | Le mod fonctionne normalement sans mise à jour automatique |

## Limites

- Aucune prévisualisation 3D des armes.
- Aucun traitement des skins, couleurs personnalisées ou de l'éditeur de skins.
- PD2Builder contrôle son propre périmètre d'import et ne remplace pas les armes.
- Les mods qui remplacent les mêmes classes de menu peuvent rester sensibles à l'ordre de chargement.

## Développement

Le code suit le principe « une fonctionnalité, un dossier ». Consulter [la documentation technique](TECHNICAL_DOCUMENTATION_Briefing_Build_Menu.md) pour l'architecture, les déclencheurs, les flux runtime, la compatibilité, les tutoriels d'évolution et la matrice minimale de tests en jeu.

## Notes de version

La liste détaillée de la version **1.10.0** se trouve dans la section anglaise [Patch notes](#patch-notes). Les entrées historiques 1.8.1, 1.7.1 et 1.7.0 y sont également conservées.

## Credits

Créé par **CptTroufion**.
