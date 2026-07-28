BriefingEnhanced = BriefingEnhanced or BriefingBuildMenu or {}

local BE = BriefingEnhanced

BE.ControllerWeaponContextMenu = BE.ControllerWeaponContextMenu or {}

local ARMOR_LOADOUT_INDEX = 5

local function add_cancel_option(options)
	table.insert(options, {
		text = managers.localization:text("dialog_cancel"),
		is_cancel_button = true
	})
end

local function select_loadout_item(loadout, index)
	local previous_index = loadout._item_selected
	local previous_item = previous_index and loadout._items and loadout._items[previous_index]
	local item = loadout._items and loadout._items[index]

	if not item then
		return false
	end

	if previous_item and previous_item ~= item then
		previous_item:deselect_item()
	end

	loadout._item_selected = index
	loadout._my_menu_component_data.selected = index
	item:select_item()

	return true
end

function BE.ControllerWeaponContextMenu:show_briefing(loadout, index)
	if not (BE.ServiceWeaponModification and BE.ControllerWeaponModification)
		or managers.job:is_forced()
		or not select_loadout_item(loadout, index) then
		return false
	end

	local category = index == 1 and "primaries" or index == 2 and "secondaries" or nil
	local weapon = category and BE.ServiceWeaponModification:get_weapon(category)

	if not weapon then
		return false
	end

	local options = {
		{
			text = managers.localization:text("bbm_weapon_context_inventory"),
			callback = function()
				if loadout and loadout.open_node then
					loadout:open_node(index)
				end
			end
		},
		{
			text = managers.localization:text("bm_menu_btn_mod"),
			callback = function()
				if BE.ControllerWeaponModification then
					BE.ControllerWeaponModification:open(category, weapon.slot)
				end
			end
		}
	}

	add_cancel_option(options)
	managers.menu_component:post_event("menu_enter")
	QuickMenu:new(
		managers.localization:text("bbm_weapon_context_title", {
			WEAPON = weapon.name
		}),
		managers.localization:text("bbm_weapon_context_description"),
		options,
		true
	)

	return true
end

function BE.ControllerWeaponContextMenu:show_armor(loadout)
	if not BE.ControllerOutfit
		or managers.job:is_forced()
		or not select_loadout_item(loadout, ARMOR_LOADOUT_INDEX) then
		return false
	end

	local options = {
		{
			text = managers.localization:text("bbm_armor_context_gloves"),
			callback = function()
				BE.ControllerOutfit:open_gloves()
			end
		},
		{
			text = managers.localization:text("bbm_armor_context_outfit"),
			callback = function()
				BE.ControllerOutfit:open_player_styles()
			end
		},
		{
			text = managers.localization:text("bbm_armor_context_armor"),
			callback = function()
				if loadout and loadout.open_node then
					loadout:open_node(ARMOR_LOADOUT_INDEX)
				end
			end
		}
	}

	add_cancel_option(options)
	managers.menu_component:post_event("menu_enter")
	QuickMenu:new(
		managers.localization:text("bbm_armor_context_title"),
		managers.localization:text("bbm_armor_context_description"),
		options,
		true
	)

	return true
end

function BE.ControllerWeaponContextMenu:try_show_briefing(gui, x, y)
	if not (gui and gui._enabled and not gui._displaying_asset) then
		return false
	end

	local state = game_state_machine and game_state_machine:current_state()

	if state and state.blackscreen_started and state:blackscreen_started() then
		return false
	end

	local loadout = gui._new_loadout_item

	if not (loadout and gui._items and gui._items[gui._selected_item] == loadout) then
		return false
	end

	for index = 1, 2 do
		local item = loadout._items and loadout._items[index]

		if item and item:inside(x, y) then
			return self:show_briefing(loadout, index)
		end
	end

	local armor_item = loadout._items and loadout._items[ARMOR_LOADOUT_INDEX]

	if armor_item and armor_item:inside(x, y) then
		return self:show_armor(loadout)
	end

	return false
end
