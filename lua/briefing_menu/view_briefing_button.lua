BriefingEnhanced = BriefingEnhanced or BriefingBuildMenu or {}

local BE = BriefingEnhanced
local Constants = BE.ConstantsBriefingEnhanced

BE.ViewBriefingButton = BE.ViewBriefingButton or {}

function BE.ViewBriefingButton:create(gui)
	if not alive(gui._panel) then
		return nil
	end

	for _, button_name in ipairs({ Constants.LEGACY_SKILL_TREE_BUTTON, Constants.BUILD_BUTTON }) do
		local existing_button = gui._panel:child(button_name)

		if alive(existing_button) then
			gui._panel:remove(existing_button)
		end
	end

	local button = gui._panel:text({
		name = Constants.BUILD_BUTTON,
		text = utf8.to_upper(managers.localization:text("bbm_button")),
		blend_mode = "add",
		layer = 2,
		font = tweak_data.menu.pd2_large_font,
		font_size = tweak_data.menu.pd2_large_font_size * 0.85,
		color = tweak_data.screen_colors.button_stage_3
	})
	local _, _, width, height = button:text_rect()

	button:set_size(width, height)

	if alive(gui._ready_button) then
		button:set_right(gui._ready_button:right())
		button:set_bottom(gui._ready_button:top() - 10)
	else
		button:set_rightbottom(gui._panel:w() - 10, gui._panel:h() - 80)
	end

	return button
end

function BE.ViewBriefingButton:get(gui)
	return alive(gui._panel) and gui._panel:child(Constants.BUILD_BUTTON) or nil
end

function BE.ViewBriefingButton:set_highlighted(gui, highlighted)
	local button = self:get(gui)

	if not button or gui._be_build_button_highlighted == highlighted then
		return
	end

	gui._be_build_button_highlighted = highlighted
	button:set_color(highlighted and tweak_data.screen_colors.button_stage_2 or tweak_data.screen_colors.button_stage_3)

	if highlighted then
		managers.menu_component:post_event("highlight")
	end
end

