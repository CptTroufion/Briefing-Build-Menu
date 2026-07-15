BriefingEnhanced = BriefingEnhanced or BriefingBuildMenu or {}

local BE = BriefingEnhanced

BE.ControllerMenuNavigation = BE.ControllerMenuNavigation or {}

function BE.ControllerMenuNavigation:open(screen_name, node_name, parameters)
	if not BE.StateBriefingSession:begin(screen_name) then
		return false
	end

	local success, error_message = pcall(managers.menu.open_node, managers.menu, node_name, parameters)

	if not success then
		BE.StateBriefingSession:reset(screen_name)
		BE.ServiceDialog:show_error("bbm_open_error", error_message)
		return false
	end

	return true
end

