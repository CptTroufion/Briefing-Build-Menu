*Generated Code by Codex.

# Briefing Enhanced

**Briefing Enhanced** extends the PAYDAY 2 mission briefing with a central `BUILD` menu. It lets players configure skills, perk decks, player styles, gloves and weapons, modify equipped weapons through a safe 2D interface, inspect weapon statistics, and optionally import or export builds with PD2Builder—without leaving the lobby briefing.

Version: **1.8.1**  
Author: **CptTroufion**  
Required runtime: **PAYDAY 2 + SuperBLT**

- [English](#english)
- [Français](#français)
- [Technical documentation](TECHNICAL_DOCUMENTATION_Briefing_Build_Menu.md)

---

# English

## Features

- Central `BUILD` button in the mission briefing.
- Open the vanilla skill tree from the briefing.
- Open the vanilla perk deck selection from the briefing.
- Open the vanilla player-style and glove screens directly from `BUILD`.
- Browse equipped primary and secondary weapon categories.
- Equip, purchase and sell weapons through vanilla BlackMarket actions.
- Optional weapon drag-and-drop integration.
- Modify the currently equipped primary or secondary weapon.
- Browse modification categories and multiple pages of available parts.
- See equipped, available, incompatible, unaffordable and unowned part states.
- Install, replace or remove parts through vanilla confirmations and transactions.
- Display vanilla `TOTAL / BASE / MOD / SKILL` weapon statistics.
- Optional additional statistics from More Weapon Stats.
- Optional PD2Builder build import and export.
- Compatibility handling for EHI and briefing chat.

## Why a custom 2D weapon modification screen?

The vanilla weapon workshop expects the BlackMarket 3D scene to exist. That scene is not guaranteed inside the mission briefing and can cause crashes, especially when other inventory mods also hook the workshop.

Briefing Enhanced therefore uses a dedicated 2D interface. It keeps the important vanilla behavior—compatible parts, inventory amounts, prices, confirmations and BlackMarket transactions—without creating a weapon preview scene.

## Requirements

- PAYDAY 2.
- [SuperBLT](https://superblt.znix.xyz/).

BeardLib is not required.

## Optional integrations

The mod checks every optional integration at runtime. Missing or disabled integrations do not prevent the base features from working.

| Integration | Added behavior | Behavior when unavailable |
|---|---|---|
| Drag and Drop Inventory | Move and swap weapons from briefing weapon grids | Equip, purchase and sale remain available |
| More Weapon Stats | Extra reload, delay, pickup, recoil, spread and falloff values | Vanilla statistics remain available |
| PD2Builder loader | Adds `IMPORT BUILD` and `EXPORT BUILD` to `BUILD` | Both entries are hidden |
| Market Favorites | Adds favorite actions, `FAV` badges and favorites-first sorting to the reused weapon-store, player-style and glove grids | Vanilla grids remain unchanged |

Optional mods are not bundled with Briefing Enhanced.

## Installation

1. Install SuperBLT.
2. Download or clone this repository.
3. Copy the `Briefing Build Menu` folder into:

   ```text
   PAYDAY 2/mods/Briefing Build Menu/
   ```

4. Confirm that `mod.txt` is directly inside that folder and not inside an additional archive directory.
5. Start or restart PAYDAY 2.

After installation, SuperBLT should list the mod as **Briefing Enhanced**.

## Usage

### BUILD menu

1. Join or host a game and reach the mission briefing.
2. Select `BUILD`.
3. Choose an available action:

   - `SKILL TREE`;
   - perk deck selection;
   - player styles;
   - gloves;
   - `WEAPON MODIFICATIONS`;
   - `IMPORT BUILD` or `EXPORT BUILD` when PD2Builder loader is available.

### Weapon selection, purchase and sale

1. Open the briefing `LOADOUT` tab.
2. Select the primary or secondary weapon slot.
3. Use the vanilla weapon grid to equip an owned weapon or select an empty slot to buy one.
4. Use the available vanilla action to sell an eligible weapon.

The last usable weapon in a category cannot be sold. Unsafe 3D preview actions are disabled only in this briefing context.

### Player styles and gloves

1. Open `BUILD`.
2. Choose the vanilla player-style or glove entry.
3. Equip an unlocked item with the standard BlackMarket action.
4. Return to the briefing with the normal Back action.

These entries reuse the briefing's vanilla `loadout` node and its `BlackMarketGui` component. Preview and customization actions are hidden in this context because their 3D scene or nested node is not available; standard equip actions remain. If Market Favorites is installed and enabled, its add/remove action, `FAV` badge and favorites-first sorting appear automatically. Briefing Enhanced does not call or require the Market Favorites namespace.

### Weapon modifications

1. Open `BUILD` → `WEAPON MODIFICATIONS`.
2. Choose `PRIMARY WEAPON` or `SECONDARY WEAPON`.
3. Select a modification category.
4. Use the previous/next page controls when the category contains more parts than one page.
5. Select a part to inspect its status, price, owned amount and stat preview.
6. Confirm `INSTALL` or `REMOVE` when the action is available.

The interface modifies the currently equipped weapon in that category.

## Current limitations

- No 3D weapon preview is created in the briefing.
- Weapon skins, custom colors and the skin editor are not managed by the 2D modification component.
- Mechanical modifications apply to the currently equipped primary or secondary weapon.
- PD2Builder controls its own import scope; its current import does not replace weapons.
- Final compatibility still depends on the load order and behavior of other mods that override PAYDAY 2 inventory classes.

## Compatibility and safety

The mod preserves historical `BriefingBuildMenu` namespaces, hook IDs, localization keys and menu component IDs for upgrades from versions up to 1.6.1. New code uses the `BriefingEnhanced` namespace.

Briefing Enhanced limits its inventory changes to the mission briefing context and delegates economic operations to vanilla managers. Optional mods are accessed through guarded adapters.

If a crash occurs, include the latest files from:

```text
PAYDAY 2/mods/logs/
PAYDAY 2/crash.txt
```

## Development and contribution

The source is organized using one feature per folder. Hooks connect game classes to controllers, services contain rules and transactions, views render UI, and adapters isolate optional mods.

Read [TECHNICAL_DOCUMENTATION_Briefing_Build_Menu.md](TECHNICAL_DOCUMENTATION_Briefing_Build_Menu.md) before changing the code. It includes:

- a beginner explanation of SuperBLT loading;
- the exact hook-to-file map;
- module and dependency diagrams;
- end-to-end feature flows;
- naming conventions;
- tutorials for adding features and integrations;
- debugging guidance and an in-game test matrix.

Before submitting a change:

1. Keep LuaJIT/Lua 5.1 compatibility.
2. Validate `mod.txt` as strict JSON.
3. Preserve stable IDs or provide an explicit migration.
4. Test repeated opening and closing from the briefing.
5. Test optional integrations in both enabled and disabled states.
6. Check the newest SuperBLT and Diesel crash logs.

## Credits

Created by **CptTroufion**. Inspired by the idea of managing build-related screens directly from the mission briefing.

---

# Français

## Description

**Briefing Enhanced** enrichit le briefing de mission de PAYDAY 2 avec un menu central `BUILD`. Il permet de configurer les compétences, le perk deck, la tenue, les gants et les armes, de modifier l'arme équipée dans une interface 2D sûre, de consulter ses statistiques et, optionnellement, d'importer ou exporter un build avec PD2Builder sans quitter le lobby.

## Fonctionnalités

- Bouton central `BUILD` dans le briefing.
- Ouverture de l'arbre de compétences vanilla.
- Ouverture de la sélection des perk decks vanilla.
- Ouverture des écrans vanilla de tenues et de gants directement depuis `BUILD`.
- Consultation des catégories d'armes principale et secondaire.
- Équipement, achat et vente avec les actions BlackMarket vanilla.
- Intégration optionnelle du glisser-déposer des armes.
- Modification de l'arme principale ou secondaire actuellement équipée.
- Catégories de pièces et pagination des modifications disponibles.
- Affichage des états : équipé, disponible, incompatible, trop cher ou non possédé.
- Installation, remplacement et retrait avec confirmations et transactions vanilla.
- Statistiques d'armes vanilla `TOTAL / BASE / MOD / SKILL`.
- Statistiques supplémentaires optionnelles avec More Weapon Stats.
- Import et export optionnels avec PD2Builder.
- Adaptations de compatibilité pour EHI et le chat du briefing.

## Pourquoi une interface 2D spécifique ?

L'atelier d'armes vanilla suppose que la scène 3D BlackMarket existe. Cette scène n'est pas garantie dans le briefing et peut provoquer des crashs, notamment lorsque d'autres mods d'inventaire hookent aussi l'atelier.

Briefing Enhanced emploie donc une interface 2D dédiée. Elle conserve les comportements vanilla importants — pièces compatibles, quantités possédées, prix, confirmations et transactions BlackMarket — sans créer de scène de prévisualisation.

## Prérequis

- PAYDAY 2.
- [SuperBLT](https://superblt.znix.xyz/).

BeardLib n'est pas requis.

## Intégrations optionnelles

Chaque intégration est vérifiée au runtime. Une intégration absente ou désactivée n'empêche pas les fonctionnalités de base de fonctionner.

| Intégration | Comportement ajouté | Repli si indisponible |
|---|---|---|
| Drag and Drop Inventory | Déplacement et permutation des armes dans les grilles du briefing | Équipement, achat et vente disponibles |
| More Weapon Stats | Valeurs supplémentaires de rechargement, délais, ramassage, recul, dispersion et portée | Statistiques vanilla disponibles |
| PD2Builder loader | Ajoute `IMPORT BUILD` et `EXPORT BUILD` dans `BUILD` | Entrées masquées |
| Market Favorites | Ajoute les actions de favori, le badge `FAV` et le tri des favoris en tête aux grilles réutilisées du magasin, des tenues et des gants | Les grilles vanilla restent inchangées |

Les mods optionnels ne sont pas inclus avec Briefing Enhanced.

## Installation

1. Installer SuperBLT.
2. Télécharger ou cloner ce repository.
3. Copier le dossier `Briefing Build Menu` dans :

   ```text
   PAYDAY 2/mods/Briefing Build Menu/
   ```

4. Vérifier que `mod.txt` se trouve directement dans ce dossier et non dans un dossier d'archive supplémentaire.
5. Démarrer ou redémarrer PAYDAY 2.

Après l'installation, SuperBLT doit afficher le mod sous le nom **Briefing Enhanced**.

## Utilisation

### Menu BUILD

1. Héberger ou rejoindre une partie et atteindre le briefing.
2. Sélectionner `BUILD`.
3. Choisir une action disponible :

   - `SKILL TREE` ;
   - sélection du perk deck ;
   - tenues ;
   - gants ;
   - `WEAPON MODIFICATIONS` ;
   - `IMPORT BUILD` ou `EXPORT BUILD` si PD2Builder loader est disponible.

### Sélection, achat et vente d'armes

1. Ouvrir l'onglet `LOADOUT` du briefing.
2. Sélectionner l'emplacement d'arme principale ou secondaire.
3. Employer la grille vanilla pour équiper une arme possédée ou sélectionner un emplacement vide afin d'en acheter une.
4. Employer l'action vanilla disponible pour vendre une arme éligible.

La dernière arme utilisable d'une catégorie ne peut pas être vendue. Les actions de prévisualisation 3D dangereuses sont désactivées uniquement dans ce contexte de briefing.

### Tenues et gants

1. Ouvrir `BUILD`.
2. Choisir l'entrée vanilla des tenues ou des gants.
3. Équiper un élément déverrouillé avec l'action BlackMarket standard.
4. Revenir au briefing avec l'action Retour normale.

Ces entrées réutilisent le nœud vanilla `loadout` du briefing et son composant `BlackMarketGui`. Les actions de prévisualisation et de personnalisation sont masquées dans ce contexte, car leur scène 3D ou leur nœud imbriqué n'est pas disponible ; les actions d'équipement standard restent présentes. Si Market Favorites est installé et activé, son action d'ajout/retrait, son badge `FAV` et son tri des favoris en tête apparaissent automatiquement. Briefing Enhanced n'appelle pas le namespace de Market Favorites et ne le requiert pas.

### Modifications d'armes

1. Ouvrir `BUILD` → `WEAPON MODIFICATIONS`.
2. Choisir `PRIMARY WEAPON` ou `SECONDARY WEAPON`.
3. Sélectionner une catégorie de modification.
4. Employer les boutons page précédente/suivante si la catégorie contient plusieurs pages.
5. Sélectionner une pièce pour consulter son état, son prix, la quantité possédée et l'aperçu des statistiques.
6. Confirmer `INSTALL` ou `REMOVE` si l'action est disponible.

L'interface modifie l'arme actuellement équipée dans la catégorie choisie.

## Limites actuelles

- Aucune prévisualisation 3D de l'arme n'est créée dans le briefing.
- Les skins, couleurs personnalisées et l'éditeur de skins ne sont pas gérés par le composant 2D.
- Les modifications mécaniques concernent l'arme principale ou secondaire actuellement équipée.
- PD2Builder contrôle la portée de son import ; son import actuel ne remplace pas les armes.
- La compatibilité finale dépend toujours de l'ordre de chargement et du comportement des autres mods qui remplacent des classes d'inventaire PAYDAY 2.

## Compatibilité et sécurité

Le mod conserve les anciens namespaces `BriefingBuildMenu`, IDs de hooks, clés de localisation et IDs de composants pour les mises à jour depuis les versions allant jusqu'à 1.6.1. Le nouveau code utilise le namespace `BriefingEnhanced`.

Briefing Enhanced limite ses modifications d'inventaire au briefing et délègue les opérations économiques aux managers vanilla. Les mods optionnels sont appelés derrière des adaptateurs protégés.

En cas de crash, joindre les derniers fichiers présents dans :

```text
PAYDAY 2/mods/logs/
PAYDAY 2/crash.txt
```

## Développement et contribution

Le code suit la règle « une fonctionnalité, un dossier ». Les hooks raccordent les classes du jeu, les contrôleurs coordonnent les parcours, les services contiennent les règles et transactions, les vues dessinent l'interface et les adaptateurs isolent les mods optionnels.

Lire [TECHNICAL_DOCUMENTATION_Briefing_Build_Menu.md](TECHNICAL_DOCUMENTATION_Briefing_Build_Menu.md) avant de modifier le code. Ce document contient :

- une explication du chargement SuperBLT pour débuter ;
- la carte exacte des hooks et fichiers ;
- les schémas des modules et dépendances ;
- les parcours fonctionnels de bout en bout ;
- les conventions de nommage ;
- des tutoriels d'ajout de fonctionnalités et d'intégrations ;
- une aide au diagnostic et une matrice de tests en jeu.

Avant de proposer une modification :

1. Conserver la compatibilité LuaJIT/Lua 5.1.
2. Valider `mod.txt` comme JSON strict.
3. Préserver les IDs stables ou fournir une migration explicite.
4. Tester les ouvertures et fermetures répétées depuis le briefing.
5. Tester les intégrations optionnelles activées puis désactivées.
6. Vérifier les derniers logs SuperBLT et Diesel.

## Crédits

Créé par **CptTroufion**. Inspiré par l'idée de gérer les écrans liés au build directement depuis le briefing de mission.
