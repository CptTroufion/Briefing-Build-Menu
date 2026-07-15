local mod_path = ModPath

dofile(mod_path .. "lua/core/bootstrap.lua")

local BE = BriefingEnhanced
local component_id = BE.ConstantsBriefingEnhanced.WEAPON_COMPONENT

function MenuComponentManager:create_be_component_weapon_modification(node)
	self:close_be_component_weapon_modification()

	if not BE.ComponentWeaponModification then
		BE.ServiceDialog:show_error("bbm_open_error", "Weapon modifications UI is not loaded.")
		return
	end

	self._be_component_weapon_modification = BE.ComponentWeaponModification:new(
		self:saferect_ws(),
		self:fullscreen_ws(),
		node
	)
	self._bbm_weapon_modifications = self._be_component_weapon_modification
	self:register_component(component_id, self._be_component_weapon_modification)
end

function MenuComponentManager:close_be_component_weapon_modification()
	local component = self._be_component_weapon_modification or self._bbm_weapon_modifications

	if component then
		self:unregister_component(component_id)
		component:close()
		self._be_component_weapon_modification = nil
		self._bbm_weapon_modifications = nil
	end

	if BE.StateBriefingSession:current_screen() == "weapon_modifications" then
		BE.StateBriefingSession:finish("weapon_modifications")
	end
end

-- Legacy manager methods kept for compatibility with versions <= 1.6.1.
function MenuComponentManager:create_bbm_weapon_modifications(node)
	return self:create_be_component_weapon_modification(node)
end

function MenuComponentManager:close_bbm_weapon_modifications()
	return self:close_be_component_weapon_modification()
end
