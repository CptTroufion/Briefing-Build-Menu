BriefingEnhanced = BriefingEnhanced or BriefingBuildMenu or {}

local BE = BriefingEnhanced

BE.PresenterWeaponStatistics = BE.PresenterWeaponStatistics or {}

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

local function format_stat(value, round_value)
	if round_value then
		return tostring(math.round(value))
	end

	return string.format("%.1f", value):gsub("%.?0+$", "")
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
			local total_color = total > base_value and "positive"
				or (total < base_value and "negative" or "text")

			if stat.percent and math.round(total) >= 100 then
				total_color = "maxed"
			end

			table.insert(rows, {
				name = managers.localization:text("bm_menu_" .. stat.name),
				total = format_stat(total, stat.round_value),
				base = format_stat(base_value, stat.round_value),
				mods = mods_value == 0
					and ""
					or (mods_value > 0 and "+" or "") .. format_stat(mods_value, stat.round_value),
				skill = skill.skill_in_effect
					and (skill_value > 0 and "+" or "") .. format_stat(skill_value, stat.round_value)
					or "",
				total_color = total_color
			})
		end
	end

	return rows
end

function BE.PresenterWeaponStatistics:get_data(weapon, part)
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

	local adapter_active, adapter_available, extended_rows = BE.AdapterMoreWeaponStats:get_rows(
		weapon,
		preview_blueprint
	)

	return {
		vanilla = vanilla_rows,
		extended = extended_rows,
		more_weapon_stats_active = adapter_active,
		more_weapon_stats_available = adapter_available
	}
end

-- Compatibility facade for versions <= 1.6.1.
function BE:is_more_weapon_stats_active()
	return self.AdapterMoreWeaponStats:is_available()
end

function BE:get_weapon_stats_data(weapon, part)
	return self.PresenterWeaponStatistics:get_data(weapon, part)
end

