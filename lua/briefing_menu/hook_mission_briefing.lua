local mod_path = ModPath

dofile(mod_path .. "lua/core/bootstrap.lua")
dofile(BriefingEnhanced.ModPath .. "lua/briefing_menu/factory_briefing_node.lua")
dofile(BriefingEnhanced.ModPath .. "lua/skill_tree/controller_skill_tree.lua")
dofile(BriefingEnhanced.ModPath .. "lua/perk_deck/controller_perk_deck.lua")
dofile(BriefingEnhanced.ModPath .. "lua/briefing_menu/controller_briefing_menu.lua")
dofile(BriefingEnhanced.ModPath .. "lua/briefing_menu/view_briefing_button.lua")

local BE = BriefingEnhanced

BE.HookMissionBriefing = BE.HookMissionBriefing or {}

if not BE.HookMissionBriefing.installed then
	BE.HookMissionBriefing.installed = true

	Hooks:PostHook(MissionBriefingGui, "init", "BriefingBuildMenu_MissionBriefingGui_init", function(gui)
		if BE.AdapterEhi then
			BE.AdapterEhi:install()
		end

		BE.StateBriefingSession:reset()
		BE.FactoryBriefingNode:ensure_all()
		BE.ViewBriefingButton:create(gui)
	end)

	Hooks:PostHook(MissionBriefingGui, "hide", "BriefingBuildMenu_MissionBriefingGui_hide", function(gui)
		if not BE.StateBriefingSession:is_open() then
			return
		end

		if alive(gui._panel) then
			gui._panel:set_alpha(0)
		end

		if alive(gui._fullscreen_panel) then
			gui._fullscreen_panel:set_alpha(0)
		end

		local briefing_hud = managers.hud and managers.hud._hud_mission_briefing

		if briefing_hud and briefing_hud._backdrop then
			briefing_hud._backdrop:hide()
		end
	end)

	Hooks:PostHook(MissionBriefingGui, "close", "BriefingBuildMenu_MissionBriefingGui_close", function()
		if BE.StateBriefingSession:is_open() then
			BE.StateBriefingSession:reset()
		end
	end)

	local original_mouse_pressed = Hooks:GetFunction(MissionBriefingGui, "mouse_pressed")

	Hooks:OverrideFunction(MissionBriefingGui, "mouse_pressed", function(gui, button, x, y)
		local build_button = BE.ViewBriefingButton:get(gui)

		if build_button and gui._enabled and not gui._displaying_asset and button == Idstring("0") and build_button:inside(x, y) then
			local state = game_state_machine and game_state_machine:current_state()

			if not (state and state.blackscreen_started and state:blackscreen_started()) then
				managers.menu_component:post_event("menu_enter")
				BE.ControllerBriefingMenu:show()
				return true
			end
		end

		return original_mouse_pressed(gui, button, x, y)
	end)

	local original_mouse_moved = Hooks:GetFunction(MissionBriefingGui, "mouse_moved")

	Hooks:OverrideFunction(MissionBriefingGui, "mouse_moved", function(gui, x, y)
		local build_button = BE.ViewBriefingButton:get(gui)
		local highlighted = build_button
			and gui._enabled
			and not gui._displaying_asset
			and build_button:inside(x, y)

		BE.ViewBriefingButton:set_highlighted(gui, highlighted == true)

		if highlighted then
			return true, "link"
		end

		return original_mouse_moved(gui, x, y)
	end)
end

