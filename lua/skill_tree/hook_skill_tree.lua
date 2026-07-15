local mod_path = ModPath

dofile(mod_path .. "lua/core/bootstrap.lua")
dofile(BriefingEnhanced.ModPath .. "lua/skill_tree/controller_skill_tree.lua")

local BE = BriefingEnhanced

BE.HookSkillTree = BE.HookSkillTree or {}

if not BE.HookSkillTree.installed then
	BE.HookSkillTree.installed = true

	Hooks:PostHook(NewSkillTreeGui, "_update_legends", "BriefingBuildMenu_NewSkillTreeGui_update_legends", function(gui)
		BE.ControllerSkillTree:remove_skill_set_legend(gui)
	end)

	local original_special_button = Hooks:GetFunction(NewSkillTreeGui, "special_btn_pressed")

	Hooks:OverrideFunction(NewSkillTreeGui, "special_btn_pressed", function(gui, button)
		if BE.ControllerSkillTree:should_block_skill_set_switch(button) then
			return
		end

		return original_special_button(gui, button)
	end)

	Hooks:PostHook(NewSkillTreeGui, "close", "BriefingBuildMenu_NewSkillTreeGui_close", function()
		BE.StateBriefingSession:finish("skilltree")
	end)
end

