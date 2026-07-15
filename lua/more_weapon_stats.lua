BriefingBuildMenu = BriefingBuildMenu or {}

local BBM = BriefingBuildMenu

local VANILLA_STATS = {
	{ round_value = true, name = "magazine" },
	{ round_value = true, name = "totalammo" },
	{ round_value = true, name = "fire_rate" },
	{ name = "damage" },
	{ percent = true, name = "spread" },
	{ percent = true, name = "recoil" },
	{ name = "concealment" },
	{ name = "suppression" }
}

local EXTENDED_STATS = {
	{ setting = "reload_partial", name_id = "mws_reload_partial", method = "mws_reload_partial" },
	{ setting = "reload_full", name_id = "mws_reload_full", method = "mws_reload_full" },
	{ setting = "equip_delay", name_id = "mws_equip_delay", method = "mws_equip_delay" },
	{ setting = "ammo_pickup", name_id = "mws_ammo_pickup", method = "mws_ammo_pickup" },
	{ setting = "recoil_horiz", name_id = "mws_recoil_horiz", method = "mws_recoil_horiz" },
	{ setting = "recoil_vert", name_id = "mws_recoil_vert", method = "mws_recoil_vert" },
	{ setting = "spread", name_id = "mws_spread", method = "mws_spread_horiz" },
	{ setting = "spread_vert", name_id = "mws_spread_vert", method = "mws_spread_vert" },
	{ setting = "falloff", name_id = "mws_falloff", method = "mws_falloff" }
}

local function get_enabled_mod()
	if not (BLT and BLT.Mods and BLT.Mods.GetModByName) then
		return nil
	end

	local mod = BLT.Mods:GetModByName("More Weapon Stats")

	return mod and mod:IsEnabled() and mod or nil
end

function BBM:is_more_weapon_stats_active()
	return get_enabled_mod() ~= nil
		and MoreWeaponStats ~= nil
		and MoreWeaponStats.settings ~= nil
		and Faker ~= nil
		and Faker.make_weapon_base ~= nil
		and Faker.use_game_classes ~= nil
		and Faker.use_normal_classes ~= nil
		and BlackMarketGui ~= nil
end

local function build_preview_blueprint(weapon, part)
	local blueprint = deep_clone(weapon.crafted.blueprint or {})

	if not part or part.equipped or not part.can_modify then
		return blueprint
	end

	managers.weapon_factory:change_part_blueprint_only(
		weapon.crafted.factory_id,
		part.id,
		blueprint,
		false
	)

	return blueprint
end

local function make_weapon_base(weapon, blueprint)
	return Faker:make_weapon_base(
		weapon.crafted.factory_id,
		blueprint,
		weapon.crafted.weapon_id,
		false
	)
end

local function format_stat(value, round_value)
	if round_value then
		return tostring(math.round(value))
	end

	return string.format("%.1f", value):gsub("%.?0+$", "")
end

local function make_text_capture(values, key)
	return {
		set_text = function(_, value)
			values[key] = tostring(value or "")
		end
	}
end

local function read_extended_value(context, method, weapon_base)
	local values = { a1 = "", b1 = "" }
	local texts = {
		a1 = make_text_capture(values, "a1"),
		b1 = make_text_capture(values, "b1")
	}
	local original_lerp = math.lerp
	local success = pcall(method, context, weapon_base, "1", texts)

	math.lerp = original_lerp

	return success and values.a1 .. values.b1 or ""
end

local function build_vanilla_rows(weapon, preview_blueprint)
	if not (WeaponDescription and WeaponDescription._get_stats) then
		return nil
	end

	local success, base_stats, mods_stats, skill_stats = pcall(
		WeaponDescription._get_stats,
		weapon.crafted.weapon_id,
		weapon.category,
		weapon.slot,
		preview_blueprint
	)

	if not success or not (base_stats and mods_stats and skill_stats) then
		return nil
	end

	local rows = {}

	for _, stat in ipairs(VANILLA_STATS) do
		local base = base_stats[stat.name]
		local mods = mods_stats[stat.name]
		local skill = skill_stats[stat.name]

		if base and mods and skill then
			local base_value = base.value or 0
			local mods_value = mods.value or 0
			local skill_value = skill.value or 0
			local total = math.max(base_value + mods_value + skill_value, 0)
			local total_color = total > base_value and "positive" or total < base_value and "negative" or "text"

			if stat.percent and math.round(total) >= 100 then
				total_color = "maxed"
			end

			table.insert(rows, {
				name = managers.localization:text("bm_menu_" .. stat.name),
				total = format_stat(total, stat.round_value),
				base = format_stat(base_value, stat.round_value),
				mods = mods_value == 0 and "" or (mods_value > 0 and "+" or "") .. format_stat(mods_value, stat.round_value),
				skill = skill.skill_in_effect and (skill_value > 0 and "+" or "") .. format_stat(skill_value, stat.round_value) or "",
				total_color = total_color
			})
		end
	end

	return rows
end

local function build_extended_rows(current_base, preview_base)
	local rows = {}
	local display_settings = MoreWeaponStats.settings.display or {}
	local context = {
		mws_ducking = false,
		mws_in_steelsight = false,
		mws_reload_x_ammo = BlackMarketGui.mws_reload_x_ammo
	}

	for _, stat in ipairs(EXTENDED_STATS) do
		local method = BlackMarketGui[stat.method]

		if display_settings[stat.setting] ~= false and method then
			local current = read_extended_value(context, method, current_base)
			local preview = read_extended_value(context, method, preview_base)

			table.insert(rows, {
				name = managers.localization:text(stat.name_id),
				total = preview,
				changed = preview ~= current
			})
		end
	end

	return rows
end

function BBM:get_weapon_stats_data(weapon, part)
	if not weapon or not weapon.crafted.factory_id then
		return nil
	end

	local preview_success, preview_blueprint = pcall(build_preview_blueprint, weapon, part)

	if not preview_success then
		return nil
	end

	local vanilla_rows = build_vanilla_rows(weapon, preview_blueprint)

	if not vanilla_rows then
		return nil
	end

	local data = {
		vanilla = vanilla_rows,
		extended = {},
		more_weapon_stats_active = self:is_more_weapon_stats_active(),
		more_weapon_stats_available = false
	}

	if not data.more_weapon_stats_active then
		return data
	end

	local classes_were_switched = Faker.using_game_classes == true
	local success, extended_rows = pcall(function()
		Faker:use_game_classes()

		local current_blueprint = deep_clone(weapon.crafted.blueprint or {})
		local current_base = make_weapon_base(weapon, current_blueprint)
		local preview_base = make_weapon_base(weapon, preview_blueprint)

		return build_extended_rows(current_base, preview_base)
	end)

	if not classes_were_switched then
		pcall(Faker.use_normal_classes, Faker)
	end

	if success then
		data.extended = extended_rows
		data.more_weapon_stats_available = true
	end

	return data
end
