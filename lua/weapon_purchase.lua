BriefingBuildMenu = BriefingBuildMenu or {}

local BBM = BriefingBuildMenu
local required_script = string.lower(RequiredScript or "")

BBM._weapon_purchase_hooks = BBM._weapon_purchase_hooks or {}

local function is_weapon_category(category)
	return category == "primaries" or category == "secondaries"
end

function BBM:is_kit_menu_active()
	local active_menu = managers.menu and managers.menu:active_menu()

	return active_menu and active_menu.id == "kit_menu"
end

function BBM:begin_weapon_purchase(category, source)
	if not self:is_kit_menu_active() or not is_weapon_category(category) then
		return false
	end

	self.weapon_purchase_context = {
		category = category,
		source = source
	}

	return true
end

function BBM:end_weapon_purchase(source)
	local context = self.weapon_purchase_context

	if context and (not source or context.source == source) then
		self.weapon_purchase_context = nil
	end
end

function BBM:is_weapon_purchase_active(category)
	local context = self.weapon_purchase_context

	return context ~= nil
		and self:is_kit_menu_active()
		and (not category or context.category == category)
end

local function remove_action(item, action_name)
	for index = #item, 1, -1 do
		if item[index] == action_name then
			table.remove(item, index)
		end
	end
end

local function add_action(item, action_name)
	for _, existing_action in ipairs(item) do
		if existing_action == action_name then
			return
		end
	end

	table.insert(item, action_name)
end

function BBM:is_drag_drop_inventory_available()
	if not (BLT and BLT.Mods and BLT.Mods.GetModByName) then
		return false
	end

	local mod = BLT.Mods:GetModByName("Drag and Drop Inventory")

	return mod ~= nil
		and mod:IsEnabled()
		and DragDropInventory ~= nil
		and managers.blackmarket ~= nil
		and managers.blackmarket.pickup_crafted_item ~= nil
		and managers.blackmarket.place_crafted_item ~= nil
		and managers.multi_profile ~= nil
		and managers.multi_profile.ddi_swap_item ~= nil
end

local function get_weapon_category_state(category)
	local crafted_category = managers.blackmarket:get_crafted_category(category) or {}
	local category_size = table.size(crafted_category)
	local unlocked_count = 0

	for _, crafted in pairs(crafted_category) do
		if managers.blackmarket:weapon_unlocked(crafted.weapon_id) then
			unlocked_count = unlocked_count + 1
		end
	end

	return crafted_category, category_size == 1, unlocked_count == 1
end

function BBM:enable_inventory_actions_on_loadout_slots(data, category)
	if not self:is_weapon_purchase_active(category) or not data then
		return
	end

	local crafted_category, last_weapon, last_unlocked_weapon = get_weapon_category_state(category)
	local hold = managers.blackmarket:get_hold_crafted_item()
	local currently_holding = hold and hold.category == category
	local drag_drop_available = self:is_drag_drop_inventory_available()

	for _, item in ipairs(data) do
		local crafted = item and item.slot and crafted_category[item.slot]

		if crafted and not item.empty_slot then
			remove_action(item, "w_sell")
			remove_action(item, "w_move")
			remove_action(item, "w_swap")
			remove_action(item, "i_stop_move")

			if currently_holding then
				remove_action(item, "lo_w_equip")

				if item.slot ~= hold.slot then
					add_action(item, "w_swap")
				end

				add_action(item, "i_stop_move")
			else
				item.last_weapon = last_weapon or item.unlocked and last_unlocked_weapon

				if not item.last_weapon then
					add_action(item, "w_sell")
				end

				if drag_drop_available and item.equipped and item.unlocked then
					add_action(item, "w_move")
				end
			end
		end
	end
end

local function configure_unlocked_slot(item, category, slot)
	item.name = "bm_menu_btn_buy_new_weapon"
	item.name_localized = managers.localization:text("bm_menu_empty_weapon_slot")
	item.name_localized_selected = item.name_localized
	item.category = category
	item.slot = slot
	item.empty_slot = true
	item.unlocked = true
	item.equipped = false
	item.is_loadout = true
	item.mid_text = {
		noselected_text = item.name_localized,
		noselected_color = tweak_data.screen_colors.button_stage_3,
		selected_text = managers.localization:text("bm_menu_btn_buy_new_weapon"),
		selected_color = tweak_data.screen_colors.button_stage_2,
		is_lock_same_color = true
	}

	local hold = managers.blackmarket:get_hold_crafted_item()

	if hold and hold.category == category then
		item.mid_text.selected_text = managers.localization:text("bm_menu_btn_place_weapon")
		add_action(item, "w_place")
		add_action(item, "i_stop_move")
	else
		add_action(item, "ew_buy")
	end
end

local function configure_locked_slot(item, category, slot)
	local price = managers.money:get_buy_weapon_slot_price()

	item.name = "bm_menu_btn_buy_weapon_slot"
	item.name_localized = managers.localization:text("bm_menu_locked_weapon_slot")
	item.name_localized_selected = item.name_localized
	item.category = category
	item.slot = slot
	item.empty_slot = true
	item.unlocked = true
	item.equipped = false
	item.is_loadout = true
	item.locked_slot = true
	item.lock_texture = "guis/textures/pd2/blackmarket/money_lock"
	item.lock_color = tweak_data.screen_colors.button_stage_3
	item.lock_shape = { x = 0, y = -32, w = 32, h = 32 }
	item.dlc_locked = managers.experience:cash_string(price)
	item.mid_text = {
		noselected_text = item.name_localized,
		noselected_color = tweak_data.screen_colors.button_stage_3,
		is_lock_same_color = true
	}

	if managers.money:can_afford_buy_weapon_slot() then
		item.mid_text.selected_text = managers.localization:text("bm_menu_btn_buy_weapon_slot")
		item.mid_text.selected_color = tweak_data.screen_colors.button_stage_2
		table.insert(item, "ew_unlock")
	else
		item.cannot_buy = true
		item.mid_text.selected_text = managers.localization:text("bm_menu_cannot_buy_weapon_slot")
		item.mid_text.selected_color = tweak_data.screen_colors.important_1
		item.mid_text.lock_noselected_color = tweak_data.screen_colors.important_1
		item.dlc_locked = item.dlc_locked .. "  " .. managers.localization:to_upper_text("bm_menu_cannot_buy_weapon_slot")
	end
end

function BBM:enable_purchase_on_loadout_slots(data, category)
	if not self:is_weapon_purchase_active(category) or not data or not data.on_create_data then
		return
	end

	for grid_index, slot in pairs(data.on_create_data) do
		local item = data[grid_index]

		if item and item.empty_slot and #item == 0 then
			if managers.blackmarket:is_weapon_slot_unlocked(category, slot) then
				configure_unlocked_slot(item, category, slot)
			else
				configure_locked_slot(item, category, slot)
			end
		end
	end
end

function BBM:remove_unsafe_purchase_actions(data)
	if not self:is_weapon_purchase_active(data and data.category) then
		return
	end

	for index = 1, #data do
		local item = data[index]

		if item then
			remove_action(item, "bw_preview")
			remove_action(item, "bw_preview_mods")
		end
	end
end

if required_script == "lib/managers/menu/playerinventorygui" and not BBM._weapon_purchase_hooks.player_inventory then
	BBM._weapon_purchase_hooks.player_inventory = true

	Hooks:PostHook(PlayerInventoryGui, "init", "BriefingBuildMenu_PlayerInventoryGui_init", function(self)
		BBM:end_weapon_purchase("player_inventory")

		if BBM:is_kit_menu_active() then
			for _, box_name in ipairs({ "primary", "secondary" }) do
				local box = self._boxes_by_name and self._boxes_by_name[box_name]

				if box and box.clbks then
					box.clbks.right = false
				end
			end
		end
	end)

	Hooks:PreHook(PlayerInventoryGui, "open_weapon_category_menu", "BriefingBuildMenu_PlayerInventoryGui_open_weapon_category_menu", function(_, category)
		BBM:begin_weapon_purchase(category, "player_inventory")
	end)
elseif required_script == "lib/managers/menu/missionbriefinggui" and not BBM._weapon_purchase_hooks.mission_briefing then
	BBM._weapon_purchase_hooks.mission_briefing = true

	local function begin_from_loadout_index(index, source)
		local category = index == 1 and "primaries" or index == 2 and "secondaries" or nil

		if category then
			BBM:begin_weapon_purchase(category, source)
		end
	end

	if NewLoadoutTab then
		Hooks:PostHook(NewLoadoutTab, "init", "BriefingBuildMenu_NewLoadoutTab_init", function()
			BBM:end_weapon_purchase("new_loadout")
		end)

		Hooks:PreHook(NewLoadoutTab, "open_node", "BriefingBuildMenu_NewLoadoutTab_open_node", function(_, index)
			begin_from_loadout_index(index, "new_loadout")
		end)

		Hooks:PostHook(NewLoadoutTab, "populate_category", "BriefingBuildMenu_NewLoadoutTab_populate_category", function(_, data)
			BBM:enable_purchase_on_loadout_slots(data, data and data.category)
			BBM:enable_inventory_actions_on_loadout_slots(data, data and data.category)
		end)

		Hooks:PostHook(NewLoadoutTab, "create_weapon_loadout", "BriefingBuildMenu_NewLoadoutTab_create_weapon_loadout", function(_, category)
			local node_data = Hooks:GetReturn()

			if node_data and BBM:is_weapon_purchase_active(category) and BBM:is_drag_drop_inventory_available() then
				-- Drag and Drop Inventory intentionally ignores loadout nodes. In the briefing
				-- this node already carries its own explicit actions, so exposing it as a
				-- regular weapon grid safely enables the mod's native mouse handlers.
				node_data.is_loadout = false
			end
		end)
	end

	if LoadoutItem then
		Hooks:PostHook(LoadoutItem, "init", "BriefingBuildMenu_LoadoutItem_init", function()
			BBM:end_weapon_purchase("legacy_loadout")
		end)

		Hooks:PreHook(LoadoutItem, "open_node", "BriefingBuildMenu_LoadoutItem_open_node", function(_, index)
			begin_from_loadout_index(index, "legacy_loadout")
		end)

		Hooks:PostHook(LoadoutItem, "populate_category", "BriefingBuildMenu_LoadoutItem_populate_category", function(_, category, data)
			BBM:enable_purchase_on_loadout_slots(data, category)
			BBM:enable_inventory_actions_on_loadout_slots(data, category)
		end)
	end
elseif required_script == "lib/managers/menu/blackmarketgui" and not BBM._weapon_purchase_hooks.blackmarket then
	BBM._weapon_purchase_hooks.blackmarket = true

	Hooks:PreHook(BlackMarketGui, "populate_weapon_category_new", "BriefingBuildMenu_BlackMarketGui_populate_weapon_category_new", function(_, data)
		if BBM:is_weapon_purchase_active(data and data.category) then
			data.allow_buy = true
			data.allow_modify = false
			data.allow_preview = false
			data.allow_sell = true
			data.allow_skinning = false
		end
	end)

	Hooks:PostHook(BlackMarketGui, "populate_buy_weapon", "BriefingBuildMenu_BlackMarketGui_populate_buy_weapon", function(_, data)
		BBM:remove_unsafe_purchase_actions(data)
	end)

	Hooks:PostHook(BlackMarketGui, "_sell_weapon_callback", "BriefingBuildMenu_BlackMarketGui_sell_weapon_callback", function(_, data)
		if BBM:is_weapon_purchase_active(data and data.category) then
			BBM:sync_player_outfit_while_open()
		end
	end)
end
