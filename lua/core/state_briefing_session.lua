BriefingEnhanced = BriefingEnhanced or BriefingBuildMenu or {}

local BE = BriefingEnhanced

BE.StateBriefingSession = BE.StateBriefingSession or {}

-- Adopt an open screen created by versions <= 1.6.1 during a SuperBLT reload.
-- The legacy implementation always cleared the outfit block when it closed.
if not BE.StateBriefingSession._session and BE.opened_from_briefing then
	BE.StateBriefingSession._session = {
		screen = BE.opened_from_briefing,
		previous_outfit_block = nil
	}
end

function BE.StateBriefingSession:is_open()
	return self._session ~= nil
end

function BE.StateBriefingSession:current_screen()
	return self._session and self._session.screen or nil
end

function BE.StateBriefingSession:begin(screen_name)
	if self:is_open() then
		return false
	end

	self._session = {
		screen = screen_name,
		previous_outfit_block = Global.block_update_outfit_information
	}
	BE.opened_from_briefing = screen_name
	Global.block_update_outfit_information = true

	if BE.AdapterEhi then
		BE.AdapterEhi:hide_xp_overview()
	end

	if BE.AdapterChat then
		BE.AdapterChat:install()
	end

	return true
end

function BE.StateBriefingSession:reset(expected_screen)
	local session = self._session

	if expected_screen and (not session or session.screen ~= expected_screen) then
		return false
	end

	if session then
		Global.block_update_outfit_information = session.previous_outfit_block
	end

	self._session = nil
	BE.opened_from_briefing = nil

	if BE.AdapterEhi then
		BE.AdapterEhi:show_xp_overview()
	end

	return true
end

function BE.StateBriefingSession:finish(screen_name)
	if not self:reset(screen_name) then
		return false
	end

	local briefing_hud = managers.hud and managers.hud._hud_mission_briefing

	if briefing_hud and briefing_hud._backdrop then
		briefing_hud._backdrop:show()
	end

	BE.ServiceOutfit:update()

	return true
end
