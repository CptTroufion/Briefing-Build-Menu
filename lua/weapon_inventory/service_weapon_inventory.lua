BriefingEnhanced = BriefingEnhanced or BriefingBuildMenu or {}

local BE = BriefingEnhanced

BE.ServiceWeaponInventory = BE.ServiceWeaponInventory or {}

local function is_weapon_category(category)
	return category == "primaries" or category == "secondaries"
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
		add_action(item, "ew_unlock")
	else
		item.cannot_buy = true
		item.mid_text.selected_text = managers.localization:text("bm_menu_cannot_buy_weapon_slot")
		item.mid_text.selected_color = tweak_data.screen_colors.important_1
		item.mid_text.lock_noselected_color = tweak_data.screen_colors.important_1
		item.dlc_locked = item.dlc_locked .. "  " .. managers.localization:to_upper_text("bm_menu_cannot_buy_weapon_slot")
	end
end

function BE.ServiceWeaponInventory:is_kit_menu_active()
	local active_menu = managers.menu and managers.menu:active_menu()

	return active_menu and active_menu.id == "kit_menu"
end

function BE.ServiceWeaponInventory:begin(category, source)
	if not self:is_kit_menu_active() or not is_weapon_category(category) then
		return false
	end

	self.context = {
		category = category,
		source = source
	}

	return true
end

function BE.ServiceWeaponInventory:finish(source)
	if self.context and (not source or self.context.source == source) then
		self.context = nil
	end
end

function BE.ServiceWeaponInventory:is_active(category)
	return self.context ~= nil
		and self:is_kit_menu_active()
		and (not category or self.context.category == category)
end

function BE.ServiceWeaponInventory:configure_inventory_actions(data, category)
	if not self:is_active(category) or not data then
		return
	end

	local crafted_category, last_weapon, last_unlocked_weapon = get_weapon_category_state(category)
	local hold = managers.blackmarket:get_hold_crafted_item()
	local currently_holding = hold and hold.category == category
	local drag_drop_available = BE.AdapterDragDropInventory:is_available()

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
				item.last_weapon = last_weapon
					or (item.unlocked and last_unlocked_weapon)

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

function BE.ServiceWeaponInventory:configure_purchase_slots(data, category)
	if not self:is_active(category) or not data or not data.on_create_data then
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

function BE.ServiceWeaponInventory:remove_unsafe_purchase_actions(data)
	if not self:is_active(data and data.category) then
		return
	end

	for _, item in ipairs(data) do
		remove_action(item, "bw_preview")
		remove_action(item, "bw_preview_mods")
	end
end

-- Compatibility facade for versions <= 1.6.1.
function BE:is_kit_menu_active()
	return self.ServiceWeaponInventory:is_kit_menu_active()
end

function BE:begin_weapon_purchase(category, source)
	return self.ServiceWeaponInventory:begin(category, source)
end

function BE:end_weapon_purchase(source)
	return self.ServiceWeaponInventory:finish(source)
end

function BE:is_weapon_purchase_active(category)
	return self.ServiceWeaponInventory:is_active(category)
end

function BE:enable_inventory_actions_on_loadout_slots(data, category)
	return self.ServiceWeaponInventory:configure_inventory_actions(data, category)
end

function BE:enable_purchase_on_loadout_slots(data, category)
	return self.ServiceWeaponInventory:configure_purchase_slots(data, category)
end

function BE:remove_unsafe_purchase_actions(data)
	return self.ServiceWeaponInventory:remove_unsafe_purchase_actions(data)
end
