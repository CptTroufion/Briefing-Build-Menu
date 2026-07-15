BriefingEnhanced = BriefingEnhanced or BriefingBuildMenu or {}

local BE = BriefingEnhanced

-- Compatibility facade for integrations or local code written against versions <= 1.6.1.
function BE:is_open()
	return self.StateBriefingSession:is_open()
end

function BE:begin_open(screen_name)
	return self.StateBriefingSession:begin(screen_name)
end

function BE:reset_open_state(screen_name)
	return self.StateBriefingSession:reset(screen_name)
end

function BE:update_player_outfit()
	return self.ServiceOutfit:update()
end

function BE:sync_player_outfit_while_open()
	return self.ServiceOutfit:sync_while_blocked()
end

function BE:finish_open(screen_name)
	return self.StateBriefingSession:finish(screen_name)
end

function BE:show_error(message_id, error_text)
	return self.ServiceDialog:show_error(message_id, error_text)
end

function BE:open_node(screen_name, node_name, parameters)
	return self.ControllerMenuNavigation:open(screen_name, node_name, parameters)
end

