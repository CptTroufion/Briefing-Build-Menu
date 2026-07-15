BriefingEnhanced = BriefingEnhanced or BriefingBuildMenu or {}

local BE = BriefingEnhanced

BE.ControllerSkillTree = BE.ControllerSkillTree or {}

function BE.ControllerSkillTree:open()
	if BE.FactoryBriefingNode:ensure_all() then
		BE.ControllerMenuNavigation:open(
			"skilltree",
			BE.ConstantsBriefingEnhanced.NODE_NAMES.skill_tree
		)
	end
end

function BE.ControllerSkillTree:remove_skill_set_legend(gui)
	if BE.StateBriefingSession:current_screen() ~= "skilltree" then
		return
	end

	local legend_panel = gui._panel:child("LegendsPanel")

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

	for index = #gui._legend_buttons, 1, -1 do
		if gui._legend_buttons[index].text == target then
			table.remove(gui._legend_buttons, index)
		end
	end

	local offset = target:w() + 10
	legend_panel:remove(target)

	for _, child in ipairs(legend_panel:children()) do
		child:move(offset, 0)
	end
end

function BE.ControllerSkillTree:should_block_skill_set_switch(button)
	return BE.StateBriefingSession:current_screen() == "skilltree"
		and button == Idstring("menu_switch_skillset")
end

-- Compatibility facade for versions <= 1.6.1.
function BE:open_skilltree()
	return self.ControllerSkillTree:open()
end
