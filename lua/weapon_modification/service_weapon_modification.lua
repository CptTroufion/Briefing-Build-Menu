BriefingEnhanced = BriefingEnhanced or BriefingBuildMenu or {}

local BE = BriefingEnhanced

BE.ServiceWeaponModification = BE.ServiceWeaponModification or {}

local function get_equipped_part(weapon, part_type)
	for _, part_id in ipairs(weapon.crafted.blueprint or {}) do
		local part_tweak = tweak_data.weapon.factory.parts[part_id]

		if part_tweak and part_tweak.type == part_type then
			return part_id
		end
	end
end

local function get_default_part(weapon, part_type)
	local default_blueprint = managers.weapon_factory:get_default_blueprint_by_factory_id(weapon.crafted.factory_id)

	for _, part_id in ipairs(default_blueprint or {}) do
		local part_tweak = tweak_data.weapon.factory.parts[part_id]

		if part_tweak and part_tweak.type == part_type then
			return part_id
		end
	end
end

local function is_type_locked(weapon, part_type)
	local lock = weapon.crafted.customize_locked

	if type(lock) == "boolean" then
		return lock
	end

	return type(lock) == "table" and lock[part_type] or false
end

local function get_cosmetic_part(weapon, part_type)
	local cosmetics = weapon.crafted.cosmetics

	if not cosmetics then
		return nil
	end

	local cosmetic_blueprint = managers.weapon_factory:get_cosmetics_blueprint_by_weapon_id(weapon.crafted.weapon_id, cosmetics.id)

	for _, part_id in ipairs(cosmetic_blueprint or {}) do
		local part_tweak = tweak_data.weapon.factory.parts[part_id]

		if part_tweak and part_tweak.type == part_type then
			return part_id
		end
	end
end

local function build_part_data(weapon, raw_part, equipped_part, default_part, cosmetic_part)
	local part_id = raw_part[1]
	local global_value = raw_part[2] or "normal"
	local part_tweak = tweak_data.blackmarket.weapon_mods[part_id]
	local factory_tweak = tweak_data.weapon.factory.parts[part_id]

	if not (part_tweak and factory_tweak) then
		return nil
	end

	local is_default = part_id == default_part
	local is_cosmetic = part_id == cosmetic_part
	local no_consume = is_cosmetic or part_tweak.is_a_unlockable == true
	local amount = (is_default or no_consume)
		and 1
		or managers.blackmarket:get_item_amount(global_value, "weapon_mods", part_id, true)
	local conflict_part = managers.blackmarket:can_modify_weapon(weapon.category, weapon.slot, part_id)
	local can_modify = conflict_part == nil
	local price = managers.money:get_weapon_modify_price(weapon.crafted.weapon_id, part_id, global_value) or 0
	local can_afford = managers.money:can_afford_weapon_modification(weapon.crafted.weapon_id, part_id, global_value)

	return {
		id = part_id,
		name = managers.weapon_factory:get_part_name_by_part_id(part_id),
		global_value = global_value,
		equipped = part_id == equipped_part,
		default_part = default_part,
		no_consume = no_consume,
		available = amount > 0 and can_modify and can_afford,
		amount = amount,
		can_modify = can_modify,
		conflict_part = conflict_part,
		can_afford = can_afford,
		price = price
	}
end

function BE.ServiceWeaponModification:get_equipped_weapon(category)
	if category ~= "primaries" and category ~= "secondaries" then
		return nil
	end

	local slot = managers.blackmarket:equipped_weapon_slot(category)
	local crafted_weapons = managers.blackmarket:get_crafted_category(category)
	local weapon = crafted_weapons and crafted_weapons[slot]

	if not weapon then
		return nil
	end

	return {
		category = category,
		slot = slot,
		crafted = weapon,
		name = managers.blackmarket:get_weapon_name_by_category_slot(category, slot)
	}
end

function BE.ServiceWeaponModification:get_part_types(mods_by_type)
	local part_types = {}

	for part_type, parts in pairs(mods_by_type or {}) do
		if #parts > 0 then
			table.insert(part_types, part_type)
		end
	end

	table.sort(part_types, function(left, right)
		return managers.localization:text("bm_menu_" .. left) < managers.localization:text("bm_menu_" .. right)
	end)

	return part_types
end

function BE.ServiceWeaponModification:get_parts(weapon, part_type, mods_by_type)
	local equipped_part = get_equipped_part(weapon, part_type)
	local default_part = get_default_part(weapon, part_type)
	local cosmetic_part = get_cosmetic_part(weapon, part_type)
	local parts = {}

	for _, raw_part in ipairs(mods_by_type and mods_by_type[part_type] or {}) do
		local part = build_part_data(weapon, raw_part, equipped_part, default_part, cosmetic_part)

		if part then
			part.type_locked = is_type_locked(weapon, part_type)
			table.insert(parts, part)
		end
	end

	table.sort(parts, function(left, right)
		if left.equipped ~= right.equipped then
			return left.equipped
		end

		return left.name < right.name
	end)

	return parts
end

function BE.ServiceWeaponModification:get_data(category)
	local weapon = self:get_equipped_weapon(category)

	if not weapon then
		return nil
	end

	local mods_by_type = managers.blackmarket:get_dropable_mods_by_weapon_id(weapon.crafted.weapon_id, {
		category = weapon.category,
		slot = weapon.slot
	}) or {}
	local part_types = self:get_part_types(mods_by_type)
	local data = {
		weapon = weapon,
		part_types = part_types,
		parts = {}
	}

	for _, part_type in ipairs(part_types) do
		data.parts[part_type] = self:get_parts(weapon, part_type, mods_by_type)
	end

	return data
end

function BE.ServiceWeaponModification:confirm_install(category, part_type, part)
	local weapon = self:get_equipped_weapon(category)

	if not weapon or type(part) ~= "table" or not part.id then
		return
	end

	local replaces, removes = managers.blackmarket:get_modify_weapon_consequence(category, weapon.slot, part.id)
	local params = {
		name = part.name,
		category = category,
		slot = weapon.slot,
		factory_id = weapon.crafted.factory_id,
		weapon_name = managers.weapon_factory:get_weapon_name_by_factory_id(weapon.crafted.factory_id),
		add = true,
		money = part.price > 0 and managers.experience:cash_string(part.price),
		replaces = replaces or {},
		removes = removes or {},
		yes_func = function()
			self:install(category, part_type, part)
		end,
		no_func = function() end
	}

	if part.default_part then
		table.delete(params.replaces, part.default_part)
		table.delete(params.removes, part.default_part)
	end

	managers.menu:show_confirm_blackmarket_mod(params)
end

function BE.ServiceWeaponModification:install(category, part_type, part)
	if type(part) ~= "table" or not part.id then
		return
	end

	local weapon = self:get_equipped_weapon(category)
	local current_part = weapon and build_part_data(
		weapon,
		{ part.id, part.global_value },
		get_equipped_part(weapon, part_type),
		part.default_part,
		get_cosmetic_part(weapon, part_type)
	)

	if not (weapon and current_part and current_part.available) then
		return
	end

	managers.menu_component:post_event("item_buy")
	managers.blackmarket:buy_and_modify_weapon(
		category,
		weapon.slot,
		part.global_value,
		part.id,
		false,
		current_part.no_consume
	)

	weapon = self:get_equipped_weapon(category)
	local installed = weapon and table.contains(weapon.crafted.blueprint or {}, part.id)

	if not installed then
		BE.ServiceDialog:show_error("bbm_weapon_transaction_error", part.id)
		BE.ControllerWeaponModification:refresh()
		return
	end

	local factory_tweak = tweak_data.weapon.factory.parts[part.id]

	if factory_tweak and factory_tweak.texture_switch then
		local default_texture = tweak_data.gui.part_texture_switches[part.id]
			or tweak_data.gui.default_part_texture_switch
		managers.blackmarket:set_part_texture_switch(category, weapon.slot, part.id, default_texture)
	end

	BE.ServiceOutfit:sync_while_blocked()
	BE.ControllerWeaponModification:refresh()
end

function BE.ServiceWeaponModification:confirm_remove(category, part_type, part)
	local weapon = self:get_equipped_weapon(category)

	if not weapon or type(part) ~= "table" or not part.id or part.id == part.default_part then
		return
	end

	local replacement = part.default_part or part.id
	local replaces, removes = managers.blackmarket:get_modify_weapon_consequence(category, weapon.slot, replacement, true)
	local params = {
		name = part.name,
		category = category,
		slot = weapon.slot,
		factory_id = weapon.crafted.factory_id,
		weapon_name = managers.weapon_factory:get_weapon_name_by_factory_id(weapon.crafted.factory_id),
		add = false,
		ignore_lost_mods = part.no_consume,
		replaces = replaces or {},
		removes = removes or {},
		yes_func = function()
			self:remove(category, part_type, part)
		end,
		no_func = function() end
	}

	managers.menu:show_confirm_blackmarket_mod(params)
end

function BE.ServiceWeaponModification:remove(category, part_type, part)
	if type(part) ~= "table" or not part.id then
		return
	end

	local weapon = self:get_equipped_weapon(category)

	if not weapon or get_equipped_part(weapon, part_type) ~= part.id then
		return
	end

	managers.menu_component:post_event("item_sell")

	if part.default_part then
		local default_tweak = tweak_data.blackmarket.weapon_mods[part.default_part]
		local global_value = default_tweak
			and (default_tweak.infamous and "infamous" or default_tweak.dlc)
			or "normal"
		managers.blackmarket:buy_and_modify_weapon(
			category,
			weapon.slot,
			global_value,
			part.default_part,
			true,
			true
		)
	else
		managers.blackmarket:remove_weapon_part(category, weapon.slot, part.global_value, part.id)
	end

	weapon = self:get_equipped_weapon(category)
	local removed = weapon and not table.contains(weapon.crafted.blueprint or {}, part.id)
	local default_restored = not part.default_part
		or (weapon and table.contains(weapon.crafted.blueprint or {}, part.default_part))

	if not (removed and default_restored) then
		BE.ServiceDialog:show_error("bbm_weapon_transaction_error", part.id)
		BE.ControllerWeaponModification:refresh()
		return
	end

	local factory_tweak = tweak_data.weapon.factory.parts[part.id]

	if factory_tweak and factory_tweak.texture_switch then
		managers.blackmarket:set_part_texture_switch(category, weapon.slot, part.id, "1 1")
	end

	BE.ServiceOutfit:sync_while_blocked()
	BE.ControllerWeaponModification:refresh()
end

-- Compatibility facade for versions <= 1.6.1.
function BE:get_equipped_weapon(category)
	return self.ServiceWeaponModification:get_equipped_weapon(category)
end

function BE:get_weapon_modification_data(category)
	return self.ServiceWeaponModification:get_data(category)
end

function BE:get_weapon_part_types(weapon)
	local mods_by_type = managers.blackmarket:get_dropable_mods_by_weapon_id(weapon.crafted.weapon_id, {
		category = weapon.category,
		slot = weapon.slot
	}) or {}

	return self.ServiceWeaponModification:get_part_types(mods_by_type), mods_by_type
end

function BE:get_weapon_parts(weapon, part_type)
	local mods_by_type = managers.blackmarket:get_dropable_mods_by_weapon_id(weapon.crafted.weapon_id, {
		category = weapon.category,
		slot = weapon.slot
	}) or {}

	return self.ServiceWeaponModification:get_parts(weapon, part_type, mods_by_type)
end

function BE:confirm_install_weapon_part(category, part_type, part)
	return self.ServiceWeaponModification:confirm_install(category, part_type, part)
end

function BE:confirm_remove_weapon_part(category, part_type, part)
	return self.ServiceWeaponModification:confirm_remove(category, part_type, part)
end

function BE:install_weapon_part(category, part_type, part)
	return self.ServiceWeaponModification:install(category, part_type, part)
end

function BE:remove_weapon_part(category, part_type, part)
	return self.ServiceWeaponModification:remove(category, part_type, part)
end
