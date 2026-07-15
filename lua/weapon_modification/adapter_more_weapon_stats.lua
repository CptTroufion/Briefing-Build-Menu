BriefingEnhanced = BriefingEnhanced or BriefingBuildMenu or {}

local BE = BriefingEnhanced

BE.AdapterMoreWeaponStats = BE.AdapterMoreWeaponStats or {}

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

local function make_weapon_base(weapon, blueprint)
	return Faker:make_weapon_base(
		weapon.crafted.factory_id,
		blueprint,
		weapon.crafted.weapon_id,
		false
	)
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

function BE.AdapterMoreWeaponStats:is_available()
	return get_enabled_mod() ~= nil
		and MoreWeaponStats ~= nil
		and MoreWeaponStats.settings ~= nil
		and Faker ~= nil
		and Faker.make_weapon_base ~= nil
		and Faker.use_game_classes ~= nil
		and Faker.use_normal_classes ~= nil
		and BlackMarketGui ~= nil
end

function BE.AdapterMoreWeaponStats:get_rows(weapon, preview_blueprint)
	if not self:is_available() then
		return false, false, {}
	end

	local classes_were_switched = Faker.using_game_classes == true
	local success, rows = pcall(function()
		Faker:use_game_classes()

		local current_blueprint = deep_clone(weapon.crafted.blueprint or {})
		local current_base = make_weapon_base(weapon, current_blueprint)
		local preview_base = make_weapon_base(weapon, preview_blueprint)

		return build_extended_rows(current_base, preview_base)
	end)

	if not classes_were_switched then
		pcall(Faker.use_normal_classes, Faker)
	end

	return true, success, success and rows or {}
end

