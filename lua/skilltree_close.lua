BriefingBuildMenu = BriefingBuildMenu or {}

Hooks:PostHook(NewSkillTreeGui, "_update_legends", "BriefingBuildMenu_NewSkillTreeGui_update_legends", function(self)
	if BriefingBuildMenu.opened_from_briefing ~= "skilltree" then
		return
	end

	local legend_panel = self._panel:child("LegendsPanel")

	if not legend_panel then
		return
	end

	local switch_text = managers.localization:to_upper_text("menu_st_switch_skillset", {
		BTN_SKILLSET = managers.localization:btn_macro("menu_switch_skillset")
	})
	local target = nil

	for _, child in ipairs(legend_panel:children()) do
		if child.text and child:text() == switch_text then
			target = child
			break
		end
	end

	if not target then
		return
	end

	for i = #self._legend_buttons, 1, -1 do
		if self._legend_buttons[i].text == target then
			table.remove(self._legend_buttons, i)
		end
	end

	local dx = target:w() + 10
	legend_panel:remove(target)

	for _, child in ipairs(legend_panel:children()) do
		child:move(dx, 0)
	end
end)

if not BriefingBuildMenu._orig_st_special_btn then
	BriefingBuildMenu._orig_st_special_btn = NewSkillTreeGui.special_btn_pressed

	function NewSkillTreeGui:special_btn_pressed(button)
		if BriefingBuildMenu.opened_from_briefing == "skilltree" and button == Idstring("menu_switch_skillset") then
			return
		end

		return BriefingBuildMenu._orig_st_special_btn(self, button)
	end
end

Hooks:PostHook(NewSkillTreeGui, "close", "BriefingBuildMenu_NewSkillTreeGui_close", function(self)
	BriefingBuildMenu:finish_open("skilltree")
end)
