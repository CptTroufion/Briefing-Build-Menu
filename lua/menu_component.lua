BriefingBuildMenu = BriefingBuildMenu or {}

local BBM = BriefingBuildMenu

function MenuComponentManager:create_bbm_weapon_modifications(node)
	self:close_bbm_weapon_modifications()

	if not BriefingWeaponModificationsGui then
		BBM:show_error("bbm_open_error", "Weapon modifications UI is not loaded.")
		return
	end

	self._bbm_weapon_modifications = BriefingWeaponModificationsGui:new(
		self:saferect_ws(),
		self:fullscreen_ws(),
		node
	)
	self:register_component("bbm_weapon_modifications", self._bbm_weapon_modifications)
end

function MenuComponentManager:close_bbm_weapon_modifications()
	if self._bbm_weapon_modifications then
		self:unregister_component("bbm_weapon_modifications")
		self._bbm_weapon_modifications:close()
		self._bbm_weapon_modifications = nil
	end

	if BBM:is_open() and BBM.opened_from_briefing == "weapon_modifications" then
		BBM:finish_open("weapon_modifications")
	end
end
