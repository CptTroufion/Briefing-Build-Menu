BriefingEnhanced = BriefingEnhanced or BriefingBuildMenu or {}

local BE = BriefingEnhanced

BE.ServiceDialog = BE.ServiceDialog or {}

function BE.ServiceDialog:show_error(message_id, error_text)
	QuickMenu:new(
		managers.localization:text("bbm_error_title"),
		managers.localization:text(message_id, { ERROR = tostring(error_text or "unknown error") }),
		{},
		true
	)
end

