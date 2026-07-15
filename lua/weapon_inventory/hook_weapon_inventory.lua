local mod_path = ModPath
local required_script = string.lower(RequiredScript or "")

dofile(mod_path .. "lua/core/bootstrap.lua")
dofile(BriefingEnhanced.ModPath .. "lua/weapon_inventory/adapter_drag_drop_inventory.lua")
dofile(BriefingEnhanced.ModPath .. "lua/weapon_inventory/service_weapon_inventory.lua")

local BE = BriefingEnhanced
local Inventory = BE.ServiceWeaponInventory

BE.HookWeaponInventory = BE.HookWeaponInventory or {}

if required_script == "lib/managers/menu/playerinventorygui" and not BE.HookWeaponInventory.player_inventory then
	BE.HookWeaponInventory.player_inventory = true

	Hooks:PostHook(PlayerInventoryGui, "init", "BriefingBuildMenu_PlayerInventoryGui_init", function(gui)
		Inventory:finish("player_inventory")

		if Inventory:is_kit_menu_active() then
			for _, box_name in ipairs({ "primary", "secondary" }) do
				local box = gui._boxes_by_name and gui._boxes_by_name[box_name]

				if box and box.clbks then
					box.clbks.right = false
				end
			end
		end
	end)

	Hooks:PreHook(PlayerInventoryGui, "open_weapon_category_menu", "BriefingBuildMenu_PlayerInventoryGui_open_weapon_category_menu", function(_, category)
		Inventory:begin(category, "player_inventory")
	end)
elseif required_script == "lib/managers/menu/missionbriefinggui" and not BE.HookWeaponInventory.mission_briefing then
	BE.HookWeaponInventory.mission_briefing = true

	local function begin_from_loadout_index(index, source)
		local category = index == 1 and "primaries" or index == 2 and "secondaries" or nil

		if category then
			Inventory:begin(category, source)
		end
	end

	if NewLoadoutTab then
		Hooks:PostHook(NewLoadoutTab, "init", "BriefingBuildMenu_NewLoadoutTab_init", function()
			Inventory:finish("new_loadout")
		end)

		Hooks:PreHook(NewLoadoutTab, "open_node", "BriefingBuildMenu_NewLoadoutTab_open_node", function(_, index)
			begin_from_loadout_index(index, "new_loadout")
		end)

		Hooks:PostHook(NewLoadoutTab, "populate_category", "BriefingBuildMenu_NewLoadoutTab_populate_category", function(_, data)
			Inventory:configure_purchase_slots(data, data and data.category)
			Inventory:configure_inventory_actions(data, data and data.category)
		end)

		Hooks:PostHook(NewLoadoutTab, "create_weapon_loadout", "BriefingBuildMenu_NewLoadoutTab_create_weapon_loadout", function(_, category)
			if Inventory:is_active(category) then
				BE.AdapterDragDropInventory:enable_for_loadout_node(Hooks:GetReturn())
			end
		end)
	end

	if LoadoutItem then
		Hooks:PostHook(LoadoutItem, "init", "BriefingBuildMenu_LoadoutItem_init", function()
			Inventory:finish("legacy_loadout")
		end)

		Hooks:PreHook(LoadoutItem, "open_node", "BriefingBuildMenu_LoadoutItem_open_node", function(_, index)
			begin_from_loadout_index(index, "legacy_loadout")
		end)

		Hooks:PostHook(LoadoutItem, "populate_category", "BriefingBuildMenu_LoadoutItem_populate_category", function(_, category, data)
			Inventory:configure_purchase_slots(data, category)
			Inventory:configure_inventory_actions(data, category)
		end)
	end
elseif required_script == "lib/managers/menu/blackmarketgui" and not BE.HookWeaponInventory.blackmarket then
	BE.HookWeaponInventory.blackmarket = true

	Hooks:PreHook(BlackMarketGui, "populate_weapon_category_new", "BriefingBuildMenu_BlackMarketGui_populate_weapon_category_new", function(_, data)
		if Inventory:is_active(data and data.category) then
			data.allow_buy = true
			data.allow_modify = false
			data.allow_preview = false
			data.allow_sell = true
			data.allow_skinning = false
		end
	end)

	Hooks:PostHook(BlackMarketGui, "populate_buy_weapon", "BriefingBuildMenu_BlackMarketGui_populate_buy_weapon", function(_, data)
		Inventory:remove_unsafe_purchase_actions(data)
	end)

	Hooks:PostHook(BlackMarketGui, "_sell_weapon_callback", "BriefingBuildMenu_BlackMarketGui_sell_weapon_callback", function(_, data)
		if Inventory:is_active(data and data.category) then
			BE.ServiceOutfit:sync_while_blocked()
		end
	end)
end

