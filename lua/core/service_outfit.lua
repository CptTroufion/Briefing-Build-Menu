BriefingEnhanced = BriefingEnhanced or BriefingBuildMenu or {}

local BE = BriefingEnhanced

BE.ServiceOutfit = BE.ServiceOutfit or {}

function BE.ServiceOutfit:update()
	if managers.player then
		managers.player:check_skills()
	end

	if MenuCallbackHandler and MenuCallbackHandler._update_outfit_information then
		MenuCallbackHandler:_update_outfit_information()
	end
end

function BE.ServiceOutfit:sync_while_blocked()
	local previous_block = Global.block_update_outfit_information

	Global.block_update_outfit_information = nil
	local success, error_message = pcall(self.update, self)
	Global.block_update_outfit_information = previous_block

	return success, error_message
end

