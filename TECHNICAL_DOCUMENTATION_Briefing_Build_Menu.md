# Briefing Enhanced — Technical Documentation

Reference for **Briefing Enhanced 1.10.0**, targeting PAYDAY 2, SuperBLT and LuaJIT/Lua 5.1.

- [English reference](#english-reference)
- [Référence française](#référence-française)

---

# English reference

## 1. Technical scope

Briefing Enhanced extends `kit_menu` without creating the BlackMarket 3D scene. It delegates data, unlock rules, prices, confirmations and mutations to PAYDAY 2 managers, while custom code coordinates briefing-only navigation and renders the weapon modification UI.

Runtime invariants:

- `BriefingEnhanced` is the canonical namespace.
- `BriefingBuildMenu` remains an alias to the same table.
- Feature state must be scoped to the active `kit_menu`.
- Custom screen initialization and cleanup must be idempotent.
- Optional integrations must have a complete vanilla fallback.
- All code must remain LuaJIT/Lua 5.1 compatible.

## 2. Design principles

- **One feature per folder:** a feature owns its hooks, controller, rules and UI.
- **KISS:** use vanilla nodes and callbacks where they are safe; use custom UI only where briefing constraints require it.
- **Single responsibility:** hooks connect runtime classes, controllers coordinate flows, services own rules, views render, adapters isolate external APIs.
- **Dependency inversion:** feature code calls an adapter contract, never an optional mod directly.
- **Fail closed:** a missing manager, node, class, unlock result or dependency disables the action instead of guessing.
- **Idempotence:** namespaces, hook installation and component registration use stable guards.
- **Scoped mutation:** BlackMarket changes apply only while the briefing inventory context is active.
- **Vanilla authority:** economic operations, inventory mutations and outfit refreshes remain owned by PAYDAY 2 managers.
- **Compatibility before visual fidelity:** the weapon editor is 2D because `managers.menu_scene` is not guaranteed in `kit_menu`.

## 3. Architecture element types

| Type | Responsibility | Must not contain |
|---|---|---|
| `hook_*` | Load modules at a SuperBLT `hook_id`; attach guarded hooks to game classes | Business rules or large UI construction |
| `Controller*` | Validate context and coordinate an end-to-end user action | Raw optional-mod calls |
| `Service*` | Query managers, enforce rules and perform transactions | Input-hook installation |
| `State*` | Own a bounded runtime lifecycle and restore prior state | Rendering |
| `Factory*` | Create or register nodes/components idempotently | Feature transactions |
| `Component*` | Own interactive custom-screen state and input behavior | PAYDAY 2 unlock/economic policy |
| `View*` | Create, update and destroy panels/textures | Navigation or transactions |
| `Presenter*` | Transform domain data into display-ready values | Game mutations |
| `Adapter*` | Detect and wrap an optional or conflicting mod API | Core feature policy |
| `Facade*` | Preserve legacy public names by delegation | New behavior |
| `localization_*` | Register display strings | Runtime rules |

Dependency direction:

```text
SuperBLT hook -> Controller -> Service / State / Factory
                              -> Presenter -> Adapter
Component -> View
```

Hooks may compose modules, but lower-level modules must not depend on hook files.

## 4. Folder architecture

```text
Briefing Build Menu/
├── mod.txt
├── main.xml
├── README.md
├── TECHNICAL_DOCUMENTATION_Briefing_Build_Menu.md
└── lua/
    ├── core/
    ├── briefing_menu/
    ├── skill_tree/
    ├── perk_deck/
    ├── outfit/
    ├── weapon_inventory/
    ├── weapon_context_menu/
    ├── weapon_modification/
    ├── build_transfer/
    ├── compatibility/
    └── localization/
```

| Path | Ownership |
|---|---|
| `mod.txt` | SuperBLT identity, version and game-script hooks |
| `main.xml` | BeardLib `AssetUpdates` declaration for the official ModWorkshop release |
| `core/` | Bootstrap, constants, session state, navigation, dialogs, outfit synchronization and legacy facade |
| `briefing_menu/` | BUILD button, QuickMenu options and custom `kit_menu` node registration |
| `skill_tree/` | Vanilla skill-tree opening, briefing restrictions and close cleanup |
| `perk_deck/` | Vanilla specialization opening and close cleanup |
| `outfit/` | Guarded reuse of the vanilla loadout node for player styles and gloves |
| `weapon_inventory/` | Briefing inventory context, equip/buy/sell actions and Drag and Drop Inventory adapter |
| `weapon_context_menu/` | Right-click routing for briefing weapon/armor slots and BlackMarket modification |
| `weapon_modification/` | Weapon/part rules, transactions, custom component, rendering, statistics and More Weapon Stats adapter |
| `build_transfer/` | PD2Builder detection and import/export bridge |
| `compatibility/` | EHI and chat lifecycle adaptations |
| `localization/` | English localization keys |

`bootstrap.lua` loads only shared core modules. Each hook entry loads its feature modules when the target PAYDAY 2 class exists.

## 5. Naming conventions

### Files and tables

- File: `<type>_<feature>.lua`, for example `service_weapon_modification.lua`.
- Table/class: `[Type][Nature][Qualifier]`, for example `ServiceWeaponModification`.
- Hook state: `BE.HookFeature = BE.HookFeature or {}` with per-runtime guards.
- Constants: uppercase snake case inside `ConstantsBriefingEnhanced`.

### Methods and locals

- A typed table uses a short verb: `open`, `refresh`, `install`, `remove`, `is_available`.
- Boolean methods start with `is_`, `has_`, `can_` or `should_`.
- Deferred callbacks requiring several values use Lua closures, not multi-argument `callback(...)`.
- Use PAYDAY 2 category names (`primaries`, `secondaries`) at manager boundaries.

### Stable identifiers

Keep the historical `bbm_*` localization IDs, node/component names and `BriefingBuildMenu_*` hook IDs. Do not rename:

- `BriefingBuildMenu`;
- compatibility facade methods;
- `BriefingWeaponModificationsGui`;
- `create_bbm_*` / `close_bbm_*`;
- existing node and component IDs.

They support upgrades, partial SuperBLT reloads and third-party wrappers.

## 6. Trigger and file map

`mod.txt` is the authoritative external load map.

| PAYDAY 2 trigger | Entry file | Purpose |
|---|---|---|
| `menucomponentmanager` | `weapon_modification/hook_menu_component.lua` | Declare create/close methods for the custom component |
| `missionbriefinggui` | `core/hook_bootstrap.lua` | Initialize the shared namespace/core |
| `missionbriefinggui` | `briefing_menu/hook_mission_briefing.lua` | Register nodes, create BUILD, route mouse input and clean session state |
| `missionbriefinggui` | `weapon_inventory/hook_weapon_inventory.lua` | Mark briefing weapon-category flows and configure cells |
| `playerinventorygui` | `weapon_inventory/hook_weapon_inventory.lua` | Track the alternate vanilla inventory entry path |
| `blackmarketgui` | `weapon_inventory/hook_weapon_inventory.lua` | Enable safe buy/sell/modify actions in marked briefing grids |
| `blackmarketgui` | `outfit/hook_outfit.lua` | Remove unsafe preview/customization actions from marked outfit grids |
| `missionbriefinggui` | `weapon_modification/hook_weapon_modification.lua` | Compose the 2D editor modules |
| `missionbriefinggui` | `build_transfer/hook_build_transfer.lua` | Load the PD2Builder adapter |
| `missionbriefinggui` | `compatibility/hook_ehi.lua` | Load and retry the EHI adaptation |
| `missionbriefinggui` | `weapon_context_menu/hook_weapon_context_menu.lua` | Capture right-click on briefing loadout slots |
| `blackmarketgui` | `weapon_context_menu/hook_weapon_context_menu.lua` | Redirect briefing `w_mod` away from the 3D workshop |
| `skilltreeguinew` | `skill_tree/hook_skill_tree.lua` | Restrict briefing skill-set actions and finish the session on close |
| `specializationguinew` | `perk_deck/hook_perk_deck.lua` | Finish the perk-deck session on close |
| `chatmanager` | `compatibility/hook_chat.lua` | Load chat support when chat classes exist |
| `localizationmanager` | `localization/localization_english.lua` | Register English strings |

Important internal composition:

| Entry file | Modules loaded |
|---|---|
| `briefing_menu/hook_mission_briefing.lua` | Node factory, skill/perk/outfit controllers, BUILD controller and view |
| `weapon_inventory/hook_weapon_inventory.lua` | Inventory service and Drag and Drop adapter |
| `weapon_modification/hook_weapon_modification.lua` | Service, controller, MWS adapter, statistics presenter, component and view |
| `weapon_context_menu/hook_weapon_context_menu.lua` | Context-menu controller |

## 7. Briefing session lifecycle

`StateBriefingSession` protects custom screens that replace the visible briefing.

```text
User action
  -> ControllerMenuNavigation:open(screen, node)
  -> StateBriefingSession:begin(screen)
       store previous Global.block_update_outfit_information
       set opened_from_briefing
       block outfit refresh
       hide tracked EHI elements
       install chat access
  -> managers.menu:open_node(...)
  -> MissionBriefingGui:hide hides briefing panels/backdrop
  -> custom screen
  -> screen close hook / component close
  -> StateBriefingSession:finish(screen)
       reset state and restore previous outfit block
       restore EHI visibility and briefing backdrop
       refresh outfit information
```

Failure path: if `open_node` throws, `ControllerMenuNavigation` calls `reset(screen)` before showing an error. `MissionBriefingGui:init` and `close` also clear stale state.

Only skill tree, perk deck and weapon modifications use this lifecycle. Outfit and glove routes reuse the vanilla `loadout` node and must **not** start a `StateBriefingSession`.

`ServiceWeaponInventory.context` is separate. It marks only the current weapon category and source while `kit_menu` is active, allowing hooks to modify BlackMarket cells without affecting the main inventory.

## 8. Feature paths

### BUILD and custom nodes

```text
MissionBriefingGui:init
  -> FactoryBriefingNode:ensure_all
  -> ViewBriefingButton:create
left-click BUILD
  -> ControllerBriefingMenu:show
  -> QuickMenu callback
  -> target controller/adapter
```

The factory inserts nodes into `managers.menu:get_menu("kit_menu").data._nodes`. `menu_component_data` is assigned through `node:parameters()` after node construction.

### Skill tree and perk deck

The controller ensures nodes, then `ControllerMenuNavigation` opens `skilltree_new` or `skilltree`. Their class-specific close hooks finish the matching session. Skill-set switching is restricted because the briefing cannot safely rebuild every profile-dependent panel.

### Outfits, gloves and armor

`ControllerOutfit` opens vanilla `loadout` with data from `ServiceOutfitMenu`. The marked tabs use `populate_player_styles` and `populate_gloves`; PostHooks remove 3D preview/customization actions but retain equip actions.

Armor right-click delegates to `NewLoadoutTab:open_node(5)`. Market Favorites compatibility is passive because its hooks see the same vanilla population methods.

### Weapon selection, purchase, sale and movement

`NewLoadoutTab` or `PlayerInventoryGui` marks `ServiceWeaponInventory.context`. BlackMarket hooks then:

- enable buy, modify and sell only for the marked category;
- rebuild actionable empty cells with their real inventory slot;
- prevent sale of the last usable weapon;
- remove unsafe `bw_preview` actions;
- synchronize outfit data after a sale.

When Drag and Drop Inventory is available, its own pickup/place/swap implementation remains authoritative. Briefing Enhanced only makes the generated weapon node eligible for that implementation.

### Context menus

`MissionBriefingGui` normally discards right-click before forwarding it to `NewLoadoutTab`. The context hook therefore wraps `mouse_pressed` at the parent:

- weapon slots 1/2 → open inventory or modify equipped slot;
- armor slot 5 → Gloves, Outfit or Armor.

In a marked BlackMarket weapon grid, `choose_weapon_mods_callback` is redirected to `ControllerWeaponModification:open(category, slot)`. Outside that context, the original callback is always called.

### Weapon modifications

```text
ControllerWeaponModification:open(category, slot?)
  -> store category/slot in node menu_component_data
  -> open custom component node
  -> ComponentWeaponModification:refresh
  -> ServiceWeaponModification:get_data
  -> ViewWeaponModification renders categories, page, details and stats
user confirms action
  -> ServiceWeaponModification:confirm_install/remove
  -> revalidate lock, compatibility, ownership and price
  -> vanilla confirmation/consequence
  -> buy_and_modify_weapon or remove_weapon_part
  -> reread blueprint and refresh component
```

The service uses `get_dropable_mods_by_weapon_id`, preserves `global_value`, checks achievement/content/milestone locks, and resolves descriptions with `get_part_desc_by_part_id_from_weapon`. Missing localization keys yield an empty description, never `ERROR: <id>`.

The component preserves icon aspect ratios and paginates `columns × rows` from constants. It never calls `_start_crafting_weapon`, `view_weapon` or a menu-scene API.

### Weapon statistics

`PresenterWeaponStatistics` obtains vanilla `TOTAL / BASE / MOD / SKILL` values from `WeaponDescription._get_stats` for the current and preview blueprints. It appends More Weapon Stats rows only when its adapter validates the complete runtime contract.

### Build transfer

The BUILD menu asks `AdapterPd2Builder:is_available()`. Import/export callbacks execute the dependency scripts under `pcall`; a PostHook on `BuilderLoader:set_build` refreshes outfit information.

## 9. Optional integrations

Adapters isolate version checks, globals and fallback behavior.

| Integration | Adapter | Availability contract | Enabled behavior | Disabled/missing behavior |
|---|---|---|---|---|
| PD2Builder loader | `build_transfer/adapter_pd2builder.lua` | BLT mod exists, `IsEnabled()`, `BuilderLoader.load_build` and `upload_build` | Show import/export; execute dependency scripts; refresh outfit after import | Hide both BUILD entries |
| Drag and Drop Inventory | `weapon_inventory/adapter_drag_drop_inventory.lua` | Enabled mod plus `DragDropInventory`, pickup/place methods and `ddi_swap_item` | Let dependency move/swap weapons in marked briefing grid | Keep vanilla equip/buy/sell |
| More Weapon Stats | `weapon_modification/adapter_more_weapon_stats.lua` | Enabled mod plus initialized `Faker`, settings and required calculators | Append extended statistic rows | Render vanilla statistics only |
| EHI | `compatibility/adapter_ehi.lua` | `MissionBriefingGui.AddXPBreakdown` exists | Track injected XP elements; hide/restore them with custom sessions | No overlay mutation |
| Chat/translator | `compatibility/adapter_chat.lua` | Core chat classes; translator path additionally requires `ChatTranslatorMessage` | Keep briefing chat accessible; preserve translation hook | Base screens still operate |
| Market Favorites | No adapter by design | Its hooks run on the reused vanilla populate methods | Favorites actions, badges and ordering appear automatically | Vanilla grid remains unchanged |
| BeardLib updater | No Lua adapter; `main.xml` | BeardLib loads `AssetUpdates` and queries ModWorkshop mod `57999` | Check semantic versions at the main menu; expose a user-confirmed download/install action | The mod runs normally without update checks |

Availability is evaluated at the point of use when dependency initialization order can vary. Adapter installation and wrapper hooks are idempotent. Core services must not retain dependency-owned data structures.

The updater is intentionally declarative and separate from runtime feature adapters. Do not add a second SuperBLT `updates` definition: two update managers for the same release would produce competing notifications and installation paths.

## 10. Compatibility policy

- Preserve the original hook chain with `PostHook`/`PreHook` where possible.
- An override must capture `Hooks:GetFunction(...)` and delegate outside the exact briefing context.
- Never open the vanilla 3D weapon workshop from `kit_menu`.
- Never modify shared dependencies (`base`, BeardLib, HopLib) for this feature.
- Guard `managers.*`, `Global.*`, classes and panels with lifecycle-appropriate checks.
- Keep historical namespaces, facades, hook IDs and component IDs.
- Recompute weapon locks and consequences immediately before mutations.
- Preserve selected weapon `category`, `slot` and part `global_value` end to end.
- Treat optional mods as capabilities, not installation assumptions.
- Keep outfit and inventory changes local; no custom LuaNetworking message is required.
- Expect other mods to wrap `BlackMarketGui`, `MissionBriefingGui` and mouse input. Do not bypass their saved original functions.

Known high-risk compatibility surfaces: Drag and Drop Inventory, MultipleWeaponModRows, More Weapon Stats, custom HUDs, EHI and profile-management mods.

## 11. How to evolve the mod

This section is an implementation guide. The goal is not merely to make a new action work once, but to place it where another PAYDAY 2 modder can trace, test and maintain it.

### 11.1 Start with a feature contract

Before editing code, write down five facts:

| Question | Example |
|---|---|
| What starts the feature? | Left-click on BUILD, right-click on a loadout slot, game callback |
| What input identifies the target? | `category`, crafted `slot`, selected tab |
| Which object owns the truth? | `managers.blackmarket`, `managers.skilltree`, active menu node |
| What changes? | Navigation only, local UI state, inventory/economic mutation |
| What is the safe fallback? | Hide the option, call the original method, show a guarded error |

This contract determines the module types. A click normally enters a controller; a game query or mutation belongs in a service; an optional global belongs behind an adapter; panels belong in a view/component.

Do not start by adding logic to a hook. A hook is only the runtime entry point.

### 11.2 Find and verify the PAYDAY 2 extension point

Use an up-to-date Lua dump matching the installed game version:

1. Find the class and method that currently implement the vanilla behavior.
2. Read the full method, not only its name. Record its arguments, return values and fields read from `self`.
3. Read its callers. A method may only be valid after another method initialized a node or scene.
4. Search local mods for wrappers on the same method.
5. Check whether the class already has a `mod.txt` entry in Briefing Enhanced.

Useful searches:

```powershell
rg -n "function MissionBriefingGui:mouse_pressed" <PAYDAY_2_LUA_DUMP>
rg -n --glob "*.lua" "Hooks:(PostHook|PreHook|OverrideFunction).*mouse_pressed" "PAYDAY 2/mods"
rg -n "lib/managers/menu/missionbriefinggui" "Briefing Build Menu/mod.txt"
```

Choose the least invasive mechanism:

| Need | Mechanism |
|---|---|
| Observe or adjust data after vanilla construction | `Hooks:PostHook` |
| Mark context before vanilla runs | `Hooks:PreHook` |
| Consume input or redirect one exact branch | `Hooks:OverrideFunction`, with saved original |

An override must delegate every unrelated call:

```lua
local original_mouse_pressed = Hooks:GetFunction(MissionBriefingGui, "mouse_pressed")

Hooks:OverrideFunction(MissionBriefingGui, "mouse_pressed", function(gui, button, x, y)
	if button == Idstring("1")
		and BE.ControllerExample:try_handle(gui, x, y) then
		return true
	end

	return original_mouse_pressed(gui, button, x, y)
end)
```

Returning `true` means the event was consumed. Returning it for an unrelated click can silently break another UI or mod.

### 11.3 Create the feature folder and loading chain

For a new feature named `profile_summary`, start with the minimum:

```text
lua/profile_summary/
├── controller_profile_summary.lua
└── hook_profile_summary.lua   # only if a new game-class trigger is required
```

Add `service_profile_summary.lua`, `view_profile_summary.lua` or `adapter_x.lua` only when the responsibility exists. Do not create empty architectural layers.

Every module must be safe when loaded more than once:

```lua
BriefingEnhanced = BriefingEnhanced or BriefingBuildMenu or {}

local BE = BriefingEnhanced

BE.ControllerProfileSummary = BE.ControllerProfileSummary or {}

function BE.ControllerProfileSummary:show()
	-- Orchestration only.
end
```

If an existing entry file already runs when the required class exists, load the module there:

```lua
dofile(BriefingEnhanced.ModPath .. "lua/profile_summary/controller_profile_summary.lua")
```

Create a new `mod.txt` hook only when a different PAYDAY 2 class must exist before installation:

```json
{
    "hook_id": "lib/managers/menu/examplegui",
    "script_path": "lua/profile_summary/hook_profile_summary.lua"
}
```

Inside a hook shared by several `hook_id` values, branch on `RequiredScript` and use stable installation guards:

```lua
local required_script = string.lower(RequiredScript or "")

BE.HookProfileSummary = BE.HookProfileSummary or {}

if required_script == "lib/managers/menu/examplegui"
	and not BE.HookProfileSummary.example_gui then
	BE.HookProfileSummary.example_gui = true

	Hooks:PostHook(ExampleGui, "init", "BriefingEnhanced_ProfileSummary_Init", function(gui)
		BE.ControllerProfileSummary:on_gui_ready(gui)
	end)
end
```

### 11.4 Tutorial: add a simple action to BUILD

The following example adds a profile summary dialog without creating a custom screen.

**Step 1 — controller**

Create `lua/profile_summary/controller_profile_summary.lua`:

```lua
BriefingEnhanced = BriefingEnhanced or BriefingBuildMenu or {}

local BE = BriefingEnhanced

BE.ControllerProfileSummary = BE.ControllerProfileSummary or {}

function BE.ControllerProfileSummary:show()
	if not (managers.experience and managers.localization) then
		return false
	end

	local level = managers.experience:current_level() or 0

	QuickMenu:new(
		managers.localization:text("bbm_profile_summary_title"),
		managers.localization:text("bbm_profile_summary_text", {
			LEVEL = tostring(level)
		}),
		{
			{
				text = managers.localization:text("dialog_ok"),
				is_cancel_button = true
			}
		},
		true
	)

	return true
end
```

**Step 2 — load the controller**

Add this line to `briefing_menu/hook_mission_briefing.lua` with the other controller loads:

```lua
dofile(BriefingEnhanced.ModPath .. "lua/profile_summary/controller_profile_summary.lua")
```

**Step 3 — expose the BUILD option**

Add an entry to the `options` table in `ControllerBriefingMenu:show`:

```lua
{
	text = managers.localization:text("bbm_profile_summary_title"),
	callback = function()
		BE.ControllerProfileSummary:show()
	end
}
```

Insert it before `add_cancel_option(options)`.

**Step 4 — localize**

Add these entries to the existing table passed to `add_localized_strings` in `localization/localization_english.lua`:

```lua
bbm_profile_summary_title = "PROFILE SUMMARY",
bbm_profile_summary_text = "Current level: $LEVEL",
```

**Step 5 — test the complete path**

Restart the game, open BUILD repeatedly, select the entry, close with mouse and keyboard, and verify that no duplicate option appears after returning to the briefing.

This feature does not hide the briefing or open a node, so it must not start `StateBriefingSession`.

### 11.5 Tutorial: add a custom briefing screen

A custom screen requires a node, component registration, component state, a view and lifecycle cleanup.

**Step 1 — register the node**

Extend `FactoryBriefingNode:ensure_all`. Nested tables must be assigned after `MenuNode:new`, which the factory already does through `node_parameters` or explicit parameters:

```lua
self:ensure(menu, "briefing_enhanced_example_node", {
	menu_components = "briefing_enhanced_example_component",
	topic_id = "bbm_example_title"
})
```

**Step 2 — declare component manager methods**

Do this from a hook on `menucomponentmanager`, not from `missionbriefinggui`:

```lua
function MenuComponentManager:create_briefing_enhanced_example(node)
	self._be_example = BE.ComponentExample:new(
		self:saferect_ws(),
		self:fullscreen_ws(),
		node
	)
	self:register_component("briefing_enhanced_example_component", self._be_example)
end

function MenuComponentManager:close_briefing_enhanced_example()
	if self._be_example then
		self:unregister_component("briefing_enhanced_example_component")
		self._be_example:close()
		self._be_example = nil
	end

	if BE.StateBriefingSession:current_screen() == "example" then
		BE.StateBriefingSession:finish("example")
	end
end
```

Register those method names in `_active_components` as `FactoryBriefingNode` does for the weapon editor.

**Step 3 — open through the lifecycle controller**

```lua
function BE.ControllerExample:open()
	if not BE.FactoryBriefingNode:ensure_all() then
		return false
	end

	return BE.ControllerMenuNavigation:open(
		"example",
		"briefing_enhanced_example_node"
	)
end
```

Never call `StateBriefingSession:begin` separately before `ControllerMenuNavigation:open`; the navigation controller owns begin/reset-on-failure.

**Step 4 — split component and view**

The component owns selection, page and input state. The view receives prepared values and only creates/updates panels. Its `close` path must remove every panel it created from the same workspace.

**Step 5 — prove cleanup**

Test normal Back, rapid repeated opening, an exception during `open_node`, lobby closure and return to the main menu. `Global.block_update_outfit_information` must equal its previous value after each path.

### 11.6 Tutorial: add an optional integration

Suppose `Example Stats` provides a global `ExampleStats:get_value`.

**Step 1 — isolate detection and calls**

Create `adapter_example_stats.lua` in the feature that consumes it:

```lua
BriefingEnhanced = BriefingEnhanced or BriefingBuildMenu or {}

local BE = BriefingEnhanced

BE.AdapterExampleStats = BE.AdapterExampleStats or {}

function BE.AdapterExampleStats:is_available()
	if not (BLT and BLT.Mods and BLT.Mods.GetModByName) then
		return false
	end

	local mod = BLT.Mods:GetModByName("Example Stats")

	return mod ~= nil
		and mod:IsEnabled()
		and ExampleStats ~= nil
		and type(ExampleStats.get_value) == "function"
end

function BE.AdapterExampleStats:get_value(weapon_id)
	if not self:is_available() then
		return nil
	end

	local success, value = pcall(ExampleStats.get_value, ExampleStats, weapon_id)

	return success and value or nil
end
```

**Step 2 — consume the capability, not the mod**

```lua
local value = BE.AdapterExampleStats:get_value(weapon.weapon_id)

if value ~= nil then
	table.insert(rows, {
		name = "EXAMPLE",
		value = tostring(value)
	})
end
```

The base rows are built whether the adapter succeeds or not.

**Step 3 — test four states**

Test the dependency absent, installed but disabled, enabled before briefing initialization, and enabled but missing one expected method. Only the fully valid state may activate the feature.

### 11.7 Tutorial: add or change a transaction

UI state is not transaction authority. Re-read every mutable condition inside the confirmation callback:

```lua
params.yes_func = function()
	local current = BE.ServiceExample:get_current_data(category, slot)

	if not current or not BE.ServiceExample:can_apply(current, selected_id) then
		managers.menu_component:post_event("menu_error")
		return
	end

	BE.ServiceExample:apply(current, selected_id)
	BE.ControllerExample:refresh()
end
```

Use a closure when several values must survive until confirmation. SuperBLT's global `callback` helper captures only one fixed parameter.

For weapon parts, preserve `category`, crafted `slot`, `part_id` and `global_value`; recompute achievement locks, compatibility, quantity, price and `get_modify_weapon_consequence` immediately before `buy_and_modify_weapon`.

### 11.8 Tutorial: add a field to the weapon editor

1. Read and validate raw data in `ServiceWeaponModification`.
2. Add it to the service DTO; do not let the view query `managers.blackmarket`.
3. If it is a calculated display value, format it in `PresenterWeaponStatistics`.
4. Render it in `ViewWeaponModification` using existing fonts/colors and safe-rect dimensions.
5. Refresh it after install/remove by rereading the blueprint.
6. Test the equipped-weapon path and an explicit non-equipped crafted slot.

For an icon, preserve the texture ratio:

```lua
local scale = math.min(frame_w / texture_w, frame_h / texture_h)
local width = texture_w * scale
local height = texture_h * scale

bitmap:set_size(width, height)
bitmap:set_center(frame:center())
```

Do not stretch a texture to both frame dimensions.

### 11.9 Tutorial: add a briefing right-click action

1. Add hit testing and routing to `ControllerWeaponContextMenu`.
2. Validate that the briefing is enabled, not displaying an asset and not entering blackscreen.
3. Update the selected `NewLoadoutTab` item before opening the menu.
4. Delegate to a safe vanilla node/callback when possible.
5. Return `true` only after opening the context menu.
6. Preserve the original `MissionBriefingGui:mouse_pressed` for every other button and coordinate.

Keep action order deterministic and append Cancel last:

```lua
local options = {
	{
		text = managers.localization:text("bbm_example_action"),
		callback = function()
			BE.ControllerExample:open()
		end
	}
}

table.insert(options, {
	text = managers.localization:text("dialog_cancel"),
	is_cancel_button = true
})
```

### 11.10 Tutorial: publish a BeardLib-compatible update

`main.xml` is the only updater declaration:

```xml
<table name="Briefing Enhanced">
	<AssetUpdates
		id="57999"
		provider="modworkshop"
		version="1.10.0"
		semantic_version="true"
	/>
</table>
```

For every release:

1. Choose one semantic version without a `v` prefix in repository files, for example `1.11.0`.
2. Set the same version in `mod.txt` and `main.xml`.
3. Publish that version on ModWorkshop mod `57999`. BeardLib accepts the `v` prefix returned by ModWorkshop, but repository files remain normalized.
4. Build a ZIP with exactly one top-level `Briefing Build Menu/` directory containing `mod.txt`, `main.xml`, documentation and `lua/`.
5. Keep the default full replacement. Do not set `dont_delete="true"`; stale Lua files are more dangerous than a clean install.
6. Never persist user settings inside the mod directory because an update replaces it. Use `SavePath`.
7. Install the previous public version in a disposable game copy, open the main menu and verify that BeardLib reports the new version.
8. Confirm the download, restart PAYDAY 2, then verify the installed files and displayed version.

The automatic part is the check and notification. Download and installation remain user-confirmed. Do not call `BeardLib.Menus.Mods:ForceDownload` from the mod.

### 11.11 Review checklist for a change

Before considering an implementation complete:

1. Confirm that the owner folder and component types match their responsibilities.
2. Confirm every hook has a stable ID and installation guard.
3. Confirm overrides delegate outside their exact context.
4. Confirm every opened session has normal, failure and forced-close cleanup.
5. Confirm all manager/global/class accesses tolerate their lifecycle.
6. Confirm localization IDs exist and missing external text cannot render `ERROR:`.
7. Confirm optional integrations have a no-dependency path.
8. Confirm no debug logs, Lua 5.2 syntax or shared-dependency edits were introduced.
9. Run the relevant in-game matrix rows, then inspect the newest SuperBLT and Diesel crash logs.

## 12. Minimum in-game test matrix

| Area | Required cases | Expected result |
|---|---|---|
| Startup | Dependency set minimal; all optional mods enabled | No load error; BUILD visible |
| BUILD lifecycle | Open/close each action repeatedly; press Back; force one unavailable node | No stuck overlay, BUILD input or outfit block |
| Skills/perks | Open, change allowed data, close | Current profile updates; briefing restores |
| Outfit/gloves/armor | Equip each type; Back navigation | Outfit refreshes; no 3D/customize action crash |
| Weapon inventory | Primary/secondary; equip; buy slot; buy weapon; sell | Correct category/slot and vanilla economy |
| Sale guards | Last weapon; last unlocked weapon | Sale action absent |
| Context menus | Right-click both weapons and armor; Cancel each | Correct ordered actions; unrelated input preserved |
| Weapon editor | Equipped entry and explicit owned slot; install/replace/remove | Correct blueprint, quantity and money |
| Weapon locks | Achievement, milestone, DLC/content and incompatible parts | Locked parts cannot transact |
| Editor UI | Multiple categories/pages; wide/tall icons; missing descriptions | Correct paging/aspect ratio; no `ERROR:` text |
| Statistics | Current vs selected part; MWS enabled/disabled | Correct vanilla values; optional rows only when available |
| Drag/drop | Dependency absent/disabled/enabled; move/swap/place/cancel | Safe fallback; profiles/bots remain consistent |
| HUD/chat | EHI and supported HUD/chat mods enabled/disabled | Overlays restore; chat remains usable |
| Updater | BeardLib absent; present with equal/lower/higher remote version; Ignore Updates enabled; valid/invalid ZIP | Base mod works without BeardLib; only a higher semantic version is offered; invalid downloads do not replace the installed mod |
| Session roles | Host and client; ready/unready; return to menu | No stale state or peer requirement |
| Reload | Restart game; optional SuperBLT reload if used locally | No duplicate hook/component |

Static checks:

```powershell
Get-Content -Raw "Briefing Build Menu/mod.txt" | ConvertFrom-Json
[xml](Get-Content -Raw "Briefing Build Menu/main.xml") | Out-Null
rg -n "log\(|Application:error|io\.write|print\(" "Briefing Build Menu/lua"
rg -n "BriefingBuildMenu_|bbm_" "Briefing Build Menu/lua"
```

In-game validation remains mandatory because static checks cannot reproduce Diesel menu lifecycles.

---

# Référence française

## 1. Périmètre technique

Briefing Enhanced étend `kit_menu` sans créer la scène 3D du BlackMarket. Les données, verrous, prix, confirmations et mutations restent délégués aux managers PAYDAY 2 ; le code du mod coordonne la navigation limitée au briefing et rend l'éditeur d'armes 2D.

Invariants :

- `BriefingEnhanced` est le namespace canonique ; `BriefingBuildMenu` reste son alias.
- Les états fonctionnels sont limités au `kit_menu` actif.
- L'initialisation et le nettoyage sont idempotents.
- Toute intégration optionnelle possède un repli vanilla complet.
- Le code reste compatible LuaJIT/Lua 5.1.

## 2. Principes de conception

- **Une fonctionnalité, un dossier.**
- **KISS :** réutiliser les nœuds/callbacks vanilla sûrs ; créer une UI uniquement si le briefing l'impose.
- **Responsabilité unique :** hook = raccordement, contrôleur = orchestration, service = règles, vue = rendu, adaptateur = frontière externe.
- **Inversion des dépendances :** le métier dépend d'un contrat d'adaptateur, jamais directement d'un mod optionnel.
- **Échec fermé :** une dépendance, classe, règle ou manager absent désactive l'action.
- **Autorité vanilla :** économie, inventaire et synchronisation restent gérés par PAYDAY 2.
- **Mutation ciblée :** les extensions BlackMarket ne s'activent que dans le contexte d'inventaire du briefing.
- **Compatibilité avant fidélité visuelle :** aucune scène 3D n'est créée.

## 3. Types d'éléments d'architecture

| Type | Responsabilité | Exclusion |
|---|---|---|
| `hook_*` | Charger les modules au bon `hook_id` et raccorder les classes du jeu | Règles métier et gros rendu UI |
| `Controller*` | Valider le contexte et orchestrer une action utilisateur | Appels bruts aux mods optionnels |
| `Service*` | Interroger les managers, appliquer les règles et effectuer les transactions | Installation des hooks d'entrée |
| `State*` | Posséder un cycle de vie borné et restaurer l'état précédent | Rendu |
| `Factory*` | Créer/enregistrer nœuds et composants idempotents | Transactions |
| `Component*` | Porter l'état interactif et les entrées d'un écran custom | Politique économique/déverrouillage |
| `View*` | Créer, mettre à jour et détruire les éléments visuels | Navigation et mutations |
| `Presenter*` | Transformer les données métier pour l'affichage | Mutation du jeu |
| `Adapter*` | Détecter et encapsuler l'API d'un mod optionnel/concurrent | Politique métier principale |
| `Facade*` | Préserver les anciens noms publics par délégation | Nouveau comportement |
| `localization_*` | Enregistrer les textes | Règles runtime |

Direction des dépendances :

```text
Hook SuperBLT -> Contrôleur -> Service / État / Factory
                              -> Presenter -> Adaptateur
Composant -> Vue
```

## 4. Architecture des dossiers

| Chemin | Responsabilité |
|---|---|
| `mod.txt` | Identité, version et hooks de scripts SuperBLT |
| `main.xml` | Déclaration BeardLib `AssetUpdates` pour la publication ModWorkshop officielle |
| `lua/core/` | Bootstrap, constantes, état de session, navigation, dialogues, synchronisation d'outfit et façade historique |
| `lua/briefing_menu/` | Bouton BUILD, QuickMenu et enregistrement des nœuds `kit_menu` |
| `lua/skill_tree/` | Ouverture, restrictions et fermeture de l'arbre de compétences |
| `lua/perk_deck/` | Ouverture et fermeture des spécialisations |
| `lua/outfit/` | Réutilisation protégée du nœud loadout pour les tenues et gants |
| `lua/weapon_inventory/` | Contexte, équipement, achat, vente et adaptateur Drag and Drop |
| `lua/weapon_context_menu/` | Clic droit des armes/armure et redirection de la modification BlackMarket |
| `lua/weapon_modification/` | Règles de pièces, transactions, composant, rendu, statistiques et adaptateur MWS |
| `lua/build_transfer/` | Pont PD2Builder |
| `lua/compatibility/` | Adaptations EHI et chat |
| `lua/localization/` | Textes anglais |

`core/bootstrap.lua` ne charge que le socle commun. Chaque fichier `hook_*` compose sa fonctionnalité lorsque la classe PAYDAY 2 visée existe.

## 5. Convention de nommage

- Fichier : `<type>_<fonctionnalité>.lua`.
- Table/classe : `[Type][Nature][Qualificatif]`, par exemple `ControllerWeaponModification`.
- Méthode d'une table typée : verbe court (`open`, `refresh`, `install`, `remove`).
- Booléen : `is_`, `has_`, `can_` ou `should_`.
- Constante : majuscules snake case dans `ConstantsBriefingEnhanced`.
- Catégories des managers : `primaries` et `secondaries`.
- Callback différée avec plusieurs valeurs : closure Lua 5.1.

Les IDs `bbm_*`, hooks `BriefingBuildMenu_*`, noms de nœuds/composants, façades, alias `BriefingBuildMenu`, global `BriefingWeaponModificationsGui` et méthodes `create_bbm_*`/`close_bbm_*` sont stables et ne doivent pas être renommés.

## 6. Carte des déclencheurs et fichiers

| Déclencheur PAYDAY 2 | Fichier | Rôle |
|---|---|---|
| `menucomponentmanager` | `weapon_modification/hook_menu_component.lua` | Déclarer la création/fermeture du composant |
| `missionbriefinggui` | `core/hook_bootstrap.lua` | Initialiser le socle |
| `missionbriefinggui` | `briefing_menu/hook_mission_briefing.lua` | Nœuds, bouton BUILD, souris et nettoyage |
| `missionbriefinggui` | `weapon_inventory/hook_weapon_inventory.lua` | Contexte/grilles d'armes du briefing |
| `playerinventorygui` | `weapon_inventory/hook_weapon_inventory.lua` | Parcours d'inventaire alternatif |
| `blackmarketgui` | `weapon_inventory/hook_weapon_inventory.lua` | Achat, vente, modification et sécurité des cellules |
| `blackmarketgui` | `outfit/hook_outfit.lua` | Retirer les actions 3D dangereuses des grilles marquées |
| `missionbriefinggui` | `weapon_modification/hook_weapon_modification.lua` | Composer l'éditeur 2D |
| `missionbriefinggui` | `build_transfer/hook_build_transfer.lua` | Charger l'adaptateur PD2Builder |
| `missionbriefinggui` | `compatibility/hook_ehi.lua` | Charger/retenter l'adaptation EHI |
| `missionbriefinggui` | `weapon_context_menu/hook_weapon_context_menu.lua` | Clic droit du loadout |
| `blackmarketgui` | `weapon_context_menu/hook_weapon_context_menu.lua` | Rediriger `w_mod` dans le contexte marqué |
| `skilltreeguinew` | `skill_tree/hook_skill_tree.lua` | Restrictions et fin de session |
| `specializationguinew` | `perk_deck/hook_perk_deck.lua` | Fin de session |
| `chatmanager` | `compatibility/hook_chat.lua` | Support du chat |
| `localizationmanager` | `localization/localization_english.lua` | Textes anglais |

Chaînes de composition principales :

- `hook_mission_briefing` → factory de nœuds, contrôleurs skill/perk/outfit/BUILD et vue du bouton.
- `hook_weapon_inventory` → service d'inventaire + adaptateur Drag and Drop.
- `hook_weapon_modification` → service, contrôleur, adaptateur MWS, presenter, composant et vue.
- `hook_weapon_context_menu` → contrôleur des menus contextuels.

## 7. Cycle de vie d'une session de briefing

```text
Action utilisateur
  -> ControllerMenuNavigation:open
  -> StateBriefingSession:begin
       sauvegarder Global.block_update_outfit_information
       marquer opened_from_briefing
       bloquer les refreshs d'outfit
       masquer les éléments EHI suivis
       installer l'accès au chat
  -> managers.menu:open_node
  -> MissionBriefingGui:hide masque le briefing
  -> écran custom
  -> hook close / fermeture du composant
  -> StateBriefingSession:finish
       restaurer l'état et le blocage précédent
       restaurer EHI et le backdrop
       rafraîchir l'outfit
```

Si `open_node` échoue, `ControllerMenuNavigation` exécute `reset` avant le dialogue d'erreur. `MissionBriefingGui:init` et `close` nettoient aussi tout état résiduel.

Seuls l'arbre de compétences, le perk deck et l'éditeur d'armes utilisent cette session. Les tenues/gants passent par le nœud vanilla `loadout` et ne doivent pas créer de `StateBriefingSession`.

`ServiceWeaponInventory.context` est un état distinct : il marque la catégorie et la source d'une grille d'armes uniquement tant que `kit_menu` est actif.

## 8. Parcours des fonctionnalités

### BUILD

`MissionBriefingGui:init` enregistre les nœuds et crée le bouton. Le clic gauche appelle `ControllerBriefingMenu:show`, puis chaque callback QuickMenu délègue au contrôleur ou à l'adaptateur propriétaire.

### Compétences et perk decks

Le contrôleur vérifie les nœuds puis ouvre `skilltree_new` ou `skilltree` via `ControllerMenuNavigation`. Le hook `close` de la classe affichée termine la session correspondante.

### Tenues, gants et armure

`ControllerOutfit` ouvre le nœud vanilla `loadout` avec deux onglets construits par `ServiceOutfitMenu`. Les actions de preview/customisation 3D sont retirées, les actions d'équipement restent vanilla. L'armure délègue à `NewLoadoutTab:open_node(5)`.

### Inventaire d'armes

L'ouverture depuis `NewLoadoutTab` ou `PlayerInventoryGui` marque le contexte. Les hooks BlackMarket activent les actions sûres, reconstruisent les cases vides avec leur vrai slot, empêchent la vente de la dernière arme utilisable et retirent les previews 3D.

### Menus contextuels

Le clic droit est capturé dans `MissionBriefingGui:mouse_pressed`, car la classe parente ne le transmet pas. Les slots 1/2 ouvrent Inventaire/Modifier ; le slot 5 ouvre Gants/Tenue/Armure. Dans une grille BlackMarket marquée, `choose_weapon_mods_callback` ouvre l'éditeur 2D avec le `slot` exact. Tous les autres contextes appellent l'original.

### Modification d'armes

```text
ControllerWeaponModification:open(catégorie, slot?)
  -> paramètres du nœud
  -> ComponentWeaponModification
  -> ServiceWeaponModification:get_data
  -> ViewWeaponModification
confirmation
  -> nouvelle validation des verrous/compatibilité/quantité/prix
  -> conséquence et confirmation vanilla
  -> buy_and_modify_weapon / remove_weapon_part
  -> relecture du blueprint et refresh
```

Le service emploie `get_dropable_mods_by_weapon_id`, conserve `global_value`, contrôle les verrous de succès/contenu/milestone et résout les descriptions avec `get_part_desc_by_part_id_from_weapon`. Une localisation absente retourne une description vide.

Le composant pagine selon les constantes, préserve le ratio des icônes et ne touche jamais aux API de scène 3D.

### Statistiques

`PresenterWeaponStatistics` utilise `WeaponDescription._get_stats` pour comparer les blueprints courant et prévisualisé. Les lignes More Weapon Stats ne sont ajoutées qu'après validation complète de son adaptateur.

### Import/export

Le menu BUILD teste `AdapterPd2Builder:is_available()`. Les scripts de la dépendance sont exécutés sous `pcall`, puis un PostHook de `BuilderLoader:set_build` rafraîchit l'outfit.

## 9. Intégrations optionnelles

| Intégration | Adaptateur | Contrat de disponibilité | Comportement actif | Repli |
|---|---|---|---|---|
| PD2Builder loader | `build_transfer/adapter_pd2builder.lua` | Mod activé + méthodes `BuilderLoader` requises | Import/export et refresh après import | Entrées masquées |
| Drag and Drop Inventory | `weapon_inventory/adapter_drag_drop_inventory.lua` | Mod activé + globals/méthodes de pickup, place et swap | Déplacement/permutation par la dépendance | Équipement/achat/vente vanilla |
| More Weapon Stats | `weapon_modification/adapter_more_weapon_stats.lua` | Mod activé + `Faker`, options et calculateurs initialisés | Lignes statistiques étendues | Statistiques vanilla |
| EHI | `compatibility/adapter_ehi.lua` | `AddXPBreakdown` disponible | Suivi puis masquage/restauration des éléments XP | Aucune mutation |
| Chat/traducteur | `compatibility/adapter_chat.lua` | Classes chat ; `ChatTranslatorMessage` pour la traduction | Accès au chat et chaîne de traduction conservés | Fonctionnalités principales inchangées |
| Market Favorites | Aucun, volontairement | Hooks externes sur les populateurs vanilla réutilisés | Actions, badges et tri ajoutés par ce mod | Grilles vanilla |
| Mise à jour BeardLib | Aucun adaptateur Lua ; `main.xml` | BeardLib charge `AssetUpdates` et interroge le mod ModWorkshop `57999` | Comparaison sémantique au menu principal et téléchargement/install confirmé par l'utilisateur | Le mod fonctionne normalement sans vérification |

La disponibilité est testée au moment utile lorsque l'ordre d'initialisation peut varier. Les installations sont idempotentes. Aucun service principal ne conserve une structure de données appartenant à une dépendance.

L'updater est volontairement déclaratif et séparé des adaptateurs runtime. Ne pas ajouter en parallèle une section `updates` SuperBLT : deux gestionnaires pour une même publication provoqueraient des notifications et chemins d'installation concurrents.

## 10. Politique de compatibilité

- Préférer `PostHook`/`PreHook`.
- Un override capture l'original avec `Hooks:GetFunction` et lui délègue tous les contextes non ciblés.
- Ne jamais ouvrir l'atelier 3D depuis `kit_menu`.
- Ne jamais modifier `base`, BeardLib ou HopLib pour cette fonctionnalité.
- Protéger les managers, globals, classes et panels à cycle de vie variable.
- Conserver les IDs et façades historiques.
- Revérifier les verrous et conséquences juste avant toute mutation.
- Transmettre `category`, `slot` et `global_value` sans perte.
- Considérer les mods optionnels comme des capacités vérifiées, pas comme des installations présumées.
- Ne pas contourner la chaîne d'overrides de `BlackMarketGui`, `MissionBriefingGui` ou des entrées souris.

Surfaces à risque : Drag and Drop Inventory, MultipleWeaponModRows, More Weapon Stats, HUDs custom, EHI et gestionnaires de profils.

## 11. Comment faire évoluer le mod

Cette partie est un guide d'implémentation. L'objectif n'est pas seulement de faire fonctionner une action, mais de l'intégrer à un emplacement qu'un autre moddeur PAYDAY 2 pourra comprendre, tester et maintenir.

### 11.1 Définir le contrat de la fonctionnalité

Avant de modifier le code, répondre à cinq questions :

| Question | Exemple |
|---|---|
| Quel événement déclenche la fonctionnalité ? | Clic sur BUILD, clic droit sur un slot, callback du jeu |
| Quelles données identifient la cible ? | `category`, `slot` fabriqué, onglet sélectionné |
| Quel objet possède la donnée de référence ? | `managers.blackmarket`, `managers.skilltree`, nœud actif |
| Quel état sera modifié ? | Navigation, UI locale, inventaire ou économie |
| Quel est le repli sûr ? | Masquer l'option, appeler l'original, afficher une erreur contrôlée |

Ce contrat détermine les composants nécessaires :

- le clic entre dans un contrôleur ;
- une lecture ou mutation du jeu appartient à un service ;
- un global d'un autre mod reste derrière un adaptateur ;
- la création des panels appartient à une vue ou un composant.

Ne pas commencer par écrire la logique dans un hook. Le hook est uniquement le point d'entrée runtime.

### 11.2 Trouver et valider le point d'extension PAYDAY 2

Employer un dump Lua correspondant à la version installée du jeu :

1. Trouver la classe et la méthode qui portent le comportement vanilla.
2. Lire la méthode entière : arguments, valeur de retour et champs utilisés sur `self`.
3. Lire ses appelants. Certaines méthodes ne sont valides qu'après la création d'un nœud ou d'une scène.
4. Rechercher les mods locaux qui hookent la même méthode.
5. Vérifier si `mod.txt` charge déjà Briefing Enhanced au moment où cette classe existe.

Recherches utiles :

```powershell
rg -n "function MissionBriefingGui:mouse_pressed" <DUMP_LUA_PAYDAY_2>
rg -n --glob "*.lua" "Hooks:(PostHook|PreHook|OverrideFunction).*mouse_pressed" "PAYDAY 2/mods"
rg -n "lib/managers/menu/missionbriefinggui" "Briefing Build Menu/mod.txt"
```

Choisir le mécanisme le moins intrusif :

| Besoin | Mécanisme |
|---|---|
| Observer ou ajuster les données après leur création vanilla | `Hooks:PostHook` |
| Marquer un contexte avant l'exécution vanilla | `Hooks:PreHook` |
| Consommer une entrée ou rediriger une branche précise | `Hooks:OverrideFunction`, original sauvegardé |

Patron d'override sûr :

```lua
local original_mouse_pressed = Hooks:GetFunction(MissionBriefingGui, "mouse_pressed")

Hooks:OverrideFunction(MissionBriefingGui, "mouse_pressed", function(gui, button, x, y)
	if button == Idstring("1")
		and BE.ControllerExample:try_handle(gui, x, y) then
		return true
	end

	return original_mouse_pressed(gui, button, x, y)
end)
```

Le retour `true` signifie que l'événement est consommé. Le retourner pour un clic non concerné peut casser silencieusement une autre UI ou un autre mod.

### 11.3 Créer le dossier et la chaîne de chargement

Pour une fonctionnalité `profile_summary`, commencer avec le minimum :

```text
lua/profile_summary/
├── controller_profile_summary.lua
└── hook_profile_summary.lua   # uniquement si un nouveau déclencheur est nécessaire
```

Ajouter un service, une vue ou un adaptateur uniquement si cette responsabilité existe. Une couche vide n'améliore pas l'architecture.

Chaque module doit supporter plusieurs chargements :

```lua
BriefingEnhanced = BriefingEnhanced or BriefingBuildMenu or {}

local BE = BriefingEnhanced

BE.ControllerProfileSummary = BE.ControllerProfileSummary or {}

function BE.ControllerProfileSummary:show()
	-- Orchestration uniquement.
end
```

Si un fichier d'entrée existant est déjà chargé au bon moment, y composer le module :

```lua
dofile(BriefingEnhanced.ModPath .. "lua/profile_summary/controller_profile_summary.lua")
```

Ajouter une entrée dans `mod.txt` seulement si une autre classe PAYDAY 2 doit exister :

```json
{
    "hook_id": "lib/managers/menu/examplegui",
    "script_path": "lua/profile_summary/hook_profile_summary.lua"
}
```

Pour un hook chargé par plusieurs `hook_id`, filtrer `RequiredScript` et protéger l'installation :

```lua
local required_script = string.lower(RequiredScript or "")

BE.HookProfileSummary = BE.HookProfileSummary or {}

if required_script == "lib/managers/menu/examplegui"
	and not BE.HookProfileSummary.example_gui then
	BE.HookProfileSummary.example_gui = true

	Hooks:PostHook(ExampleGui, "init", "BriefingEnhanced_ProfileSummary_Init", function(gui)
		BE.ControllerProfileSummary:on_gui_ready(gui)
	end)
end
```

### 11.4 Tutoriel : ajouter une action simple à BUILD

Cet exemple ajoute un résumé du profil sous forme de dialogue, sans créer d'écran custom.

**Étape 1 — créer le contrôleur**

Créer `lua/profile_summary/controller_profile_summary.lua` :

```lua
BriefingEnhanced = BriefingEnhanced or BriefingBuildMenu or {}

local BE = BriefingEnhanced

BE.ControllerProfileSummary = BE.ControllerProfileSummary or {}

function BE.ControllerProfileSummary:show()
	if not (managers.experience and managers.localization) then
		return false
	end

	local level = managers.experience:current_level() or 0

	QuickMenu:new(
		managers.localization:text("bbm_profile_summary_title"),
		managers.localization:text("bbm_profile_summary_text", {
			LEVEL = tostring(level)
		}),
		{
			{
				text = managers.localization:text("dialog_ok"),
				is_cancel_button = true
			}
		},
		true
	)

	return true
end
```

Le contrôleur valide le runtime, lit la valeur nécessaire et coordonne l'ouverture. Il ne crée pas lui-même de panel Diesel.

**Étape 2 — charger le contrôleur**

Dans `briefing_menu/hook_mission_briefing.lua`, ajouter avec les autres `dofile` :

```lua
dofile(BriefingEnhanced.ModPath .. "lua/profile_summary/controller_profile_summary.lua")
```

**Étape 3 — ajouter l'option**

Dans la table `options` de `ControllerBriefingMenu:show`, avant `add_cancel_option(options)` :

```lua
{
	text = managers.localization:text("bbm_profile_summary_title"),
	callback = function()
		BE.ControllerProfileSummary:show()
	end
}
```

**Étape 4 — ajouter les textes**

Ajouter ces entrées dans la table existante passée à `add_localized_strings` dans `localization/localization_english.lua` :

```lua
bbm_profile_summary_title = "PROFILE SUMMARY",
bbm_profile_summary_text = "Current level: $LEVEL",
```

**Étape 5 — tester le parcours**

Redémarrer le jeu, ouvrir BUILD plusieurs fois, déclencher l'action, fermer avec la souris puis le clavier et vérifier qu'aucune option n'est dupliquée après le retour au briefing.

Ce dialogue ne masque pas le briefing et n'ouvre aucun nœud : il ne doit pas démarrer de `StateBriefingSession`.

### 11.5 Tutoriel : ajouter un écran custom au briefing

Un écran custom nécessite un nœud, l'enregistrement d'un composant, un état interactif, une vue et un nettoyage.

**Étape 1 — enregistrer le nœud**

Étendre `FactoryBriefingNode:ensure_all` :

```lua
self:ensure(menu, "briefing_enhanced_example_node", {
	menu_components = "briefing_enhanced_example_component",
	topic_id = "bbm_example_title"
})
```

`CoreMenuNode.MenuNode:new` ignore certaines tables imbriquées. Les données complexes doivent être affectées après la construction via `node:parameters()`, comme le fait la factory.

**Étape 2 — déclarer le composant**

Les méthodes doivent être déclarées depuis un hook sur `menucomponentmanager` :

```lua
function MenuComponentManager:create_briefing_enhanced_example(node)
	self._be_example = BE.ComponentExample:new(
		self:saferect_ws(),
		self:fullscreen_ws(),
		node
	)
	self:register_component("briefing_enhanced_example_component", self._be_example)
end

function MenuComponentManager:close_briefing_enhanced_example()
	if self._be_example then
		self:unregister_component("briefing_enhanced_example_component")
		self._be_example:close()
		self._be_example = nil
	end

	if BE.StateBriefingSession:current_screen() == "example" then
		BE.StateBriefingSession:finish("example")
	end
end
```

Enregistrer ensuite ces callbacks dans `_active_components`, sur le modèle de `FactoryBriefingNode` pour l'éditeur d'armes.

**Étape 3 — ouvrir par le contrôleur de navigation**

```lua
function BE.ControllerExample:open()
	if not BE.FactoryBriefingNode:ensure_all() then
		return false
	end

	return BE.ControllerMenuNavigation:open(
		"example",
		"briefing_enhanced_example_node"
	)
end
```

Ne pas appeler séparément `StateBriefingSession:begin`. `ControllerMenuNavigation` possède le début de session et le `reset` en cas d'échec de `open_node`.

**Étape 4 — séparer composant et vue**

Le composant porte la sélection, la page et les entrées clavier/souris. La vue reçoit des valeurs déjà préparées et crée/met à jour les panels. `close` doit retirer chaque panel du workspace qui l'a créé.

**Étape 5 — prouver le nettoyage**

Tester Retour normal, ouvertures rapides répétées, échec de `open_node`, fermeture du lobby et retour au menu principal. Après chaque parcours, `Global.block_update_outfit_information` doit retrouver sa valeur précédente.

### 11.6 Tutoriel : ajouter une intégration optionnelle

Supposons qu'un mod `Example Stats` fournisse `ExampleStats:get_value`.

**Étape 1 — isoler la détection et l'appel**

Créer `adapter_example_stats.lua` dans le dossier de la fonctionnalité consommatrice :

```lua
BriefingEnhanced = BriefingEnhanced or BriefingBuildMenu or {}

local BE = BriefingEnhanced

BE.AdapterExampleStats = BE.AdapterExampleStats or {}

function BE.AdapterExampleStats:is_available()
	if not (BLT and BLT.Mods and BLT.Mods.GetModByName) then
		return false
	end

	local mod = BLT.Mods:GetModByName("Example Stats")

	return mod ~= nil
		and mod:IsEnabled()
		and ExampleStats ~= nil
		and type(ExampleStats.get_value) == "function"
end

function BE.AdapterExampleStats:get_value(weapon_id)
	if not self:is_available() then
		return nil
	end

	local success, value = pcall(ExampleStats.get_value, ExampleStats, weapon_id)

	return success and value or nil
end
```

Tester le mod activé ne suffit pas : chaque global et méthode appelée doit être présent. `pcall` protège une API optionnelle susceptible de changer.

**Étape 2 — consommer une capacité**

```lua
local value = BE.AdapterExampleStats:get_value(weapon.weapon_id)

if value ~= nil then
	table.insert(rows, {
		name = "EXAMPLE",
		value = tostring(value)
	})
end
```

Les lignes vanilla sont construites indépendamment de l'adaptateur.

**Étape 3 — tester quatre états**

Tester la dépendance absente, installée mais désactivée, activée avant le briefing, puis activée avec une méthode attendue manquante. Seul le contrat complet active l'intégration.

### 11.7 Tutoriel : ajouter ou modifier une transaction

L'état affiché par l'UI n'est jamais l'autorité de transaction. Toutes les conditions mutables sont relues dans la callback de confirmation :

```lua
params.yes_func = function()
	local current = BE.ServiceExample:get_current_data(category, slot)

	if not current or not BE.ServiceExample:can_apply(current, selected_id) then
		managers.menu_component:post_event("menu_error")
		return
	end

	BE.ServiceExample:apply(current, selected_id)
	BE.ControllerExample:refresh()
end
```

Employer une closure lorsque plusieurs valeurs doivent survivre jusqu'à la confirmation. La fonction globale `callback` de PAYDAY 2 ne capture qu'un paramètre fixe.

Pour une pièce d'arme, conserver `category`, le `slot` fabriqué, `part_id` et `global_value`. Revérifier succès, milestone, contenu, compatibilité, quantité, prix et `get_modify_weapon_consequence` immédiatement avant `buy_and_modify_weapon`.

### 11.8 Tutoriel : ajouter une donnée à l'éditeur d'armes

1. Lire et valider la donnée brute dans `ServiceWeaponModification`.
2. L'ajouter à la structure retournée par le service ; la vue ne doit pas interroger `managers.blackmarket`.
3. Formater les valeurs calculées dans `PresenterWeaponStatistics`.
4. Les rendre dans `ViewWeaponModification` avec les polices, couleurs et dimensions du safe rect.
5. Après installation/retrait, relire le blueprint puis rafraîchir.
6. Tester l'arme équipée et un slot fabriqué explicite non équipé.

Pour une texture, préserver son ratio :

```lua
local scale = math.min(frame_w / texture_w, frame_h / texture_h)
local width = texture_w * scale
local height = texture_h * scale

bitmap:set_size(width, height)
bitmap:set_center(frame:center())
```

Ne jamais imposer simultanément la largeur et la hauteur de la frame à une image.

### 11.9 Tutoriel : ajouter une action au clic droit

1. Ajouter la détection et le routage à `ControllerWeaponContextMenu`.
2. Vérifier que le briefing est actif, qu'aucun asset n'est affiché et que le blackscreen n'a pas commencé.
3. Mettre à jour l'élément sélectionné de `NewLoadoutTab`.
4. Déléguer à un nœud/callback vanilla sûr ou au contrôleur propriétaire.
5. Retourner `true` uniquement après l'ouverture du menu contextuel.
6. Appeler l'original pour chaque bouton, coordonnée ou élément non concerné.

Conserver un ordre déterministe et ajouter Annuler en dernier :

```lua
local options = {
	{
		text = managers.localization:text("bbm_example_action"),
		callback = function()
			BE.ControllerExample:open()
		end
	}
}

table.insert(options, {
	text = managers.localization:text("dialog_cancel"),
	is_cancel_button = true
})
```

### 11.10 Tutoriel : publier une mise à jour compatible BeardLib

`main.xml` constitue l'unique déclaration de mise à jour :

```xml
<table name="Briefing Enhanced">
	<AssetUpdates
		id="57999"
		provider="modworkshop"
		version="1.10.0"
		semantic_version="true"
	/>
</table>
```

Pour chaque publication :

1. Choisir une version sémantique sans préfixe `v` dans le repository, par exemple `1.11.0`.
2. Reporter exactement cette version dans `mod.txt` et `main.xml`.
3. Publier cette version sur le mod ModWorkshop `57999`. BeardLib accepte le préfixe `v` renvoyé par ModWorkshop, mais les fichiers du repository restent normalisés.
4. Construire un ZIP possédant un seul dossier racine `Briefing Build Menu/`, qui contient directement `mod.txt`, `main.xml`, la documentation et `lua/`.
5. Conserver le remplacement complet par défaut. Ne pas définir `dont_delete="true"` : un ancien script Lua résiduel est plus dangereux qu'une installation propre.
6. Ne jamais stocker les préférences utilisateur dans le dossier du mod, car il est remplacé. Employer `SavePath`.
7. Installer l'ancienne version publique dans une copie de test, ouvrir le menu principal et vérifier que BeardLib détecte la nouvelle version.
8. Confirmer le téléchargement, redémarrer PAYDAY 2 puis vérifier les fichiers installés et la version affichée.

La vérification et la notification sont automatiques. Le téléchargement et l'installation restent confirmés par l'utilisateur. Ne pas appeler `BeardLib.Menus.Mods:ForceDownload` depuis le mod.

### 11.11 Checklist de review

Avant de considérer l'implémentation terminée :

1. Vérifier que le dossier propriétaire et les types de composants correspondent à leurs responsabilités.
2. Vérifier les IDs stables et gardes d'installation de chaque hook.
3. Vérifier que les overrides délèguent hors de leur contexte exact.
4. Vérifier le nettoyage normal, sur erreur et sur fermeture forcée de chaque session.
5. Protéger tous les managers, globals, classes et panels selon leur cycle de vie.
6. Vérifier les localisations et empêcher qu'un texte externe absent affiche `ERROR:`.
7. Vérifier le parcours sans chaque dépendance optionnelle.
8. Rechercher les logs de debug, la syntaxe Lua 5.2 et les modifications de dépendances partagées.
9. Exécuter les lignes concernées de la matrice puis lire les nouveaux logs SuperBLT et Diesel.

## 12. Matrice minimale de tests en jeu

| Zone | Cas obligatoires | Résultat attendu |
|---|---|---|
| Démarrage | Dépendances minimales ; toutes les options activées | Aucun load error ; BUILD visible |
| Cycle BUILD | Ouvrir/fermer chaque action ; Back ; nœud indisponible | Aucun overlay, input ou blocage d'outfit résiduel |
| Skills/perks | Ouvrir, modifier, fermer | Profil courant mis à jour ; briefing restauré |
| Tenues/gants/armure | Équiper chaque type ; Back | Outfit actualisé ; aucun crash 3D |
| Inventaire armes | Primaire/secondaire ; équiper ; acheter slot/arme ; vendre | Bonne catégorie, bon slot, économie vanilla |
| Garde de vente | Dernière arme ; dernière arme déverrouillée | Action de vente absente |
| Menus contextuels | Deux armes, armure et Cancel | Bon ordre ; entrées non ciblées intactes |
| Éditeur | Arme équipée + slot explicite ; installer/remplacer/retirer | Blueprint, quantités et argent corrects |
| Verrous | Succès, milestone, DLC/contenu, incompatibilité | Aucune transaction interdite |
| UI éditeur | Plusieurs pages ; icônes larges/hautes ; description absente | Pagination/ratio corrects ; aucun `ERROR:` |
| Statistiques | Pièce courante/sélectionnée ; MWS actif/inactif | Valeurs vanilla ; lignes optionnelles conditionnelles |
| Drag and Drop | Absent/désactivé/actif ; move/swap/place/cancel | Repli sûr ; profils/bots cohérents |
| HUD/chat | EHI et HUD/chat compatibles actifs/inactifs | Overlays restaurés ; chat utilisable |
| Updater | BeardLib absent ; version distante égale/inférieure/supérieure ; Ignore Updates ; ZIP valide/invalide | Mod fonctionnel sans BeardLib ; seule une version sémantique supérieure est proposée ; une archive invalide ne remplace pas le mod |
| Session | Hôte/client ; ready/unready ; retour menu | Aucun état résiduel ni exigence côté pair |
| Rechargement | Redémarrage ; reload SuperBLT local si utilisé | Aucun hook/composant dupliqué |

Validations statiques :

```powershell
Get-Content -Raw "Briefing Build Menu/mod.txt" | ConvertFrom-Json
[xml](Get-Content -Raw "Briefing Build Menu/main.xml") | Out-Null
rg -n "log\(|Application:error|io\.write|print\(" "Briefing Build Menu/lua"
rg -n "BriefingBuildMenu_|bbm_" "Briefing Build Menu/lua"
```

Les tests en jeu restent obligatoires : les contrôles statiques ne reproduisent pas le cycle de vie des menus Diesel.
