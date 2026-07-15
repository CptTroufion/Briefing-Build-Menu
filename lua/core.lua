BriefingBuildMenu = BriefingBuildMenu or {}

local BBM = BriefingBuildMenu

BBM.BUTTON_NAME = "briefing_build_menu_button"
BBM.OLD_BUTTON_NAME = "briefing_skilltree_button"

BBM.NODE_NAMES = BBM.NODE_NAMES or {
	skilltree = "briefing_build_menu_skilltree_node",
	specialization = "briefing_build_menu_specialization_node",
	weapon_modifications = "briefing_build_menu_weapon_modifications_node"
}

function BBM:is_open()
	return self.opened_from_briefing ~= nil
end

function BBM:begin_open(screen_name)
	if self:is_open() then
		return false
	end

	self.opened_from_briefing = screen_name
	Global.block_update_outfit_information = true

	self:hide_ehi_xp_overview()

	if self.install_chat_translator_patch then
		self:install_chat_translator_patch()
	end

	if self.install_chat_access_patch then
		self:install_chat_access_patch()
	end

	return true
end

function BBM:reset_open_state(screen_name)
	if screen_name and self.opened_from_briefing ~= screen_name then
		return false
	end

	self.opened_from_briefing = nil
	Global.block_update_outfit_information = nil
	self:show_ehi_xp_overview()

	return true
end

function BBM:update_player_outfit()
	if managers.player then
		managers.player:check_skills()
	end

	if MenuCallbackHandler and MenuCallbackHandler._update_outfit_information then
		MenuCallbackHandler:_update_outfit_information()
	end
end

function BBM:sync_player_outfit_while_open()
	local update_was_blocked = Global.block_update_outfit_information

	Global.block_update_outfit_information = nil
	pcall(self.update_player_outfit, self)
	Global.block_update_outfit_information = update_was_blocked
end

function BBM:finish_open(screen_name)
	if not self:reset_open_state(screen_name) then
		return
	end

	local briefing_hud = managers.hud and managers.hud._hud_mission_briefing

	if briefing_hud and briefing_hud._backdrop then
		briefing_hud._backdrop:show()
	end

	self:update_player_outfit()
end

function BBM:show_error(message_id, error_text)
	QuickMenu:new(
		managers.localization:text("bbm_error_title"),
		managers.localization:text(message_id, { ERROR = tostring(error_text or "unknown error") }),
		{},
		true
	)
end

function BBM:open_node(screen_name, node_name, parameters)
	if not self:begin_open(screen_name) then
		return false
	end

	local success, error_message = pcall(managers.menu.open_node, managers.menu, node_name, parameters)

	if not success then
		self:reset_open_state(screen_name)
		self:show_error("bbm_open_error", error_message)
		return false
	end

	return true
end
