# Briefing Enhanced — Technical Documentation

Version documented: **1.8.1**  
Runtime: **PAYDAY 2 / SuperBLT / LuaJIT (Lua 5.1)**

- [English](#english)
- [Français](#français)

---

# English

## 1. Purpose

Briefing Enhanced adds a `BUILD` entry to the mission briefing. It lets the player manage the current build without leaving the briefing:

- skill tree and perk deck;
- player styles and gloves through the vanilla briefing BlackMarket flow;
- primary and secondary weapon selection;
- weapon purchase, sale and optional drag-and-drop;
- mechanical weapon modifications through a safe 2D interface;
- vanilla weapon statistics and optional More Weapon Stats values;
- optional PD2Builder import and export.

The mod reuses vanilla menus and transactions whenever they are safe in `kit_menu`. It does not open the vanilla 3D weapon workshop from the briefing because `managers.menu_scene` is not guaranteed to exist there.

Recommended learning path for a new modder:

1. Read sections 2 and 3 to understand SuperBLT vocabulary.
2. Follow section 8 from a game `hook_id` to the loaded files.
3. Read section 10 before changing any screen opening or closing code.
4. Use the recipes in section 13 for actual changes.
5. Finish with the test matrix in section 14.

## 2. Beginner mental model: how a PAYDAY 2 mod runs

PAYDAY 2 does not execute every Lua file in a mod at startup. SuperBLT first reads `mod.txt`. Each `hooks` entry tells SuperBLT: **when PAYDAY 2 loads this game script, execute this mod entry file too**.

There are therefore two different loading levels:

```text
PAYDAY 2 loads a game script
  → SuperBLT finds the matching hook_id in mod.txt
  → SuperBLT executes the declared hook_*.lua entry file
  → the entry file loads its own modules with dofile(...)
  → the entry file registers PreHook/PostHook/OverrideFunction callbacks
  → the callback runs later when the hooked game method is called
```

Example for the `BUILD` button:

```text
Game loads lib/managers/menu/missionbriefinggui
  → mod.txt executes lua/briefing_menu/hook_mission_briefing.lua
  → that file loads FactoryBriefingNode, controllers and ViewBriefingButton
  → it registers a PostHook on MissionBriefingGui:init
  → PAYDAY 2 creates the briefing UI and calls init
  → the PostHook creates the BUILD button
```

This distinction is essential when debugging:

- a crash at the top of a `hook_*.lua` file is a **loading or dependency problem**;
- a crash inside a hook callback is a **runtime lifecycle problem**;
- a button that appears but does nothing is usually an **input, node or controller problem**;
- an action that opens the correct UI but changes nothing is usually a **service or game transaction problem**.

## 3. Beginner glossary

| Term | Simple meaning in this mod |
|---|---|
| `mod.txt` | Manifest read by SuperBLT; it declares the mod and its game-script entry points |
| `hook_id` | Path of the PAYDAY 2 game script that triggers a mod entry file |
| `RequiredScript` | Runtime value containing the current game script path; used when one entry file handles several contexts |
| `dofile(path)` | Executes another Lua file; used here to compose internal modules |
| `Hooks:PreHook` | Runs mod code before the original game method |
| `Hooks:PostHook` | Runs mod code after the original game method |
| `Hooks:OverrideFunction` | Wraps/replaces a method; use only when its return value or input handling must change |
| `manager` | Long-lived PAYDAY 2 service available through `managers`, such as `managers.menu` or `managers.blackmarket` |
| menu `node` | Description of a menu screen and the component it must create |
| menu `component` | Runtime UI object that owns panels, input and close behavior |
| `panel` / `workspace` | Diesel UI containers used to draw text, rectangles and bitmaps |
| `blueprint` | List of part IDs currently assembled on a crafted weapon |
| `global_value` | Economic/source variant of an item; it must travel with a weapon part transaction |
| idempotent | Safe to load or install more than once without duplicating hooks or state |
| facade | Compatibility method that forwards an old API to the new implementation |

## 4. Design principles

- **One feature, one folder:** files that change together stay together.
- **KISS:** hook files connect PAYDAY 2 to the feature; business rules remain in small named modules.
- **Single responsibility:** views render, controllers coordinate, services apply rules, adapters isolate optional mods.
- **Vanilla first:** purchases, sales, equipment and part transactions use PAYDAY 2 managers and confirmations.
- **Defensive runtime access:** lifecycle-sensitive objects such as `managers.*`, panels and optional mod globals are checked before use.
- **Idempotent loading:** namespaces and hook installation flags prevent duplicate installation.
- **Backward compatibility:** historical IDs and public entry points remain available through aliases and facades.

## 5. Directory architecture

```text
Briefing Build Menu/
├── mod.txt
├── TECHNICAL_DOCUMENTATION_Briefing_Build_Menu.md
└── lua/
    ├── core/
    ├── briefing_menu/
    ├── skill_tree/
    ├── perk_deck/
    ├── outfit/
    ├── weapon_inventory/
    ├── weapon_modification/
    ├── build_transfer/
    ├── compatibility/
    └── localization/
```

| Folder | Responsibility |
|---|---|
| `core/` | Namespace, constants, session state, navigation, dialogs, outfit synchronization and legacy facade |
| `briefing_menu/` | `BUILD` button, context menu and `kit_menu` node creation |
| `skill_tree/` | Skill tree opening, input restriction and close cleanup |
| `perk_deck/` | Perk deck opening and close cleanup |
| `outfit/` | Builds the vanilla loadout tabs, opens them and removes unsafe outfit actions |
| `weapon_inventory/` | Weapon selection, purchase, sale and Drag and Drop Inventory integration |
| `weapon_modification/` | Part discovery, transactions, 2D component, rendering and statistics |
| `build_transfer/` | Optional PD2Builder loader integration |
| `compatibility/` | EHI and chat adapters |
| `localization/` | English localization strings |

## 6. Component types and naming convention

Names descend from the broad technical role to the feature or nature:

| Prefix | Role | Example |
|---|---|---|
| `Hook` | Connects a PAYDAY 2 class or custom event to the mod | `HookMissionBriefing` |
| `Controller` | Coordinates a user flow | `ControllerWeaponModification` |
| `Service` | Contains reusable rules or mutations | `ServiceWeaponInventory` |
| `Adapter` | Isolates an external or optional mod API | `AdapterMoreWeaponStats` |
| `Component` | Owns UI lifecycle, state and input | `ComponentWeaponModification` |
| `View` | Creates or renders visual elements | `ViewBriefingButton` |
| `Presenter` | Converts game data into display-ready values | `PresenterWeaponStatistics` |
| `State` | Owns explicit runtime state | `StateBriefingSession` |
| `Factory` | Creates and registers objects | `FactoryBriefingNode` |
| `Constants` | Stores stable identifiers and layout constants | `ConstantsBriefingEnhanced` |

File names use lowercase `snake_case` and start with the component type, for example `service_weapon_modification.lua`.

Methods use short action names inside their typed table:

```lua
BriefingEnhanced.ControllerPerkDeck:open()
BriefingEnhanced.ServiceWeaponModification:install(category, part_type, part)
```

Repeating the file or component name in every method is avoided because the owning table already provides that context. Local helpers use explicit verb phrases such as `build_part_data` or `configure_locked_slot`.

Stable identifiers keep their historical `BriefingBuildMenu_*`, `bbm_*` or `briefing_build_menu_*` names. They must not be renamed without a migration because SuperBLT hooks, menu nodes, localization and third-party wrappers may depend on them.

## 7. Namespace and internal loading

`mod.txt` declares each PAYDAY 2 `hook_id` and its entry script. An entry script is loaded only when the corresponding game class is available.

Every feature entry loads `lua/core/bootstrap.lua`. The bootstrap:

1. creates the canonical `BriefingEnhanced` table;
2. aliases `BriefingBuildMenu` to the same table;
3. captures `ModPath` once;
4. loads the core modules once through `_core_loaded`.

Feature hooks then load only their required service, controller, adapter, presenter, component or view files. Hook tables contain installation flags so loading the same routed script in multiple game contexts does not register a hook twice.

## 8. Exact trigger and file map

Start here when you need to know why a file is loaded. The left column is the PAYDAY 2 script. The middle column is the file SuperBLT executes from `mod.txt`.

| PAYDAY 2 trigger (`hook_id`) | Mod entry file | What the entry file loads or installs |
|---|---|---|
| `lib/managers/menu/menucomponentmanager` | `weapon_modification/hook_menu_component.lua` | Loads core and adds create/close methods to `MenuComponentManager` |
| `lib/managers/menu/missionbriefinggui` | `core/hook_bootstrap.lua` | Initializes the shared namespace and core services first |
| `lib/managers/menu/missionbriefinggui` | `weapon_inventory/hook_weapon_inventory.lua` | Loads the inventory service/adapter and hooks `NewLoadoutTab` or `LoadoutItem` |
| `lib/managers/menu/playerinventorygui` | `weapon_inventory/hook_weapon_inventory.lua` | The same entry detects `RequiredScript` and hooks `PlayerInventoryGui` |
| `lib/managers/menu/blackmarketgui` | `weapon_inventory/hook_weapon_inventory.lua` | The same entry hooks BlackMarket population and sale completion |
| `lib/managers/menu/blackmarketgui` | `outfit/hook_outfit.lua` | Removes preview/customization actions only from marked briefing outfit tabs |
| `lib/managers/menu/missionbriefinggui` | `weapon_modification/hook_weapon_modification.lua` | Loads modification service, controller, stats adapter/presenter, component and view |
| `lib/managers/menu/missionbriefinggui` | `build_transfer/hook_build_transfer.lua` | Loads the PD2Builder adapter |
| `lib/managers/menu/missionbriefinggui` | `compatibility/hook_ehi.lua` | Loads the EHI adapter; actual installation waits for the EHI method |
| `lib/managers/menu/missionbriefinggui` | `briefing_menu/hook_mission_briefing.lua` | Loads briefing modules, outfit controller and hooks init/hide/close/mouse methods |
| `lib/managers/menu/skilltreeguinew` | `skill_tree/hook_skill_tree.lua` | Loads the skill controller and hooks legends, special input and close |
| `lib/managers/menu/specializationguinew` | `perk_deck/hook_perk_deck.lua` | Loads the perk controller and hooks close |
| `lib/managers/chatmanager` | `compatibility/hook_chat.lua` | Loads the chat adapter and registers its later menu initialization callback |
| `lib/managers/localizationmanager` | `localization/localization_english.lua` | Registers every `bbm_*` display string |

The order of the `missionbriefinggui` entries is intentional: core and feature classes are loaded before `hook_mission_briefing.lua` creates the button that can call them.

### Internal load chain by feature

```text
BUILD menu
hook_mission_briefing
  ├─ factory_briefing_node
  ├─ controller_briefing_menu
  ├─ view_briefing_button
  ├─ controller_skill_tree
  ├─ controller_outfit
  └─ controller_perk_deck

Weapon inventory
hook_weapon_inventory
  ├─ adapter_drag_drop_inventory
  └─ service_weapon_inventory

Weapon modification
hook_weapon_modification
  ├─ service_weapon_modification
  ├─ controller_weapon_modification
  ├─ adapter_more_weapon_stats
  ├─ presenter_weapon_statistics
  ├─ component_weapon_modification
  └─ view_weapon_modification

Every chain above
  └─ core/bootstrap
       ├─ constants_briefing_enhanced
       ├─ service_outfit
       ├─ service_dialog
       ├─ state_briefing_session
       ├─ controller_menu_navigation
       └─ facade_legacy
```

## 9. Dependencies

### Required dependencies

| Dependency | Why it is required |
|---|---|
| PAYDAY 2 | Provides the menu, BlackMarket, weapon factory and UI classes |
| SuperBLT | Reads `mod.txt`, provides `Hooks`, `QuickMenu` and the mod runtime |
| LuaJIT / Lua 5.1 syntax | PAYDAY 2's Lua runtime; Lua 5.2+ syntax is invalid |

BeardLib is **not** required by the current architecture.

### Optional integrations

| Optional mod/API | Detection | Feature enabled | Safe fallback |
|---|---|---|---|
| Drag and Drop Inventory | Enabled BLT mod plus `DragDropInventory` and required manager methods | Move/swap actions in weapon grids | Normal equip, purchase and sale remain |
| More Weapon Stats | Enabled BLT mod plus initialized `MoreWeaponStats` and `Faker` APIs | Extra statistic rows | Vanilla statistics remain |
| PD2Builder loader | Enabled BLT mod plus `BuilderLoader.load_build` and `upload_build` | Import/Export entries | Entries are hidden |
| Market Favorites | Its independent `BlackMarketGui` hooks are active | Favorite actions, `FAV` badges and sorting in reused weapon, player-style and glove grids | Vanilla BlackMarket grids |
| EHI | Runtime presence of `MissionBriefingGui.AddXPBreakdown` | Hides/restores EHI briefing elements | No EHI-specific action |
| Chat translator API | Runtime presence of `ChatTranslatorMessage` | Translation request for received messages | Normal chat remains |

An adapter must treat a missing optional dependency as a normal state, never as an error. Do not call an optional mod global directly from a controller, service or view.

### Dependency direction rule

Dependencies should flow in one direction:

```text
PAYDAY 2 hook → Controller → Service → PAYDAY 2 manager
                         ↘ Presenter → View
Optional mod hook/API → Adapter ───────↗
```

A service must not know how a button is drawn. A view must not directly buy, sell or install an item. This separation makes it possible to change one layer without rewriting the others.

## 10. Briefing session lifecycle

`StateBriefingSession` is the shared lifecycle boundary for custom nodes and build editors opened from the briefing.

```text
User selects an option
  → ControllerMenuNavigation:open
  → StateBriefingSession:begin
  → save previous outfit-block value
  → open the kit_menu node
  → user changes the build
  → vanilla/custom component closes
  → StateBriefingSession:finish
  → restore previous block value
  → refresh outfit information
```

While a screen is open, `Global.block_update_outfit_information` prevents the briefing from updating an incomplete intermediate loadout. Its previous value is stored and restored exactly. Opening failures reset the session immediately. A legacy `opened_from_briefing` value can also be adopted during a SuperBLT reload.

The player-style and glove entries are an intentional exception. The briefing owns a `MissionBriefingGui` and `NewLoadoutTab`, not a `PlayerInventoryGui`. `ControllerOutfit` opens the existing vanilla `loadout` node in `kit_menu`, so its transition and Back navigation remain authoritative. Starting a second `StateBriefingSession` around that flow would duplicate its lifecycle and could block outfit publication.

## 11. Feature flows

### 11.1 BUILD button

1. `MissionBriefingGui:init` is post-hooked.
2. `FactoryBriefingNode:ensure_all()` registers the mod nodes in the active `kit_menu`.
3. `ViewBriefingButton:create()` removes the replaced legacy button and creates `BUILD`.
4. The mouse overrides consume input only when the pointer is on this button.
5. `ControllerBriefingMenu:show()` opens a `QuickMenu` containing available features.

Files traversed: `hook_mission_briefing.lua` → `factory_briefing_node.lua` / `view_briefing_button.lua` → `controller_briefing_menu.lua`.

### 11.2 Skill tree and perk deck

The controllers ensure the nodes exist, begin a briefing session and open the vanilla menu components:

- `skilltree_new` creates `NewSkillTreeGui`;
- `skilltree` creates `SpecializationGuiNew` in the current game version.

The skill-set switch is disabled only when the skill tree was opened from the briefing. Closing either screen ends the matching session and synchronizes the current outfit.

Skill tree call chain:

```text
ControllerBriefingMenu option
  → ControllerSkillTree:open                         (controller_skill_tree.lua)
  → FactoryBriefingNode:ensure_all                   (factory_briefing_node.lua)
  → ControllerMenuNavigation:open("skilltree", ...)  (controller_menu_navigation.lua)
  → managers.menu:open_node
  → NewSkillTreeGui
  → close PostHook                                   (hook_skill_tree.lua)
  → StateBriefingSession:finish
```

The perk deck follows the same chain through `controller_perk_deck.lua`, `SpecializationGuiNew` and `hook_perk_deck.lua`.

### 11.3 Player styles and gloves

`ControllerBriefingMenu` exposes separate player-style and glove entries using the game's localized labels. `ServiceOutfitMenu` creates two standard BlackMarket tab definitions using `populate_player_styles` and `populate_gloves`; `ControllerOutfit` selects tab 1 or 2 and opens the existing `loadout` node.

The reused `BlackMarketGui` retains vanilla cell population and equip callbacks. The marked context removes `trd_preview`, `trd_customize`, `hnd_preview` and BeardLib's `hnd_customize`, because those actions require the unavailable 3D preview path or an outfit customization node outside `kit_menu`. Equip, DLC and favorite actions remain available.

Market Favorites integration is passive and optional. When installed, its existing hooks on `populate_player_styles` and `populate_gloves` decorate these reused grids automatically. Briefing Enhanced neither detects Market Favorites nor calls its namespace, so either mod remains usable alone.

### 11.4 Weapon selection, purchase and sale

The inventory feature is enabled only when the active menu is `kit_menu` and the internal context targets `primaries` or `secondaries`.

1. `PlayerInventoryGui`, `NewLoadoutTab` or legacy `LoadoutItem` identifies the selected category.
2. `ServiceWeaponInventory` enables the appropriate vanilla actions.
3. Empty unlocked slots receive `ew_buy`; locked slots receive `ew_unlock` when affordable.
4. Owned weapons receive equip and sale actions while protecting the last usable weapon.
5. `BlackMarketGui` keeps vanilla lists, prices, DLC locks and confirmations.
6. Unsafe 3D preview actions are removed in this briefing-only context.
7. After a sale, outfit information is synchronized.

The same `hook_weapon_inventory.lua` is deliberately registered for three game scripts. `RequiredScript` selects only the matching branch: briefing/loadout creation, `PlayerInventoryGui` category selection, or `BlackMarketGui` action population. All action rules are centralized in `service_weapon_inventory.lua`; the hook should only collect context and pass game data to that service.

### 11.5 Drag and Drop Inventory

`AdapterDragDropInventory` exposes the integration only when the dependency is installed, enabled and all required APIs exist. The mod then lets the dependency perform pickup, placement and profile-safe swaps. Briefing Enhanced does not duplicate its permutation logic. Without the dependency, purchase and sale remain available.

The adapter is loaded by `hook_weapon_inventory.lua`. `ServiceWeaponInventory` asks `AdapterDragDropInventory:is_available()` while building actions. When available, the hook removes the loadout-only marker from the briefing weapon node so the dependency's existing handlers can process the grid.

### 11.6 Weapon modifications

Weapon modifications use a dedicated 2D component registered on `MenuComponentManager`.

1. The user chooses the equipped primary or secondary weapon.
2. `ControllerWeaponModification` opens the custom `kit_menu` node.
3. `ServiceWeaponModification` reads the equipped crafted weapon and calls `get_dropable_mods_by_weapon_id` once per refresh.
4. It groups compatible parts by type and preserves each part's `global_value`, inventory amount, price, conflict, default and cosmetic state.
5. `ComponentWeaponModification` owns selection, tabs, pages, mouse/controller input and refreshes.
6. `View` methods render the grid, part details and statistics without a 3D preview.
7. Installation or removal uses the vanilla confirmation and BlackMarket transaction methods.
8. The blueprint is read again after the mutation. A failed or rejected change displays an error instead of assuming success.
9. The outfit and UI are refreshed.

UI creation has two separate entry moments. `hook_menu_component.lua` runs when `MenuComponentManager` exists and declares the create/close callbacks. Later, `hook_weapon_modification.lua` runs with the briefing and loads the actual component class. `FactoryBriefingNode` connects both using the stable component ID. This split prevents callbacks from referencing a manager method that has not been declared yet.

The component is registered under the historical `bbm_weapon_modifications` ID. Legacy manager methods and the `BriefingWeaponModificationsGui` global remain aliases for compatibility.

### 11.7 Weapon statistics

`PresenterWeaponStatistics` builds preview data without changing the real blueprint. Vanilla `TOTAL / BASE / MOD / SKILL` values come from `WeaponDescription._get_stats`.

`AdapterMoreWeaponStats` is used only if More Weapon Stats is installed, enabled and fully initialized. Its optional rows are calculated through its `Faker` API. If any required API is unavailable, the UI remains functional with vanilla statistics only.

Data path: selected part in `ComponentWeaponModification` → `PresenterWeaponStatistics:get_data()` → vanilla `WeaponDescription._get_stats` plus optional `AdapterMoreWeaponStats:get_rows()` → rendering in `view_weapon_modification.lua`.

### 11.8 PD2Builder

`AdapterPd2Builder` checks that **PD2Builder loader** is enabled and that `BuilderLoader` exposes the expected methods. Import and Export appear in the `BUILD` menu only when those checks pass. A post-hook on `BuilderLoader:set_build` refreshes outfit information after an import.

`hook_build_transfer.lua` only loads the adapter. `ControllerBriefingMenu` performs the availability check when building the QuickMenu, so enabling/disabling the dependency changes whether the entries are displayed without duplicating the menu logic.

### 11.9 EHI and chat

- `AdapterEhi` detects EHI's late-added XP breakdown method, surrounds it with pre/post hooks and temporarily hides the captured elements while a build screen is open.
- `AdapterChat` preserves access to chat inside the custom flow and optionally requests translation when the relevant translator API exists.

Both adapters are optional and idempotent.

## 12. Compatibility policy

The displayed name is **Briefing Enhanced**, but the physical folder remains `Briefing Build Menu` to avoid breaking existing installations.

The following compatibility surfaces are intentionally retained:

- `BriefingBuildMenu` namespace alias;
- historical hook IDs and localization keys;
- historical node and component IDs;
- methods marked `Compatibility facade`;
- `BriefingWeaponModificationsGui`;
- `create_bbm_weapon_modifications` and `close_bbm_weapon_modifications`.

New code should use `BriefingEnhanced` and the typed modules. Compatibility facades should contain delegation only, not new business logic.

## 13. How to evolve the mod

### 13.1 Find the correct starting file

| Desired change | Start reading here | Usually also change |
|---|---|---|
| Add or reorder a BUILD option | `briefing_menu/controller_briefing_menu.lua` | Localization and possibly a new controller |
| Change BUILD button appearance/position | `briefing_menu/view_briefing_button.lua` | Shared constants if the value is reused |
| Add a menu node | `briefing_menu/factory_briefing_node.lua` | Controller that opens it and component create/close methods |
| Change open/close behavior | `core/state_briefing_session.lua` and `controller_menu_navigation.lua` | Matching feature close hook |
| Change weapon purchase/sale rules | `weapon_inventory/service_weapon_inventory.lua` | Its routed hook only if another game method is required |
| Change part availability or transactions | `weapon_modification/service_weapon_modification.lua` | Controller/component only if the interaction changes |
| Change modification screen layout | `weapon_modification/view_weapon_modification.lua` | Component for new input/state |
| Add a displayed statistic | `weapon_modification/presenter_weapon_statistics.lua` | View columns/rows or optional adapter |
| Integrate another mod | A new `adapter_<mod>.lua` in the owning feature | Entry hook and availability check |
| Add displayed text | `localization/localization_english.lua` | Use a new stable `bbm_*` key in the consumer |

### 13.2 Recipe: add a new option to BUILD

Suppose a new feature must open a custom screen.

1. Create `lua/<feature>/controller_<feature>.lua`.
2. Define `BriefingEnhanced.ControllerFeature = ... or {}` and an `open()` method.
3. If a menu node is required, add a stable node ID to `ConstantsBriefingEnhanced.NODE_NAMES`.
4. Register the node in `FactoryBriefingNode:ensure_all()`.
5. Make `open()` call `ControllerMenuNavigation:open(screen_name, node_name)` so session cleanup stays centralized.
6. Load the controller from a suitable `hook_<feature>.lua` or before `controller_briefing_menu.lua` uses it.
7. Add the option callback in `ControllerBriefingMenu:show()`.
8. Add its English `bbm_*` localization key.
9. Ensure the component or vanilla screen calls `StateBriefingSession:finish(screen_name)` when it closes.
10. Test open, back, repeated open and forced briefing close.

Do not call `managers.menu:open_node` directly from the QuickMenu callback. Going through `ControllerMenuNavigation` prevents a failed opening from leaving BUILD locked.

### 13.3 Recipe: add a new optional integration

1. Place all third-party API knowledge in `adapter_<mod>.lua`.
2. Implement `is_available()` using both the BLT enabled state and the exact globals/methods needed.
3. Make every adapter public method harmless when unavailable.
4. Load the adapter before the controller/view that may call it.
5. Keep the base feature usable without the dependency.
6. Test four cases: absent, installed but disabled, enabled but not initialized yet, fully available.

Do not cache “unavailable” permanently when another mod may initialize later. EHI is the reference for a retryable late API; PD2Builder is the reference for an enabled BLT mod check.

### 13.4 Recipe: add UI state or interaction

1. Store selection/page/input state in `ComponentWeaponModification`.
2. Add a small method that changes that state and returns `true` only when the input was consumed.
3. Let the component call `_rebuild()` after a visible state change.
4. Draw the result in `view_weapon_modification.lua`.
5. Keep economic mutations in `ServiceWeaponModification`.
6. Check `alive(panel)` for objects that may have been destroyed during menu transitions.

### 13.5 Recipe: hook another PAYDAY 2 class

1. Find the current decompiled PAYDAY 2 method and verify its parameters and return value.
2. Add its game script path as a `hook_id` in `mod.txt`.
3. Create or reuse a `hook_<feature>.lua` entry file.
4. Load core first, then only the modules required by that context.
5. Prefer `PostHook` for reacting after vanilla work and `PreHook` for preparing data before it.
6. Use `OverrideFunction` only if input must be consumed or the original return value must be changed; save and call `Hooks:GetFunction` for all other cases.
7. Give the hook a globally unique, stable ID.
8. Guard installation with a feature hook flag if the entry can load more than once.

### 13.6 Safe change checklist

Before editing:

- follow `mod.txt` from the relevant `hook_id` to the entry file;
- identify which layer owns the behavior;
- inspect the vanilla method and any local mod that hooks the same method.

While editing:

- use Lua 5.1 syntax;
- preserve `ModPath` in a local or in `BriefingEnhanced.ModPath` before deferred callbacks;
- protect lifecycle-sensitive objects;
- keep optional dependencies behind adapters;
- preserve historical IDs unless a migration is explicitly implemented;
- never add feature code to `base/`, BeardLib or another mod.

After editing:

- validate `mod.txt` as strict JSON;
- check that every `script_path` and `dofile` target exists;
- search for duplicate hook IDs and temporary debug logs;
- test the feature with all optional integrations enabled and disabled;
- read the newest SuperBLT and Diesel crash logs.

### 13.7 Debugging by symptom

| Symptom | First files/objects to inspect |
|---|---|
| The mod never loads | `mod.txt`, matching `hook_id`, entry `script_path`, SuperBLT log |
| BUILD does not appear | `hook_mission_briefing.lua`, `MissionBriefingGui:init`, `ViewBriefingButton` |
| BUILD appears but cannot be clicked | mouse overrides, button bounds, `gui._enabled`, blackscreen guard |
| An option shows `ERROR: <ID>` | `localization_english.lua` and the exact `bbm_*` key |
| A screen does not open | `FactoryBriefingNode`, active `kit_menu`, `ControllerMenuNavigation` |
| BUILD stays blocked after Back | matching close hook, `StateBriefingSession:finish`, component close callback |
| A weapon part is listed but not installed | service transaction arguments, `global_value`, availability and post-transaction blueprint |
| Weapon workshop crashes on `menu_scene` | a 3D preview/crafting path was entered from briefing; keep the custom 2D path |
| Feature works only with another mod enabled | adapter boundary or an unguarded third-party global is missing |

## 14. Minimum in-game test matrix

- Start the game and enter a lobby without errors.
- Open and close `BUILD` repeatedly.
- Open skill tree and perk deck, apply a change and return.
- Open player styles and gloves from `BUILD`, equip an item, return and repeat.
- Repeat the player-style and glove test with Market Favorites enabled and disabled.
- Equip, buy and sell primary and secondary weapons.
- Repeat inventory tests with Drag and Drop Inventory enabled and disabled.
- Install, replace and remove weapon parts; test pagination and controller/mouse input.
- Repeat statistics tests with More Weapon Stats enabled and disabled.
- Repeat build transfer tests with PD2Builder enabled and disabled.
- Return to the main menu, re-enter a lobby and verify that BUILD and outfit updates still work.
- Read the latest SuperBLT log and Diesel crash log after testing.

---

# Français

## 1. Objectif

Briefing Enhanced ajoute une entrée `BUILD` au briefing de mission. Elle permet de gérer le build courant sans quitter le briefing :

- arbre de compétences et perk deck ;
- tenues et gants via le parcours BlackMarket vanilla du briefing ;
- sélection des armes principale et secondaire ;
- achat, vente et glisser-déposer optionnel des armes ;
- modifications mécaniques des armes dans une interface 2D sûre ;
- statistiques vanilla et valeurs optionnelles de More Weapon Stats ;
- import et export optionnels avec PD2Builder.

Le mod réutilise les menus et transactions vanilla lorsqu'ils sont sûrs dans `kit_menu`. Il n'ouvre pas l'atelier 3D vanilla depuis le briefing, car `managers.menu_scene` n'y est pas garanti.

Parcours de lecture conseillé pour un modeur débutant :

1. Lire les sections 2 et 3 pour comprendre le vocabulaire SuperBLT.
2. Suivre la section 8 depuis un `hook_id` du jeu jusqu'aux fichiers chargés.
3. Lire la section 10 avant de modifier l'ouverture ou la fermeture d'un écran.
4. Utiliser les tutoriels de la section 13 pour réaliser une évolution.
5. Terminer par la matrice de tests de la section 14.

## 2. Modèle mental pour débuter : comment un mod PAYDAY 2 s'exécute

PAYDAY 2 n'exécute pas tous les fichiers Lua d'un mod au démarrage. SuperBLT lit d'abord `mod.txt`. Chaque entrée de `hooks` signifie : **lorsque PAYDAY 2 charge ce script du jeu, exécuter aussi ce fichier d'entrée du mod**.

Il existe donc deux niveaux de chargement différents :

```text
PAYDAY 2 charge un script du jeu
  → SuperBLT trouve le hook_id correspondant dans mod.txt
  → SuperBLT exécute le fichier hook_*.lua déclaré
  → ce fichier charge ses modules avec dofile(...)
  → il enregistre des callbacks PreHook/PostHook/OverrideFunction
  → ces callbacks s'exécutent plus tard quand la méthode du jeu est appelée
```

Exemple du bouton `BUILD` :

```text
Le jeu charge lib/managers/menu/missionbriefinggui
  → mod.txt exécute lua/briefing_menu/hook_mission_briefing.lua
  → ce fichier charge FactoryBriefingNode, les contrôleurs et ViewBriefingButton
  → il enregistre un PostHook sur MissionBriefingGui:init
  → PAYDAY 2 crée le briefing et appelle init
  → le PostHook crée le bouton BUILD
```

Cette distinction est essentielle pour diagnostiquer un problème :

- un crash en haut d'un fichier `hook_*.lua` indique un **problème de chargement ou de dépendance** ;
- un crash dans le callback d'un hook indique un **problème de cycle de vie runtime** ;
- un bouton visible mais sans effet indique souvent un **problème d'entrée, de nœud ou de contrôleur** ;
- la bonne UI qui ne modifie rien indique souvent un **problème de service ou de transaction du jeu**.

## 3. Glossaire pour débuter

| Terme | Signification simple dans ce mod |
|---|---|
| `mod.txt` | Manifeste lu par SuperBLT ; il déclare le mod et ses points d'entrée dans les scripts du jeu |
| `hook_id` | Chemin du script PAYDAY 2 qui déclenche un fichier d'entrée du mod |
| `RequiredScript` | Valeur runtime contenant le script de jeu courant ; utilisée lorsqu'une même entrée gère plusieurs contextes |
| `dofile(path)` | Exécute un autre fichier Lua ; utilisé ici pour composer les modules internes |
| `Hooks:PreHook` | Exécute le code du mod avant la méthode originale |
| `Hooks:PostHook` | Exécute le code du mod après la méthode originale |
| `Hooks:OverrideFunction` | Entoure/remplace une méthode ; à réserver au changement de retour ou à la consommation d'une entrée |
| `manager` | Service PAYDAY 2 durable accessible dans `managers`, comme `managers.menu` ou `managers.blackmarket` |
| `node` de menu | Description d'un écran et du composant qu'il doit créer |
| `component` de menu | Objet UI runtime qui possède les panels, les entrées et la fermeture |
| `panel` / `workspace` | Conteneurs UI Diesel utilisés pour dessiner textes, rectangles et images |
| `blueprint` | Liste des IDs de pièces assemblées sur une arme fabriquée |
| `global_value` | Variante économique/origine d'un objet ; elle doit accompagner une transaction de pièce |
| idempotent | Peut être chargé ou installé plusieurs fois sans dupliquer les hooks ou l'état |
| façade | Méthode de compatibilité qui redirige une ancienne API vers la nouvelle implémentation |

## 4. Principes de conception

- **Une fonctionnalité, un dossier :** les fichiers qui évoluent ensemble restent regroupés.
- **KISS :** les hooks raccordent PAYDAY 2 à la fonctionnalité ; les règles restent dans des modules nommés et limités.
- **Responsabilité unique :** les vues dessinent, les contrôleurs coordonnent, les services appliquent les règles et les adaptateurs isolent les mods optionnels.
- **Vanilla en priorité :** achats, ventes, équipements et transactions de pièces passent par les managers et confirmations de PAYDAY 2.
- **Accès défensif :** les `managers.*`, panels et globals de mods optionnels dépendants du cycle de vie sont vérifiés avant utilisation.
- **Chargement idempotent :** namespaces et drapeaux empêchent l'installation multiple des hooks.
- **Rétrocompatibilité :** les anciens IDs et points d'entrée publics sont conservés par des alias et façades.

## 5. Architecture des dossiers

```text
Briefing Build Menu/
├── mod.txt
├── TECHNICAL_DOCUMENTATION_Briefing_Build_Menu.md
└── lua/
    ├── core/
    ├── briefing_menu/
    ├── skill_tree/
    ├── perk_deck/
    ├── outfit/
    ├── weapon_inventory/
    ├── weapon_modification/
    ├── build_transfer/
    ├── compatibility/
    └── localization/
```

| Dossier | Responsabilité |
|---|---|
| `core/` | Namespace, constantes, session, navigation, dialogues, synchronisation d'outfit et façade historique |
| `briefing_menu/` | Bouton `BUILD`, menu contextuel et création des nœuds du `kit_menu` |
| `skill_tree/` | Ouverture, restriction des entrées et nettoyage de l'arbre de compétences |
| `perk_deck/` | Ouverture et nettoyage du menu des perk decks |
| `outfit/` | Construit et ouvre les onglets vanilla du loadout, puis retire les actions dangereuses |
| `weapon_inventory/` | Sélection, achat, vente et intégration de Drag and Drop Inventory |
| `weapon_modification/` | Recherche des pièces, transactions, composant 2D, rendu et statistiques |
| `build_transfer/` | Intégration optionnelle de PD2Builder loader |
| `compatibility/` | Adaptateurs EHI et chat |
| `localization/` | Textes anglais affichés par le mod |

## 6. Types de composants et convention de nommage

Les noms descendent du rôle technique général vers la fonctionnalité ou la nature :

| Préfixe | Rôle | Exemple |
|---|---|---|
| `Hook` | Raccorde une classe PAYDAY 2 ou un événement au mod | `HookMissionBriefing` |
| `Controller` | Coordonne un parcours utilisateur | `ControllerWeaponModification` |
| `Service` | Contient des règles ou mutations réutilisables | `ServiceWeaponInventory` |
| `Adapter` | Isole l'API d'un mod externe ou optionnel | `AdapterMoreWeaponStats` |
| `Component` | Possède le cycle de vie, l'état et les entrées d'une UI | `ComponentWeaponModification` |
| `View` | Crée ou dessine des éléments visuels | `ViewBriefingButton` |
| `Presenter` | Transforme les données du jeu en valeurs affichables | `PresenterWeaponStatistics` |
| `State` | Possède un état runtime explicite | `StateBriefingSession` |
| `Factory` | Crée et enregistre des objets | `FactoryBriefingNode` |
| `Constants` | Conserve les identifiants stables et constantes de mise en page | `ConstantsBriefingEnhanced` |

Les fichiers utilisent le `snake_case` minuscule et commencent par le type du composant, par exemple `service_weapon_modification.lua`.

Dans une table déjà typée, les méthodes utilisent des actions courtes :

```lua
BriefingEnhanced.ControllerPerkDeck:open()
BriefingEnhanced.ServiceWeaponModification:install(category, part_type, part)
```

Le nom du fichier n'est pas répété dans chaque méthode, car la table propriétaire donne déjà ce contexte. Les fonctions locales utilisent des actions explicites comme `build_part_data` ou `configure_locked_slot`.

Les identifiants stables conservent leurs noms historiques `BriefingBuildMenu_*`, `bbm_*` ou `briefing_build_menu_*`. Ils ne doivent pas être renommés sans migration : les hooks SuperBLT, nœuds, localisations ou wrappers tiers peuvent en dépendre.

## 7. Namespace et chargement interne

`mod.txt` déclare chaque `hook_id` PAYDAY 2 et son script d'entrée. Un script n'est chargé que lorsque la classe de jeu correspondante est disponible.

Chaque entrée charge `lua/core/bootstrap.lua`. Le bootstrap :

1. crée la table canonique `BriefingEnhanced` ;
2. fait pointer `BriefingBuildMenu` vers la même table ;
3. capture `ModPath` une seule fois ;
4. charge les modules du noyau une seule fois avec `_core_loaded`.

Les hooks de fonctionnalité chargent ensuite uniquement leurs services, contrôleurs, adaptateurs, presenters, composants ou vues. Leurs tables possèdent des drapeaux d'installation afin qu'un script routé dans plusieurs contextes n'enregistre pas deux fois ses hooks.

## 8. Carte exacte des déclencheurs et fichiers

Commencez ici pour comprendre pourquoi un fichier est chargé. La colonne de gauche est le script PAYDAY 2. Celle du milieu est le fichier que SuperBLT exécute depuis `mod.txt`.

| Déclencheur PAYDAY 2 (`hook_id`) | Fichier d'entrée du mod | Chargement ou installation effectuée |
|---|---|---|
| `lib/managers/menu/menucomponentmanager` | `weapon_modification/hook_menu_component.lua` | Charge le noyau et ajoute les méthodes create/close à `MenuComponentManager` |
| `lib/managers/menu/missionbriefinggui` | `core/hook_bootstrap.lua` | Initialise en premier le namespace et les services partagés |
| `lib/managers/menu/missionbriefinggui` | `weapon_inventory/hook_weapon_inventory.lua` | Charge le service/adaptateur d'inventaire et hooke `NewLoadoutTab` ou `LoadoutItem` |
| `lib/managers/menu/playerinventorygui` | `weapon_inventory/hook_weapon_inventory.lua` | La même entrée détecte `RequiredScript` et hooke `PlayerInventoryGui` |
| `lib/managers/menu/blackmarketgui` | `weapon_inventory/hook_weapon_inventory.lua` | La même entrée hooke le remplissage BlackMarket et la fin d'une vente |
| `lib/managers/menu/blackmarketgui` | `outfit/hook_outfit.lua` | Retire prévisualisation/personnalisation seulement des onglets de tenue marqués du briefing |
| `lib/managers/menu/missionbriefinggui` | `weapon_modification/hook_weapon_modification.lua` | Charge service, contrôleur, adaptateur/presenter de statistiques, composant et vue |
| `lib/managers/menu/missionbriefinggui` | `build_transfer/hook_build_transfer.lua` | Charge l'adaptateur PD2Builder |
| `lib/managers/menu/missionbriefinggui` | `compatibility/hook_ehi.lua` | Charge l'adaptateur EHI ; l'installation réelle attend la méthode EHI |
| `lib/managers/menu/missionbriefinggui` | `briefing_menu/hook_mission_briefing.lua` | Charge le briefing, le contrôleur de tenue et hooke init/hide/close ainsi que la souris |
| `lib/managers/menu/skilltreeguinew` | `skill_tree/hook_skill_tree.lua` | Charge le contrôleur et hooke légendes, entrée spéciale et fermeture |
| `lib/managers/menu/specializationguinew` | `perk_deck/hook_perk_deck.lua` | Charge le contrôleur de perk deck et hooke la fermeture |
| `lib/managers/chatmanager` | `compatibility/hook_chat.lua` | Charge l'adaptateur de chat et enregistre son callback d'initialisation du menu |
| `lib/managers/localizationmanager` | `localization/localization_english.lua` | Enregistre tous les textes `bbm_*` |

L'ordre des entrées `missionbriefinggui` est volontaire : le noyau et les classes des fonctionnalités sont chargés avant que `hook_mission_briefing.lua` crée le bouton capable de les appeler.

### Chaîne de chargement interne par fonctionnalité

```text
Menu BUILD
hook_mission_briefing
  ├─ factory_briefing_node
  ├─ controller_briefing_menu
  ├─ view_briefing_button
  ├─ controller_skill_tree
  ├─ controller_outfit
  └─ controller_perk_deck

Inventaire des armes
hook_weapon_inventory
  ├─ adapter_drag_drop_inventory
  └─ service_weapon_inventory

Modification des armes
hook_weapon_modification
  ├─ service_weapon_modification
  ├─ controller_weapon_modification
  ├─ adapter_more_weapon_stats
  ├─ presenter_weapon_statistics
  ├─ component_weapon_modification
  └─ view_weapon_modification

Chaque chaîne ci-dessus
  └─ core/bootstrap
       ├─ constants_briefing_enhanced
       ├─ service_outfit
       ├─ service_dialog
       ├─ state_briefing_session
       ├─ controller_menu_navigation
       └─ facade_legacy
```

## 9. Dépendances

### Dépendances obligatoires

| Dépendance | Pourquoi elle est nécessaire |
|---|---|
| PAYDAY 2 | Fournit les classes de menus, BlackMarket, weapon factory et UI |
| SuperBLT | Lit `mod.txt` et fournit `Hooks`, `QuickMenu` ainsi que le runtime du mod |
| Syntaxe LuaJIT / Lua 5.1 | Runtime Lua de PAYDAY 2 ; la syntaxe Lua 5.2+ est invalide |

BeardLib n'est **pas** requis par l'architecture actuelle.

### Intégrations optionnelles

| Mod/API optionnel | Détection | Fonction activée | Repli sûr |
|---|---|---|---|
| Drag and Drop Inventory | Mod BLT activé, global `DragDropInventory` et méthodes de managers requises | Déplacement/permutation dans les grilles d'armes | Équipement, achat et vente normaux |
| More Weapon Stats | Mod BLT activé et API `MoreWeaponStats`/`Faker` initialisées | Lignes de statistiques supplémentaires | Statistiques vanilla |
| PD2Builder loader | Mod BLT activé et méthodes `BuilderLoader.load_build`/`upload_build` | Entrées Import/Export | Entrées masquées |
| Market Favorites | Ses hooks `BlackMarketGui` autonomes sont actifs | Actions de favori, badges `FAV` et tri dans les grilles réutilisées des armes, tenues et gants | Grilles BlackMarket vanilla |
| EHI | Présence runtime de `MissionBriefingGui.AddXPBreakdown` | Masquage/restauration des éléments EHI | Aucune action propre à EHI |
| API de traduction du chat | Présence runtime de `ChatTranslatorMessage` | Demande de traduction des messages reçus | Chat normal |

Un adaptateur doit considérer l'absence d'une dépendance optionnelle comme un état normal, jamais comme une erreur. Ne pas appeler directement un global de mod optionnel depuis un contrôleur, service ou une vue.

### Règle de direction des dépendances

Les dépendances doivent suivre un seul sens :

```text
Hook PAYDAY 2 → Controller → Service → manager PAYDAY 2
                            ↘ Presenter → View
Hook/API d'un mod optionnel → Adapter ───↗
```

Un service ne doit pas savoir comment un bouton est dessiné. Une vue ne doit pas acheter, vendre ou installer directement un objet. Cette séparation permet de modifier une couche sans réécrire les autres.

## 10. Cycle de vie d'une session de briefing

`StateBriefingSession` délimite les nœuds custom et éditeurs de build ouverts depuis le briefing.

```text
L'utilisateur sélectionne une option
  → ControllerMenuNavigation:open
  → StateBriefingSession:begin
  → sauvegarde de l'ancien blocage d'outfit
  → ouverture du nœud dans kit_menu
  → modification du build
  → fermeture du composant vanilla/custom
  → StateBriefingSession:finish
  → restauration du blocage précédent
  → mise à jour des informations d'outfit
```

Pendant l'ouverture, `Global.block_update_outfit_information` empêche le briefing de publier un loadout intermédiaire incomplet. Sa valeur précédente est mémorisée puis restaurée exactement. Un échec d'ouverture réinitialise immédiatement la session. Une ancienne valeur `opened_from_briefing` peut aussi être reprise après un rechargement SuperBLT.

Les entrées de tenue et de gants constituent une exception volontaire. Le briefing possède un `MissionBriefingGui` et un `NewLoadoutTab`, pas un `PlayerInventoryGui`. `ControllerOutfit` ouvre le nœud vanilla `loadout` déjà présent dans le `kit_menu` : sa transition et son Retour restent donc autoritaires. Démarrer une seconde `StateBriefingSession` autour de ce parcours doublerait son cycle de vie et pourrait bloquer la publication de l'outfit.

## 11. Parcours des fonctionnalités

### 11.1 Bouton BUILD

1. `MissionBriefingGui:init` est post-hooké.
2. `FactoryBriefingNode:ensure_all()` enregistre les nœuds du mod dans le `kit_menu` actif.
3. `ViewBriefingButton:create()` retire l'ancien bouton remplacé et crée `BUILD`.
4. Les overrides souris ne consomment l'entrée que lorsque le pointeur se trouve sur ce bouton.
5. `ControllerBriefingMenu:show()` ouvre un `QuickMenu` contenant les fonctionnalités disponibles.

Fichiers traversés : `hook_mission_briefing.lua` → `factory_briefing_node.lua` / `view_briefing_button.lua` → `controller_briefing_menu.lua`.

### 11.2 Arbre de compétences et perk deck

Les contrôleurs vérifient les nœuds, commencent une session puis ouvrent les composants vanilla :

- `skilltree_new` crée `NewSkillTreeGui` ;
- `skilltree` crée `SpecializationGuiNew` dans la version actuelle du jeu.

Le changement de skill set est bloqué uniquement lorsque l'arbre a été ouvert depuis le briefing. La fermeture de chaque écran termine la session correspondante et synchronise l'outfit courant.

Chaîne d'appel de l'arbre de compétences :

```text
Option de ControllerBriefingMenu
  → ControllerSkillTree:open                         (controller_skill_tree.lua)
  → FactoryBriefingNode:ensure_all                   (factory_briefing_node.lua)
  → ControllerMenuNavigation:open("skilltree", ...)  (controller_menu_navigation.lua)
  → managers.menu:open_node
  → NewSkillTreeGui
  → PostHook de close                                (hook_skill_tree.lua)
  → StateBriefingSession:finish
```

Le perk deck suit la même chaîne avec `controller_perk_deck.lua`, `SpecializationGuiNew` et `hook_perk_deck.lua`.

### 11.3 Tenues et gants

`ControllerBriefingMenu` expose deux entrées distinctes avec les libellés localisés du jeu. `ServiceOutfitMenu` crée deux définitions d'onglets BlackMarket standard avec `populate_player_styles` et `populate_gloves` ; `ControllerOutfit` sélectionne l'onglet 1 ou 2 et ouvre le nœud `loadout` existant.

Le `BlackMarketGui` réutilisé conserve le remplissage des cellules et les callbacks d'équipement vanilla. Dans ce contexte marqué, le hook retire `trd_preview`, `trd_customize`, `hnd_preview` et `hnd_customize` de BeardLib, car ces actions exigent une prévisualisation 3D indisponible ou un nœud de personnalisation absent du `kit_menu`. Les actions d'équipement, de DLC et de favoris restent disponibles.

L'intégration de Market Favorites est passive et optionnelle. Lorsqu'il est installé, ses hooks existants sur `populate_player_styles` et `populate_gloves` décorent automatiquement ces grilles réutilisées. Briefing Enhanced ne détecte pas Market Favorites et n'appelle pas son namespace ; chaque mod reste donc utilisable seul.

### 11.4 Sélection, achat et vente d'armes

La fonctionnalité d'inventaire n'est active que si le menu courant est `kit_menu` et si le contexte interne vise `primaries` ou `secondaries`.

1. `PlayerInventoryGui`, `NewLoadoutTab` ou l'ancien `LoadoutItem` identifie la catégorie sélectionnée.
2. `ServiceWeaponInventory` active les actions vanilla appropriées.
3. Les emplacements vides déverrouillés reçoivent `ew_buy` ; les emplacements verrouillés reçoivent `ew_unlock` si le joueur peut payer.
4. Les armes possédées reçoivent les actions d'équipement et de vente, tout en protégeant la dernière arme utilisable.
5. `BlackMarketGui` conserve les listes, prix, blocages DLC et confirmations vanilla.
6. Les actions de prévisualisation 3D dangereuses sont retirées uniquement dans ce contexte de briefing.
7. Après une vente, les informations d'outfit sont synchronisées.

Le même `hook_weapon_inventory.lua` est volontairement enregistré sur trois scripts du jeu. `RequiredScript` sélectionne uniquement la branche correspondante : création du briefing/loadout, sélection de catégorie dans `PlayerInventoryGui`, ou construction des actions dans `BlackMarketGui`. Toutes les règles d'action sont centralisées dans `service_weapon_inventory.lua` ; le hook doit seulement capturer le contexte et transmettre les données du jeu au service.

### 11.5 Drag and Drop Inventory

`AdapterDragDropInventory` n'active l'intégration que si la dépendance est installée, activée et expose toutes les API nécessaires. Le mod laisse alors la dépendance gérer la prise, le placement et les permutations compatibles avec les profils. Briefing Enhanced ne duplique pas cette logique. Sans la dépendance, l'achat et la vente continuent de fonctionner.

L'adaptateur est chargé par `hook_weapon_inventory.lua`. `ServiceWeaponInventory` appelle `AdapterDragDropInventory:is_available()` lors de la création des actions. Si elle est disponible, le hook retire le marqueur réservé au loadout du nœud d'armes du briefing afin que les handlers existants de la dépendance puissent traiter la grille.

### 11.6 Modifications d'armes

Les modifications utilisent un composant 2D dédié enregistré sur `MenuComponentManager`.

1. Le joueur choisit l'arme principale ou secondaire équipée.
2. `ControllerWeaponModification` ouvre le nœud custom du `kit_menu`.
3. `ServiceWeaponModification` lit l'arme fabriquée équipée et appelle `get_dropable_mods_by_weapon_id` une fois par rafraîchissement.
4. Il regroupe les pièces compatibles par type et conserve leur `global_value`, quantité, prix, conflit, statut par défaut et cosmétique.
5. `ComponentWeaponModification` gère sélection, onglets, pages, entrées souris/manette et rafraîchissements.
6. Les méthodes de vue dessinent la grille, le détail de la pièce et les statistiques sans prévisualisation 3D.
7. L'installation ou le retrait passe par les confirmations et transactions BlackMarket vanilla.
8. Le blueprint est relu après la mutation. Une modification refusée affiche une erreur au lieu de supposer sa réussite.
9. L'outfit et l'interface sont rafraîchis.

La création de l'UI possède deux moments d'entrée distincts. `hook_menu_component.lua` s'exécute lorsque `MenuComponentManager` existe et déclare les callbacks create/close. Plus tard, `hook_weapon_modification.lua` s'exécute avec le briefing et charge la vraie classe du composant. `FactoryBriefingNode` relie les deux avec l'ID stable du composant. Cette séparation empêche une callback de viser une méthode du manager qui n'a pas encore été déclarée.

Le composant reste enregistré sous l'ID historique `bbm_weapon_modifications`. Les anciennes méthodes du manager et le global `BriefingWeaponModificationsGui` restent des alias de compatibilité.

### 11.7 Statistiques d'armes

`PresenterWeaponStatistics` construit un aperçu sans modifier le vrai blueprint. Les colonnes vanilla `TOTAL / BASE / MOD / SKILL` proviennent de `WeaponDescription._get_stats`.

`AdapterMoreWeaponStats` n'est utilisé que si More Weapon Stats est installé, activé et complètement initialisé. Ses lignes optionnelles sont calculées avec son API `Faker`. Si une API requise manque, l'interface reste fonctionnelle avec les statistiques vanilla uniquement.

Chemin des données : pièce sélectionnée dans `ComponentWeaponModification` → `PresenterWeaponStatistics:get_data()` → `WeaponDescription._get_stats` vanilla plus `AdapterMoreWeaponStats:get_rows()` optionnel → rendu dans `view_weapon_modification.lua`.

### 11.8 PD2Builder

`AdapterPd2Builder` vérifie que **PD2Builder loader** est activé et que `BuilderLoader` expose les méthodes attendues. Import et Export n'apparaissent dans `BUILD` que si ces vérifications réussissent. Un post-hook sur `BuilderLoader:set_build` rafraîchit l'outfit après un import.

`hook_build_transfer.lua` charge uniquement l'adaptateur. `ControllerBriefingMenu` vérifie sa disponibilité lors de la construction du QuickMenu : activer ou désactiver la dépendance change donc l'affichage des entrées sans dupliquer la logique du menu.

### 11.9 EHI et chat

- `AdapterEhi` détecte la méthode d'aperçu d'XP ajoutée tardivement par EHI, l'entoure de pre/post-hooks et masque temporairement les éléments capturés pendant l'ouverture d'un écran de build.
- `AdapterChat` conserve l'accès au chat dans le parcours custom et demande optionnellement une traduction si l'API correspondante existe.

Les deux adaptateurs sont optionnels et idempotents.

## 12. Politique de compatibilité

Le nom affiché est **Briefing Enhanced**, mais le dossier physique reste `Briefing Build Menu` afin de ne pas casser les installations existantes.

Les surfaces suivantes sont volontairement conservées :

- alias de namespace `BriefingBuildMenu` ;
- anciens IDs de hooks et clés de localisation ;
- anciens IDs de nœuds et composants ;
- méthodes marquées `Compatibility facade` ;
- `BriefingWeaponModificationsGui` ;
- `create_bbm_weapon_modifications` et `close_bbm_weapon_modifications`.

Le nouveau code doit utiliser `BriefingEnhanced` et les modules typés. Les façades de compatibilité doivent seulement déléguer et ne pas contenir de nouvelle logique métier.

## 13. Comment faire évoluer le mod

### 13.1 Trouver le bon fichier de départ

| Modification souhaitée | Commencer la lecture ici | Modifier généralement aussi |
|---|---|---|
| Ajouter ou réordonner une option BUILD | `briefing_menu/controller_briefing_menu.lua` | Localisation et éventuellement un nouveau contrôleur |
| Modifier l'apparence/position de BUILD | `briefing_menu/view_briefing_button.lua` | Constantes partagées si la valeur est réutilisée |
| Ajouter un nœud de menu | `briefing_menu/factory_briefing_node.lua` | Contrôleur d'ouverture et méthodes create/close du composant |
| Modifier le cycle ouverture/fermeture | `core/state_briefing_session.lua` et `controller_menu_navigation.lua` | Hook de fermeture de la fonctionnalité |
| Modifier les règles d'achat/vente | `weapon_inventory/service_weapon_inventory.lua` | Hook routé seulement si une autre méthode du jeu est nécessaire |
| Modifier les pièces disponibles ou transactions | `weapon_modification/service_weapon_modification.lua` | Contrôleur/composant uniquement si l'interaction change |
| Modifier la disposition de l'écran | `weapon_modification/view_weapon_modification.lua` | Composant pour un nouvel état ou une nouvelle entrée |
| Ajouter une statistique affichée | `weapon_modification/presenter_weapon_statistics.lua` | Vue ou adaptateur optionnel |
| Intégrer un autre mod | Nouveau `adapter_<mod>.lua` dans la fonctionnalité propriétaire | Hook d'entrée et vérification de disponibilité |
| Ajouter un texte affiché | `localization/localization_english.lua` | Nouvelle clé stable `bbm_*` dans le consommateur |

### 13.2 Tutoriel : ajouter une option dans BUILD

Supposons qu'une nouvelle fonctionnalité doive ouvrir un écran custom.

1. Créer `lua/<fonctionnalité>/controller_<fonctionnalité>.lua`.
2. Définir `BriefingEnhanced.ControllerFeature = ... or {}` et une méthode `open()`.
3. Si un nœud est requis, ajouter un ID stable dans `ConstantsBriefingEnhanced.NODE_NAMES`.
4. Enregistrer ce nœud dans `FactoryBriefingNode:ensure_all()`.
5. Dans `open()`, appeler `ControllerMenuNavigation:open(screen_name, node_name)` pour centraliser le cycle de session.
6. Charger le contrôleur depuis un `hook_<fonctionnalité>.lua` adapté ou avant son utilisation par `controller_briefing_menu.lua`.
7. Ajouter l'option et sa callback dans `ControllerBriefingMenu:show()`.
8. Ajouter la clé de localisation anglaise `bbm_*`.
9. S'assurer que le composant ou écran vanilla appelle `StateBriefingSession:finish(screen_name)` à sa fermeture.
10. Tester ouverture, retour, ouvertures répétées et fermeture forcée du briefing.

Ne pas appeler directement `managers.menu:open_node` depuis la callback du QuickMenu. Le passage par `ControllerMenuNavigation` évite qu'un échec d'ouverture laisse BUILD bloqué.

### 13.3 Tutoriel : ajouter une intégration optionnelle

1. Placer toute la connaissance de l'API tierce dans `adapter_<mod>.lua`.
2. Implémenter `is_available()` avec l'état BLT activé et la présence exacte des globals/méthodes nécessaires.
3. Rendre chaque méthode publique de l'adaptateur inoffensive si la dépendance manque.
4. Charger l'adaptateur avant le contrôleur ou la vue qui peut l'appeler.
5. Conserver la fonctionnalité de base utilisable sans cette dépendance.
6. Tester quatre situations : absent, installé mais désactivé, activé mais pas encore initialisé, complètement disponible.

Ne pas mémoriser définitivement « indisponible » lorsqu'un autre mod peut s'initialiser plus tard. EHI sert de référence pour une API tardive à retenter ; PD2Builder sert de référence pour la détection d'un mod BLT activé.

### 13.4 Tutoriel : ajouter un état ou une interaction UI

1. Stocker sélection, page et état d'entrée dans `ComponentWeaponModification`.
2. Ajouter une petite méthode qui modifie cet état et renvoie `true` uniquement si l'entrée est consommée.
3. Appeler `_rebuild()` après un changement visible.
4. Dessiner le résultat dans `view_weapon_modification.lua`.
5. Conserver les mutations économiques dans `ServiceWeaponModification`.
6. Vérifier `alive(panel)` pour les objets susceptibles d'être détruits pendant une transition de menu.

### 13.5 Tutoriel : hooker une autre classe PAYDAY 2

1. Trouver la méthode dans un dump PAYDAY 2 actuel et vérifier paramètres et valeur de retour.
2. Ajouter le chemin du script du jeu comme `hook_id` dans `mod.txt`.
3. Créer ou réutiliser un fichier d'entrée `hook_<fonctionnalité>.lua`.
4. Charger le noyau en premier, puis uniquement les modules nécessaires dans ce contexte.
5. Préférer `PostHook` pour réagir après le jeu et `PreHook` pour préparer les données avant lui.
6. Utiliser `OverrideFunction` seulement pour consommer une entrée ou modifier le retour ; sauvegarder et rappeler `Hooks:GetFunction` dans les autres cas.
7. Donner au hook un ID stable et unique globalement.
8. Protéger l'installation avec un drapeau de hook si l'entrée peut être chargée plusieurs fois.

### 13.6 Liste de contrôle d'une modification sûre

Avant l'édition :

- suivre le `hook_id` concerné depuis `mod.txt` jusqu'au fichier d'entrée ;
- identifier la couche propriétaire du comportement ;
- inspecter la méthode vanilla et les mods locaux qui hookent la même méthode.

Pendant l'édition :

- employer la syntaxe Lua 5.1 ;
- préserver `ModPath` dans une locale ou `BriefingEnhanced.ModPath` avant une callback différée ;
- protéger les objets dépendants du cycle de vie ;
- conserver les dépendances optionnelles derrière leurs adaptateurs ;
- préserver les IDs historiques sauf migration explicite ;
- ne jamais ajouter la fonctionnalité dans `base/`, BeardLib ou un autre mod.

Après l'édition :

- valider `mod.txt` comme JSON strict ;
- vérifier l'existence de chaque `script_path` et cible de `dofile` ;
- rechercher les doublons d'IDs de hooks et logs temporaires ;
- tester la fonctionnalité avec chaque intégration optionnelle activée et désactivée ;
- lire les derniers logs SuperBLT et Diesel.

### 13.7 Diagnostic selon le symptôme

| Symptôme | Premiers fichiers/objets à inspecter |
|---|---|
| Le mod ne se charge jamais | `mod.txt`, `hook_id`, `script_path` d'entrée et log SuperBLT |
| BUILD n'apparaît pas | `hook_mission_briefing.lua`, `MissionBriefingGui:init`, `ViewBriefingButton` |
| BUILD apparaît mais ne se clique pas | Overrides souris, limites du bouton, `gui._enabled`, garde du blackscreen |
| Une option affiche `ERROR: <ID>` | `localization_english.lua` et clé `bbm_*` exacte |
| Un écran ne s'ouvre pas | `FactoryBriefingNode`, `kit_menu` actif, `ControllerMenuNavigation` |
| BUILD reste bloqué après Retour | Hook de fermeture, `StateBriefingSession:finish`, callback close du composant |
| Une pièce est listée mais pas installée | Arguments de transaction, `global_value`, disponibilité et blueprint relu |
| L'atelier crashe sur `menu_scene` | Un chemin 3D a été ouvert depuis le briefing ; conserver le composant 2D |
| Une fonction marche seulement avec un autre mod | Frontière de l'adaptateur ou global tiers non protégé |

## 14. Matrice minimale de tests en jeu

- Démarrer le jeu et rejoindre un lobby sans erreur.
- Ouvrir et fermer `BUILD` plusieurs fois.
- Ouvrir l'arbre de compétences et le perk deck, appliquer une modification et revenir.
- Ouvrir les tenues et les gants depuis `BUILD`, équiper un élément, revenir puis répéter.
- Répéter le test des tenues et des gants avec Market Favorites activé puis désactivé.
- Équiper, acheter et vendre des armes principales et secondaires.
- Répéter les tests d'inventaire avec Drag and Drop Inventory activé puis désactivé.
- Installer, remplacer et retirer des pièces ; tester pagination, souris et manette.
- Répéter les statistiques avec More Weapon Stats activé puis désactivé.
- Répéter l'import/export avec PD2Builder activé puis désactivé.
- Revenir au menu principal, rejoindre un autre lobby et vérifier BUILD ainsi que les mises à jour d'outfit.
- Lire le dernier log SuperBLT et le crash log Diesel après les tests.
